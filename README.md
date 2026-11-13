# Construire un agent IA, étape par étape

Dans cet atelier, vous construisez un agent IA sur votre propre ordinateur, une capacité à la fois : conversation, personnalité, mémoire, outils, fichiers, recherche web, MCP et skills.

- L'agent tourne sur deux petits modèles locaux, `llama3.2:3b` et `qwen2.5:3b`, avec [Ollama](https://ollama.com). Vous lui parlez dans une page web.
- Vous n'écrivez pas le code. [OpenCode](https://opencode.ai), un agent de programmation open source, l'écrit à partir de vos prompts.

## Avant l'atelier : l'installation

Il vous faut environ 3 Go d'espace disque libre et une bonne connexion (le modèle pèse environ 2 Go).

1. Téléchargez l'application de bureau **OpenCode** sur [opencode.ai/download](https://opencode.ai/download) et installez-la.
2. Téléchargez [le fichier zip](https://github.com/alexisperrier/construire_agent/archive/refs/heads/main.zip), placez-le dans un dossier dédié et décompressez-le. Vous obtenez un dossier nommé `construire_agent-main`.
3. Dans OpenCode, choisissez `construire_agent-main` comme dossier de projet. Sous la zone de chat, sélectionnez le modèle **GLM 5.3 Flash Free** s'il ne l'est pas déjà.
4. Dans OpenCode, ouvrez le panneau latéral (en haut à droite), puis un onglet **Terminal**, et lancez le script d'installation. Il installe Ollama et uv s'ils manquent, télécharge le modèle `llama3.2:3b` et installe les paquets Python. Vous pouvez le relancer sans risque.
   - macOS ou Linux : `bash setup/setup-mac-linux.sh`
   - Windows : `powershell -ExecutionPolicy Bypass -File setup\setup-windows.ps1`

   À la fin, il affiche la liste des modèles installés. Il crée aussi un fichier `.env` vide, qui servira à l'étape 6 pour la clé de recherche web.

5. Vérifiez que tout fonctionne. La vérification affiche chaque élément comme OK ou ÉCHEC, avec la marche à suivre pour chaque ÉCHEC :
   - macOS ou Linux : `bash setup/check-mac-linux.sh`
   - Windows : `powershell -ExecutionPolicy Bypass -File setup\check-windows.ps1`

Avec git plutôt que le zip : choisissez n'importe quel dossier comme projet dans OpenCode, demandez `clone le dépôt https://github.com/alexisperrier/construire_agent`, puis changez le dossier de projet pour `construire_agent`.

## Lancer la page de l'agent

Dans un onglet **Terminal** d'OpenCode, lancez :

```
uv run streamlit run app.py
```

La page s'ouvre dans votre navigateur à l'adresse [http://localhost:8804](http://localhost:8804) et affiche « Notre agent à Paris ». Laissez ce terminal tourner.

## Travailler avec OpenCode

- Pour modifier le code, écrivez un prompt à OpenCode dans le chat, ou ouvrez `app.py` depuis le panneau latéral, sélectionnez quelques lignes et ajoutez un commentaire. Le commentaire part dans le chat et ne concerne que ces lignes.
- Les fichiers sont en lecture seule dans OpenCode : chaque modification passe par l'agent.
- La page se recharge toute seule chaque fois que `app.py` est enregistré.

**Étape 0** : modifiez la page statique (titre, texte, couleurs) avec quelques prompts, pour voir la boucle : vous écrivez un prompt, OpenCode modifie `app.py`, la page se met à jour.

### Passer OpenCode sur un modèle OpenRouter

Vous commencez avec un modèle gratuit. Quand votre formateur vous le dit, ouvrez le sélecteur de modèle sous le chat, choisissez **Connect provider**, choisissez **OpenRouter** et collez la clé que votre formateur vous a donnée. Sélectionnez ensuite un modèle OpenRouter, par exemple **GLM 5.3**.

## Suivre l'atelier

Les prompts de chaque étape sont dans [prompts.md](prompts.md). Collez un prompt dans OpenCode, attendez qu'il ait enregistré `app.py`, puis parlez à votre agent dans la page web.

| Étape | Ajoute | Ce que ça montre |
|---|---|---|
| 0 | Une page statique | Vous écrivez un prompt, OpenCode écrit le code |
| 1 | Chat avec historique, choix du modèle | La « mémoire » d'un chat, c'est l'historique renvoyé à chaque fois |
| 2 | Prompt système (`system.md`) | Le harnais fixe le comportement du modèle |
| 3 | `memory.md` | La mémoire d'une session à l'autre est un fichier |
| 4 | Premier outil (la date) | La boucle d'agent : le modèle demande, le harnais agit |
| 5 | Outils de fichiers (`docs/`) | Limites d'accès et permission d'écrire |
| 6 | Recherche web (Tavily) | Informations à jour et sources |
| 7 | Outil `remember` | Le modèle décide de ce qu'il retient |
| 8 | Serveur MCP (fetch) | Des outils tout faits, via un protocole standard |
| 9 | Skills (`skills/`) | Des instructions chargées seulement quand il le faut |

**Avant l'étape 6** : ouvrez `.env` et ajoutez la clé Tavily donnée par votre formateur après `TAVILY_API_KEY=`. Puis arrêtez la page (Ctrl+C dans son terminal) et relancez-la pour qu'elle lise la clé.

Les lignes grises `[harness]` et les encadrés « Résultat de l'outil » montrent ce que fait le programme autour du modèle (le harnais, *harness* en anglais). La barre latérale montre ce qui est envoyé au modèle.

## Les fichiers de ce dossier

- `app.py` : l'agent. OpenCode le réécrit à chaque étape.
- `prompts.md` : le prompt de chaque étape.
- `AGENTS.md` : les règles qu'OpenCode lit avant chaque tâche.
- `system.md` : le prompt système de l'agent (à partir de l'étape 2).
- `concepts.md` : les notions clés de l'atelier.
- `docs/` : des fichiers d'exemple pour les outils de fichiers (étape 5).
- `streamlit_docs/` : de la documentation Streamlit pour OpenCode.
- `opencode.json` : les réglages d'OpenCode (modèles et fournisseurs).
- `pyproject.toml` : les paquets Python utilisés par l'agent.
- `setup/` : les scripts d'installation et de vérification.
- `.env` : la clé de recherche web (étape 6). Ne la partagez et ne la publiez jamais.

## En cas de problème

- La page est blanche ou affiche « connection refused » : le terminal qui faisait tourner la page a été fermé. Relancez la commande de démarrage.
- La page affiche une erreur à propos d'Ollama : lancez l'application Ollama.
- La recherche web dit que la clé n'est pas définie : vérifiez que `.env` contient `TAVILY_API_KEY`, puis arrêtez la page (Ctrl+C dans son terminal) et relancez-la.
- La réponse est lente : le modèle tourne sur votre ordinateur. Attendez quelques secondes.
- L'agent invente une réponse ou choisit le mauvais outil : les modèles sont petits et se trompent. Ouvrez les encadrés « Résultat de l'outil » pour voir ce qui s'est passé, ou essayez l'autre modèle dans la barre latérale.

## Option : GitHub Codespaces

Si vous préférez travailler dans votre navigateur, avec un compte GitHub et rien d'installé sur votre ordinateur :

[![Ouvrir dans GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/alexisperrier/construire_agent)

1. Cliquez sur le bouton, puis sur **Create codespace**. L'installation met en place Ollama, les deux modèles, uv et OpenCode, et lance la page de l'agent sur le port 8804. Si aucun onglet ne s'ouvre, allez dans l'onglet **PORTS**, trouvez le port 8804 (« Agent ») et cliquez sur l'icône du globe.
2. Glissez votre fichier `.env` dans la liste des fichiers, à côté de `app.py`, puis lancez `bash .devcontainer/start-app.sh` dans le terminal.
3. Lancez OpenCode dans le terminal :
   ```
   source .devcontainer/load-env.sh
   opencode
   ```
4. Quand vous avez terminé, arrêtez le codespace pour économiser vos heures gratuites : [github.com/codespaces](https://github.com/codespaces) → `...` → **Stop codespace**.

Les formateurs peuvent plutôt définir `OPENROUTER_API_KEY` et `TAVILY_API_KEY` comme secrets Codespaces (Settings → Secrets and variables → **Codespaces**). GitHub ne transmet ces secrets qu'aux personnes ayant un accès en écriture au dépôt : les participants doivent donc être collaborateurs.
