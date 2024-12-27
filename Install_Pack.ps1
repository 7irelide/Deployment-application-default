clear
# Fonction pour afficher le menu
function Show-Menu {
    Clear-Host
    Write-Host "=== Installation automatisée de logiciels via Chocolatey et AnyDesk via wget ===" -ForegroundColor Cyan
    Write-Host "Ce script va installer ou mettre à jour les logiciels suivants :" -ForegroundColor Yellow
    Write-Host "1. Adobe Acrobat Reader DC : Lecteur PDF standard" -ForegroundColor Green
    Write-Host "2. Mozilla Firefox : Navigateur web rapide et sécurisé" -ForegroundColor Green
    Write-Host "3. Google Chrome : Navigateur web populaire de Google" -ForegroundColor Green
    Write-Host "4. Microsoft Office 365 ProPlus : Suite bureautique complète" -ForegroundColor Green
    Write-Host "5. AnyDesk : Logiciel d'accès à distance et de support (via wget)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Le script vérifiera d'abord si Chocolatey est installé et l'installera si nécessaire." -ForegroundColor Yellow
    Write-Host "Ensuite, il installera ou mettra à jour chaque logiciel à sa dernière version." -ForegroundColor Yellow
    Write-Host "AnyDesk sera installé séparément via wget." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Appuyez sur une touche pour continuer ou CTRL+C pour annuler..." -ForegroundColor Magenta
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour vérifier si AnyDesk est installé
function Test-AnyDeskInstalled {
    $anydesk = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Where-Object { $_.DisplayName -like "*AnyDesk*" }
    return $null -ne $anydesk
}

# Fonction pour installer ou mettre à jour un package
function Install-OrUpgrade {
    param($packageName, $description, $additionalArgs = "")
    Write-Host "Installation/Mise à jour de $description..." -ForegroundColor Cyan
    if (choco list --local-only $packageName -r) {
        choco upgrade $packageName -y $additionalArgs
    } else {
        choco install $packageName -y $additionalArgs
    }
}

# Affichage du menu
Show-Menu

# Vérification de l'installation de Chocolatey
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey n'est pas installé. Installation en cours..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey est déjà installé. Mise à jour..." -ForegroundColor Green
    choco upgrade chocolatey -y
}

# Installation ou mise à jour des logiciels
Install-OrUpgrade "adobereader" "Adobe Acrobat Reader DC"
Install-OrUpgrade "firefox" "Mozilla Firefox"
Install-OrUpgrade "googlechrome" "Google Chrome" "--ignore-checksums"
Install-OrUpgrade "office365proplus" "Microsoft Office 365 ProPlus"

# Installation spécifique d'AnyDesk avec wget
if (!(Test-AnyDeskInstalled)) {
    Write-Host "AnyDesk n'est pas installé. Installation en cours via wget..." -ForegroundColor Yellow
    $anyDeskUrl = "https://download.anydesk.com/AnyDesk.exe"
    $anyDeskInstaller = "$env:TEMP\AnyDesk.exe"
    Invoke-WebRequest -Uri $anyDeskUrl -OutFile $anyDeskInstaller
    Start-Process -FilePath $anyDeskInstaller -ArgumentList "/S" -Wait
    Remove-Item $anyDeskInstaller -Force
} else {
    Write-Host "AnyDesk est déjà installé." -ForegroundColor Green
}

# Vérification des autorisations du pare-feu pour AnyDesk
Write-Host "Vérification des autorisations du pare-feu pour AnyDesk..." -ForegroundColor Cyan
$firewallRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*AnyDesk*" }
if ($null -eq $firewallRule) {
    Write-Host "Ajout d'AnyDesk aux exceptions du pare-feu Windows..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "AnyDesk" -Direction Inbound -Program "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" -Action Allow
} else {
    Write-Host "AnyDesk est déjà autorisé dans le pare-feu Windows." -ForegroundColor Green
}

# Nettoyage après installation
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
Remove-Item "$env:TEMP\chocolatey\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installation terminée. Appuyez sur une touche pour quitter..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
