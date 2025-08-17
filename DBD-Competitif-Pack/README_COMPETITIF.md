# Pack de Configuration Compétitive pour Dead by Daylight

**Auteur : Jules, Ingénieur Logiciel**
**Version : 1.0**

Ce pack a pour but d'optimiser Dead by Daylight pour la **performance**, la **stabilité** et la **lisibilité**, dans le respect le plus total des règles du jeu. Il est conçu pour les joueurs souhaitant une expérience fluide et réactive, sans altérer l'équilibrage du gameplay.

---

## ⚠️ Important : Conformité et Fair-Play

Ce pack est **100% fair-play** et respecte l'EULA de Behaviour Interactive.

*   **AUCUNE MODIFICATION INTERDITE :** Les configurations ne visent PAS à supprimer le brouillard, le feu, les herbes, ni à amplifier la tache rouge du tueur ou à altérer les ombres de manière déloyale.
*   **PAS DE TRICHE :** Aucune injection de code, aucun "hook", aucun outil externe intrusif. Tout est géré via les fichiers de configuration `.ini` du jeu, en utilisant des variables moteur standards d'Unreal Engine.
*   **RÉVERSIBLE :** L'intégralité des modifications peut être annulée en une seule commande grâce au script de désinstallation fourni.

L'objectif est une image **propre** et **fluide**, pas un avantage illégitime.

---

## 🚀 Installation Automatique

Le script PowerShell s'occupe de tout.

1.  **Décompressez l'archive** `DBD-Competitif-Pack.zip` dans un dossier de votre choix.
2.  Naviguez dans le dossier `Scripts`.
3.  Faites un clic droit sur `install_dbd_competitif.ps1` et choisissez **"Exécuter avec PowerShell"**.
    *   *Si vous rencontrez une erreur de stratégie d'exécution, ouvrez une fenêtre PowerShell en tant qu'administrateur, naviguez jusqu'au dossier `Scripts` et tapez : `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`. Confirmez avec 'O' (Oui), puis relancez le script avec `.\install_dbd_competitif.ps1`.*
4.  Le script va automatiquement :
    *   Sauvegarder vos configurations actuelles.
    *   Détecter votre matériel (VRAM, résolution).
    *   Installer le profil le plus adapté.
5.  **(Optionnel) Verrouiller les fichiers :** Pour empêcher le jeu de réinitialiser certains paramètres, vous pouvez exécuter le script avec l'option `-SetReadOnly`.
    *   Exemple (dans une fenêtre PowerShell) : `.\install_dbd_competitif.ps1 -SetReadOnly`

## ⏪ Rollback / Désinstallation

Pour restaurer votre configuration d'origine :

1.  Naviguez dans le dossier `Scripts`.
2.  Faites un clic droit sur `Uninstall.ps1` et choisissez **"Exécuter avec PowerShell"**.
3.  Le script restaurera automatiquement votre dernière sauvegarde. C'est instantané.

---

## 📊 Tableau des Réglages par Profil

Le script choisit automatiquement le meilleur profil pour vous. Voici les différences clés :

| Profil | Cible VRAM | `r.Streaming.PoolSize` | `sg.TextureQuality` | `sg.ViewDistanceQuality` |
| :--- | :--- | :--- | :--- | :--- |
| **A - Très Basse** | 2-4 Go | `512` Mo | `0` (Basse) | `1` (Moyenne) |
| **B - Moyenne** | 6-8 Go | `1024` Mo | `1` (Moyenne) | `1` (Moyenne) |
| **C - Haute** | 10-12 Go | `1536` Mo | `2` (Haute) | `2` (Haute) |
| **D - Très Haute**| 12+ Go | `2048` Mo | `3` (Ultra) | `2` (Haute) |

---

## ✅ Recommandations Essentielles (Hors Script)

Pour des résultats optimaux, appliquez également ces réglages :

#### 1. Panneau de Configuration NVIDIA
*   **Gérer les paramètres 3D -> Paramètres de programme -> Dead by Daylight (`DeadByDaylight-Win64-Shipping.exe`)**
    *   **Mode de faible latence :** `Activé` ou `Ultra`.
    *   **Mode de gestion de l'alimentation :** `Privilégier les performances maximales`.
    *   **Synchronisation verticale :** `Désactivé` (le script s'en charge dans le jeu, mais une double sécurité est préférable).

#### 2. Logiciel AMD Adrenalin
*   **Jeux -> Dead by Daylight -> Graphismes**
    *   **Radeon Anti-Lag :** `Activé`.
    *   **Attendre la synchronisation verticale :** `Toujours désactivé`.

#### 3. Paramètres Windows
*   **Options d'alimentation :** Choisissez le mode `Performances élevées`.
*   **Paramètres graphiques (Windows 10/11) :** Activez la `Planification de processeur graphique à accélération matérielle` (HAGS). Un redémarrage est nécessaire. Testez avec et sans, car la stabilité peut varier selon les pilotes.

#### 4. Options de Lancement Steam
*   **Bibliothèque Steam -> Clic droit sur Dead by Daylight -> Propriétés -> Général -> Options de lancement**
    *   Vous pouvez tester `-dx11` ou `-dx12`.
    *   `-dx12` peut offrir de meilleures performances sur les GPU récents, mais peut être moins stable.
    *   `-dx11` est généralement plus stable et fiable.
    *   **Ne mettez rien si vous ne rencontrez pas de problème.**

---

## 📝 Check-list de Validation Post-Installation

Après avoir lancé le script, vérifiez ces points en jeu :
1.  **Stabilité Alt-Tab :** Le jeu est-il en fenêtré plein écran ? Faites `Alt+Tab` plusieurs fois. Ce doit être rapide et sans plantage.
2.  **Fluidité :** Lancez une partie personnalisée (KYF). Vos FPS sont-ils plus élevés et plus stables ?
3.  **Qualité visuelle :** L'image doit paraître plus "brute" et nette, sans flou de mouvement ni effets de caméra superflus. Les textures doivent correspondre à votre profil.
4.  **Conformité :** Vérifiez que le brouillard, les feux des tonneaux et les ombres importantes sont toujours présents.

---

## ❓ FAQ

*   **Quelle est la différence entre `WindowsClient` et `WindowsNoEditor` ?**
    `WindowsClient` est le dossier de configuration utilisé par la version Steam standard. `WindowsNoEditor` est un ancien nom ou un fallback parfois utilisé par la version Microsoft Store ou d'anciennes builds. Le script détecte le bon automatiquement.

*   **Puis-je personnaliser mes touches ?**
    Oui. Ce pack ne modifie pas vos attributions de touches (`ActionMappings`). Vous pouvez les changer en jeu sans problème.

*   **Le script a échoué, que faire ?**
    Consultez le fichier `.log` créé dans le dossier `Logs` pour voir l'erreur. La cause la plus commune est un problème de permissions. Essayez de l'exécuter en tant qu'administrateur.

*   **Pourquoi mettre les fichiers en lecture seule ?**
    Parfois, le jeu peut écraser certains paramètres (comme `FrameRateLimit`) après une mise à jour ou une modification des options en jeu. La lecture seule empêche cela. Pour modifier à nouveau les options, lancez le script `Uninstall.ps1` ou retirez manuellement l'attribut (clic droit sur le fichier -> Propriétés -> décochez "Lecture seule").
