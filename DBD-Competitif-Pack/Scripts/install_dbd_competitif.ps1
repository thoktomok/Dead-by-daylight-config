<#
.SYNOPSIS
    Installe et configure les fichiers .ini compétitifs pour Dead by Daylight.

.DESCRIPTION
    Ce script automatise l'installation de configurations optimisées pour la performance,
    la stabilité et la lisibilité dans Dead by Daylight.
    Il effectue les actions suivantes :
    1. Détecte le chemin de configuration du jeu.
    2. Sauvegarde les fichiers de configuration (.ini) actuels dans un dossier de backup horodaté.
    3. Détecte le matériel de l'utilisateur (VRAM, CPU, Résolution) via WMI.
    4. Sélectionne le profil de configuration le plus adapté (de A à D).
    5. Copie les fichiers .ini optimisés et ajuste la résolution native.
    6. Applique optionnellement un attribut de lecture seule pour protéger les réglages.
    7. Journalise l'intégralité du processus dans un fichier de log.

.PARAMETER SetReadOnly
    Si ce commutateur est utilisé, les fichiers de configuration installés seront mis en lecture seule
    pour empêcher le jeu de les modifier.

.EXAMPLE
    .\install_dbd_competitif.ps1
    Lance l'installation avec détection automatique, sans mettre les fichiers en lecture seule.

.EXAMPLE
    .\install_dbd_competitif.ps1 -SetReadOnly
    Lance l'installation et verrouille les fichiers en lecture seule après coup.

.NOTES
    Auteur: Jules, Ingénieur Logiciel
    Version: 1.0
    Assurez-vous d'exécuter ce script depuis son dossier d'origine.
#>

[CmdletBinding()]
param(
    [switch]$SetReadOnly
)

# --- Initialisation et Configuration ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProfilsDir = Join-Path $ScriptDir "..
\Profils"
$LogsDir = Join-Path $ScriptDir "..\Logs"
$BackupDir = Join-Path $ScriptDir "..\Backup"

# Création des dossiers nécessaires s'ils n'existent pas
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir }

# Démarrage du logging
$LogFile = Join-Path $LogsDir "install-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
Start-Transcript -Path $LogFile -Append

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Installation des Configurations Compétitives pour DbD   " -ForegroundColor Green
Write-Host "=========================================================="
Write-Host "Script par Jules. Lancement du processus..."
Write-Host "Le journal complet sera sauvegardé dans : $LogFile"

# --- Fonctions Principales ---

function Get-DbDConfigPath {
    Write-Host "`n[1/7] Recherche du dossier de configuration de Dead by Daylight..."
    $basePath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Config"
    $primaryPath = Join-Path $basePath "WindowsClient"
    $fallbackPath = Join-Path $basePath "WindowsNoEditor"

    if (Test-Path $primaryPath) {
        Write-Host "  -> Dossier trouvé : WindowsClient" -ForegroundColor Cyan
        return $primaryPath
    } elseif (Test-Path $fallbackPath) {
        Write-Host "  -> Dossier trouvé : WindowsNoEditor (fallback)" -ForegroundColor Yellow
        return $fallbackPath
    } else {
        Write-Host "  ERREUR : Impossible de trouver le dossier de configuration de DbD." -ForegroundColor Red
        Write-Host "  Assurez-vous que le jeu a été lancé au moins une fois." -ForegroundColor Red
        return $null
    }
}

