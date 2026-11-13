# Construire un agent local : les prompts pour OpenCode

Un prompt par étape, chacun ajoutant une capacité à `app.py` : une page web où vous parlez à un agent qui tourne sur un petit modèle local (llama3.2:3b) grâce à Ollama. OpenCode écrit le code ; l'agent lui-même tourne sur votre ordinateur, sauf la recherche web de l'étape 6.

Les prompts décrivent ce que l'agent doit faire, en français courant. Les détails techniques sont dans `AGENTS.md`, qu'OpenCode lit avant chaque tâche.

## Mise en place

1. Installez votre ordinateur et lancez la page de l'agent (voir le README). La page se recharge toute seule chaque fois que `app.py` est enregistré.
2. Collez un prompt par étape dans OpenCode, puis parlez à l'agent dans la page web.

Le modèle est petit et se trompe (un appel d'outil inutile, un mauvais argument, une source inventée). Ces erreurs valent la peine d'être montrées. Si votre formateur vous fait télécharger un second modèle (`ollama pull qwen2.5:3b`), demandez à OpenCode de l'ajouter au menu des modèles et comparez les deux.

### Clés d'API

Nous aurons besoin, à un moment, d'accéder à deux services par clé d'API :
- OpenRouter, pour accéder à des modèles plus puissants que les modèles locaux ;
- Tavily, un moteur de recherche.

Remplacez le fichier `.env` actuel, qui est vide, par celui que vous a donné le formateur.

Puis, dans OpenCode, demandez de vérifier que les deux clés d'API, OpenRouter et Tavily, sont définies et valides.

### Étape 0 : page statique

`app.py` commence par une page statique : un titre et un court message. Modifiez-la avec quelques prompts (le titre, le texte, les couleurs) pour voir la boucle : vous écrivez un prompt, OpenCode modifie `app.py`, la page se recharge.



------------------------

## Partie 1 : la mémoire

### Étape 1 : chat avec historique

Le modèle est une fonction : du texte en entrée, du texte en sortie. La mémoire pendant la session, c'est le harnais qui renvoie toute la conversation à chaque tour.

```markdown
Transforme app.py en page de chat :
je tape un message, l'agent répond, toute la conversation reste affichée sur la page.
Envoie toute la conversation au modèle à chaque fois, pour qu'il se souvienne de ce qui a été dit avant.
Affiche la réponse au fur et à mesure qu'elle s'écrit.
Dans la barre latérale, affiche :
- un menu pour choisir le modèle Ollama installé (seulement llama3.2:3b pour l'instant),
- combien de messages sont envoyés au modèle, et leur taille approximative en tokens.
```

Regardez comment le fichier app.py change.

**Démo** :

Votre premier prompt peut mettre un peu de temps avant que l'agent réponde.

Écrivez : « Je m'appelle Alexis. », puis demandez « Comment je m'appelle ? » : l'agent s'en souvient. À ce stade, l'information est gardée en vie dans la fenêtre de contexte de l'agent. Au fil de vos messages, regardez la taille de la fenêtre de contexte grandir dans la barre latérale.

Puis rechargez la page : l'agent ne connaît plus votre nom.

- Essayez de comprendre ce qu'est le modèle, ce qu'il sait, qui l'a créé, sa date limite de connaissances.
- Essayez d'évaluer son « intelligence » : « Combien de r y a-t-il dans le mot strawberry ? » ou « Je veux laver ma voiture. La station de lavage est à 50 m. Est-ce que j'y vais à pied ou en voiture ? »


### Étape 2 : prompt système

Une partie du rôle du harnais est de donner à l'agent un ensemble d'instructions, transmises par un prompt système.
Ici, le prompt système est un fichier markdown chargé avant chaque session.

Dans son état actuel, notre agent se comporte selon le prompt système par défaut du modèle.
Par exemple, voici le [prompt système d'OpenCode pour Llama](https://github.com/anomalyco/opencode/blob/dev/packages/core/src/plugin/system-prompt/meta.txt) (en anglais).

Vous pouvez écrire votre propre prompt système pour affiner celui par défaut.

Un petit prompt système est déjà disponible dans le fichier system.md pour que vous puissiez jouer avec.

Commençons par modifier l'agent pour qu'il lise le prompt système au début de chaque session.

```markdown
Utilise le texte de system.md comme prompt système : le modèle le reçoit en premier, avant la conversation, à chaque fois.
Ne l'affiche pas dans le chat.
Dans la barre latérale, affiche le contenu de system.md dans une zone de texte que l'utilisateur peut modifier, avec un bouton Enregistrer.
Enregistrer écrit le texte dans system.md.
Garde la conversation : le message suivant utilise le nouveau prompt système.
La zone de texte affiche toujours le contenu actuel de system.md, même si le fichier a été modifié en dehors de la page.
```

`system.md` est déjà dans le dossier : l'agent est Amandine, une éleveuse de poules en Normandie, fière de ses poules et obsédée par le prix des œufs.

**Pratique** : c'est en général amusant. Modifiez le prompt système pour faire incarner d'autres personnes à l'agent, ajoutez des traits de caractère, des détails de style, etc.
Observez comment l'agent répond. Respecte-t-il vos instructions ?


### Étape 2 bis

Le modèle Llama 3.2 est assez bavard.
Essayons un autre modèle : qwen2.5:3b.

Dans OpenCode, ouvrez un nouveau terminal et lancez :

```
ollama pull qwen2.5:3b
```

Si le modèle n'apparaît pas dans le menu des modèles de la barre latérale, écrivez simplement ```dans le menu des modèles de la barre latérale, ajoute qwen2.5:3b```

Puis sélectionnez le modèle `qwen2.5:3b` et discutez avec l'agent. Qu'observez-vous ?


### Étape 3 : mémoire persistante

La mémoire d'une session à l'autre est un fichier que le harnais lit et écrit, automatiquement.

```markdown
Donne à l'agent une mémoire qui dure après le rechargement de la page, enregistrée dans le fichier memory.md.
Après chaque réponse, ajoute l'échange à memory.md, mot pour mot : "Utilisateur : " suivi du message, puis "Agent : " suivi de la réponse, puis une ligne vide.
Ne résume pas.

Quand la page est ouverte ou rechargée, lis memory.md une fois et ajoute son contenu après le prompt système, sous "Conversations précédentes :".
Ne l'écris pas dans system.md.
Dans la barre latérale, affiche la taille de memory.md en tokens, à côté de la taille de la conversation.
```

**Test** : « Bonjour, je m'appelle Alexis, je suis fan de Star Trek et je préfère les réponses courtes. », rechargez la page, puis « Que sais-tu de moi ? ». Ouvrez memory.md : du texte brut que n'importe qui peut lire ou modifier. Discutez au fil de plusieurs rechargements et regardez la barre latérale : chaque échange passé est renvoyé avec chaque message, donc le contexte ne fait que grandir.

Vous pouvez inspecter le contenu du fichier memory.md et le voir grossir.

## Partie 2 : les outils

### Étape 4 : premier outil et boucle d'agent

Le modèle ne peut pas agir ; il peut seulement demander. Le harnais exécute la fonction et renvoie le résultat.

Nous commençons simplement, avec une fonction qui donne la date du jour.
Le prompt ci-dessous fait plusieurs choses :
- il décrit l'outil et le code qui va avec ;
- la fonction a ce qu'on appelle une docstring, c'est-à-dire une description de la fonction. C'est cette docstring que l'agent utilise pour décider quand appeler l'outil ;
- la décision d'appeler un outil repose sur la correspondance entre la demande de l'utilisateur et la description de la fonction. Elle n'est pas déterministe. Parfois l'agent décide à tort de ne pas appeler l'outil, alors que ce serait évident pour un humain ;
- le prompt modifie aussi l'interface avec un indicateur « Réflexion… » et un affichage des appels d'outils, pour savoir si l'outil a vraiment été appelé ou non ;
- enfin, il faut informer l'agent de la présence d'outils : on l'ajoute donc au prompt système.


```markdown
Donne à l'agent son premier outil : une fonction qui renvoie la date du jour et l'heure actuelle.
Sa description, que le modèle lit, dit : "Donne la date du jour et l'heure actuelle. À utiliser seulement quand l'utilisateur demande la date ou l'heure."
Quand le modèle demande un outil, exécute-le, renvoie le résultat au modèle et laisse-le continuer.
Recommence jusqu'à ce qu'il réponde en texte simple, 5 fois au maximum ; au-delà, affiche "Je n'ai pas pu terminer cette tâche."
Affiche un message "Réflexion..." pendant ce temps (la réponse ne s'affiche plus au fur et à mesure qu'elle s'écrit).
Affiche chaque appel d'outil et son résultat dans le chat, et liste les outils dans la barre latérale.
N'enregistre dans memory.md que le message de l'utilisateur et la réponse finale, pas les appels d'outils.
Ajoute à system.md : "Tu as des outils, mais la plupart des questions n'en ont pas besoin. Si aucun outil ne correspond clairement à la question, réponds directement avec tes propres connaissances, sans appeler d'outil. Quand un outil renvoie un résultat, fais-lui confiance et utilise-le dans ta réponse."
```

**Démo** : avant cette étape, demandez « Quelle est la date d'aujourd'hui ? ». L'agent devine ou refuse de répondre.
Après le prompt, redemandez et ouvrez le résultat de l'outil.
Changez de modèle et reformulez la question pour qu'elle soit moins directe. Par exemple : « Combien de jours avant Noël ? ».

N'oubliez pas de vider la mémoire entre les sessions (écrivez simplement : ```ajoute dans la barre latérale un bouton pour vider la mémoire, qui efface le contenu de memory.md```).

Divulgâcheur : vous verrez peut-être qu'un modèle peine à répondre alors que l'autre y arrive.



### Étape 5 : fichiers locaux

Ensuite, donnons à l'agent de nouveaux outils pour lister, lire et modifier les fichiers du dossier `./docs`.
Nous voulons aussi nous assurer que les outils sont vraiment appelés.

`docs/` contient déjà deux fichiers d'exemple.


```markdown
Ajoute trois outils pour travailler avec les fichiers texte du dossier docs/, et seulement dans ce dossier. Pour tout chemin en dehors, réponds "Refusé : seuls les fichiers de docs/ sont autorisés."
- lister les fichiers ;
- lire un fichier ; sa description dit au modèle de lister d'abord les fichiers s'il ne connaît pas le nom. Si le fichier n'existe pas, réponds "Aucun fichier nommé ... Fichiers disponibles : ..." ;
- écrire un fichier (le créer ou le remplacer), seulement si un interrupteur "Autoriser l'écriture de fichiers" est activé dans la barre latérale ; sinon réponds "Non enregistré : l'écriture de fichiers est désactivée. Demande à l'utilisateur d'activer 'Autoriser l'écriture de fichiers' dans la barre latérale, puis réessaie."
Affiche les fichiers de docs/ dans la barre latérale, mis à jour après chaque réponse.

Quand l'agent appelle un outil, affiche au-dessus de la zone de saisie quel outil est appelé, ainsi que le résultat de l'outil,
dans une police à chasse fixe grisée pour que ça se distingue.
```


**Démo** :
- Demandez d'abord à l'agent de lister les fichiers avec « Quels fichiers ai-je ? » ou « À quels fichiers ai-je accès ? ».
- Puis faites-lui lire les fichiers. Vous pouvez par exemple demander : « Le communiqué de presse et les notes d'entretien sont-ils d'accord sur le budget ? »
- Enfin, faites-lui écrire un nouveau fichier avec ses conclusions. Vérifiez que l'interrupteur d'écriture fonctionne.
Demandez à l'agent : « Enregistre un résumé de la contradiction en deux lignes dans resume.md », avec l'interrupteur désactivé, puis activé.
- Vérifiez que le fichier resume.md a bien été créé et regardez son contenu.

### Étape 6 : recherche web

Les connaissances du modèle s'arrêtent à sa date d'entraînement ; la recherche web apporte des sources à jour.

Il faut d'abord vérifier que la clé TAVILY_API_KEY est définie et valide.
Dans OpenCode, demandez simplement : « Peux-tu charger les clés de .env ? Sont-elles valides et actives ? »

OpenCode va lire le fichier `.env` et vérifier que les clés sont valides en faisant une recherche de test et en vérifiant la clé OpenRouter.


Plutôt que de copier-coller le prompt ci-dessous, essayez d'écrire votre propre prompt pour créer cet outil.
Le prompt doit préciser :
- ce que fait l'outil, combien de résultats il a le droit de récupérer ;
- quoi faire quand la clé TAVILY_API_KEY manque ;
- essayez de rendre la recherche web consciente de la date, pour qu'elle ne récupère que des résultats récents.

Comme d'habitude, il est utile de savoir ce que fait l'agent : ici, pouvoir voir quels sites, quelles URL il a lus.

Un prompt possible pour créer l'outil de recherche web :

```markdown
Ajoute un outil de recherche web qui utilise Tavily. La clé est TAVILY_API_KEY dans .env ; si elle manque, l'outil répond "La recherche web est indisponible : TAVILY_API_KEY n'est pas définie."
Tu dois utiliser python-dotenv pour charger les clés.
L'outil renvoie la réponse courte de Tavily, puis 5 résultats, chacun avec son titre, sa date, son adresse web et le début du texte.
Ajoute la date du jour au prompt système.
Ajoute à system.md : "Quand tu utilises la recherche web, base ta réponse uniquement sur les résultats de la recherche et cite leurs URL. Si les résultats ne répondent pas à la question, dis-le."
Assure-toi que les clés du fichier .env sont chargées à chaque nouvelle session.
```

**Démo** : posez une question sur un événement de cette semaine, puis consultez le résultat de l'outil et comparez-le avec la réponse.
Si vous parlez toujours à Amandine, l'éleveuse normande, vous pouvez par exemple demander : « Quel est le prix actuel des œufs en France ? ».

Si vous obtenez le message d'erreur « La recherche web est indisponible : TAVILY_API_KEY n'est pas définie. » alors que la clé est bien dans le fichier `.env`, collez simplement le message d'erreur dans OpenCode et demandez-lui de corriger le bug.
La cause la plus fréquente est qu'il faut redémarrer l'application. OpenCode devrait pouvoir le faire tout seul. Si ça ne marche pas, allez dans l'onglet de terminal qui vous a servi à lancer l'application la première fois, tapez `Ctrl+C` et relancez l'application avec `uv run --env-file .env streamlit run app.py --server.port 8804`


### Étape 7 : la mémoire comme outil

Garder et recharger toutes les sessions précédentes va vite épuiser la fenêtre de contexte. Mieux vaut résumer les informations importantes à chaque tour que tout enregistrer aveuglément.

Ajoutons un outil `remember` (« se souvenir »), qui écrit seulement les faits importants sur l'utilisateur. Laissons l'agent décider quand et quoi enregistrer.
Pensez à vider la mémoire actuelle avant de commencer une nouvelle conversation.

```markdown
Remplace l'enregistrement automatique de la conversation par un outil "remember".
Supprime le code qui enregistre chaque échange dans memory.md.
Le modèle l'appelle avec une courte phrase, dans ses propres mots, qui résume un fait durable sur l'utilisateur.
Jamais le message de l'utilisateur recopié tel quel. Dis-le dans la description de l'outil, puisque le modèle la lit.
L'outil ajoute cette phrase comme une ligne de memory.md, sauf si la même ligne y est déjà, et répond "Enregistré : " suivi de la phrase.
Continue à charger memory.md quand la page est ouverte ou rechargée, désormais sous "Ce que tu sais de l'utilisateur :". Affiche ses lignes dans la barre latérale.
Ajoute à system.md : "Quand l'utilisateur partage un fait durable sur lui-même (nom, métier, préférences, projets), appelle remember avec un résumé de ce fait en une phrase. N'enregistre pas les questions, les salutations ni la conversation elle-même."
```

**Démo** : supprimez d'abord memory.md.
- Puis « Bonjour, je m'appelle Alexis et je suis fan de Star Trek. » et regardez l'appel d'outil.
- Rechargez, puis « Propose-moi un dîner pour ce soir. »

À discuter : qu'est-ce qu'un agent devrait avoir le droit de retenir, et qui le vérifie ?

## Partie 3 : les extensions standard

### Étape 8 : MCP

Au lieu d'écrire chaque outil, on branche un serveur qui propose des outils tout faits via un protocole standard.

Par exemple, Tavily propose un serveur MCP qui décrit tous ses outils et fonctions.

Le serveur MCP de Tavily donne à votre agent ces outils
(voir https://docs.tavily.com/documentation/mcp#other-clients) :

| Outil | Ce qu'il fait |
| :--- | :--- |
| tavily_search | Cherche sur le web des sources récentes et pertinentes. |
| tavily_extract | Extrait le contenu propre d'une ou plusieurs URL. |
| tavily_crawl | Lit de nombreuses pages d'un site. |
| tavily_map | Découvre la structure d'un site. |

Ici, nous allons utiliser le [serveur MCP fetch en Python](https://github.com/modelcontextprotocol/servers/blob/main/src/fetch/README.md), qui fournit automatiquement des outils pour récupérer des pages du web.

```markdown
Connecte l'agent au serveur MCP "fetch", qui propose un outil tout fait pour lire des pages web. Le serveur se lance avec `uvx mcp-server-fetch`.
Ajoute ses outils aux outils de l'agent, et affiche-les dans la barre latérale.
Ne lance le serveur qu'une seule fois. Affiche "Démarrage du serveur fetch..." pendant qu'il démarre : la première fois, il est téléchargé.
Si le serveur ne peut pas démarrer, garde l'agent fonctionnel sans lui et affiche un avertissement dans la barre latérale.
Coupe chaque page renvoyée par l'outil à 3 000 caractères avant de l'envoyer au modèle.
```

**Démo** :
Aucun code de fetch n'a été écrit dans app.py : le même serveur fonctionne dans Claude, OpenCode ou Cursor.

Demandez à l'agent :

```
Lis le début de la page Wikipédia sur la poule (https://fr.wikipedia.org/wiki/Poule) et résume-la en quelques phrases.
```

**Serveurs MCP**
Il existe déjà énormément de serveurs MCP.

Par exemple :

- Excalidraw : dessine des schémas sur un tableau blanc à mesure que vous les décrivez.
- [Spotify](https://github.com/marcelmarais/spotify-mcp-server) : cherche de la musique et crée des playlists.
- Playwright (Microsoft) : ouvre un navigateur, clique et remplit des formulaires sous les yeux des participants. Comparez-le avec fetch, qui ne lit que le texte.
- arXiv et Semantic Scholar : trouvent des articles scientifiques.
- Obsidian ou Notion : lisent et écrivent leurs notes.
- Google Maps ou OpenStreetMap : trouvent des lieux et des itinéraires.

Consultez par exemple ces sources : https://mcp.so/blog/best-mcp-servers, https://mcp.directory/servers/leaderboard?sort=views, https://github.com/tolkonepiu/best-of-mcp-servers, ...

En bref, les serveurs MCP sont un moyen rapide d'ajouter des outils à un agent.

### Étape 9 : skills

Une skill (compétence) est un ensemble d'instructions écrites en langage courant, enregistrées dans un fichier. L'agent ne la garde pas en permanence : il ne la charge que sur demande, pour ne pas remplir la fenêtre de contexte. Ici, l'utilisateur appelle une skill en tapant `/` suivi de son nom, comme les commandes slash d'OpenCode. Pas besoin de code pour écrire une skill : c'est un fichier texte.

La skill est déjà écrite et disponible à l'adresse https://gist.githubusercontent.com/alexisperrier/4d16cee4ad05c212b052e473cc62cbaf/raw/SKILL.md

```markdown
Ajoute les skills. Une skill est un dossier dans skills/ avec un fichier SKILL.md qui commence par un en-tête entre deux lignes --- donnant son nom (name) et une description d'une ligne (description).
Télécharge https://gist.githubusercontent.com/alexisperrier/4d16cee4ad05c212b052e473cc62cbaf/raw/SKILL.md et enregistre-le, sans le modifier, sous skills/grand-siecle/SKILL.md.
Dans la barre latérale, liste les skills avec leurs descriptions.
Quand le message de l'utilisateur commence par / suivi d'un nom de skill, charge le SKILL.md de cette skill et ajoute-le à la conversation, pour que le modèle continue à la suivre dans les messages suivants. Affiche une ligne [harness] qui dit quelle skill a été chargée. Puis envoie le reste du message au modèle, comme d'habitude.
Si aucune skill ne porte ce nom, réponds "Aucune skill nommée ... Skills disponibles : ..." sans appeler le modèle.
```

**Démo** :

1. Posez une question normale : `Quel est le prix des œufs ?` Amandine répond comme d'habitude.
2. Appelez la skill : `/grand-siecle Quel est le prix des œufs ?` La ligne [harness] montre que la skill a été chargée, et Amandine répond comme chez Molière. Regardez la taille du contexte bondir dans la barre latérale : toute la skill a été ajoutée.
3. Changez de langue sans rappeler la skill : `And how fare thy hens?` (Shakespeare), puis `¿Cuántos huevos ponen vuestras gallinas?` (Cervantès). La skill reste dans la conversation.
4. `Parle normalement maintenant.` La skill dit au modèle d'arrêter quand on le lui demande.
5. Essayez une skill qui n'existe pas : `/haiku Parle-moi des œufs.` Le harnais répond tout seul, sans le modèle.
6. Ouvrez `skills/grand-siecle/SKILL.md` dans OpenCode : c'est du texte brut. Demandez à OpenCode de créer une seconde skill à partir d'une description en français courant (un haïku, un cartel de musée, une lettre officielle), puis appelez-la avec `/`.

Les petits modèles imitent le vocabulaire plus que le rythme, et peuvent retomber dans un style normal après quelques messages. Rappeler la skill fait revenir le style.

Pour conclure, si un second modèle est disponible : passez dessus et reposez quelques questions précédentes (la date, les fichiers, la skill du XVIIe siècle). Même harnais, modèle différent, résultats différents. OpenCode, qui a écrit tout cela, est le même genre de harnais autour d'un modèle bien plus gros.
