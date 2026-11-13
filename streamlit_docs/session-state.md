# Utiliser l'état de session de Streamlit

Streamlit réexécute le script de haut en bas à chaque interaction. Sans état de session, les variables sont remises à zéro à chaque fois. Utilisez `st.session_state` pour conserver des valeurs d'une exécution à l'autre.

## Usage de base

L'état de session est un objet de type dictionnaire, accessible par attribut ou par crochets :

```python
# Initialiser avec setdefault (méthode préférée)
st.session_state.setdefault("count", 0)

# Autre solution : vérifier avant d'affecter
if "count" not in st.session_state:
    st.session_state.count = 0

# Lire
current = st.session_state.count

# Modifier
st.session_state.count += 1
st.session_state["count"] = 5  # La notation entre crochets marche aussi

# Supprimer
del st.session_state.count
```

**Accéder à une clé non initialisée lève une erreur :** `KeyError` pour `st.session_state["key"]` et `AttributeError` pour `st.session_state.key`. Utilisez `st.session_state.get("key", default)` pour un accès sans risque.

## Lien entre widgets et état

Tout widget qui a un paramètre `key` se synchronise automatiquement avec l'état de session :

```python
name = st.text_input("Nom", key="user_name")
# st.session_state.user_name contient la même valeur que `name`
```

## Synchroniser un widget avec l'URL (liens partageables)

Pour rendre la valeur d'un widget partageable par l'URL de la page, passez `bind="query-params"` avec `key=`. Streamlit écrit la valeur dans les paramètres de l'URL quand elle change et la restaure depuis l'URL au chargement et lors des retours arrière/avant du navigateur : **ne bricolez pas `st.query_params` à la main** pour cela. Le `key=` devient le nom du paramètre d'URL.

```python
# BIEN : un widget, synchronisation automatique avec l'URL. Choisir "Newest" -> ?sort=Newest ;
# charger ?sort=Price rouvre la page avec "Price" sélectionné.
sort = st.selectbox(
    "Ordre de tri",
    ["Relevance", "Newest", "Price"],
    key="sort",  # OBLIGATOIRE avec bind= ; devient le nom du paramètre d'URL (?sort=...)
    bind="query-params",  # chaîne exacte, avec un tiret
)
st.write(f"Tri par : {sort}")
```

```python
# MAL : plomberie faite main. Plus de code, une réexécution en plus à surveiller, conflit
# avec bind= (un paramètre lié ne peut pas être modifié/supprimé via st.query_params), et plantage
# sur une valeur d'URL inattendue : .index(default) lève ValueError si un
# utilisateur ouvre ?sort=Foo. Avec bind="query-params", une valeur d'URL inconnue
# revient simplement à la valeur par défaut au lieu de lever une erreur.
default = st.query_params.get("sort", "Relevance")
sort = st.selectbox(
    "Ordre de tri",
    ["Relevance", "Newest", "Price"],
    index=["Relevance", "Newest", "Price"].index(default),
)
st.query_params["sort"] = sort  # à ne pas faire quand bind= gère la synchronisation
```

Remarques :
- `bind="query-params"` exige `key=`. La seule valeur valide est la chaîne exacte `"query-params"` (avec un tiret, pas `"query_params"`) ; toute autre valeur est invalide. Non pris en charge avec `st.text_input(type="password")`.
- Les boutons retour/avant du navigateur restaurent la valeur liée depuis l'URL (ou la valeur par défaut du widget si le paramètre manque). Cette restauration ne déclenche pas `on_change`. Un paramètre absent lors d'une navigation dans l'historique écrase aussi une valeur affectée dans `st.session_state` avant l'appel du widget ; le chargement initial laisse cette affectation en place.
- Quand la valeur est égale à la valeur par défaut, le paramètre est retiré de l'URL pour la garder propre.
- Un paramètre lié ne peut pas être modifié ni supprimé via `st.query_params` : changez-le par le code en affectant `st.session_state[key]` *avant* l'affichage du widget, ou depuis un callback `on_change`. Affecter après que le widget a déjà été affiché dans la même exécution lève `StreamlitWidgetAlreadyInstantiatedError` (voir [Modifier l'état après la création d'un widget](#modifier-létat-après-la-création-dun-widget)). Ne mélangez pas `bind=` avec des lectures/écritures manuelles de `st.query_params`.
- Affichez quand même la valeur (par exemple `st.write(f"Tri par : {sort}")`) si l'application doit montrer la sélection actuelle.
- Fonctionne sur les widgets de saisie en général. Ce n'est **pas** pris en charge sur les widgets déclencheurs ou boutons (`st.button`, `st.download_button`, `st.form_submit_button`, `st.menu_button`), les saisies de fichiers et de médias (`st.file_uploader`, `st.camera_input`, `st.audio_input`), `st.chat_input`, `st.feedback` ni `st.data_editor`, ni sur les sélections de `st.dataframe` ou des graphiques ; considérez que tout autre widget de saisie le prend en charge. (Lister les exceptions plutôt que chaque widget pris en charge évite que cette liste ne vieillisse à chaque nouveau widget.)
- Applications multipages : les paramètres d'URL appartiennent à l'URL de l'application, pas à une page en particulier ; une valeur liée persiste donc dans l'URL lors des changements de page via `st.navigation` et est partagée dans toute l'application. Si deux pages lient des widgets à la même `key=`, ils partagent cette valeur : utilisez des clés distinctes par page si vous ne voulez pas qu'elle se transmette.
- Pour garder une valeur d'une exécution ou d'une page à l'autre *sans* l'exposer dans l'URL, utilisez plutôt `persist_state` (voir [Conserver les valeurs des widgets](#conserver-les-valeurs-des-widgets-persist_state)) ; quand les deux sont définis, `bind` l'emporte.

