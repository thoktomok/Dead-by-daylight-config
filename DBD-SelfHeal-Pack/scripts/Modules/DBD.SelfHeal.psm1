# ====================================================================================
# Module PowerShell pour DBD-SelfHeal-Pack
# Auteur : Jules, Ingénieur Outillage
# Version : 1.0
#
# DESCRIPTION:
# Ce module contient toutes les fonctions de bas niveau pour diagnostiquer,
# nettoyer, réparer et optimiser une installation de Dead by Daylight.
# ====================================================================================

# --- Paramètres d'exportation du module ---
# Exporte toutes les fonctions pour qu'elles soient disponibles dans le script principal.
Export-ModuleMember -Function *

#region Fonctions de Localisation (Paths)

function Get-DBDConfigPath {
    <#
    .SYNOPSIS
        Trouve le chemin du dossier de configuration de Dead by Daylight.
    .DESCRIPTION
        Cherche le dossier 'WindowsClient' en priorité, puis 'WindowsNoEditor' comme solution de repli.
    .OUTPUTS
        String. Le chemin complet vers le dossier de configuration.
    #>
    [CmdletBinding()]
    param()

    Write-Verbose "Recherche du dossier de configuration de DbD..."
    $basePath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Config"
    $primaryPath = Join-Path $basePath "WindowsClient"
    $fallbackPath = Join-Path $basePath "WindowsNoEditor"

    if (Test-Path $primaryPath) {
        Write-Verbose "Dossier principal 'WindowsClient' trouvé."
        return $primaryPath
    }
    elseif (Test-Path $fallbackPath) {
        Write-Verbose "Dossier de secours 'WindowsNoEditor' trouvé."
        return $fallbackPath
    }
    else {
        throw "Impossible de trouver le dossier de configuration de Dead by Daylight. Le jeu a-t-il été lancé au moins une fois ?"
    }
}

function Get-DBDLogsPath {
    <#
    .SYNOPSIS
        Trouve le chemin du dossier des journaux (logs) de Dead by Daylight.
    #>
    [CmdletBinding()]
    param()

    $logsPath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Logs"
    if (Test-Path $logsPath) {
        return $logsPath
    }
    else {
        throw "Impossible de trouver le dossier des logs de Dead by Daylight."
    }
}

function Get-DBDInstallPath {
    <#
    .SYNOPSIS
        Trouve le chemin d'installation de Dead by Daylight via Steam.
    #>
    [CmdletBinding()]
    param()

    Write-Verbose "Recherche du chemin d'installation de DbD via le registre..."
    # Méthode la plus fiable : clé de désinstallation de l'application Steam
    $steamAppKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 381210"
    if (Test-Path $steamAppKey) {
        $installPath = (Get-ItemProperty -Path $steamAppKey).InstallLocation
        if ($installPath) {
            Write-Verbose "Chemin d'installation trouvé : $installPath"
            return $installPath
        }
    }

    # Méthode de secours (plus complexe, non implémentée ici pour rester simple) :
    # 1. Trouver l'installation de Steam.
    # 2. Lire le fichier libraryfolders.vdf pour trouver toutes les bibliothèques.
    # 3. Chercher 'Dead by Daylight' dans chaque bibliothèque.
    throw "Impossible de trouver le chemin d'installation de Dead by Daylight via le registre. L'installation est peut-être non standard ou corrompue."
}

#endregion

#region Fonctions de Mesure et d'Analyse

