<#
.SYNOPSIS
    Instala/atualiza o OpenClaw (Jarvis) no Windows, reforça a segurança do
    WhatsApp e cria automações - tudo com confirmação a cada passo.

.DESCRIPTION
    Baseado na documentação oficial do OpenClaw (github.com/openclaw/openclaw, pasta docs/).
    O script NÃO guarda senhas, tokens nem o seu número em arquivo: tudo é
    perguntado na hora. Cada etapa pergunta "S/N" antes de mudar algo.
    Um registro (log) completo fica em %USERPROFILE%\jarvis-setup-logs.

.NOTES
    Como rodar (PowerShell normal, NÃO precisa ser administrador):
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\jarvis-setup.ps1
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------- utilidades
function Escrever-Titulo($texto) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host "  $texto" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
}

function Confirmar($pergunta) {
    while ($true) {
        $r = Read-Host "$pergunta [S/N]"
        if ($r -match '^(s|sim)$') { return $true }
        if ($r -match '^(n|nao|não)$') { return $false }
        Write-Host "Responda S ou N." -ForegroundColor Yellow
    }
}

function Rodar($descricao, [scriptblock]$comando) {
    Write-Host "-> $descricao" -ForegroundColor Gray
    try {
        $global:LASTEXITCODE = 0
        & $comando
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Write-Host "   AVISO: terminou com código $LASTEXITCODE." -ForegroundColor Yellow
            return $false
        }
        Write-Host "   OK" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function OpenClaw-Instalado {
    return [bool](Get-Command openclaw -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------- log
$pastaLog = Join-Path $env:USERPROFILE 'jarvis-setup-logs'
New-Item -ItemType Directory -Force -Path $pastaLog | Out-Null
$arquivoLog = Join-Path $pastaLog ("setup-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $arquivoLog | Out-Null

Escrever-Titulo "Configuração do Jarvis (OpenClaw) - passo a passo"
Write-Host "Nada será alterado sem a sua confirmação. Log: $arquivoLog"

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "É necessário PowerShell 5 ou superior." -ForegroundColor Red
    Stop-Transcript | Out-Null; exit 1
}

# ---------------------------------------------------------------- 1. backup
$jaInstalado = OpenClaw-Instalado
if ($jaInstalado) {
    Escrever-Titulo "1/6 - Backup de segurança"
    Write-Host "O OpenClaw já está instalado. Antes de mexer, é recomendado um backup verificado."
    if (Confirmar "Criar backup agora (openclaw backup create --verify)?") {
        Rodar "Criando backup" { openclaw backup create --verify } | Out-Null
    }
} else {
    Write-Host "`nOpenClaw não encontrado neste computador - o backup será pulado."
}

# ---------------------------------------------------------------- 2. instalar/atualizar
Escrever-Titulo "2/6 - Instalar ou atualizar o OpenClaw"
if ($jaInstalado) {
    Write-Host "Versão atual:"; openclaw --version
    if (Confirmar "Atualizar para a versão mais recente (openclaw update)?") {
        Rodar "Atualizando" { openclaw update } | Out-Null
    }
} else {
    Write-Host "Será baixado o instalador OFICIAL: https://openclaw.ai/install.ps1"
    Write-Host "Ele instala o Node.js (se faltar) e o OpenClaw, e depois inicia a configuração inicial."
    if (Confirmar "Baixar o instalador oficial para revisão?") {
        $instalador = Join-Path $env:TEMP 'openclaw-install.ps1'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://openclaw.ai/install.ps1' -OutFile $instalador
        $hash = (Get-FileHash $instalador -Algorithm SHA256).Hash
        Write-Host "Instalador salvo em: $instalador"
        Write-Host "SHA-256: $hash"
        Write-Host "(Se quiser, abra o arquivo no Bloco de Notas para conferir antes.)"
        if (Confirmar "Executar o instalador agora?") {
            Rodar "Instalando OpenClaw" { & $instalador } | Out-Null
            # Recarrega o PATH do usuário para encontrar o comando novo
            $env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' +
                        [Environment]::GetEnvironmentVariable('Path','Machine')
        }
    }
}

if (-not (OpenClaw-Instalado)) {
    Write-Host "`nO comando 'openclaw' não foi encontrado. Feche e abra o PowerShell e rode o script de novo." -ForegroundColor Yellow
    Stop-Transcript | Out-Null; exit 1
}

# ---------------------------------------------------------------- 3. doctor
Escrever-Titulo "3/6 - Diagnóstico e correções automáticas (doctor)"
Rodar "Diagnóstico somente leitura" { openclaw doctor } | Out-Null
if (Confirmar "Aplicar as correções seguras sugeridas (openclaw doctor --fix)?") {
    Rodar "Aplicando correções" { openclaw doctor --fix } | Out-Null
}

# ---------------------------------------------------------------- 4. segurança WhatsApp
Escrever-Titulo "4/6 - Segurança do WhatsApp (só você fala com o Jarvis)"
Write-Host @"
Recomendação da documentação oficial:
  - dmPolicy = "allowlist"  -> desconhecidos são bloqueados, sem pedido de pareamento
  - allowFrom = [seu número] -> só você pode mandar mensagem ao Jarvis
  - groupPolicy = "allowlist" -> em grupos, só números autorizados acionam o Jarvis
  - fuso horário = America/Sao_Paulo
Antes de aplicar, a configuração atual do WhatsApp será mostrada.
"@
Write-Host "`nConfiguração atual (segredos nunca aparecem):"
openclaw config get channels.whatsapp

if (Confirmar "Aplicar o reforço de segurança acima?") {
    do {
        $numero = Read-Host "Seu número no formato internacional (ex.: +5511999999999)"
    } until ($numero -match '^\+\d{10,15}$')

    $lista = '["' + $numero + '"]'
    Rodar "dmPolicy = allowlist"   { openclaw config set channels.whatsapp.dmPolicy "allowlist" } | Out-Null
    Rodar "allowFrom = seu número" { openclaw config set channels.whatsapp.allowFrom $lista --strict-json } | Out-Null
    Rodar "groupPolicy = allowlist" { openclaw config set channels.whatsapp.groupPolicy "allowlist" } | Out-Null
    Rodar "groupAllowFrom = seu número" { openclaw config set channels.whatsapp.groupAllowFrom $lista --strict-json } | Out-Null
    Rodar "Fuso horário São Paulo" { openclaw config set agents.defaults.userTimezone "America/Sao_Paulo" } | Out-Null
    Rodar "Validando configuração" { openclaw config validate } | Out-Null
} else {
    $numero = $null
}

# ---------------------------------------------------------------- 5. auditoria
Escrever-Titulo "5/6 - Auditoria de segurança"
Rodar "Auditoria completa (openclaw security audit --deep)" { openclaw security audit --deep } | Out-Null
Write-Host "Leia os avisos acima. O --fix só aplica correções seguras (permissões e padrões mais restritos)."
if (Confirmar "Aplicar as correções seguras da auditoria (openclaw security audit --fix)?") {
    Rodar "Corrigindo" { openclaw security audit --fix } | Out-Null
}

# ---------------------------------------------------------------- 6. automações
Escrever-Titulo "6/6 - Automações (Jarvis mais proativo)"
Write-Host "Automações existentes:"
openclaw automations list --all

if ($numero -and (Confirmar "Criar o 'Resumo da manhã' (seg a sex, 07:50, enviado no seu WhatsApp, em pt-BR)?")) {
    Rodar "Criando Resumo da manhã" {
        openclaw automations create "50 7 * * 1-5" `
            "Faça um resumo da manhã em português do Brasil: compromissos do dia, pendências e lembretes importantes. Seja breve. Nunca inclua senhas, códigos ou dados sensíveis. Não execute nenhuma ação, apenas informe." `
            --name "Resumo da manha" `
            --tz "America/Sao_Paulo" `
            --session isolated `
            --announce `
            --channel whatsapp `
            --to $numero
    } | Out-Null
}

if ($numero -and (Confirmar "Criar o 'Fechamento do dia' (seg a sex, 18:40, enviado no seu WhatsApp, em pt-BR)?")) {
    Rodar "Criando Fechamento do dia" {
        openclaw automations create "40 18 * * 1-5" `
            "Faça um fechamento do dia em português do Brasil: o que foi feito, o que ficou pendente e o que precisa da minha aprovação amanhã. Seja breve. Não execute nenhuma ação, apenas informe." `
            --name "Fechamento do dia" `
            --tz "America/Sao_Paulo" `
            --session isolated `
            --announce `
            --channel whatsapp `
            --to $numero
    } | Out-Null
}

# ---------------------------------------------------------------- final
Escrever-Titulo "Concluído"
Rodar "Status do gateway" { openclaw gateway status } | Out-Null
Write-Host @"

Próximos passos (manuais, por segurança):
  - Para conectar o WhatsApp (se ainda não estiver): openclaw channels login --channel whatsapp
  - Para ver/editar automações:                     openclaw automations list --all
  - Para procurar skills (NÃO instala nada):         openclaw skills search "calendar"
    Só instale skills de publicadores oficiais ou que você revisou.

Log completo salvo em: $arquivoLog
"@
Stop-Transcript | Out-Null
