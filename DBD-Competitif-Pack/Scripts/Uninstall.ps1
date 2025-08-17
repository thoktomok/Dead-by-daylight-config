<#
.SYNOPSIS
    Restaure la dernière sauvegarde des fichiers de configuration de Dead by Daylight.

.DESCRIPTION
    Ce script annule les changements effectués par 'install_dbd_competitif.ps1'.
    Il effectue les actions suivantes :
    1. Détecte le chemin de configuration du jeu.
    2. Trouve la sauvegarde la plus récente dans le dossier 'Backup'.
    3. Retire l'attribut de lecture seule des fichiers .ini actuellement installés.
    4. Copie les fichiers de la sauvegarde pour restaurer la configuration d'origine.
    5. Affiche le résultat de l'opération.

.EXAMPLE
    .\Uninstall.ps1
    Lance le processus de restauration.

.NOTES
    Auteur: Jules, Ingénieur Logiciel
    Version: 1.0
#>

# --- Initialisation et Configuration ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupDir = Join-Path $ScriptDir "..\Backup"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  Désinstallation des Configurations Compétitives pour DbD " -ForegroundColor Yellow
Write-Host "=========================================================="
Write-Host "Script par Jules. Lancement de la restauration..."

# --- Fonctions ---

function Get-DbDConfigPath {
    Write-Host "`n[1/4] Recherche du dossier de configuration de Dead by Daylight..."
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
        return $null
    }
}

function Get-LatestBackup {
    Write-Host "`n[2/4] Recherche de la dernière sauvegarde..."
    $latestBackup = Get-ChildItem -Path $BackupDir | Sort-Object Name -Descending | Select-Object -First 1

    if ($latestBackup) {
        Write-Host "  -> Sauvegarde la plus récente trouvée : $($latestBackup.Name)" -ForegroundColor Cyan
        return $latestBackup.FullName
    } else {
        Write-Host "  ERREUR : Aucun dossier de sauvegarde trouvé dans le dossier 'Backup'." -ForegroundColor Red
        return $null
    }
}

function Restore-FromBackup {
    param(
        [string]$ConfigPath,
        [string]$BackupPath
    )

    Write-Host "`n[3/4] Retrait de l'attribut lecture seule des fichiers actuels..."
    try {
        Get-ChildItem -Path $ConfigPath -Filter "*.ini" | Set-ItemProperty -Name IsReadOnly -Value $false
        Write-Host "  -> Attribut lecture seule retiré."
    } catch {
        Write-Host "  AVERTISSEMENT : Impossible de retirer l'attribut lecture seule. $_" -ForegroundColor Yellow
    }

    Write-Host "`n[4/4] Restauration des fichiers depuis la sauvegarde..."
    try {
        Copy-Item -Path (Join-Path $BackupPath "*") -Destination $ConfigPath -Force
        Write-Host "  -> Fichiers restaurés avec succès !" -ForegroundColor Green
    } catch {
        Write-Host "  ERREUR lors de la restauration : $_" -ForegroundColor Red
    }
}

# --- Exécution du Script ---

$dbdPath = Get-DbDConfigPath
if (-not $dbdPath) { exit 1 }

$latestBackupPath = Get-LatestBackup
if (-not $latestBackupPath) { exit 1 }

Restore-FromBackup -ConfigPath $dbdPath -BackupPath $latestBackupPath

Write-Host "`nDésinstallation terminée." -ForegroundColor Green
Write-Host "Vos anciens fichiers de configuration ont été restaurés."