function Measure-Frametime {
    <#
    .SYNOPSIS
        Mesure les performances de frametime en utilisant PresentMon.
    .DESCRIPTION
        Cette fonction cherche PresentMon.exe, lance une capture de 60 secondes,
        puis analyse le fichier CSV résultant pour calculer les métriques clés (P1, P99, etc.).
    .PARAMETER OutputFileName
        Le nom du fichier CSV à générer (ex: 'frametime_before.csv').
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$OutputFileName,
        [Parameter(Mandatory=$true)][string]$LogsPath
    )

    $presentMonPath = Join-Path $PSScriptRoot "..\..\PresentMon\PresentMon.exe" # Supposant qu'il est packagé avec l'outil
    if (-not (Test-Path $presentMonPath)) {
        Write-Warning "PresentMon.exe non trouvé à l'emplacement attendu. La mesure de performance est impossible."
        Write-Warning "Veuillez télécharger PresentMon depuis le site d'Intel ou de NVIDIA et le placer dans un dossier 'PresentMon' à la racine du pack."
        return $null
    }

    $outputCsvPath = Join-Path $LogsPath $OutputFileName
    $processName = "DeadByDaylight-Win64-Shipping.exe"

    Write-Host "Lancement de la capture de performance pour '$processName' pendant 30 secondes." -ForegroundColor Green
    Write-Host "Veuillez vous assurer que le jeu est au premier plan et dans le menu principal."
    Read-Host "Appuyez sur Entrée pour démarrer la capture..."

    try {
        $pinfo = Start-Process -FilePath $presentMonPath -ArgumentList "--process_name $processName --output_file $outputCsvPath --timed 30" -PassThru
        Wait-Process -Id $pinfo.Id
        Write-Verbose "Capture PresentMon terminée. Fichier de sortie : $outputCsvPath"
    }
    catch {
        throw "Erreur lors de l'exécution de PresentMon : $_"
    }

    # Analyse du CSV
    if (-not (Test-Path $outputCsvPath)) {
        throw "Le fichier de sortie de PresentMon n'a pas été créé."
    }

    $data = Import-Csv $outputCsvPath
    $msPresents = $data.msBetweenPresents | ForEach-Object { [double]$_ }
    if ($msPresents.Count -eq 0) {
        Write-Warning "Aucune donnée de frametime capturée. Le jeu était-il bien lancé ?"
        return $null
    }

    $sortedTimes = $msPresents | Sort-Object

    $metrics = [PSCustomObject]@{
        AverageFPS      = [math]::Round(1000 / ($sortedTimes | Measure-Object -Average).Average, 1)
        MedianFrametime = [math]::Round(($sortedTimes | Measure-Object -Median).Median, 2)
        P1_Frametime    = [math]::Round($sortedTimes[[int]($sortedTimes.Count * 0.01)], 2)
        P99_Frametime   = [math]::Round($sortedTimes[[int]($sortedTimes.Count * 0.99)], 2)
        SpikeCount      = ($sortedTimes | Where-Object { $_ -gt 16.7 }).Count # Spikes > 16.7ms (cible 60 FPS)
    }

    return $metrics
}

function Compare-Results {
    <#
    .SYNOPSIS
        Compare deux ensembles de métriques (avant/après) et génère un rapport.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$MetricsBefore,
        [Parameter(Mandatory=$true)]$MetricsAfter
    )

    $report = @"
======================================================
  Rapport de Performance Avant/Après
======================================================
Métrique                    | Avant     | Après     | Changement
----------------------------|-----------|-----------|-----------
FPS Moyen                   | $($MetricsBefore.AverageFPS.ToString("F1"))     | $($MetricsAfter.AverageFPS.ToString("F1"))     | $([math]::Round((($MetricsAfter.AverageFPS / $MetricsBefore.AverageFPS) - 1) * 100, 1))%
Frametime Médian (ms)       | $($MetricsBefore.MedianFrametime.ToString("F2"))   | $($MetricsAfter.MedianFrametime.ToString("F2"))   | $([math]::Round((($MetricsAfter.MedianFrametime / $MetricsBefore.MedianFrametime) - 1) * 100, 1))%
P99 Frametime (ms) [Stutter]| $($MetricsBefore.P99_Frametime.ToString("F2"))   | $($MetricsAfter.P99_Frametime.ToString("F2"))   | $([math]::Round((($MetricsAfter.P99_Frametime / $MetricsBefore.P99_Frametime) - 1) * 100, 1))% (plus bas = mieux)
P1 Frametime (ms) [Fluidité]| $($MetricsBefore.P1_Frametime.ToString("F2"))   | $($MetricsAfter.P1_Frametime.ToString("F2"))   | $([math]::Round((($MetricsAfter.P1_Frametime / $MetricsBefore.P1_Frametime) - 1) * 100, 1))%
Nombre de Spikes (>16.7ms)  | $($MetricsBefore.SpikeCount)        | $($MetricsAfter.SpikeCount)        | $([math]::Round((($MetricsAfter.SpikeCount / [double]$MetricsBefore.SpikeCount) - 1) * 100, 1))%
------------------------------------------------------

