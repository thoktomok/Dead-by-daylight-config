<#
.SYNOPSIS
    Installe et configure le Pack E-Sport pour Dead by Daylight en deux phases.
.DESCRIPTION
    Phase 1: Installe un profil de configuration optimisé basé sur votre matériel.
    Phase 2: Après un lancement du jeu, valide les paramètres et auto-corrige le fichier Engine.ini.
.NOTES
    Auteur: Jules, Ingénieur Expert Unreal & Windows
    Version: 1.1 (corrigé)
#>

#==============================================================================
# SECTION 1: DÉFINITION DE TOUTES LES FONCTIONS
#==============================================================================

function Get-DBDConfigPath {
    Write-Host "-> Recherche du dossier de configuration..."
    $basePath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Config"
    $primaryPath = Join-Path $basePath "WindowsClient"
    $fallbackPath = Join-Path $basePath "WindowsNoEditor"
    if (Test-Path $primaryPath) { return $primaryPath }
    if (Test-Path $fallbackPath) { return $fallbackPath }
    throw "ERREUR: Dossier de configuration de DbD introuvable."
}

function Get-DBDInstallPath {
    Write-Host "-> Recherche du dossier d'installation du jeu..."
    $steamAppKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 381210"
    if (Test-Path $steamAppKey) {
        return (Get-ItemProperty -Path $steamAppKey).InstallLocation
    }
    throw "ERREUR: Chemin d'installation de DbD (via registre Steam) introuvable."
}

function Backup-UserConfigs {
    param([string]$ConfigPath, [string]$BackupRoot)
    Write-Host "-> Sauvegarde de la configuration existante..."
    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $destBackupDir = Join-Path $BackupRoot $timestamp
    New-Item -ItemType Directory -Path $destBackupDir -ErrorAction Stop | Out-Null
    $iniFiles = Get-ChildItem -Path $ConfigPath -Filter "*.ini"
    if ($iniFiles) {
        Copy-Item -Path $iniFiles.FullName -Destination $destBackupDir -ErrorAction Stop
        Write-Host "   OK: Sauvegarde créée dans le dossier '$timestamp'." -ForegroundColor Green
    } else {
        Write-Host "   INFO: Aucune configuration à sauvegarder." -ForegroundColor Cyan
    }
}

function Get-HardwareInfo {
    Write-Host "-> Détection du matériel système..."
    $videoController = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $hardware = @{
        VRAM_GB = [math]::Round($videoController.AdapterRAM / 1GB)
        CPU_Threads = $processor.NumberOfLogicalProcessors
        ResolutionX = $videoController.CurrentHorizontalResolution
        ResolutionY = $videoController.CurrentVerticalResolution
    }
    Write-Host "   OK: VRAM: $($hardware.VRAM_GB)Go, Threads: $($hardware.CPU_Threads), Résolution: $($hardware.ResolutionX)x$($hardware.ResolutionY)" -ForegroundColor Green
    return $hardware
}

function Select-Profile {
    param([hashtable]$Hardware)
    Write-Host "-> Sélection du profil optimisé..."
    if ($Hardware.VRAM_GB -le 4) { return "Profil-A" }
    if ($Hardware.VRAM_GB -le 8) { return "Profil-B" }
    if ($Hardware.VRAM_GB -le 12) { return "Profil-C" }
    return "Profil-D"
}

function Run-Phase1-Install {
    param($configPath, $hardwareInfo, $profilesRoot)
    $selectedProfile = Select-Profile -Hardware $hardwareInfo
    $profileSourcePath = Join-Path $profilesRoot $selectedProfile
    Write-Host "-> Installation des fichiers du profil '$selectedProfile'..." -ForegroundColor Cyan
    Copy-Item -Path "$profileSourcePath\*" -Destination $configPath -Force
    $gusPath = Join-Path $configPath "GameUserSettings.ini"
    Write-Host "-> Mise à jour de la résolution..."
    (Get-Content $gusPath) |
        ForEach-Object { $_ -replace 'ResolutionSizeX=\d+', "ResolutionSizeX=$($hardwareInfo.ResolutionX)" } |
        ForEach-Object { $_ -replace 'ResolutionSizeY=\d+', "ResolutionSizeY=$($hardwareInfo.ResolutionY)" } |
        ForEach-Object { $_ -replace 'LastUserConfirmedResolutionSizeX=\d+', "LastUserConfirmedResolutionSizeX=$($hardwareInfo.ResolutionX)" } |
        ForEach-Object { $_ -replace 'LastUserConfirmedResolutionSizeY=\d+', "LastUserConfirmedResolutionSizeY=$($hardwareInfo.ResolutionY)" } |
        Set-Content -Path $gusPath -Encoding UTF8
    Write-Host "   OK: Installation de la Phase 1 terminée." -ForegroundColor Green
}

