#!/usr/bin/env bash
# Executado DENTRO do Ubuntu (WSL) pelo jarvis-wsl-parte2.ps1.
# Instala OpenClaw + Claude Code + claude-mem (modo privado). Cada passo pede S/N.
set -euo pipefail

confirmar() {
  local r
  while true; do
    read -r -p "$1 [S/N] " r </dev/tty
    case "${r,,}" in s|sim) return 0 ;; n|nao|não) return 1 ;; esac
  done
}
titulo() { printf '\n\033[36m=== %s ===\033[0m\n' "$1"; }
baixar_e_revisar() { # $1 = url, $2 = arquivo
  curl -fsSL --proto '=https' --tlsv1.2 "$1" -o "$2"
  echo "Baixado: $2"
  echo "SHA-256: $(sha256sum "$2" | cut -d' ' -f1)"
  echo "(Para conferir o conteúdo antes: less $2)"
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ------------------------------------------------------------- A. systemd
titulo "A - Pré-requisitos do Ubuntu"
if [ "$(ps -p 1 -o comm=)" != "systemd" ]; then
  echo "O systemd não está ativo no WSL (necessário para o Jarvis rodar como serviço)."
  if confirmar "Ativar o systemd em /etc/wsl.conf?"; then
    printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null
    echo
    echo "Ativado. Agora, no PowerShell, rode:  wsl --shutdown"
    echo "e depois rode a PARTE 2 de novo."
  fi
  exit 1
fi
if confirmar "Atualizar o Ubuntu e instalar curl/git (sudo apt)?"; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get install -y curl git ca-certificates
fi
# Mantém os serviços do usuário rodando mesmo sem terminal aberto
loginctl enable-linger "$USER" || true

# ------------------------------------------------------------- B. OpenClaw
titulo "B - OpenClaw (Jarvis) no Ubuntu"
if command -v openclaw >/dev/null 2>&1; then
  echo "OpenClaw já instalado: $(openclaw --version)"
else
  echo "Instalador OFICIAL: https://openclaw.ai/install.sh"
  baixar_e_revisar "https://openclaw.ai/install.sh" "$TMP/openclaw-install.sh"
  if confirmar "Executar o instalador do OpenClaw?"; then
    bash "$TMP/openclaw-install.sh" --no-onboard
    export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
    hash -r
  else
    echo "Sem OpenClaw não há como continuar."; exit 1
  fi
fi

# Copiar a "personalidade"/arquivos do Jarvis do Windows (opcional)
if [ -n "${JARVIS_WIN_WORKSPACE:-}" ] && [ -d "$JARVIS_WIN_WORKSPACE" ]; then
  echo
  echo "Encontrei a pasta de trabalho do Jarvis do Windows:"
  echo "  $JARVIS_WIN_WORKSPACE"
  echo "Ela tem os arquivos de instruções/memória do Jarvis (regras que você criou)."
  if confirmar "Copiar essa pasta para o Jarvis do Ubuntu?"; then
    mkdir -p "$HOME/.openclaw"
    if [ -e "$HOME/.openclaw/workspace" ]; then
      mv "$HOME/.openclaw/workspace" "$HOME/.openclaw/workspace.bak-$(date +%Y%m%d%H%M%S)"
    fi
    cp -r "$JARVIS_WIN_WORKSPACE" "$HOME/.openclaw/workspace"
    chmod -R go-rwx "$HOME/.openclaw"
    echo "Copiado."
  fi
fi

echo
echo "Agora vem a configuração inicial do OpenClaw (onboarding)."
echo "  - Escolha WhatsApp como canal e escaneie o QR pelo celular"
echo "    (WhatsApp > Aparelhos conectados > Conectar aparelho)."
echo "  - Quando perguntar o modo, use seu número pessoal com allowlist (só você)."
if confirmar "Iniciar a configuração inicial agora?"; then
  openclaw onboard --install-daemon
fi

titulo "Segurança do WhatsApp"
read -r -p "Seu número no formato internacional (ex.: +5511999999999): " NUMERO </dev/tty
until [[ "$NUMERO" =~ ^\+[0-9]{10,15}$ ]]; do
  read -r -p "Formato inválido. Ex.: +5511999999999: " NUMERO </dev/tty
done
if confirmar "Aplicar: só o seu número fala com o Jarvis (DM e grupos) + fuso São Paulo?"; then
  openclaw config set channels.whatsapp.dmPolicy "allowlist"
  openclaw config set channels.whatsapp.allowFrom "[\"$NUMERO\"]" --strict-json
  openclaw config set channels.whatsapp.groupPolicy "allowlist"
  openclaw config set channels.whatsapp.groupAllowFrom "[\"$NUMERO\"]" --strict-json
  openclaw config set agents.defaults.userTimezone "America/Sao_Paulo"
  openclaw config validate
fi
openclaw doctor || true
if confirmar "Aplicar correções seguras (doctor --fix)?"; then openclaw doctor --fix; fi
openclaw security audit --deep || true
if confirmar "Aplicar correções seguras da auditoria (security audit --fix)?"; then
  openclaw security audit --fix
fi

# ------------------------------------------------------------- C. Claude Code
titulo "C - Claude Code (usado pelo claude-mem para os resumos, no seu plano)"
if ! command -v claude >/dev/null 2>&1; then
  echo "Instalador OFICIAL da Anthropic: https://claude.ai/install.sh"
  baixar_e_revisar "https://claude.ai/install.sh" "$TMP/claude-install.sh"
  if confirmar "Instalar o Claude Code?"; then
    bash "$TMP/claude-install.sh"
    export PATH="$HOME/.local/bin:$PATH"; hash -r
  fi
fi
if command -v claude >/dev/null 2>&1; then
  echo
  echo "Agora faça login no Claude com a SUA conta: vai abrir o 'claude'."
  echo "Dentro dele digite  /login , conclua no navegador e depois digite  /exit"
  if confirmar "Abrir o Claude para login agora?"; then claude </dev/tty || true; fi
fi

# ------------------------------------------------------------- D. claude-mem (privado)
titulo "D - claude-mem em modo privado"
cat <<'EOF'
Ajustes de privacidade que serão aplicados ANTES da instalação:
  - Estatísticas de uso (telemetria): DESLIGADAS
  - Captura de prints/imagens: DESLIGADA
  - Sincronização na nuvem (cmem.ai): NÃO ativada, sem cadastro e sem cartão
  - Servidor local só em 127.0.0.1 (não acessível pela rede)
  - IA de resumo: seu plano Claude (o texto vai para a Anthropic para ser resumido)
EOF
if confirmar "Instalar o claude-mem com esses ajustes?"; then
  mkdir -p "$HOME/.claude-mem"; chmod 700 "$HOME/.claude-mem"
  CFG="$HOME/.claude-mem/settings.json"
  # O instalador preserva chaves já existentes neste arquivo.
  python3 - "$CFG" <<'PY'
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.exists(p):
    try: d = json.load(open(p))
    except Exception: d = {}
d.update({
    "CLAUDE_MEM_TELEMETRY": "0",
    "CLAUDE_MEM_MEDIA_CAPTURE_ENABLED": "false",
    "CLAUDE_MEM_MEDIA_INFERENCE_ENABLED": "false",
    "CLAUDE_MEM_WORKER_HOST": "127.0.0.1",
    "CLAUDE_MEM_PROVIDER": "claude",
})
json.dump(d, open(p, "w"), indent=2)
PY
  chmod 600 "$CFG"
  export CLAUDE_MEM_TELEMETRY=0 DO_NOT_TRACK=1 CLAUDE_MEM_ONLINE_OPTIN=false
  for linha in 'export CLAUDE_MEM_TELEMETRY=0' 'export DO_NOT_TRACK=1' 'export CLAUDE_MEM_ONLINE_OPTIN=false'; do
    grep -qxF "$linha" "$HOME/.bashrc" || echo "$linha" >> "$HOME/.bashrc"
  done

  echo "Instalador do claude-mem para OpenClaw: https://install.cmem.ai/openclaw.sh"
  baixar_e_revisar "https://install.cmem.ai/openclaw.sh" "$TMP/cmem-openclaw.sh"
  if confirmar "Executar o instalador do claude-mem?"; then
    bash "$TMP/cmem-openclaw.sh" --provider claude
    echo
    echo "Se o instalador perguntar sobre 'feeds' para Telegram/Discord/Slack: responda NÃO."
    npx --yes claude-mem telemetry disable || true
  fi
fi

# ------------------------------------------------------------- E. verificação
titulo "E - Verificação final"
openclaw gateway status || true
curl -s -o /dev/null -w "claude-mem local (127.0.0.1:37777): HTTP %{http_code}\n" \
  http://127.0.0.1:37777/api/health || echo "claude-mem ainda não respondeu."
echo
echo "Pronto. Agora mande uma mensagem ao Jarvis no WhatsApp para testar."