## Les contraintes de saisie des widgets sont surtout côté navigateur

La plupart des contraintes de saisie des widgets (listes d'options autorisées `options` de `st.selectbox`, `st.multiselect`, `st.radio`, `min_value`/`max_value` de `st.slider`, `st.number_input`, `max_chars` / `validate` de `st.text_input`, `required` de `st.text_input`, `st.number_input`, `disabled`, et les colonnes `validate`/`num_rows` de `st.data_editor`) sont avant tout appliquées dans le navigateur, pour le confort d'utilisation. Voyez-les comme des garde-fous pour les utilisateurs normaux, **pas** comme une barrière de sécurité : la valeur renvoyée par un widget (et son entrée dans `st.session_state`) reflète ce que le client a envoyé, et un client modifié ou malveillant peut envoyer des valeurs hors de ces contraintes.

Pour toute décision sensible ou liée à la sécurité (contrôle d'autorisation ou de rôle, écritures en base de données, chemins de fichiers, plafonds de dépense ou de quota, ou tout ce qui ne doit pas dépasser une limite déclarée), revalidez la valeur dans votre propre script avant d'agir :

```python
ALLOWED_ROLES = ["viewer", "editor"]
role = st.selectbox("Rôle", ALLOWED_ROLES, key="role")

# Ne comptez pas sur les options du widget comme contrôle de sécurité.
if role not in ALLOWED_ROLES:
    st.error("Rôle invalide.")
    st.stop()
grant_access(role)
```

## Conserver les valeurs des widgets (`persist_state`)

Par défaut, la valeur d'un widget avec clé est perdue quand le widget n'est plus affiché (par exemple quand il est caché sous condition ou que l'utilisateur change de page). Définissez le paramètre nommé `persist_state` pour garder la valeur :

- `None` (par défaut) : la valeur est abandonnée quand le widget n'est pas affiché.
- `"page"` : la valeur est conservée tant que l'utilisateur reste sur la page où le widget est défini (par exemple quand il est caché sous condition) ; elle est abandonnée lors d'un changement de page.
- `"session"` : la valeur est conservée pendant toute la session, y compris lors des changements de page, et revient quand l'utilisateur retourne sur la page.

```python
st.text_input("Nom", key="name", persist_state="session")
```

`persist_state` exige une `key` et est disponible sur la plupart des widgets qui prennent en charge `bind="query-params"` (pas encore sur `st.tabs`). Quand les deux sont définis, `bind` l'emporte : la valeur vit dans l'URL et persiste lors des changements de page, quelle que soit la portée de `persist_state`.

## Callbacks

Les callbacks s'exécutent **avant** la réexécution du script, ce qui permet de modifier l'état immédiatement. Utilisez `on_change` ou `on_click`, avec `args` et `kwargs` en option :

```python
def increment(amount):
    st.session_state.count += amount


st.button("Ajouter 5", on_click=increment, args=(5,))
```

Dans son propre callback, accédez à la valeur d'un widget via `st.session_state.key`, pas via la variable renvoyée.

Appeler `st.rerun()` ou `st.switch_page()` dans un callback termine immédiatement ce callback (les instructions suivantes ne s'exécutent pas). Streamlit exécute quand même les autres callbacks de l'interaction avant de réexécuter le script ou de changer de page.

Sur certains widgets, `on_change` peut aussi valoir `"ignore"` ou `"rerun"` au lieu d'un callback. `"ignore"` met à jour le widget sans réexécution ; voir [Éviter les réexécutions sur certains widgets](performance.md#skip-reruns-on-individual-widgets-advanced).

## Modèles d'initialisation

Initialisez tout l'état en haut de l'application, pour plus de clarté :

```python
st.session_state.setdefault("user", None)
st.session_state.setdefault("page", "home")
st.session_state.setdefault("filters", {})
```

## État dans une application multipage

Par défaut, les widgets NE gardent PAS leur état d'une page à l'autre : leurs valeurs sont remises à zéro lors de la navigation. Pour garder la valeur d'un widget lors des changements de page, définissez `persist_state="session"` (voir [Conserver les valeurs des widgets](#conserver-les-valeurs-des-widgets-persist_state) plus haut).

### Partager l'état

Utilisez des variables d'état de session (pas des clés de widgets) pour partager des données :

```python
# Page 1 : enregistrer la valeur
st.session_state.selected_user = st.selectbox("Utilisateur", users)

# Page 2 : lire la valeur enregistrée
if "selected_user" in st.session_state:
    st.write(f"Sélectionné : {st.session_state.selected_user}")
```

### Widgets partagés

Placez les widgets communs dans le fichier d'entrée (avant `nav.run()`) :

```python
# app.py (fichier d'entrée)
with st.sidebar:
    st.session_state.theme = st.selectbox("Thème", ["Clair", "Sombre"])

nav = st.navigation(pages)
nav.run()
```

## Erreurs fréquentes

### État modifiable au niveau d'un module

```python
# MAL : dans un module importé, ceci est partagé entre TOUS les utilisateurs
# utils.py
cache = {}  # Persiste entre les exécutions ET entre les utilisateurs !

# BIEN : utilisez l'état de session pour les données propres à chaque utilisateur
st.session_state.setdefault("cache", {})
```

### Modifier l'état après la création d'un widget

On ne peut pas affecter la clé d'état de session d'un widget après que ce widget a été créé dans l'exécution en cours. Cela lève `StreamlitWidgetAlreadyInstantiatedError`.

```python
st.slider("Valeur", key="my_slider")
st.session_state["my_slider"] = 50  # Lève StreamlitWidgetAlreadyInstantiatedError
```

Affectez la valeur **avant** de créer le widget :

```python
st.session_state.setdefault("my_slider", 50)
st.slider("Valeur", key="my_slider")
```

Ou depuis un callback `on_change` / `on_click` (les callbacks s'exécutent avant la création des widgets) :

```python
def reset_slider():
    st.session_state["my_slider"] = 50


st.button("Réinitialiser", on_click=reset_slider)
st.slider("Valeur", key="my_slider")
```

Pour les widgets dont les clés sont en lecture seule (voir [Clés de widgets en lecture seule](#clés-de-widgets-en-lecture-seule)), stockez les valeurs sous une autre clé d'état de session.

### Clés de widgets en lecture seule

Certains widgets sont en lecture seule dans l'état de session (boutons et déclencheurs de type bouton, saisies de fichiers et de médias, `st.data_editor`, clés de `st.form`, et sélections dans les graphiques ou les `ButtonColumn`). En créer un après avoir affecté sa clé lève `StreamlitValueAssignmentNotAllowedError`. Laissez cette clé en lecture seule et stockez les valeurs que vous devez modifier sous une **autre** clé d'état de session :

```python
def mark_done():
    st.session_state["done"] = True


st.button("Terminé", key="done_btn", on_click=mark_done)
```

### Mélanger le paramètre `value` et l'état de session

Ne définissez pas les deux : cela provoque des avertissements.

```python
# MAL : sources contradictoires
st.session_state.setdefault("name", "Alice")
st.text_input("Nom", value="Bob", key="name")  # Avertissement !

# BIEN : utilisez l'un ou l'autre
st.session_state.setdefault("name", "Alice")
st.text_input("Nom", key="name")
```

## Caractéristiques d'une session

- **Par utilisateur, par onglet** : chaque onglet du navigateur a sa propre session
- **Temporaire** : perdue quand l'onglet se ferme ou que le serveur redémarre
- **Inadaptée au stockage durable** : utilisez une base de données pour un stockage permanent

## Références

- [API st.session_state](https://docs.streamlit.io/develop/api-reference/caching-and-state/st.session_state)
- [Concepts de l'état de session](https://docs.streamlit.io/develop/concepts/architecture/session-state)
- [Comportement des widgets](https://docs.streamlit.io/develop/concepts/architecture/widget-behavior)
