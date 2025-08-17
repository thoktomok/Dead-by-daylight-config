<#
.SYNOPSIS
    Désinstalle le Self-Heal Pack en restaurant la dernière sauvegarde de configuration.
.DESCRIPTION
    Ce script annule toutes les modifications apportées aux fichiers .ini en restaurant
    la sauvegarde la plus récente créée par Start-DBD-SelfHeal.ps1.
.EXAMPLE
    .\Uninstall-DBD-SelfHeal.ps1
    Lance le processus de restauration.
#>
[CmdletBinding()]
param()

# --- Initialisation et Importation ---
try {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Import-Module (Join-Path $PSScriptRoot "Modules\DBD.SelfHeal.psm1") -Force
}
catch {
    Write-Host "ERREUR CRITIQUE : Impossible de charger le module DBD.SelfHeal.psm1." -ForegroundColor Red
    exit 1
}

# --- Configuration des Chemins ---
$BackupPath = Join-Path $PSScriptRoot "..\backup"

# --- En-tête ---
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "     Restauration de la configuration de DbD              " -ForegroundColor Yellow
Write-Host "=========================================================="

try {
    # 1. Détection du chemin de config
    $ConfigPath = Get-DBDConfigPath
    Write-Host "Dossier de configuration trouvé : $ConfigPath"

    # 2. Trouver la dernière sauvegarde
    $latestBackup = Get-ChildItem -Path $BackupPath | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latestBackup) {
        throw "Aucun dossier de sauvegarde trouvé. Impossible de restaurer."
    }

    Write-Host "La dernière sauvegarde trouvée est : $($latestBackup.Name)" -ForegroundColor Cyan
    $choice = Read-Host "Voulez-vous restaurer cette sauvegarde ? (O/N)"

    if ($choice -eq 'O') {
        # 3. Restauration
        Write-Host "Restauration en cours..."
        Restore-DBDConfig -ConfigPath $ConfigPath -BackupRoot $BackupPath -Slot $latestBackup.Name
        Write-Host "Restauration terminée avec succès." -ForegroundColor Green
        Write-Host "Vos anciens fichiers de configuration ont été restaurés."
    } else {
        Write-Host "Opération annulée par l'utilisateur."
    }
}
catch {
    Write-Host "UNE ERREUR CRITIQUE EST SURVENUE :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "Fin du script."