"@

    # Verdict
    $p99Change = (($MetricsAfter.P99_Frametime / $MetricsBefore.P99_Frametime) - 1)
    if ($p99Change -lt -0.1) {
        $report += "`nVERDICT : Amélioration significative de la stabilité (P99).`n"
    } elseif ($p99Change -lt -0.02) {
        $report += "`nVERDICT : Amélioration mineure de la stabilité.`n"
    } elseif ($p99Change -gt 0.1) {
        $report += "`nVERDICT : Régression détectée dans la stabilité (P99). Un retour en arrière pourrait être nécessaire.`n"
    } else {
        $report += "`nVERDICT : Pas de changement notable de la performance.`n"
    }

    return $report
}

#endregion

#region Fonctions de Diagnostic Système (Opt-in)

function Check-WindowsImage {
    <#
    .SYNOPSIS
        Exécute DISM et SFC pour vérifier l'intégrité de l'image Windows.
    #>
    [CmdletBinding()]
    param()

    Write-Host "Cette opération va vérifier les fichiers système de Windows. Elle peut prendre du temps." -ForegroundColor Yellow
    $choice = Read-Host "Voulez-vous continuer ? (O/N)"
    if ($choice -ne 'O') {
        Write-Host "Opération annulée."
        return
    }

    $logContent = ""
    $commands = @(
        "DISM.exe /Online /Cleanup-Image /CheckHealth",
        "DISM.exe /Online /Cleanup-Image /ScanHealth",
        "DISM.exe /Online /Cleanup-Image /RestoreHealth",
        "sfc.exe /scannow"
    )

    foreach ($cmd in $commands) {
        Write-Host "Exécution de : $cmd" -ForegroundColor Green
        try {
            # Exécution avec élévation de privilèges
            $output = Start-Process -FilePath ($cmd.Split(' ')[0]) -ArgumentList ($cmd.Split(' ')[1..($cmd.Split(' ').Length - 1)] -join ' ') -Verb RunAs -Wait -PassThru -RedirectStandardOutput ".\temp_log.txt"
            $logContent += "`n--- Output of $cmd ---`n"
            $logContent += Get-Content ".\temp_log.txt"
            Remove-Item ".\temp_log.txt"
        }
        catch {
            $logContent += "`n--- FAILED to run $cmd ---`n$($_)`n"
            Write-Warning "Erreur lors de l'exécution de $cmd. Consultez les logs pour plus de détails."
        }
    }
    return $logContent
}

function Report-HAGS {
    <#
    .SYNOPSIS
        Vérifie si la planification de processeur graphique à accélération matérielle (HAGS) est active.
    #>
    [CmdletBinding()]
    param()

    $regKey = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    try {
        $hwSchMode = Get-ItemProperty -Path $regKey -Name "HwSchMode" -ErrorAction SilentlyContinue
        if ($hwSchMode -and $hwSchMode.HwSchMode -eq 2) {
            return "Activé"
        } else {
            return "Désactivé"
        }
    }
    catch {
        return "Inconnu (impossible de lire la clé de registre)"
    }
}

#endregion

#region Fonctions de Nettoyage et Réparation

