<#
.SYNOPSIS
    PARTE 1 de 2 - Instala o WSL (Linux dentro do Windows) com Ubuntu.

.DESCRIPTION
    Rode este script como ADMINISTRADOR. Ele:
      1. Verifica se o PC suporta virtualização;
      2. Mostra o estado atual do WSL;
      3. Instala o WSL + Ubuntu (com sua confirmação);
      4. Pede para reiniciar o computador.
    Nada do Jarvis é alterado nesta parte.

    Como rodar:
      Clique com o botão direito no PowerShell -> "Executar como administrador"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\jarvis-wsl-parte1.ps1
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Confirmar($pergunta) {
    while ($true) {
        $r = Read-Host "$pergunta [S/N]"
        if ($r -match '^(s|sim)$') { return $true }
        if ($r -match '^(n|nao|não)$') { return $false }
    }
}

$pastaLog = Join-Path $env:USERPROFILE 'jarvis-setup-logs'
New-Item -ItemType Directory -Force -Path $pastaLog | Out-Null
Start-Transcript -Path (Join-Path $pastaLog ("wsl-parte1-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")) | Out-Null

Write-Host "`n=== PARTE 1: instalação do WSL (Ubuntu) ===`n" -ForegroundColor Cyan

# 1. Administrador?
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Este script precisa ser executado como ADMINISTRADOR." -ForegroundColor Red
    Write-Host "Feche, clique com o botão direito no PowerShell e escolha 'Executar como administrador'."
    Stop-Transcript | Out-Null; exit 1
}

# 2. Versão do Windows e virtualização
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "Windows: $($os.Caption) (build $($os.BuildNumber))"
if ([int]$os.BuildNumber -lt 19041) {
    Write-Host "O WSL 2 precisa do Windows 10 build 19041 ou superior. Atualize o Windows primeiro." -ForegroundColor Red
    Stop-Transcript | Out-Null; exit 1
}
try {
    $virt = (Get-CimInstance Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
    if ($virt -eq $false) {
        Write-Host "AVISO: a virtualização parece DESLIGADA na BIOS/UEFI." -ForegroundColor Yellow
        Write-Host "Se a instalação falhar, ative 'Intel VT-x' ou 'AMD-V/SVM' na BIOS e tente de novo."
    } else {
        Write-Host "Virtualização: OK"
    }
} catch { Write-Host "Não foi possível verificar a virtualização (seguindo mesmo assim)." }

# 3. Estado atual
Write-Host "`nEstado atual do WSL:"
wsl.exe --status 2>&1 | Out-Host
Write-Host "`nDistribuições instaladas:"
wsl.exe --list --verbose 2>&1 | Out-Host

$temUbuntu = (wsl.exe --list --quiet 2>$null | Out-String) -replace "`0", '' -match 'Ubuntu'
if ($temUbuntu) {
    Write-Host "`nO Ubuntu já está instalado. Pode pular direto para a PARTE 2." -ForegroundColor Green
    if (Confirmar "Atualizar o WSL para a versão mais recente (wsl --update)?") { wsl.exe --update }
    Stop-Transcript | Out-Null; exit 0
}

# 4. Instalação
Write-Host @"

Será executado:  wsl --install -d Ubuntu
  - Ativa os recursos 'Subsistema do Windows para Linux' e 'Plataforma de Máquina Virtual'
  - Baixa o Ubuntu da Microsoft Store (fonte oficial)
  - Depois é preciso REINICIAR o computador
"@
if (-not (Confirmar "Instalar o WSL com Ubuntu agora?")) {
    Write-Host "Cancelado. Nada foi alterado."
    Stop-Transcript | Out-Null; exit 0
}

wsl.exe --install -d Ubuntu
if ($LASTEXITCODE -ne 0) {
    Write-Host "A instalação retornou erro ($LASTEXITCODE). Me mande o print desta tela." -ForegroundColor Red
    Stop-Transcript | Out-Null; exit 1
}

Write-Host @"

Instalação concluída!
PRÓXIMOS PASSOS:
  1. Reinicie o computador.
  2. Depois de reiniciar, abra 'Ubuntu' no menu Iniciar.
     Ele vai pedir para criar um USUÁRIO e SENHA do Linux.
     -> Anote a senha em local seguro (gerenciador de senhas). Ela será pedida
        na Parte 2 para instalar pacotes. NÃO me envie essa senha.
  3. Rode a PARTE 2 (PowerShell normal, NÃO administrador):
        .\jarvis-wsl-parte2.ps1
"@ -ForegroundColor Green

Stop-Transcript | Out-Null
if (Confirmar "Reiniciar o computador agora?") { Restart-Computer }
