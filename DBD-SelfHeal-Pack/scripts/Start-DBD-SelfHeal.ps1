<#
.SYNOPSIS
    Orchestrateur principal pour le diagnostic et la réparation de Dead by Daylight.
.DESCRIPTION
    Ce script exécute un cycle complet d'opérations pour améliorer la stabilité et
    la performance de Dead by Daylight. Il utilise les fonctions du module DBD.SelfHeal.psm1.
.PARAMETER Auto
    Exécute le script en mode semi-automatique, en ne posant que les questions essentielles
    et en ignorant les vérifications système optionnelles comme DISM/SFC.
.EXAMPLE
    .\Start-DBD-SelfHeal.ps1
    Lance le script en mode interactif complet.
.EXAMPLE
    .\Start-DBD-SelfHeal.ps1 -Auto
    Lance le script en mode rapide et automatisé.
#>
[CmdletBinding()]
param(
    [switch]$Auto
)

# --- Initialisation et Importation ---
try {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Import-Module (Join-Path $PSScriptRoot "Modules\DBD.SelfHeal.psm1") -Force
}
catch {
    Write-Host "ERREUR CRITIQUE : Impossible de charger le module DBD.SelfHeal.psm1." -ForegroundColor Red
    Write-Host "Assurez-vous que le fichier se trouve bien dans le sous-dossier 'Modules'." -ForegroundColor Red
    exit 1
}

# --- Configuration des Chemins et Logs ---
$LogsPath = Join-Path $PSScriptRoot "..\logs"
$BackupPath = Join-Path $PSScriptRoot "..\backup"
$ProfilesPath = Join-Path $PSScriptRoot "..\profiles"
if (-not (Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath }
$LogFile = Join-Path $LogsPath "SelfHeal-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
Start-Transcript -Path $LogFile -Append

# --- En-tête ---
Write-Host "==========================================================" -ForegroundColor Magenta
Write-Host "         DBD Self-Heal Pack par Jules - v1.0              " -ForegroundColor Magenta
Write-Host "=========================================================="

# --- Début du Workflow ---
$Report = ""
$Warnings = @()

try {
    # 1. Détection des chemins
    Write-Host "`n[1/8] Détection des chemins d'accès..." -ForegroundColor Cyan
    $ConfigPath = Get-DBDConfigPath
    $DbdInstallPath = Get-DBDInstallPath
    $Report += "Chemin de configuration détecté : $ConfigPath`n"
    $Report += "Chemin d'installation détecté : $DbdInstallPath`n"

    # 2. Sauvegarde
    Write-Host "`n[2/8] Sauvegarde de la configuration actuelle..." -ForegroundColor Cyan
    $backupSlot = (Backup-DBDConfig -ConfigPath $ConfigPath -BackupRoot $BackupPath).Name
    Write-Host "Configuration sauvegardée dans le slot : $backupSlot"
    $Report += "Configuration sauvegardée dans le slot : $backupSlot`n"

    # 3. Mesure de performance "Avant"
    Write-Host "`n[3/8] Mesure de performance (AVANT)..." -ForegroundColor Cyan
    $MetricsBefore = Measure-Frametime -OutputFileName "frametime_before.csv" -LogsPath $LogsPath
    if (-not $MetricsBefore) { $Warnings += "La mesure de performance 'Avant' a échoué." }

    # 4. Nettoyage des caches
    Write-Host "`n[4/8] Nettoyage des caches..." -ForegroundColor Cyan
    Clear-DerivedDataCache
    if (-not $Auto) {
        $choice = Read-Host "Voulez-vous tenter de nettoyer le cache des shaders DirectX ? (O/N)"
        if ($choice -eq 'O') { Clear-DirectXShaderCache }
    }

    # 5. Normalisation des INI
    Write-Host "`n[5/8] Normalisation des fichiers de configuration..." -ForegroundColor Cyan
    Normalize-INI -ConfigPath $ConfigPath -ProfilesPath $ProfilesPath
    Write-Host "Fichiers .ini nettoyés et optimisés."

    # 6. Réparations optionnelles
    Write-Host "`n[6/8] Outils de réparation (Optionnel)..." -ForegroundColor Cyan
    if (-not $Auto) {
        $choice = Read-Host "Voulez-vous vérifier l'intégrité des fichiers du jeu via Steam ? (O/N)"
        if ($choice -eq 'O') { Test-DBDIntegrity }

        $choice = Read-Host "Voulez-vous lancer l'outil de réparation Easy Anti-Cheat ? (O/N)"
        if ($choice -eq 'O') { Repair-EAC -DBDInstallPath $DbdInstallPath }
    }

    # 7. Mesure de performance "Après"
    Write-Host "`n[7/8] Mesure de performance (APRÈS)..." -ForegroundColor Cyan
    Write-Host "Veuillez REDÉMARRER le jeu pour que tous les changements prennent effet."
    $MetricsAfter = Measure-Frametime -OutputFileName "frametime_after.csv" -LogsPath $LogsPath
    if (-not $MetricsAfter) { $Warnings += "La mesure de performance 'Après' a échoué." }

    # 8. Génération du rapport
    Write-Host "`n[8/8] Génération du rapport final..." -ForegroundColor Cyan
    if ($MetricsBefore -and $MetricsAfter) {
        $Report += Compare-Results -MetricsBefore $MetricsBefore -MetricsAfter $MetricsAfter
    } else {
        $Report += "`nComparaison de performance impossible car une des mesures a échoué.`n"
    }

    $hagsStatus = Report-HAGS
    $Report += "`n--- Diagnostics Système ---`n"
    $Report += "Statut HAGS (Planification GPU) : $hagsStatus`n"

    if (-not $Auto) {
        $choice = Read-Host "Voulez-vous lancer une vérification des fichiers système Windows (DISM & SFC) ? (Recommandé si vous avez des crashs fréquents, peut être long)"
        if ($choice -eq 'O') {
            $windowsReport = Check-WindowsImage
            $Report += "`n--- Rapport de vérification Windows ---`n$windowsReport`n"
        }
    }

    # Sauvegarde du rapport
    $Report | Out-File -FilePath (Join-Path $LogsPath "SelfHeal-Report.txt") -Encoding UTF8
    Write-Host "Rapport final sauvegardé dans le dossier 'logs'." -ForegroundColor Green

    # Création du fichier de validation
    if ($Warnings.Count -gt 0) {
        $Warnings | Out-File -FilePath (Join-Path $LogsPath "VALIDATION_WARNINGS.txt")
        Write-Host "Opération terminée avec des avertissements. Consultez VALIDATION_WARNINGS.txt." -ForegroundColor Yellow
    } else {
        "Opération terminée avec succès à $(Get-Date)" | Out-File -FilePath (Join-Path $LogsPath "VALIDATION_OK.txt")
        Write-Host "Opération terminée avec succès." -ForegroundColor Green
    }

}
catch {
    Write-Host "UNE ERREUR CRITIQUE EST SURVENUE :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Warnings += "Erreur critique : $($_.Exception.Message)"
    $Warnings | Out-File -FilePath (Join-Path $LogsPath "VALIDATION_ERRORS.txt")
}
finally {
    Write-Host "Fin du script."
    Stop-Transcript
}
