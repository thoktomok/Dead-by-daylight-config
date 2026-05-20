# Changelog

Toutes les modifications notables de ce pack sont listées ici.

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

---

## [2.0.0] — Refonte complète

### Ajouts

- **`Scalability.ini`** : nouveau fichier redéfinissant tous les buckets
  de qualité graphique (Low/Medium/High/Epic/Cinematic) spécifiquement
  pour Dead by Daylight.
- **`INSTALL.md`** : guide d'installation pas-à-pas
  (Windows + Steam Deck + Linux).
- **`CHANGELOG.md`** : journal des versions.
- **`README.md`** : documentation complète remplaçant les 2 lignes
  d'origine — installation, profil ciblé, anti-cheat, personnalisation,
  FAQ, restauration.
- Sections complètes ajoutées dans `Engine.ini` :
  - `[Core.Log]` (réduction du logging)
  - `[/Script/Engine.Engine]` (frame rate, NetClientTicksPerSecond)
  - `[/Script/Engine.GarbageCollectionSettings]` (anti micro-freeze)
  - `[TextureStreaming]` (pool de streaming)
  - `[/Script/Engine.RendererSettings]` (renderer defaults)
  - `[SystemSettings]` (CVars runtime exhaustives)
  - `[Audio]` / `[/Script/Engine.AudioSettings]`
  - `[/Script/MoviePlayer.MoviePlayerSettings]` (skip intro vidéos)

### Corrections

- **`GameUserSettings.ini`** — Suppression de tous les doublons :
  - `Gamma` (apparaissait 3× avec 3 valeurs différentes : 3.2, 2.8, 3.2)
  - `MainVolume` (×2 : 100 puis 80)
  - `SurvivorCameraSensitivity` (×2)
  - `KillerCameraSensitivity` (×2)
  - `SurvivorMouseSensitivity` (×2)
  - `KillerMouseSensitivity` (×2)
  - `InvertY` (×2)
  - `LegacyPrestigePortraits` (×2)
  - `LargeText` (×2)
  - `ColorblindMode` (×2)
  - `MenuMusicVolume` (×2)
  - `TerrorRadiusVisualFeedback` (×2)
  - `VoiceOverLanguage` (×2)
  - `PreferredFullscreenMode` (×2)
  - `AudioQualityLevel` (×2)

- **`Input.ini`** — Résolution des conflits de touches :
  - `PushToTalk` déplacé de `Q` vers `V` (la touche `Q` était utilisée
    par `MoveRightSurvivor`, `MoveRightKiller` et `MoveUp` simultanément).
  - `EventAbility_Killer` déplacé de `ThumbMouseButton2` vers
    `ThumbMouseButton` (conflit avec `Gesture02`).

### Améliorations

- Structure des fichiers `.ini` : sections regroupées et ordonnées
  logiquement.
- Commentaires inline en français pour chaque réglage non trivial.
- En-tête de fichier expliquant l'objectif, l'emplacement Windows, et
  les avertissements EAC.
- Profil cohérent "compétitif / lisibilité maximale" appliqué à tous
  les fichiers.
- Gamma final fixé à `2.800000` (au lieu d'osciller entre 2.8 et 3.2).
- Volume principal final fixé à `80` (au lieu de basculer 100 → 80).

---

## [1.0.0] — Version d'origine

### Contenu d'origine

- `Engine.ini` (4 lignes : juste `CachedClientID=358`)
- `GameUserSettings.ini` (avec nombreux doublons)
- `Input.ini` (avec conflits de touches non résolus)
- `README.md` (2 lignes)
