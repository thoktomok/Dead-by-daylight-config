# Guide d'installation — Dead by Daylight Config

Procédure pas-à-pas pour installer ce pack `.ini` sur votre machine.

---

## 1. Avant de commencer

- [ ] **Fermez Dead by Daylight** complètement.
- [ ] **Fermez Steam / l'Epic Games Launcher** (sinon ils peuvent garder
      une poignée sur le dossier de config).
- [ ] Vérifiez que vous avez une copie de sauvegarde de vos `.ini` actuels
      (étape ci-dessous).

---

## 2. Localiser le dossier de configuration

### Windows 10 / Windows 11

Appuyez sur **Windows + R**, collez ceci et validez :

```
%LOCALAPPDATA%\DeadByDaylight\Saved\Config\WindowsNoEditor\
```

Le dossier doit contenir (au minimum) :
- `Engine.ini`
- `GameUserSettings.ini`
- `Input.ini`

### Steam Deck (Linux / Proton)

Activez l'affichage des fichiers cachés, puis ouvrez :

```
~/.local/share/Steam/steamapps/compatdata/381210/pfx/drive_c/users/steamuser/AppData/Local/DeadByDaylight/Saved/Config/WindowsNoEditor/
```

> `381210` est l'AppID Steam de DBD. Si le dossier `compatdata/381210`
> n'existe pas, lancez DBD une fois pour le créer puis quittez.

---

## 3. Sauvegarder l'existant

Dans le dossier `WindowsNoEditor`, renommez :

```
Engine.ini             ->  Engine.ini.bak
GameUserSettings.ini   ->  GameUserSettings.ini.bak
Input.ini              ->  Input.ini.bak
Scalability.ini        ->  Scalability.ini.bak   (si présent)
```

> Astuce Windows : sélectionnez les 4 fichiers, appuyez sur **F2**,
> ajoutez `.bak` à la fin du nom — Windows l'applique à tous d'un coup
> (en réalité il faut faire un par un sur Windows ; sous PowerShell :
> `Get-ChildItem *.ini | Rename-Item -NewName { $_.Name + ".bak" }`).

---

## 4. Copier les nouveaux fichiers

Téléchargez ce dépôt (ZIP → décompresser) ou clonez-le :

```bash
git clone https://github.com/<votre-user>/Dead-by-daylight-config.git
```

Copiez les fichiers suivants dans `WindowsNoEditor` :

- `Engine.ini`
- `GameUserSettings.ini`
- `Input.ini`
- `Scalability.ini`

Ne copiez **PAS** : `README.md`, `INSTALL.md`, `CHANGELOG.md`,
le dossier `.git` — ils sont inutiles pour le jeu.

---

## 5. Passer en lecture seule (recommandé)

Sans cette étape, DBD **écrasera** vos réglages dès que vous toucherez à
une option in-game.

### Méthode souris (Windows)

1. Sélectionnez les 4 `.ini`.
2. Clic-droit → **Propriétés**.
3. Cochez **Lecture seule**.
4. **OK** → Appliquer aux fichiers sélectionnés.

### Méthode PowerShell (rapide)

Dans le dossier `WindowsNoEditor`, ouvrez PowerShell et tapez :

```powershell
Set-ItemProperty -Path "Engine.ini","GameUserSettings.ini","Input.ini","Scalability.ini" -Name IsReadOnly -Value $true
```

### Méthode Linux / Steam Deck

```bash
chmod 444 Engine.ini GameUserSettings.ini Input.ini Scalability.ini
```

---

## 6. Premier lancement

1. Lancez Dead by Daylight via Steam / Epic.
2. **Au menu principal**, attendez 1-2 minutes : le cache de shaders se
   reconstruit silencieusement à cause des nouvelles valeurs.
3. Lancez une **partie d'entraînement** (Custom Game seul vs bot) pour
   vérifier que :
   - [ ] La résolution est bonne.
   - [ ] Les binds clavier répondent (Z/Q/S/D, LeftShift sprint, etc.).
   - [ ] Le FPS est stable autour de 120 (compteur via overlay Steam).
   - [ ] Le son est correctement positionné (HRTF actif).

---

## 7. Si quelque chose ne va pas

### Le jeu ne se lance plus

Très improbable. Repassez vos fichiers en lecture-écriture, supprimez les
`.ini` du pack, restaurez vos `.bak` (renommez sans le suffixe).

### Les sensibilités souris ont changé

C'est normal : le profil a fixé `SurvivorMouseSensitivity=50` et
`KillerMouseSensitivity=50`. Ajustez dans Options du jeu. Pour rendre les
changements persistants, repassez les fichiers en lecture-écriture,
modifiez, sauvegardez, repassez en lecture seule.

### Les binds AZERTY ne marchent pas

Vérifiez que Windows est bien en disposition **Français AZERTY** au
démarrage du jeu (et pas en QWERTY US). Indicateur Windows en bas-droite.

### Mes shaders compilent dans chaque partie

C'est une compilation initiale. Elle ne se reproduit pas. Si oui :
- Vérifiez que le dossier `WindowsNoEditor` n'est pas en lecture seule
  (juste les `.ini`, pas le dossier entier).
- Vérifiez que vous avez assez d'espace disque (>5 Go libres).

---

## 8. Mise à jour du pack

Quand une nouvelle version sort :

```bash
cd Dead-by-daylight-config
git pull
```

Puis ré-exécutez les étapes 1, 5 et 6 (la copie n'est pas nécessaire si
vous avez fait un lien symbolique, sinon recopiez les `.ini`).

---

Bonne chasse. Ou bonne survie.