function Clear-DirectXShaderCache {
    <#
    .SYNOPSIS
        Tente de nettoyer le cache des shaders DirectX.
    .DESCRIPTION
        Cette fonction est délicate à automatiser. Elle ouvre l'outil de nettoyage de disque de Windows
        et guide l'utilisateur, ce qui est la méthode la plus sûre.
    #>
    [CmdletBinding()]
    param()

    Write-Host "Le nettoyage du cache des shaders DirectX est mieux géré par les outils Windows." -ForegroundColor Yellow
    Write-Host "1. L'outil 'Nettoyage de disque' va s'ouvrir."
    Write-Host "2. Cochez la case 'Cache de nuanceur DirectX'."
    Write-Host "3. Cliquez sur OK pour lancer le nettoyage."
    Read-Host "Appuyez sur Entrée pour continuer..."

    try {
        # Lance l'outil de nettoyage de disque de Windows, qui est la méthode la plus sûre.
        cleanmgr.exe /d $env:SystemDrive
    }
    catch {
        throw "Impossible de lancer l'outil de nettoyage de disque (cleanmgr.exe)."
    }
}

function Clear-DerivedDataCache {
    <#
    .SYNOPSIS
        Purge le cache de données dérivées de Dead by Daylight.
    #>
    [CmdletBinding()]
    param()

    $ddcPath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\DerivedDataCache"
    if (Test-Path $ddcPath) {
        try {
            Write-Verbose "Suppression du cache de données dérivées : $ddcPath"
            Remove-Item -Path $ddcPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Cache de données dérivées supprimé avec succès."
        }
        catch {
            throw "Erreur lors de la suppression du DerivedDataCache : $_"
        }
    }
    else {
        Write-Verbose "Aucun DerivedDataCache trouvé. Rien à faire."
    }
}

function Test-DBDIntegrity {
    <#
    .SYNOPSIS
        Lance la vérification de l'intégrité des fichiers du jeu via Steam.
    #>
    [CmdletBinding()]
    param()

    Write-Host "La méthode la plus sûre pour vérifier les fichiers du jeu est via l'interface Steam." -ForegroundColor Yellow
    Write-Host "Steam va maintenant s'ouvrir sur la fenêtre de validation pour Dead by Daylight."

    try {
        # Utilise le protocole Steam pour lancer la validation pour l'AppID 381210 (DbD)
        Start-Process "steam://validate/381210"
        Write-Verbose "Commande de validation Steam envoyée."
    }
    catch {
        throw "Impossible de lancer la validation via le protocole Steam. Steam est-il installé correctement ?"
    }
}

function Repair-EAC {
    <#
    .SYNOPSIS
        Lance l'outil de réparation de Easy Anti-Cheat.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$DBDInstallPath
    )

    $eacSetupPath = Join-Path $DBDInstallPath "EasyAntiCheat\EasyAntiCheat_EOS_Setup.exe"
    if (-not (Test-Path $eacSetupPath)) {
        throw "Impossible de trouver l'installeur Easy Anti-Cheat à l'emplacement attendu."
    }

    Write-Host "Lancement de l'outil de réparation Easy Anti-Cheat..." -ForegroundColor Yellow
    Write-Host "Une élévation de privilèges (UAC) vous sera demandée."
    Write-Host "Dans l'outil, sélectionnez 'Dead by Daylight' et cliquez sur 'Réparer'."

    try {
        # L'outil doit être lancé en tant qu'administrateur.
        Start-Process -FilePath $eacSetupPath -Verb RunAs
    }
    catch {
        throw "Erreur lors du lancement de EasyAntiCheat_EOS_Setup.exe : $_"
    }
}

#endregion

#region Fonctions de Normalisation des .ini

# Helper function to get VRAM, needed for Normalize-INI
function Get-GPUInfo {
    try {
        $videoController = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        $vramGB = [math]::Round($videoController.AdapterRAM / 1GB)
        return @{ VRAM_GB = $vramGB }
    } catch {
        Write-Warning "Impossible de détecter la VRAM via WMI. Utilisation d'une valeur par défaut."
        return @{ VRAM_GB = 8 } # Valeur par défaut sûre
    }
}

