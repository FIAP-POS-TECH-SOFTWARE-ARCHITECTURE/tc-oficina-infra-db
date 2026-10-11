#!/usr/bin/env bash
# Recria o ambiente da oficina (ex.: depois de um reset da conta do AWS
# Academy) disparando, em ordem, o workflow de CD de cada repositório e
# esperando cada execução terminar com sucesso antes de seguir.
#
# Ordem:
#   1. tc-oficina-infra-k8s (main)  - VPC, EKS, ECR, SNS/SQS
#   2. tc-oficina-infra-db  (main)  - RDS, DynamoDB, segredos no SSM
#   3. por ambiente: os-service -> billing-service -> execution-service -> lambda-auth
#      A Lambda/API Gateway lê do SSM o hostname do LoadBalancer de cada
#      serviço, publicado pelo CD do serviço; por isso roda por último.
#
# A infraestrutura é única para os dois ambientes e sempre roda a partir de
# main. Serviços e Lambda usam a branch do ambiente: develop -> homolog,
# main -> prod.
#
# Uso:
#   scripts/subir-tudo.sh <homolog|prod|todos> [--pular-ausentes] [--simular]
#
#   --pular-ausentes  segue sem os repositórios que ainda não têm cd.yml com
#                     workflow_dispatch na branch alvo (padrão: abortar)
#   --simular         só verifica os pré-requisitos e mostra a sequência
#
# Pré-requisitos: gh autenticado com acesso à organização; AWS CLI com as
# credenciais da sessão atual do lab; secrets AWS_* dos repositórios
# atualizados (scripts/aws-academy-refresh.ps1 no tc-oficina-os-service).
set -euo pipefail

ORG="FIAP-POS-TECH-SOFTWARE-ARCHITECTURE"
WORKFLOW="cd.yml"
IDADE_MAXIMA_SECRETS_MIN=240
INFRA=(tc-oficina-infra-k8s tc-oficina-infra-db)
SERVICOS=(tc-oficina-os-service tc-oficina-billing-service tc-oficina-execution-service tc-oficina-lambda-auth)

uso() {
  echo "Uso: $0 <homolog|prod|todos> [--pular-ausentes] [--simular]" >&2
  exit 2
}

falha() {
  echo "ERRO: $*" >&2
  exit 1
}

[ $# -ge 1 ] || uso
ALVO="$1"
shift
PULAR_AUSENTES=0
SIMULAR=0
for arg in "$@"; do
  case "$arg" in
    --pular-ausentes) PULAR_AUSENTES=1 ;;
    --simular) SIMULAR=1 ;;
    *) uso ;;
  esac
done

case "$ALVO" in
  homolog) AMBIENTES=(homolog) ;;
  prod) AMBIENTES=(prod) ;;
  todos) AMBIENTES=(homolog prod) ;;
  *) uso ;;
esac

branch_do_ambiente() {
  if [ "$1" = "prod" ]; then echo main; else echo develop; fi
}

# Sequência de passos "repositorio branch", na ordem de execução
PASSOS=()
for repo in "${INFRA[@]}"; do
  PASSOS+=("$repo main")
done
for ambiente in "${AMBIENTES[@]}"; do
  ref=$(branch_do_ambiente "$ambiente")
  for repo in "${SERVICOS[@]}"; do
    PASSOS+=("$repo $ref")
  done
done

echo "== Pré-requisitos"
command -v gh >/dev/null || falha "gh não encontrado no PATH"
command -v aws >/dev/null || falha "aws não encontrado no PATH"
gh auth status >/dev/null 2>&1 || falha "gh não autenticado (gh auth login)"
ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null) \
  || falha "credenciais AWS locais inválidas ou expiradas (rode aws-academy-refresh.ps1)"
echo "AWS: $ARN"

AGORA=$(date -u +%s)
AUSENTES=" "
VERIFICADOS=" "
for passo in "${PASSOS[@]}"; do
  read -r repo ref <<<"$passo"
  if ! gh workflow view "$WORKFLOW" -R "$ORG/$repo" --ref "$ref" --yaml 2>/dev/null | grep -q 'workflow_dispatch'; then
    if [ "$PULAR_AUSENTES" = 1 ]; then
      echo "AVISO: $repo@$ref sem $WORKFLOW com workflow_dispatch; será pulado"
      AUSENTES+="$repo@$ref "
      continue
    fi
    falha "$repo@$ref sem $WORKFLOW com workflow_dispatch (use --pular-ausentes para seguir sem ele)"
  fi
  case "$VERIFICADOS" in *" $repo "*) continue ;; esac
  atualizado=$(gh secret list -R "$ORG/$repo" --json name,updatedAt \
    --jq '.[] | select(.name == "AWS_SESSION_TOKEN") | .updatedAt')
  [ -n "$atualizado" ] || falha "$repo sem secret AWS_SESSION_TOKEN"
  idade=$(((AGORA - $(date -u -d "$atualizado" +%s)) / 60))
  [ "$idade" -le "$IDADE_MAXIMA_SECRETS_MIN" ] \
    || falha "secrets AWS de $repo atualizados há $idade min (a sessão do lab dura 4h): rode aws-academy-refresh.ps1"
  VERIFICADOS+="$repo "
done

echo "== Sequência"
for passo in "${PASSOS[@]}"; do
  read -r repo ref <<<"$passo"
  case "$AUSENTES" in
    *" $repo@$ref "*) echo "  (pulado) $repo@$ref" ;;
    *) echo "  $repo@$ref" ;;
  esac
done
if [ "$SIMULAR" = 1 ]; then
  echo "Simulação: nada foi disparado."
  exit 0
fi

ultimo_run() { # $1 repositório, $2 branch
  gh run list -R "$ORG/$1" --workflow "$WORKFLOW" --branch "$2" --event workflow_dispatch \
    --limit 1 --json databaseId --jq '.[0].databaseId // 0'
}

disparar_e_esperar() { # $1 repositório, $2 branch
  local repo="$1" ref="$2" antes atual id=""
  antes=$(ultimo_run "$repo" "$ref")
  echo "== $repo@$ref: disparando $WORKFLOW"
  gh workflow run "$WORKFLOW" -R "$ORG/$repo" --ref "$ref"
  # O run criado pelo dispatch não é devolvido pelo gh: espera surgir um id
  # maior que o último existente antes do disparo.
  for _ in $(seq 1 30); do
    sleep 4
    atual=$(ultimo_run "$repo" "$ref")
    if [ "$atual" -gt "$antes" ]; then
      id="$atual"
      break
    fi
  done
  [ -n "$id" ] || falha "execução de $repo@$ref não apareceu em 2 min"
  echo "   https://github.com/$ORG/$repo/actions/runs/$id"
  if ! gh run watch "$id" -R "$ORG/$repo" --exit-status --interval 15 >/dev/null; then
    falha "$repo@$ref falhou. Detalhes: gh run view $id -R $ORG/$repo --log-failed"
  fi
  echo "   concluído"
}

INICIO=$(date +%s)
for passo in "${PASSOS[@]}"; do
  read -r repo ref <<<"$passo"
  case "$AUSENTES" in *" $repo@$ref "*) continue ;; esac
  disparar_e_esperar "$repo" "$ref"
done
echo "== Ambiente pronto em $((($(date +%s) - INICIO) / 60)) min"
