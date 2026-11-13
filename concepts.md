# Notions clés : ce que nous avons utilisé, et pourquoi

Un petit guide des idées derrière l'atelier. Il explique pourquoi chaque élément existe et quand on s'en sert, pas comment taper les commandes.

## 1. Modèle, harnais, agent

- **Le modèle** (on parle aussi de grand modèle de langage, ou LLM) est un programme qui reçoit du texte et produit du texte. Il ne fait rien d'autre : il ne peut ni se souvenir, ni naviguer sur le web, ni lire des fichiers, ni agir.
- **Le harnais** (*harness* en anglais) est le code ordinaire autour du modèle. Il décide quel texte envoyer, garde l'historique, exécute les outils et affiche les résultats. Dans l'atelier, le harnais, c'est `app.py`.
- **Un agent** est un modèle plus un harnais qui lui permet d'agir en boucle : le modèle demande une action, le harnais l'exécute, renvoie le résultat, et le modèle continue jusqu'à pouvoir répondre.

Presque tout ce que vous avez vu dans l'atelier (mémoire, outils, fichiers, recherche, skills) relève du harnais, pas du modèle. ChatGPT, Claude ou Le Chat de Mistral sont un modèle plus un gros harnais.

## 2. Tokens, fenêtre de contexte et mémoire

- Les modèles lisent et écrivent des **tokens**, des morceaux de mots. En règle générale, 1 token ≈ 4 caractères en anglais (un peu moins en français).
- La **fenêtre de contexte** est tout ce qui est envoyé au modèle en un appel : instructions, conversation, fichiers, résultats de recherche. Elle a une taille maximale, et plus elle est grande, plus l'appel est lent et coûteux.
- Le modèle est **sans état** (*stateless*). Un chat « se souvient » seulement parce que le harnais renvoie toute la conversation à chaque fois (étape 1). Rechargez la page et tout est perdu.
- La **mémoire à long terme** est un fichier que le harnais lit et ajoute au contexte (étape 3). Tout enregistrer fait grossir le contexte très vite : les vrais assistants n'enregistrent que des faits choisis, sélectionnés par le modèle (étape 7).

## 3. Prompt système

Le prompt système est le texte que le harnais place avant la conversation : qui est le modèle, comment il doit répondre, ce qu'il ne doit pas faire (`system.md`, Amandine l'éleveuse de poules). L'utilisateur ne le voit jamais, mais il façonne chaque réponse.

Leçons de l'atelier :
- **Les exemples marchent mieux que les descriptions.** « Glisse des mots normands » change peu de chose ; une phrase d'exemple fonctionne.
- **Le même prompt donne des résultats différents selon le modèle.** Llama est plus bavard, Qwen plus sobre.
- **Le harnais peut ajouter du texte que vous n'avez pas écrit.** Le modèle de prompt (template) d'Ollama pour Llama dit au modèle de répondre par un appel d'outil dès que des outils sont disponibles, ce qui explique ses appels d'outils inutiles.

## 4. Les outils et la boucle d'agent

Un **outil** est une fonction que le harnais propose au modèle, décrite en quelques mots : « donne la date du jour », « lis un fichier », « cherche sur le web ». Le modèle ne peut pas l'exécuter. Il peut seulement écrire une demande dans un format convenu, et c'est le harnais qui décide s'il l'exécute et comment.

Ce qui peut mal tourner, et ce que nous avons vu :
- le modèle appelle le mauvais outil, ou un outil dont il n'a pas besoin ;
- il invente un argument, ou écrit sa demande en texte libre, si bien que rien ne s'exécute ;
- il ignore le résultat de l'outil et répond de mémoire (le mauvais acteur de Star Trek).

Le harnais est aussi l'endroit où se joue la **sécurité** : l'agent ne peut lire que les fichiers de `docs/`, et il ne peut écrire que si vous activez « Autoriser l'écriture de fichiers ». Un document lu par l'agent peut contenir des instructions (injection de prompt) : les permissions comptent donc plus que les bonnes intentions.

## 5. MCP (Model Context Protocol)

MCP est une façon standard de brancher des outils sur n'importe quel agent, un peu comme l'USB pour les outils d'IA. Au lieu d'écrire une fonction « récupérer une page web », l'étape 8 branche un **serveur MCP** existant qui la propose. Le même serveur fonctionne avec Claude, ChatGPT, OpenCode ou Cursor. Les entreprises publient désormais des serveurs MCP pour leurs produits (agendas, bases de données, CRM), si bien qu'un seul agent peut utiliser de nombreux services sans code sur mesure pour chacun.

## 6. Skills

Une **skill** (compétence) est une procédure écrite en langage courant, enregistrée dans un fichier (`skills/grand-siecle/SKILL.md`). Le prompt système ne liste que les noms des skills et leur description d'une ligne. Quand une tâche correspond, l'agent charge les instructions complètes.