function Normalize-INI {
    <#
    .SYNOPSIS
        Fusionne les .ini de l'utilisateur avec les profils de base pour les stabiliser.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath,
        [Parameter(Mandatory=$true)][string]$ProfilesPath
    )

    Write-Verbose "Début de la normalisation des fichiers .ini."

    # --- Normalisation de Engine.ini ---
    Write-Verbose "Normalisation de Engine.ini..."
    $userEngineIniPath = Join-Path $ConfigPath "Engine.ini"
    $masterEngineIniPath = Join-Path $ProfilesPath "Engine.ini"

    # Préserver la section réseau de l'utilisateur
    $userNetSection = (Get-Content $userEngineIniPath -Raw) -match "(?sm)(\[GameNetDriver StatelessConnectHandlerComponent\].*?)(?:(\r?\n){2,}|\[)"
    $preservedNetSection = if ($userNetSection) { $matches[1] } else { "[GameNetDriver StatelessConnectHandlerComponent]`r`nCachedClientID=0" }

    $masterEngineContent = Get-Content $masterEngineIniPath -Raw
    # Remplacer le placeholder de la section réseau
    $masterEngineContent = $masterEngineContent -replace "(?s)(\[GameNetDriver StatelessConnectHandlerComponent\].*?CachedClientID=0)", $preservedNetSection

    # Ajuster le PoolSize en fonction de la VRAM
    $gpuInfo = Get-GPUInfo
    $poolSize = 512 # Fallback
    if ($gpuInfo.VRAM_GB -le 4) { $poolSize = 512 }
    elseif ($gpuInfo.VRAM_GB -le 8) { $poolSize = 1024 }
    elseif ($gpuInfo.VRAM_GB -le 12) { $poolSize = 1536 }
    else { $poolSize = 2048 }
    $masterEngineContent = $masterEngineContent -replace 'r.Streaming.PoolSize=\d+', "r.Streaming.PoolSize=$poolSize"

    $masterEngineContent | Set-Content -Path $userEngineIniPath -Encoding UTF8 -Force

    # --- Normalisation de GameUserSettings.ini ---
    # C'est complexe. Pour une robustesse maximale, on ne préserve que quelques clés critiques.
    # Une vraie fusion nécessiterait un analyseur INI complet.
    Write-Verbose "Normalisation de GameUserSettings.ini..."
    $userGUSIniPath = Join-Path $ConfigPath "GameUserSettings.ini"
    $masterGUSIniPath = Join-Path $ProfilesPath "GameUserSettings.ini"

    # Liste des clés personnelles à préserver
    $keysToPreserve = @(
        'FieldOfView', 'AimAssist', 'VoiceChatEnabled', 'MuteOnFocusLoss', 'MainMenuMusic', 'LobbyMusic',
        'ShowPlayerNames', 'PartyPrivacy', 'SkillCheck', '*Sensitivity', 'MainVolume', 'MenuMusicVolume',
        'Headphones', 'ColorblindMode', 'ColorblindIntensity', 'Gamma', 'SharpnessValue'
    )
    $regexKeys = $keysToPreserve -join '|'

    $masterGUSContent = Get-Content $masterGUSIniPath -Raw
    $userGUSContent = Get-Content $userGUSIniPath -Raw

    # Recherche des valeurs à préserver
    $userGUSContent | Select-String -Pattern "^($regexKeys)\s*=" -AllMatches | ForEach-Object {
        $line = $_.Line
        $key = ($line -split '=')[0].Trim()
        Write-Verbose "  -> Préservation de la clé '$key' depuis le fichier utilisateur."
        # Remplacer la valeur dans le fichier maître
        $masterGUSContent = $masterGUSContent -replace "(?m)(^$key\s*=.*)", $line
    }

    $masterGUSContent | Set-Content -Path $userGUSIniPath -Encoding UTF8 -Force

    # --- Normalisation de Input.ini ---
    Write-Verbose "Normalisation de Input.ini..."
    $userInputIniPath = Join-Path $ConfigPath "Input.ini"
    $masterInputIniPath = Join-Path $ProfilesPath "Input.ini"

    $userInputContent = Get-Content $userInputIniPath -Raw
    $masterInputContent = Get-Content $masterInputIniPath -Raw

    # Si la section de settings n'existe pas, on l'ajoute.
    if ($userInputContent -notmatch "\[/Script/Engine.InputSettings\]") {
        Write-Verbose "Ajout de la section InputSettings à Input.ini."
        Add-Content -Path $userInputIniPath -Value "`r`n$masterInputContent"
    } else {
        # La section existe, on s'assure que les clés sont correctes
        # (Cette logique peut être affinée si nécessaire)
        Write-Verbose "La section InputSettings existe déjà. Les valeurs seront vérifiées par le jeu."
    }

    Write-Verbose "Normalisation des .ini terminée."
}