function Run-Phase2-Validation {
    param($configPath, $docsPath)
    $logPath = Join-Path $configPath "..\Logs\DeadByDaylight.log"
    Write-Host "-> Analyse du log '$logPath' pour valider les cvars..." -ForegroundColor Cyan
    if (-not (Test-Path $logPath)) { throw "Fichier log introuvable. Avez-vous bien lancé le jeu ?" }

    $logContent = Get-Content $logPath -Raw
    $engineIniPath = Join-Path $configPath "Engine.ini"
    $engineIniLines = Get-Content $engineIniPath

    $cvarInIniRegex = '(?im)^([a-z]\..*?)=.*'
    $rejectedInLogRegex = '(?im)Unknown console variable ''(.*?)\''|Setting CVar \[\[(.*?)\].*?ignored as it is lower priority'

    $allCvarsInIni = ($engineIniLines | Select-String -Pattern $cvarInIniRegex -AllMatches).Matches.Groups[1].Value
    $rejectedCvars = ($logContent | Select-String -Pattern $rejectedInLogRegex -AllMatches).Matches.Groups | Where-Object { $_.Success -and $_.Name -ne '0' } | Select-Object -ExpandProperty Value -Unique

    Write-Host "   OK: $($rejectedCvars.Count) cvars rejetées détectées." -ForegroundColor Yellow

    $newEngineIniContent = foreach ($line in $engineIniLines) {
        $cvarMatch = [regex]::Match($line, $cvarInIniRegex)
        if ($cvarMatch.Success -and ($cvarMatch.Groups[1].Value -in $rejectedCvars)) {
            ";$line ; REJETÉE PAR LE JEU"
        } else {
            $line
        }
    }
    $newEngineIniContent | Set-Content -Path $engineIniPath -Encoding UTF8

    $acceptedCvars = $allCvarsInIni | Where-Object { $_ -notin $rejectedCvars }
    $acceptedCvars | Out-File -FilePath (Join-Path $docsPath "ACCEPTED_CVARS.txt")
    $rejectedCvars | Out-File -FilePath (Join-Path $docsPath "REJECTED_CVARS.txt")
    Write-Host "   OK: Engine.ini corrigé et rapports de validation créés dans le dossier 'docs'." -ForegroundColor Green
}

#==============================================================================
# SECTION 2: EXÉCUTION PRINCIPALE DU SCRIPT
#==============================================================================

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProfilesRoot = Join-Path $PSScriptRoot "..\profiles"
$BackupRoot = Join-Path $PSScriptRoot "..\backup"
$DocsRoot = Join-Path $PSScriptRoot "..\docs"
if (-not (Test-Path $BackupRoot)) { New-Item -ItemType Directory -Path $BackupRoot }
if (-not (Test-Path $DocsRoot)) { New-Item -ItemType Directory -Path $DocsRoot }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         Installation du Pack E-Sport pour DbD            " -ForegroundColor Cyan
Write-Host "=========================================================="

try {
    $configPath = Get-DBDConfigPath
    $logPath = Join-Path $configPath "..\Logs\DeadByDaylight.log"
    $latestBackup = Get-ChildItem -Path $BackupRoot | Sort-Object CreationTime -Descending | Select-Object -First 1

    # Détection de la phase
    if ($latestBackup -and (Test-Path $logPath) -and ((Get-Item $logPath).LastWriteTime -gt $latestBackup.CreationTime)) {
        # --- PHASE 2 ---
        Write-Host "`nDétection de la Phase 2 (validation post-lancement)..." -ForegroundColor Magenta
        Run-Phase2-Validation -configPath $configPath -docsPath $DocsRoot
        Write-Host "`nPACK E-SPORT INSTALLÉ ET VALIDÉ !" -ForegroundColor Green
    } else {
        # --- PHASE 1 ---
        Write-Host "`nDétection de la Phase 1 (première installation)..." -ForegroundColor Magenta
        $installPath = Get-DBDInstallPath
        Backup-UserConfigs -ConfigPath $configPath -BackupRoot $BackupRoot
        $hardwareInfo = Get-HardwareInfo
        Run-Phase1-Install -configPath $configPath -hardwareInfo $hardwareInfo -profilesRoot $ProfilesRoot

        Write-Host "`nPHASE 1 TERMINÉE. ACTION REQUISE :" -ForegroundColor Yellow
        Write-Host "1. Lancez Dead by Daylight maintenant."
        Write-Host "2. Allez jusqu'au menu principal, puis quittez proprement le jeu."
        Write-Host "3. Relancez ce script pour finaliser l'installation (Phase 2)."
    }
}
catch {
    Write-Host "`nERREUR CRITIQUE LORS DE L'INSTALLATION :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Read-Host "`nAppuyez sur Entrée pour quitter."
