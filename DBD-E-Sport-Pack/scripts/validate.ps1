<#
.SYNOPSIS
    Valide la cohérence entre Engine.ini et GameUserSettings.ini.
.DESCRIPTION
    Ce script compare les réglages graphiques entre les deux fichiers de configuration
    principaux pour détecter d'éventuelles contradictions (ex: ombres désactivées dans l'un
    mais activées dans l'autre) et génère un rapport HTML.
.NOTES
    Auteur: Jules, Ingénieur Expert Unreal & Windows
    Version: 1.0
#>

# --- Fonctions Internes ---

function Get-DBDConfigPath {
    $basePath = "$env:LOCALAPPDATA\DeadByDaylight\Saved\Config"
    $primaryPath = Join-Path $basePath "WindowsClient"
    $fallbackPath = Join-Path $basePath "WindowsNoEditor"
    if (Test-Path $primaryPath) { return $primaryPath }
    if (Test-Path $fallbackPath) { return $fallbackPath }
    throw "ERREUR: Dossier de configuration de DbD introuvable."
}

# Helper pour parser une valeur spécifique d'un fichier INI
function Get-IniValue {
    param($FilePath, $Regex)
    $match = (Get-Content $FilePath | Select-String -Pattern $Regex -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($match) {
        return ([regex]::Match($match.Line, $Regex).Groups[1].Value)
    }
    return "Non trouvé"
}


# --- Exécution Principale ---
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DocsRoot = Join-Path $PSScriptRoot "..\docs"
if (-not (Test-Path $DocsRoot)) { New-Item -ItemType Directory -Path $DocsRoot }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     Validation de la Cohérence des Fichiers .ini         " -ForegroundColor Cyan
Write-Host "=========================================================="

try {
    $configPath = Get-DBDConfigPath
    $engineIni = Join-Path $configPath "Engine.ini"
    $gusIni = Join-Path $configPath "GameUserSettings.ini"

    if ((-not (Test-Path $engineIni)) -or (-not (Test-Path $gusIni))) {
        throw "Un ou plusieurs fichiers .ini sont manquants dans le dossier de configuration."
    }

    Write-Host "-> Analyse des fichiers..."

    # Définir les paires de clés à comparer
    $validationPairs = @(
        @{ Name="Qualité des Ombres";         EngineRegex='r\.ShadowQuality=(\d+)';        GusRegex='sg\.ShadowQuality=(\d+)' },
        @{ Name="Qualité du Post-Process";    EngineRegex='r\.PostProcessAAQuality=(\d+)'; GusRegex='sg\.PostProcessQuality=(\d+)' },
        @{ Name="Qualité des Réflexions";     EngineRegex='r\.SSR\.Quality=(\d+)';         GusRegex='sg\.ReflectionQuality=(\d+)' },
        @{ Name="Qualité de l'Occlusion Amb."; EngineRegex='r\.AmbientOcclusionQuality=(\d+)'; GusRegex='sg\.GlobalIlluminationQuality=(\d+)' }
    )

    $results = @()
    foreach ($pair in $validationPairs) {
        $engineValue = Get-IniValue -FilePath $engineIni -Regex $pair.EngineRegex
        $gusValue = Get-IniValue -FilePath $gusIni -Regex $pair.GusRegex

        $status = if ($engineValue -eq $gusValue) { "<font color='green'>OK</font>" } else { "<font color='red'>INCOHÉRENCE</font>" }

        $results += [PSCustomObject]@{
            "Réglage" = $pair.Name
            "Valeur (Engine.ini)" = $engineValue
            "Valeur (GameUserSettings.ini)" = $gusValue
            "Statut" = $status
        }
    }

    Write-Host "-> Génération du rapport HTML..."

    # CSS pour un rapport propre
    $htmlHeader = @"
<style>
    body { font-family: sans-serif; }
    table { border-collapse: collapse; margin: 20px 0; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
    h1 { color: #333; }
</style>
"@

    $reportPath = Join-Path $DocsRoot "Rapport_Validation_INI.html"
    $results | ConvertTo-Html -Head $htmlHeader -Body "<h1>Rapport de Validation de Cohérence INI</h1><p>Généré le $(Get-Date)</p>" | Out-File $reportPath

    Write-Host "   OK: Rapport généré : docs\Rapport_Validation_INI.html" -ForegroundColor Green
    Invoke-Item $reportPath # Ouvre le rapport dans le navigateur par défaut
}
catch {
    Write-Host "`nERREUR CRITIQUE LORS DE LA VALIDATION :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Read-Host "`nAppuyez sur Entrée pour quitter."
