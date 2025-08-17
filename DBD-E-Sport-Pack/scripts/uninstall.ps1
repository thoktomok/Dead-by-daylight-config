<#
.SYNOPSIS
    Désinstalle le Pack E-Sport en restaurant la configuration précédente.
.DESCRIPTION
    Ce script trouve la dernière sauvegarde créée par install.ps1 et l'utilise
    pour restaurer les fichiers .ini de l'utilisateur à leur état d'origine.
.NOTES
    Auteur: Jules, Ingénieur Expert Unreal & Windows
    Version: 1.0
#>

# --- Fonctions Internes (simplifiées pour ce script) ---
function Get-DBDConfigPath {
    $basePath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Config"
    $primaryPath = Join-Path $basePath "WindowsClient"
    $fallbackPath = Join-Path $basePath "WindowsNoEditor"
    if (Test-Path $primaryPath) { return $primaryPath }
    if (Test-Path $fallbackPath) { return $fallbackPath }
    throw "ERREUR: Dossier de configuration de DbD introuvable."
}

# --- Exécution Principale ---
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupRoot = Join-Path $PSScriptRoot "..\backup"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "     Désinstallation du Pack E-Sport pour DbD             " -ForegroundColor Yellow
Write-Host "=========================================================="

try {
    $configPath = Get-DBDConfigPath
    $latestBackup = Get-ChildItem -Path $BackupRoot | Where-Object { $_.PSIsContainer } | Sort-Object Name -Descending | Select-Object -First 1

    if (-not $latestBackup) {
        throw "ERREUR: Aucun dossier de sauvegarde trouvé. Impossible de restaurer."
    }

    Write-Host "La dernière sauvegarde trouvée est : $($latestBackup.Name)" -ForegroundColor Cyan
    $choice = Read-Host "Voulez-vous vraiment restaurer cette configuration et écraser les fichiers actuels ? (O/N)"

    if ($choice -eq 'O') {
        Write-Host "-> Restauration en cours..."
        Copy-Item -Path (Join-Path $latestBackup.FullName "*") -Destination $configPath -Force
        Write-Host "   OK: Restauration terminée avec succès." -ForegroundColor Green
        Write-Host "Vos anciens fichiers de configuration ont été restaurés."
    } else {
        Write-Host "Opération annulée par l'utilisateur."
    }
}
catch {
    Write-Host "`nERREUR CRITIQUE LORS DE LA DÉSINSTALLATION :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Read-Host "`nAppuyez sur Entrée pour quitter."
