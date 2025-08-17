# Pack E-Sport Ultra-Sophistiqué pour Dead by Daylight

**Auteur : Jules, Ingénieur Expert Unreal & Windows**
**Version : 1.0**

## 1. Philosophie et Approche d'Ingénierie

Ce pack n'est pas une simple collection de fichiers de configuration. C'est un **outil d'ingénierie** conçu pour optimiser Dead by Daylight au niveau e-sport, en se concentrant sur trois piliers :
1.  **Performance Mesurable :** Latence d'entrée minimale et frametimes les plus stables possible (faible P99).
2.  **Lisibilité Maximale :** Une image propre, nette, sans effets superflus (motion blur, DoF, etc.), pour une détection parfaite des mouvements.
3.  **Validation et Robustesse :** Le pack ne se contente pas d'appliquer des réglages ; il **vérifie** que le moteur du jeu les accepte et s'**auto-corrige** si ce n'est pas le cas.

**GARANTIE 100% FAIR-PLAY :** Cet outil respecte scrupuleusement l'EULA du jeu. Aucune modification n'est apportée pour obtenir un avantage déloyal (pas de suppression de brouillard, pas d'altération du stain, etc.). Nous n'utilisons que les leviers fournis par Unreal Engine.

---

## 2. Installation en 2 Phases : La Méthode Intelligente

L'installation se déroule en deux temps pour garantir une configuration parfaitement adaptée à **votre** version du jeu.

### Phase 1 : Installation du Profil de Base

1.  **Exécutez `install.ps1`** (dans le dossier `scripts`) une première fois.
2.  Le script va :
    *   Sauvegarder votre configuration actuelle dans le dossier `backup`.
    *   Détecter votre matériel (VRAM, CPU) et sélectionner le profil le plus adapté (A, B, C ou D).
    *   Installer les fichiers `.ini` optimisés pour ce profil.
3.  À la fin de cette phase, le script vous demandera de lancer le jeu.

### ACTION REQUISE : Lancez et Quittez le Jeu

C'est l'étape la plus importante.
1.  **Lancez Dead by Daylight.**
2.  Attendez d'être dans le **menu principal**.
3.  **Quittez proprement le jeu** via le menu.

En faisant cela, vous forcez le moteur du jeu à lire tous nos nouveaux paramètres et à écrire dans son fichier journal (`DeadByDaylight.log`) ceux qu'il accepte et ceux qu'il rejette.

### Phase 2 : Validation et Auto-Correction

1.  **Relancez `install.ps1`** une seconde fois.
2.  Le script détectera automatiquement qu'il est temps pour la Phase 2. Il va :
    *   **Analyser le fichier journal** du jeu.
    *   Identifier toutes les commandes (cvars) que le jeu a marquées comme "Unknown" ou "ignored".
    *   **Réécrire votre `Engine.ini`** en commentant automatiquement les lignes rejetées, avec une note explicative.
    *   Générer les rapports `ACCEPTED_CVARS.txt` et `REJECTED_CVARS.txt` dans le dossier `docs`.

À la fin de la Phase 2, vous disposez d'une configuration **prouvée et validée** par le moteur du jeu lui-même.

---

## 3. Comprendre les Outils Fournis

*   `install.ps1`: L'orchestrateur principal pour l'installation en deux phases.
*   `uninstall.ps1`: Restaure votre dernière sauvegarde. Rapide, sûr, efficace.
*   `validate.ps1`: Un outil d'audit. Il compare vos fichiers `Engine.ini` et `GameUserSettings.ini` pour détecter des incohérences (ex: ombres à 0 dans l'un, à 2 dans l'autre) et produit un rapport HTML.

---

## 4. FAQ et Concepts Techniques

*   **Pourquoi `WindowsClient` et pas `WindowsNoEditor` ?**
    `WindowsClient` est le dossier de configuration standard pour la version Steam de DbD. `WindowsNoEditor` est un ancien chemin ou un fallback (parfois pour la version MS Store). Le script cible `WindowsClient` en priorité, comme le recommande la communauté et [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Dead_by_Daylight).

*   **Pourquoi la validation par le log est-elle si importante ?**
    Les développeurs peuvent désactiver certaines cvars à chaque mise à jour du jeu pour des raisons d'équilibrage. Une commande qui fonctionnait hier peut être rejetée aujourd'hui. La seule source de vérité est le log du jeu (`DeadByDaylight.log`), qui écrit noir sur blanc "Unknown console variable" si une commande est inconnue. Notre script automatise cette lecture, garantissant que votre configuration est toujours 100% pertinente.

*   **Cohérence entre `SystemSettings` et `ScalabilityGroups`**
    Dans Unreal Engine, les `ScalabilityGroups` (dans `GameUserSettings.ini`) sont des préréglages (Bas, Moyen, etc.) qui contrôlent des dizaines de cvars. Les `[SystemSettings]` (dans `Engine.ini`) peuvent outrepasser ces cvars individuellement. Pour éviter les conflits, notre pack s'assure que si `sg.ShadowQuality` est à `0`, les cvars correspondantes dans `Engine.ini` le sont aussi. C'est un principe de base pour une configuration stable, documenté par [Epic Games](https://docs.unrealengine.com/en-US/topic/performance-and-profiling/scalability-and-the-device-profiles-and-rules/index.html).

*   **CVars Expérimentales**
    Certaines lignes dans `Engine.ini` sont commentées et marquées `EXPERIMENTAL`. Ce sont des optimisations connues mais dont l'efficacité peut varier. Le script de validation les ignore volontairement, mais les utilisateurs avancés peuvent les tester et utiliser le log pour vérifier si elles sont acceptées.

---

## 5. Procédure de Rollback (Désinstallation)

Pour annuler toutes les modifications :
1.  Exécutez `scripts/uninstall.ps1`.
2.  Confirmez votre choix.
3.  Vos fichiers de configuration d'origine seront restaurés.

---
**FIN**
