# DBD Self-Heal Pack - Outil de Diagnostic et Réparation

**Auteur : Jules, Ingénieur Outillage**
**Version : 1.0**

## ⚠️ Avertissement et Philosophie

Ce pack est un outil d'ingénierie conçu pour **diagnostiquer et réparer** les problèmes courants de stabilité, de performance et de configuration de Dead by Daylight sur PC. Il agit comme un technicien automatisé.

*   **100% FAIR-PLAY :** Cet outil n'est **PAS** un outil de triche. Il ne modifie aucun élément de gameplay, ne supprime pas le brouillard, n'altère pas la tache rouge, etc. Il respecte scrupuleusement l'EULA du jeu.
*   **SÉCURISÉ :** Toutes les opérations sont conçues pour être sûres. Des sauvegardes sont créées automatiquement et toutes les actions sensibles (nettoyage système, etc.) demandent votre confirmation.
*   **RÉVERSIBLE :** Tout ce que fait cet outil peut être annulé via le script `Uninstall-DBD-SelfHeal.ps1`.

---

## 🚀 Guide de Démarrage Rapide

1.  **Prérequis :**
    *   Téléchargez [PresentMon](https://github.com/GameTechDev/PresentMon/releases) (cherchez le dernier `PresentMon-vX.X.X.exe`). Installez-le. Le script s'attend à le trouver dans son emplacement d'installation par défaut. Si ce n'est pas le cas, vous pouvez copier `PresentMon.exe` et les `.dll` associées dans un dossier `PresentMon` à la racine de ce pack.
2.  **Installation :**
    *   Décompressez l'archive `DBD-SelfHeal-Pack.zip`.
    *   Naviguez dans le dossier `scripts`.
3.  **Exécution :**
    *   Faites un clic droit sur `Start-DBD-SelfHeal.ps1` et choisissez **"Exécuter avec PowerShell"**.
    *   Le script vous guidera à travers chaque étape. Lisez attentivement les instructions à l'écran.

*Note sur la politique d'exécution PowerShell :* Si vous rencontrez une erreur, ouvrez une fenêtre PowerShell en tant qu'administrateur et tapez `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`. Confirmez avec 'O', puis relancez le script.

## ⏪ Comment Annuler les Changements (Rollback)

Si vous souhaitez revenir à votre configuration d'avant l'utilisation de l'outil :
1.  Allez dans le dossier `scripts`.
2.  Exécutez `Uninstall-DBD-SelfHeal.ps1`.
3.  Le script restaurera automatiquement la dernière sauvegarde de vos fichiers `.ini`.

---

## 🛠️ Détail des Opérations

Voici ce que l'outil fait, et comment vous pouvez utiliser ses composants manuellement.

#### Gestion des Configurations (.ini)
*   **Où se trouvent les configs ?** Le script cherche automatiquement dans `%LOCALAPPDATA%\DeadByDaylight\Saved\Config\WindowsClient`. C'est le dossier standard pour la version Steam. En cas d'échec, il peut utiliser `WindowsNoEditor` comme solution de secours (plus rare, concerne parfois la version Microsoft Store).
*   **Normalisation :** Le script nettoie vos fichiers `.ini` des doublons et des erreurs, tout en préservant vos paramètres personnels (sensibilité, touches, FOV, etc.). Il applique ensuite une base de réglages optimisés pour la stabilité.

#### Vérification de l'Intégrité (Steam)
*   **Qu'est-ce que ça fait ?** Le script lance la commande `steam://validate/381210` (381210 est l'ID de DbD sur Steam). Cela ouvre l'outil de vérification de Steam, qui est la méthode la plus sûre pour réparer des fichiers de jeu corrompus.
*   **Utilisation manuelle :** Dans Steam -> Bibliothèque -> Clic droit sur Dead by Daylight -> Propriétés -> Fichiers locaux -> Vérifier l'intégrité des fichiers du jeu.

#### Réparation de Easy Anti-Cheat (EAC)
*   **Qu'est-ce que ça fait ?** Le script localise et exécute `EasyAntiCheat_EOS_Setup.exe` avec les droits d'administrateur.
*   **Utilisation manuelle :** Allez dans votre dossier d'installation de DbD, puis dans `EasyAntiCheat`. Exécutez `EasyAntiCheat_EOS_Setup.exe`, sélectionnez "Dead by Daylight" et cliquez sur "Réparer".

#### Nettoyage des Caches
*   **DirectX Shader Cache :** Ce cache peut parfois se corrompre et causer des stutters. Le script ouvre l'outil "Nettoyage de disque" de Windows. C'est à vous de cocher la case "Cache de nuanceur DirectX" et de valider.
*   **DerivedDataCache :** Cache interne d'Unreal Engine. Le script le vide automatiquement car l'opération est sans risque. Le jeu le reconstruira au prochain lancement.

#### API Graphique (DirectX 11 vs DirectX 12)
*   **Quand changer ?** DbD utilise par défaut DX12 sur beaucoup de configurations récentes. Si vous subissez des crashs ou des stutters importants que rien d'autre ne résout, forcer le jeu en DX11 peut grandement améliorer la stabilité.
*   **Comment faire ?** Dans Steam, allez dans les options de lancement du jeu et ajoutez `-dx11`. Retirez la commande pour revenir à la version par défaut (probablement DX12). Le script ne modifie pas ce paramètre automatiquement mais le fera dans une future version avec watchdog.

---

## 💡 Bonnes Pratiques et FAQ

*   **Pilotes Graphiques :** Gardez toujours vos pilotes Nvidia ou AMD à jour. Utilisez DDU (Display Driver Uninstaller) en mode sans échec pour une réinstallation propre si vous suspectez un problème de pilote.
*   **Overlays :** Les overlays (Discord, Nvidia GeForce Experience, etc.) peuvent causer des instabilités. Si vous rencontrez des problèmes, essayez de les désactiver un par un pour identifier un éventuel coupable.
*   **FAQ : Pourquoi une de mes options .ini est ignorée ?**
    Certaines variables (cvars) sont verrouillées par les développeurs dans la version "shipping" (commerciale) du jeu pour des raisons d'équilibrage ou de stabilité. Même si vous les ajoutez à votre `.ini`, le jeu les ignorera purement et simplement. Cet outil n'utilise que des variables connues pour être actives et autorisées.

---
**FIN**