#endregion

#region Fonctions de Sauvegarde et Restauration

function Backup-DBDConfig {
    <#
    .SYNOPSIS
        Sauvegarde les fichiers de configuration actuels de DbD.
    .PARAMETER ConfigPath
        Le chemin vers le dossier de configuration de DbD.
    .PARAMETER BackupRoot
        Le dossier racine où stocker les sauvegardes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath,
        [Parameter(Mandatory=$true)][string]$BackupRoot
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $destBackupDir = Join-Path $BackupRoot $timestamp

    try {
        Write-Verbose "Création du dossier de sauvegarde : $destBackupDir"
        New-Item -ItemType Directory -Path $destBackupDir -ErrorAction Stop | Out-Null

        $iniFiles = Get-ChildItem -Path $ConfigPath -Filter "*.ini"
        if ($iniFiles) {
            Write-Verbose "Copie de $($iniFiles.Count) fichiers .ini vers le dossier de sauvegarde."
            Copy-Item -Path $iniFiles.FullName -Destination $destBackupDir -ErrorAction Stop
            return $destBackupDir
        }
        else {
            Write-Warning "Aucun fichier .ini trouvé dans '$ConfigPath' à sauvegarder."
            return $null
        }
    }
    catch {
        throw "Une erreur est survenue lors de la sauvegarde : $_"
    }
}

function Restore-DBDConfig {
    <#
    .SYNOPSIS
        Restaure une sauvegarde spécifique.
    .PARAMETER Slot
        Le nom du dossier de sauvegarde (timestamp) à restaurer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath,
        [Parameter(Mandatory=$true)][string]$BackupRoot,
        [Parameter(Mandatory=$true)][string]$Slot
    )

    $backupSourceDir = Join-Path $BackupRoot $Slot
    if (-not (Test-Path $backupSourceDir)) {
        throw "Le slot de sauvegarde '$Slot' n'existe pas."
    }

    try {
        Write-Verbose "Restauration des fichiers depuis '$backupSourceDir' vers '$ConfigPath'."
        # D'abord, s'assurer que les fichiers de destination ne sont pas en lecture seule.
        Unprotect-DBDKeys -ConfigPath $ConfigPath
        Copy-Item -Path (Join-Path $backupSourceDir "*") -Destination $ConfigPath -Force -ErrorAction Stop
        Write-Verbose "Restauration terminée."
    }
    catch {
        throw "Une erreur est survenue lors de la restauration : $_"
    }
}

#endregion

#region Fonctions de Protection des Fichiers

function Protect-DBDKeys {
    <#
    .SYNOPSIS
        Applique l'attribut de lecture seule sur les fichiers .ini de configuration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    try {
        Get-ChildItem -Path $ConfigPath -Filter "*.ini" | Set-ItemProperty -Name IsReadOnly -Value $true
        Write-Verbose "Attribut de lecture seule appliqué aux fichiers .ini."
    }
    catch {
        throw "Erreur lors de l'application de l'attribut lecture seule : $_"
    }
}

function Unprotect-DBDKeys {
    <#
    .SYNOPSIS
        Retire l'attribut de lecture seule des fichiers .ini de configuration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    try {
        Get-ChildItem -Path $ConfigPath -Filter "*.ini" | Set-ItemProperty -Name IsReadOnly -Value $false
        Write-Verbose "Attribut de lecture seule retiré des fichiers .ini."
    }
    catch {
        # On ne lance pas d'erreur ici, car il est possible que les fichiers n'existent pas encore
        # ou que l'on n'ait pas les droits, et ce n'est pas bloquant pour une restauration.
        Write-Warning "Impossible de retirer l'attribut de lecture seule : $_"
    }
}

#endregion
