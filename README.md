# Dead by Daylight — Config compétitive optimisée

Pack de configuration `.ini` pour **Dead by Daylight** (PC, Steam / Epic).
Pensé pour le **jeu compétitif** : 120 FPS stables, latence d'entrée
minimale, lisibilité maximale, son spatialisé.

> Disposition clavier : **AZERTY** (Français). Adaptez `Input.ini` si vous
> jouez en QWERTY.

---

## Sommaire

- [Contenu du dépôt](#contenu-du-dépôt)
- [Installation](#installation) (voir aussi [`INSTALL.md`](INSTALL.md))
- [Profil ciblé](#profil-ciblé)
- [Points-clés des réglages](#points-clés-des-réglages)
- [Anti-cheat (EAC)](#anti-cheat-eac)
- [Personnalisation rapide](#personnalisation-rapide)
- [FAQ](#faq)
- [Restauration des réglages d'origine](#restauration-des-réglages-dorigine)

---

## Contenu du dépôt

| Fichier                  | Rôle                                                                                          |
|--------------------------|-----------------------------------------------------------------------------------------------|
| `Engine.ini`             | Tweaks moteur Unreal : threading, GC, streaming textures, post-process, audio, réseau.        |
| `GameUserSettings.ini`   | Options visibles dans le menu (résolution, FOV, volume, sensibilités, accessibilité, HUD).    |
| `Input.ini`              | Bindings clavier/souris/manette (axes + actions Survivor & Killer + gestes + UI).             |
| `Scalability.ini`        | Redéfinition des buckets de qualité graphique (Low/Medium/High/Epic) pour DBD.                |
| `INSTALL.md`             | Procédure d'installation pas-à-pas (Windows / Steam Deck).                                    |
| `CHANGELOG.md`           | Journal des changements depuis la config d'origine.                                           |

---

## Installation

### Chemin Windows

```
%LOCALAPPDATA%\DeadByDaylight\Saved\Config\WindowsNoEditor\
```

Astuce : collez ce chemin tel quel dans la barre d'adresse de l'explorateur
Windows.

### Procédure express

1. **Fermez Dead by Daylight** (et Steam, par sécurité).
2. **Sauvegardez** vos `.ini` existants (renommez-les en `.bak`).
3. **Copiez** les 4 fichiers `.ini` du dépôt dans le dossier ci-dessus.
4. (Optionnel mais recommandé) **Passez chaque `.ini` en lecture seule** :
   clic-droit → Propriétés → cocher *Lecture seule* → OK.
   Cela empêche DBD d'écraser vos réglages au prochain lancement.
5. **Lancez DBD**. La première partie peut compiler des shaders : c'est
   normal, ne paniquez pas si elle est saccadée.

> Guide détaillé : voir [`INSTALL.md`](INSTALL.md).

---

## Profil ciblé

| Critère                     | Valeur cible                                            |
|-----------------------------|---------------------------------------------------------|
| Résolution                  | 1920×1080 (Full HD)                                     |
| Affichage                   | Borderless (Alt-Tab instantané)                         |
| Frame rate cible            | 120 FPS                                                 |
| Cap moteur                  | 120 FPS (anti tearing + latence stable)                 |
| V-Sync                      | OFF                                                     |
| Anti-aliasing               | OFF (image la plus nette)                               |
| Champ de vision (FOV)       | 103 (max survivor)                                      |
| Gamma                       | 2.8 (équilibre visibilité/réalisme)                     |
| Volume principal            | 80 % (headroom pour ne pas saturer en chase)            |
| HRTF / Headphones           | ON                                                      |
| Musique lobby / menu        | OFF en partie, ON au menu                               |
| Anti-cheat                  | EAC respecté (aucun bypass)                             |

---

## Points-clés des réglages

### Engine.ini — Performance & latence

- `bSmoothFrameRate=False` : le smoothing UE4 est désactivé, on laisse DBD
  gérer le cap FPS → input lag réduit.
- `NetClientTicksPerSecond=120` : tickrate client augmenté à 120.
- `r.OneFrameThreadLag=1` + `r.FinishCurrentFrame=0` : pipeline CPU/GPU
  optimal.
- `r.Streaming.PoolSize=4096` : 4 Go dédiés au streaming textures (adapter
  à la VRAM, voir commentaires dans le fichier).
- `gc.TimeBetweenPurgingPendingKillObjects=180` : les passes de Garbage
  Collector tombent toutes les 3 min — beaucoup plus rare que par défaut,
  donc moins de micro-freezes en chase.
- Post-process coûteux désactivés : bloom, motion blur, aberration
  chromatique, lens flare, fog volumétrique.
- Logique audio basse latence + désactivation du master EQ.
- Vidéos d'intro (logos Behaviour/EAC) sautées au lancement.

### GameUserSettings.ini — Réglages visibles + corrections

> Tous les **doublons** du fichier d'origine ont été supprimés.
> Quand DBD lisait l'ancien fichier, c'était toujours la **dernière**
> occurrence qui gagnait → certains réglages affichés dans le menu ne
> correspondaient pas à la valeur réellement appliquée.

Doublons consolidés :
- `Gamma` (apparaissait 3× avec des valeurs différentes)
- `MainVolume` (×2 : 100 puis 80)
- `SurvivorCameraSensitivity`, `KillerCameraSensitivity` (×2)
- `SurvivorMouseSensitivity`, `KillerMouseSensitivity` (×2)
- `InvertY`, `LegacyPrestigePortraits`, `LargeText`, `ColorblindMode` (×2)
- `MenuMusicVolume`, `TerrorRadiusVisualFeedback`, `VoiceOverLanguage` (×2)
- `PreferredFullscreenMode`, `AudioQualityLevel` (×2)

### Input.ini — Bindings nettoyés

> La touche `Q` était partagée par **5 actions différentes**.
> C'est maintenant résolu :

- `PushToTalk` → déplacé de `Q` vers `V` (pour ne plus interférer avec
  `MoveRightSurvivor=Q` et `MoveRightKiller=Q`).
- `EventAbility_Killer` → déplacé de `ThumbMouseButton2` (qui était déjà
  utilisée par `Gesture02`) vers `ThumbMouseButton`.
- Sections regroupées : **AXES**, **SURVIVOR**, **KILLER**, **GESTES**, **UI**.

### Scalability.ini — Buckets qualité personnalisés

Redéfinit ce que veut dire "Medium", "High", "Epic" pour chaque axe :
- **Feuillage** : densité conservée même en bas niveau → pas d'avantage
  anti-bush déloyal.
- **Ombres** : minimum de 1024×1024 — voir la silhouette du killer dans
  une ombre portée reste possible.
- **Effets** : motion blur, DoF, lens flare → toujours à 0, peu importe le
  niveau choisi.

---

## Anti-cheat (EAC)

Tous les tweaks de ce pack sont des paramètres standards d'Unreal Engine
utilisés par toute la communauté DBD depuis des années. **Aucun ne
contourne EAC**, ne modifie un fichier de jeu, ni n'injecte de code.

Easy Anti-Cheat **ne ban pas** pour modification de `.ini` situés dans
`%LOCALAPPDATA%` (c'est le dossier officiel de config utilisateur).
Si vous voyez un témoignage en ligne disant le contraire, il s'agit
quasiment toujours d'un autre logiciel (overlay, macro, trainer) lancé
en parallèle qui était la vraie cause.

> En cas de doute, faites une **vérification d'intégrité Steam**
> (Bibliothèque → DBD → Propriétés → Fichiers locaux → Vérifier).
> Cela ne touche pas aux `.ini` utilisateur.

---

## Personnalisation rapide

### J'ai moins de 8 Go de RAM

Dans `GameUserSettings.ini` :
```ini
[DeadByDaylight.Optimization]
bLowMemoryMode=True
bPreloadLobbyAssets=False
```

Dans `Engine.ini`, baissez `r.Streaming.PoolSize` à `1500`.

### Mon écran est en QHD (1440p) ou 4K

Dans `GameUserSettings.ini` :
```ini
ResolutionSizeX=2560
ResolutionSizeY=1440
LastUserConfirmedResolutionSizeX=2560
LastUserConfirmedResolutionSizeY=1440
DesiredScreenWidth=2560
DesiredScreenHeight=1440
```
(ou `3840` / `2160` pour 4K)

Et augmentez `r.Streaming.PoolSize` à `6144` (8 Go VRAM) ou `8192` (12 Go+).

### Je joue en QWERTY

Dans `Input.ini`, remplacez :
- `Z` → `W` (MoveForward)
- `Q` → `A` (MoveRight, scale -1.0)
- `S` reste `S`
- `D` reste `D`

Et `PushToTalk` sur `V` reste pratique.

### Je veux plus de FPS (>120)

Dans `GameUserSettings.ini` :
```ini
FrameRateLimit=240.000000
FPSLimitMode=240
```

Pensez à augmenter le `Hz` de votre écran en parallèle.

---

## FAQ

**Q. Ces réglages me donnent-ils un avantage déloyal ?**
R. Non. Le fichier conserve volontairement la densité de feuillage et la
qualité des ombres à un niveau qui ne permet pas le "bush-hiding cheese"
ou la transparence des ombres. C'est un setup *propre*.

**Q. Le jeu écrase mes réglages à chaque lancement.**
R. C'est normal : DBD réécrit `GameUserSettings.ini` à la sortie.
Passez les fichiers en **lecture seule** (voir Installation, étape 4).

**Q. Mes shaders mettent une plombe à compiler à la première partie.**
R. Normal après modification d'`Engine.ini`. Le cache se reconstruit.
Patientez 2-3 minutes au menu avant de lancer une partie classée.

**Q. Mes binds ne sont pas pris en compte.**
R. Vérifiez que `Input.ini` est bien lecture-seule et que DBD n'a pas
créé une copie dans `%LOCALAPPDATA%\DeadByDaylight\Saved\SaveGames\`.
Supprimez tout fichier `.uesave` lié aux contrôles si nécessaire.

**Q. Puis-je utiliser ces réglages sur Steam Deck ?**
R. Oui. Le chemin est :
`~/.local/share/Steam/steamapps/compatdata/381210/pfx/drive_c/users/steamuser/AppData/Local/DeadByDaylight/Saved/Config/WindowsNoEditor/`

**Q. Et sur PS5 / Xbox / Switch ?**
R. Non, les `.ini` ne sont pas modifiables sur consoles.

---

## Restauration des réglages d'origine

1. Fermez DBD.
2. Allez dans le dossier `WindowsNoEditor`.
3. Supprimez `Engine.ini`, `GameUserSettings.ini`, `Input.ini`,
   `Scalability.ini`.
4. Si vous aviez fait des `.bak`, renommez-les en retirant le suffixe.
5. Sinon, DBD régénérera des fichiers par défaut au prochain lancement.

---

## Crédits

Pack maintenu par la communauté. Basé sur les pratiques éprouvées du
DBD compétitif (FPS uncap stable, latence d'entrée minimale, lisibilité).

Distribué tel quel, sans garantie. Utilisez à vos risques (très limités).
