<#
.SYNOPSIS
    PARTE 2 de 2 - Move o Jarvis (OpenClaw) para o WSL e instala o claude-mem
    em modo privado.

.DESCRIPTION
    Rode em PowerShell NORMAL (não administrador), depois da Parte 1 e do
    primeiro acesso ao Ubuntu (usuário/senha criados).

    O que acontece (cada passo pede S/N):
      1. Backup do Jarvis atual no Windows (nada é apagado);
      2. Desliga o Jarvis do Windows (para não haver dois Jarvis no mesmo WhatsApp);
      3. Dentro do Ubuntu: instala OpenClaw + Claude Code + claude-mem
         (arquivo jarvis-wsl-parte2.sh, que fica na mesma pasta deste script);
      4. Cria uma tarefa para o Jarvis iniciar sozinho quando você entrar no Windows;
      5. Só no final, e se tudo funcionar, oferece remover o serviço antigo do Windows.

    Como rodar:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\jarvis-wsl-parte2.ps1
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Distro = 'Ubuntu'

function Confirmar($pergunta) {
    while ($true) {
        $r = Read-Host "$pergunta [S/N]"
        if ($r -match '^(s|sim)$') { return $true }
        if ($r -match '^(n|nao|não)$') { return $false }
    }
}
function Titulo($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

$pastaLog = Join-Path $env:USERPROFILE 'jarvis-setup-logs'
New-Item -ItemType Directory -Force -Path $pastaLog | Out-Null
Start-Transcript -Path (Join-Path $pastaLog ("wsl-parte2-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")) | Out-Null

# ---------------------------------------------------------------- verificações
Titulo "Verificando o Ubuntu (WSL)"
$lista = (wsl.exe --list --quiet 2>$null | Out-String) -replace "`0", ''
if ($lista -notmatch $Distro) {
    Write-Host "Ubuntu não encontrado. Rode a PARTE 1 primeiro." -ForegroundColor Red
    Stop-Transcript | Out-Null; exit 1
}
$usuarioLinux = (wsl.exe -d $Distro -- whoami | Out-String).Trim()
if (-not $usuarioLinux -or $usuarioLinux -eq 'root') {
    Write-Host "Abra o 'Ubuntu' no menu Iniciar uma vez e crie seu usuário/senha. Depois rode de novo." -ForegroundColor Yellow
    Stop-Transcript | Out-Null; exit 1
}
Write-Host "Ubuntu OK - usuário Linux: $usuarioLinux"

$scriptBash = Join-Path $PSScriptRoot 'jarvis-wsl-parte2.sh'
if (-not (Test-Path $scriptBash)) {
    Write-Host "Arquivo jarvis-wsl-parte2.sh não encontrado ao lado deste script." -ForegroundColor Red
    Stop-Transcript | Out-Null; exit 1
}

# ---------------------------------------------------------------- 1. backup Windows
$ocWindows = [bool](Get-Command openclaw -ErrorAction SilentlyContinue)
$pastaOpenClawWin = Join-Path $env:USERPROFILE '.openclaw'
Titulo "1/5 - Backup do Jarvis atual (Windows)"
if ($ocWindows) {
    Write-Host "Jarvis encontrado no Windows. Nada será apagado."
    if (Confirmar "Criar backup verificado agora (openclaw backup create --verify)?") {
        openclaw backup create --verify
    }
} else {
    Write-Host "OpenClaw não encontrado no Windows - pulando backup."
}

# ---------------------------------------------------------------- 2. parar Windows
Titulo "2/5 - Desligar o Jarvis do Windows"
if ($ocWindows) {
    Write-Host @"
Para não ter DOIS Jarvis respondendo no mesmo WhatsApp, o do Windows será
PARADO (não desinstalado). O Jarvis ficará fora do ar até o fim desta parte.
Se algo der errado, para voltar ao normal basta rodar:  openclaw gateway start
"@
    if (Confirmar "Parar o Jarvis do Windows agora?") {
        openclaw gateway stop
    } else {
        Write-Host "Ok - sem parar o do Windows não é seguro continuar. Encerrando." -ForegroundColor Yellow
        Stop-Transcript | Out-Null; exit 0
    }
}

# ---------------------------------------------------------------- 3. instalar no WSL
Titulo "3/5 - Instalação dentro do Ubuntu"
$caminhoBash = (wsl.exe -d $Distro -- wslpath -a ($scriptBash -replace '\\','/') | Out-String).Trim()
$caminhoWorkspace = ''
$wsWin = Join-Path $pastaOpenClawWin 'workspace'
if (Test-Path $wsWin) {
    $caminhoWorkspace = (wsl.exe -d $Distro -- wslpath -a ($wsWin -replace '\\','/') | Out-String).Trim()
}
Write-Host "A instalação vai abrir dentro do Ubuntu. Ela pedirá a SUA senha do Linux (sudo)."
wsl.exe -d $Distro -- env "JARVIS_WIN_WORKSPACE=$caminhoWorkspace" bash "$caminhoBash"
$okLinux = ($LASTEXITCODE -eq 0)

if (-not $okLinux) {
    Write-Host "`nA parte do Ubuntu não terminou com sucesso." -ForegroundColor Red
    if ($ocWindows -and (Confirmar "Religar o Jarvis do Windows para não ficar sem ele?")) {
        openclaw gateway start
    }
    Write-Host "Me mande o log: $pastaLog"
    Stop-Transcript | Out-Null; exit 1
}

# ---------------------------------------------------------------- 4. início automático
Titulo "4/5 - Iniciar o Jarvis (WSL) automaticamente"
Write-Host "Cria uma tarefa agendada do Windows que mantém o Ubuntu ligado quando você faz login,"
Write-Host "para o Jarvis continuar respondendo no WhatsApp."
if (Confirmar "Criar a tarefa 'Jarvis WSL'?") {
    $acao = New-ScheduledTaskAction -Execute 'wsl.exe' -Argument "-d $Distro --exec sleep infinity"
    $gatilho = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
              -ExecutionTimeLimit ([TimeSpan]::Zero) -Hidden
    Register-ScheduledTask -TaskName 'Jarvis WSL' -Action $acao -Trigger $gatilho -Settings $config `
        -Description 'Mantém o Ubuntu (WSL) ligado para o Jarvis/OpenClaw' -Force | Out-Null
    Start-ScheduledTask -TaskName 'Jarvis WSL'
    Write-Host "Tarefa criada e iniciada." -ForegroundColor Green
}

# ---------------------------------------------------------------- 5. remover serviço antigo
Titulo "5/5 - Serviço antigo do Windows"
if ($ocWindows) {
    Write-Host @"
TESTE PRIMEIRO: mande uma mensagem ao Jarvis no WhatsApp e veja se ele responde.
Só depois remova o serviço antigo. Isso remove apenas a inicialização automática
do Windows - os arquivos e o backup continuam no seu PC.
"@
    if (Confirmar "O Jarvis respondeu no WhatsApp e você quer remover o serviço antigo do Windows?") {
        openclaw gateway uninstall
        Write-Host "Serviço do Windows removido. Dados preservados em $pastaOpenClawWin" -ForegroundColor Green
        Write-Host "Dica: no celular, em WhatsApp > Aparelhos conectados, remova o aparelho antigo do Windows."
    } else {
        Write-Host "Ok, mantido (parado). Você pode remover depois com: openclaw gateway uninstall"
    }
}

Write-Host "`nConcluído! Log salvo em: $pastaLog" -ForegroundColor Green
Stop-Transcript | Out-Null