function Backup-ExistingConfigs {
    param([string]$ConfigPath)

    Write-Host "`n[2/7] Sauvegarde des fichiers de configuration existants..."
    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
    $destBackupDir = Join-Path $BackupDir $timestamp

    try {
        if (-not (Test-Path $destBackupDir)) {
            New-Item -ItemType Directory -Path $destBackupDir | Out-Null
        }
        $iniFiles = Get-ChildItem -Path $ConfigPath -Filter "*.ini"
        if ($iniFiles) {
            Copy-Item -Path $iniFiles.FullName -Destination $destBackupDir
            Write-Host "  -> Sauvegarde réussie dans le dossier : $timestamp" -ForegroundColor Cyan
        } else {
            Write-Host "  -> Aucun fichier .ini existant à sauvegarder." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ERREUR lors de la sauvegarde : $_" -ForegroundColor Red
    }
}

function Get-HardwareInfo {
    Write-Host "`n[3/7] Détection du matériel système (VRAM, Résolution)..."
    try {
        $videoController = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        $vramBytes = $videoController.AdapterRAM
        $vramGB = [math]::Round($vramBytes / 1GB)

        $resolutionX = $videoController.CurrentHorizontalResolution
        $resolutionY = $videoController.CurrentVerticalResolution

        Write-Host "  -> VRAM détectée : $vramGB Go" -ForegroundColor Cyan
        Write-Host "  -> Résolution détectée : ${resolutionX}x${resolutionY}" -ForegroundColor Cyan

        return @{
            VRAM = $vramGB
            ResX = $resolutionX
            ResY = $resolutionY
        }
    } catch {
        Write-Host "  ERREUR : Impossible de récupérer les informations matérielles via WMI." -ForegroundColor Red
        return $null
    }
}

function Select-Profile {
    param([int]$VRAM)

    Write-Host "`n[4/7] Sélection du profil optimisé..."
    if ($VRAM -le 4) {
        Write-Host "  -> Profil A (Très Basse Config) sélectionné." -ForegroundColor Cyan
        return "Profil-A-Low"
    } elseif ($VRAM -ge 5 -and $VRAM -le 8) {
        Write-Host "  -> Profil B (Moyenne Config) sélectionné." -ForegroundColor Cyan
        return "Profil-B-Medium"
    } elseif ($VRAM -ge 9 -and $VRAM -le 12) {
        Write-Host "  -> Profil C (Haute Config) sélectionné." -ForegroundColor Cyan
        return "Profil-C-High"
    } else { # $VRAM -gt 12
        Write-Host "  -> Profil D (Très Haute Config) sélectionné." -ForegroundColor Cyan
        return "Profil-D-Ultra"
    }
}

function Install-ProfileFiles {
    param(
        [string]$ProfileName,
        [string]$ConfigPath,
        [hashtable]$HardwareInfo
    )

    Write-Host "`n[5/7] Installation des fichiers du profil '$ProfileName'..."
    $sourceDir = Join-Path $ProfilsDir $ProfileName

    try {
        # Copier les 3 fichiers .ini
        Get-ChildItem -Path $sourceDir -Filter "*.ini" | Copy-Item -Destination $ConfigPath -Force

        # Mettre à jour la résolution dans GameUserSettings.ini
        $gusPath = Join-Path $ConfigPath "GameUserSettings.ini"
        if (Test-Path $gusPath) {
            Write-Host "  -> Mise à jour de la résolution dans GameUserSettings.ini..."
            $gusContent = Get-Content $gusPath
            $gusContent = $gusContent -replace 'ResolutionSizeX=\d+', "ResolutionSizeX=$($HardwareInfo.ResX)"
            $gusContent = $gusContent -replace 'ResolutionSizeY=\d+', "ResolutionSizeY=$($HardwareInfo.ResY)"
            $gusContent = $gusContent -replace 'LastUserConfirmedResolutionSizeX=\d+', "LastUserConfirmedResolutionSizeX=$($HardwareInfo.ResX)"
            $gusContent = $gusContent -replace 'LastUserConfirmedResolutionSizeY=\d+', "LastUserConfirmedResolutionSizeY=$($HardwareInfo.ResY)"
            $gusContent | Set-Content -Path $gusPath -Encoding UTF8
        }
        Write-Host "  -> Fichiers installés et configurés avec succès." -ForegroundColor Cyan
        return $true
    } catch {
        Write-Host "  ERREUR lors de l'installation des fichiers : $_" -ForegroundColor Red
        return $false
    }
}

function Set-ReadOnlyAttribute {
    param([string]$ConfigPath)

    Write-Host "`n[6/7] Application de l'attribut lecture seule..."
    try {
        Get-ChildItem -Path $ConfigPath -Filter "*.ini" | Set-ItemProperty -Name IsReadOnly -Value $true
        Write-Host "  -> Fichiers .ini verrouillés en lecture seule." -ForegroundColor Cyan
    } catch {
        Write-Host "  ERREUR lors du verrouillage des fichiers : $_" -ForegroundColor Red
    }
}

function Validate-Installation {
    param([string]$ProfileName, [string]$ConfigPath)

    Write-Host "`n[7/7] Validation de l'installation..."
    $sourceDir = Join-Path $ProfilsDir $ProfileName
    $validationReport = "Logs\VALIDATION_OK.txt"
    $issuesFound = $false

    "Rapport de validation pour l'installation du $(Get-Date)" | Out-File $validationReport

    # Comparaison des hashs de fichiers
    $sourceFiles = Get-ChildItem $sourceDir -Filter "*.ini"
    foreach ($sourceFile in $sourceFiles) {
        $destFile = Join-Path $ConfigPath $sourceFile.Name
        $sourceHash = (Get-FileHash $sourceFile.FullName).Hash
        $destHash = (Get-FileHash $destFile).Hash

        Add-Content $validationReport "  - Fichier : $($sourceFile.Name)"
        if ($sourceHash -eq $destHash) {
            Add-Content $validationReport "    -> Hash OK."
        } else {
            # L'hash de GameUserSettings sera différent à cause de la résolution, c'est normal.
            if ($sourceFile.Name -eq "GameUserSettings.ini") {
                 Add-Content $validationReport "    -> Hash différent (attendu, car la résolution a été personnalisée)."
            } else {
                Add-Content $validationReport "    -> ERREUR: Hash ne correspond pas !"
                $issuesFound = $true
            }
        }
    }

    if ($issuesFound) {
        Rename-Item $validationReport "Logs\VALIDATION_WARNINGS.txt" -Force
        Write-Host "  -> Validation terminée avec des avertissements. Consultez Logs\VALIDATION_WARNINGS.txt" -ForegroundColor Yellow
    } else {
        Write-Host "  -> Validation terminée avec succès. Rapport disponible dans Logs\VALIDATION_OK.txt" -ForegroundColor Green
    }
}


# --- Exécution du Script ---

$dbdPath = Get-DbDConfigPath
if (-not $dbdPath) { Stop-Transcript; exit 1 }

Backup-ExistingConfigs -ConfigPath $dbdPath

$hw = Get-HardwareInfo
if (-not $hw) { Stop-Transcript; exit 1 }

$profile = Select-Profile -VRAM $hw.VRAM
if (-not $profile) { Stop-Transcript; exit 1 }

$installSuccess = Install-ProfileFiles -ProfileName $profile -ConfigPath $dbdPath -HardwareInfo $hw
if (-not $installSuccess) { Stop-Transcript; exit 1 }

if ($SetReadOnly.IsPresent) {
    Set-ReadOnlyAttribute -ConfigPath $dbdPath
} else {
    Write-Host "`n[6/7] Attribut lecture seule ignoré (option -SetReadOnly non utilisée)."
}

Validate-Installation -ProfileName $profile -ConfigPath $dbdPath

Write-Host "`nInstallation terminée !" -ForegroundColor Green
Write-Host "Vous pouvez maintenant lancer Dead by Daylight."
Write-Host "Pour annuler ces changements, utilisez le script 'Uninstall.ps1'."

Stop-Transcript
