# Règles du projet : construire un agent IA local, étape par étape

Contexte
- Un atelier : les participants construisent un agent IA local une fonctionnalité à la fois, un prompt par étape (voir `prompts.md`).
- Les participants viennent des sciences humaines et n'ont jamais programmé.
- L'atelier est en français : tout le texte visible dans la page (titres, boutons, messages, encadrés), les descriptions des outils et les commentaires du code sont en français.

Code
- L'agent est une page web Streamlit dans un seul fichier, `app.py`, sur le port 8804. Elle se recharge toute seule quand `app.py` est enregistré.
- Les participants lancent la page eux-mêmes. Ne la lancez pas et ne l'ouvrez pas. Si vous devez la lancer, vérifiez d'abord que rien ne tourne déjà sur le port 8804.
- Pour vérifier votre travail, lancez `uv run python -m py_compile app.py`.
- Gardez un code court et simple : des fonctions courtes, pas de classes, pas de tests. C'est du code de démonstration, pas du code de production.
- Un commentaire en français simple par bloc, qui explique ce qu'il fait et pourquoi.
- Chaque étape ajoute exactement une fonctionnalité. Les fonctionnalités précédentes doivent continuer à marcher. Ne refactorisez pas et n'ajoutez pas de gestion d'erreurs au-delà de ce que l'étape demande.
- N'utilisez que les dépendances de `pyproject.toml` (ollama, streamlit, tavily-python, mcp, python-dotenv). N'en ajoutez pas d'autres.
- Les clés d'API sont dans `.env`. Chargez-les avec `load_dotenv()` (python-dotenv) en haut de `app.py`, puis lisez-les dans les variables d'environnement.

Modèles
- Le modèle de l'agent tourne en local avec Ollama, via la bibliothèque Python `ollama`.
- Un menu déroulant (selectbox) dans la barre latérale le choisit, et le stocke dans `MODEL`. Pour l'instant il n'a qu'une option, "llama3.2:3b".

Streamlit
- Pour le code Streamlit, suivez `streamlit_docs/chat-ui.md` et `streamlit_docs/session-state.md`.
- À partir de l'étape 1, l'agent garde toute la conversation pendant la session et l'affiche.

Harnais (harness)
- Rendez le harnais visible :
    - chaque appel d'outil sous forme de légende grise (caption) commençant par `[harness]` ;
    - chaque résultat d'outil dans un encadré repliable ;
    - dans la barre latérale : combien de messages sont envoyés au modèle et leur taille approximative en tokens (caractères / 4), les outils, le prompt système et la mémoire.
- Les outils sont de simples fonctions Python avec des annotations de type et une docstring en français (le modèle lit la docstring). Les erreurs des outils sont renvoyées au modèle sous forme de texte, jamais levées comme exceptions.

Notes d'implémentation (les prompts des participants sont en français courant : voici les détails techniques qui sont derrière)
- Chat : diffusez la réponse en continu avec `ollama.chat(stream=True)`. Gardez la conversation dans `st.session_state.messages` et enregistrez le texte complet diffusé comme réponse.
- Outils : passez les fonctions Python à `ollama.chat(tools=...)`. Boucle d'agent : tant que la réponse contient des appels d'outils, exécutez chacun d'eux, ajoutez le résultat comme message "tool", et rappelez le modèle. La boucle n'est pas diffusée en continu. Enregistrez les messages du modèle avec `message.model_dump(exclude_none=True)`. Avant d'appeler un outil, retirez tout argument que la fonction n'accepte pas.
- Recherche web : `tavily-python`, `search(query, max_results=5, include_answer=True)`, clé dans `TAVILY_API_KEY`. Renvoyez d'abord la réponse, puis pour chaque résultat son titre, sa date de publication, son URL et ses 500 premiers caractères.
- MCP : le SDK Python officiel `mcp`, version 2 ou plus (les schémas des outils sont dans `tool.input_schema`). Démarrez le serveur en stdio dans une seule fonction async qui, soit liste ses outils, soit en appelle un, lancée avec `asyncio.run`. Listez les outils une seule fois (`st.cache_resource`) et convertissez-les en définitions d'outils Ollama. Avant d'appeler un outil MCP, retirez les arguments dont la valeur est None.
- Skills : chaque skill est `skills/<nom>/SKILL.md`, qui commence par un en-tête entre deux lignes `---` donnant `name` et `description`. L'utilisateur appelle une skill en commençant son message par `/<nom>` : le harnais (pas le modèle) charge ce `SKILL.md`, l'ajoute à la conversation comme message système pour qu'il reste en vigueur, affiche une ligne `[harness]`, puis envoie le reste du message au modèle. Un nom inconnu reçoit « Aucune skill nommée ... Skills disponibles : ... » sans appeler le modèle.