Pourquoi : on ne peut pas mettre toutes les procédures dans le prompt système, il remplirait la fenêtre de contexte. Les skills permettent à des non-programmeurs d'enseigner une méthode à un agent (« comment nous vérifions les faits », « comment nous rédigeons une revue de presse ») en écrivant un fichier texte, pas du code.

## 7. Modèles locaux et modèles dans le cloud

| | Local (Ollama) | Cloud (OpenRouter, ChatGPT, Claude…) |
|---|---|---|
| Où il tourne | votre ordinateur, ou votre codespace | les serveurs du fournisseur |
| Données | restent chez vous | envoyées au fournisseur |
| Coût | gratuit une fois téléchargé | payé au token |
| Qualité | petits modèles (3 milliards de paramètres), beaucoup d'erreurs | grands modèles, bien plus fiables |

**Ollama** est un programme gratuit qui télécharge des modèles ouverts et les fait tourner sur votre machine. Nous en avons utilisé deux : Qwen 2.5 (Alibaba) et Llama 3.2 (Meta). Les **modèles ouverts** ont des poids téléchargeables ; n'importe qui peut les faire tourner. **OpenRouter** est un compte unique qui donne accès à de nombreux modèles cloud de différents laboratoires.

Dans l'atelier, l'agent que vous avez construit tourne sur un modèle local, tandis qu'**OpenCode**, qui écrit le code, utilise un grand modèle dans le cloud. Ce contraste est tout l'intérêt : le même genre de harnais, avec un modèle environ cent fois plus gros.

## 8. OpenCode et AGENTS.md

**OpenCode** est un agent de programmation : un agent dont les outils lisent et modifient des fichiers et lancent des commandes. Vous décrivez ce que vous voulez en langage courant, et il écrit le code. Claude Code, Codex et Cursor sont des outils similaires.

**`AGENTS.md`** est un fichier d'instructions permanentes pour les agents de programmation qui travaillent sur un projet : à qui s'adresse le code, quel style suivre, à quoi ne pas toucher. C'est le prompt système de l'agent de programmation, écrit par le responsable du projet. De nombreux agents de programmation lisent automatiquement un fichier de ce type.

## 9. GitHub en cinq minutes

- **Git** garde tout l'historique d'un dossier de fichiers. **GitHub** est un site web qui héberge ces dossiers en ligne pour que l'on puisse les partager et y travailler à plusieurs.
- Un **dépôt** (*repository*, ou *repo*) est un dossier de projet avec son historique (ici, `construire_agent`).
- Un **commit** est un instantané enregistré avec un court message (« ajoute la recherche web »). On peut revenir à n'importe quel commit.
- **Push** envoie vos commits sur GitHub. **Pull** récupère les commits des autres. **Clone** télécharge un dépôt entier pour la première fois.
- Une **branche** est une version parallèle pour essayer des choses sans toucher à la version principale (`main`). Le formateur a testé l'atelier sur une branche `workshop`, puis a ramené les bonnes modifications sur `main`.
- **Codespaces** est un ordinateur dans le cloud que GitHub crée à partir d'un dépôt, avec tout ce qu'il faut d'installé. Chaque participant reçoit sa propre copie. Les modifications faites dedans y restent, et les modifications ultérieures du dépôt ne l'atteignent pas tant qu'on ne les récupère pas (pull).

## 10. Clés, .env et .gitignore

- Une **clé d'API** est un mot de passe qui permet à un programme d'utiliser un service payant (OpenRouter, Tavily). Quiconque la possède peut dépenser votre argent.
- **`.env`** est un petit fichier qui contient ces clés sur votre machine. Les programmes le lisent ; il n'est jamais partagé publiquement.
- **`.gitignore`** liste les fichiers que git ne doit jamais enregistrer ni publier : `.env` (secrets), `memory.md` (données personnelles) et les gros dossiers générés.
- Si une clé se retrouve sur GitHub, des robots la trouvent en quelques minutes. C'est pourquoi les clés vont dans `.env`, et `.env` va dans `.gitignore`.

## À retenir

1. Un modèle ne fait que produire du texte. Tout ce qu'un agent « fait », c'est le harnais autour de lui qui le fait.
2. La fenêtre de contexte est la mémoire de travail de l'agent : tout doit y tenir, et tout ce qui s'y trouve coûte du temps et de l'argent.
3. La plupart des erreurs d'un agent viennent des choix du modèle (mauvais outil, faits inventés) ou de ce que le harnais lui donne (résultats tronqués, messages trompeurs). Lisez la trace avant de faire confiance à la réponse.
4. Les outils, MCP et les skills sont autant de façons de donner plus de capacités au modèle. Les permissions décident de celles qu'il peut réellement utiliser.
