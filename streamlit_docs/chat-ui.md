# Interfaces de chat avec Streamlit

Construire des interfaces conversationnelles avec les éléments de chat de Streamlit.

## Structure de base d'un chat

```python
import streamlit as st

if "messages" not in st.session_state:
    st.session_state.messages = []

# Affiche l'historique du chat
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.write(msg["content"])

# Traite un nouveau message
if prompt := st.chat_input("Posez une question"):
    st.session_state.messages.append({"role": "user", "content": prompt})

    with st.chat_message("user"):
        st.write(prompt)

    with st.chat_message("assistant"):
        response = get_response(prompt)  # Votre appel au LLM
        st.write(response)

    st.session_state.messages.append({"role": "assistant", "content": response})
```

## Réponses diffusées en continu (streaming)

Utilisez `st.write_stream` pour un affichage token par token. Passez-lui n'importe quel générateur qui produit des chaînes, y compris directement le générateur d'OpenAI :

```python
def get_streaming_response(prompt):
    # Remplacez par votre client LLM (OpenAI, Anthropic, Cortex, etc.)
    for chunk in your_llm_client.stream(prompt):
        yield chunk


with st.chat_message("assistant"):
    response = st.write_stream(get_streaming_response(prompt))

st.session_state.messages.append({"role": "assistant", "content": response})
```

Avec OpenAI, vous pouvez passer le flux directement :

```python
from openai import OpenAI

client = OpenAI()
with st.chat_message("assistant"):
    stream = client.chat.completions.create(
        model="gpt-4o",
        messages=st.session_state.messages,
        stream=True,
    )
    response = st.write_stream(stream)
```

## Contrôler la saisie pendant la réponse

Utilisez `submit_mode` pour contrôler ce qui arrive à la zone de saisie du chat quand l'utilisateur envoie un message alors que le script (par exemple une réponse du LLM) tourne encore :

```python
# Désactive la saisie jusqu'à la fin de la réponse (évite les interruptions)
prompt = st.chat_input("Posez une question", submit_mode="disable")

# Transforme le bouton d'envoi en bouton d'arrêt pour pouvoir annuler une longue réponse
prompt = st.chat_input("Posez une question", submit_mode="stop")
```

- `"submit"` (par défaut) : la saisie reste active, l'utilisateur peut envoyer de nouveaux messages pendant que le script tourne.
- `"disable"` : la saisie est désactivée après l'envoi et réactivée à la fin de l'exécution ; utile pour ne pas interrompre les réponses diffusées en continu.
- `"stop"` : le bouton d'envoi devient un bouton d'arrêt pendant l'exécution ; cliquer dessus arrête le script, comme le bouton « Stop » de l'application.

## Réflexion et étapes de l'agent

Utilisez `type="compact"` ou `type="step"` sur `st.status` ou `st.expander` à l'intérieur d'un message de chat pour dévoiler le raisonnement sans le cadre bordé par défaut. Préférez `st.status` pour une réflexion en direct ; `st.expander` convient pour réafficher l'historique de façon statique.

**Encadré de réflexion compact.** Un interrupteur en ligne sans bordure : le motif « A réfléchi pendant N secondes » de ChatGPT ou Claude. Utilisez-le pour un seul bloc de raisonnement. Pendant que le travail tourne, entourez le libellé compact de `:shimmer[...]` pour que le texte lui-même signale le travail en cours ; remplacez-le par un libellé statique une fois terminé.

```python
with st.chat_message("assistant"):
    with st.status(":shimmer[Réflexion]", type="compact") as status:
        st.write(reasoning)
        status.update(label="A réfléchi pendant 4 secondes", state="complete")

    response = st.write_stream(get_streaming_response(prompt))
```

**Frise d'étapes.** Des conteneurs `type="step"` consécutifs partagent un trait vertical qui les relie. Utilisez-les pour les appels d'outils, la recherche de documents et le travail d'agent en plusieurs étapes qui doit rester visible dans le message.

```python
with st.chat_message("assistant"):
    with st.status("Recherche dans la documentation", type="step"):
        sources = search(prompt)
        st.write(sources[0])

    with st.status("Réflexion", type="step"):
        st.write(reasoning)

    response = st.write_stream(get_streaming_response(prompt, sources))
```

Le trait s'arrête déjà quand l'élément suivant n'est pas une étape : pas besoin d'une étape finale vide avant la réponse diffusée.

**Les deux combinés.** Imbriquez la frise d'étapes dans un statut compact quand les détails doivent rester repliés par défaut. C'est en général le meilleur choix dans un chat : un interrupteur « A réfléchi pendant N secondes » qui dévoile la chaîne de raisonnement.

```python
with st.chat_message("assistant"):
    with st.status(":shimmer[Réflexion]", type="compact") as status:
        with st.status("Recherche dans la documentation", type="step"):
            sources = search(prompt)
            st.write(sources[0])

        with st.status("Planification", type="step"):
            st.write(reasoning)

        status.update(label="A réfléchi pendant 4 secondes", state="complete")

    response = st.write_stream(get_streaming_response(prompt, sources))
```

- Gardez les conteneurs `type="step"` consécutifs. Tout autre élément entre eux, y compris un `st.empty()` invisible, commence un nouveau segment de frise.
- Une étape sans contenu termine aussi la frise, ce qui sert à découper une chaîne en segments, pas à faire un faux nœud « terminé » avant la réponse.
- `state` doit valoir `"running"` (par défaut), `"complete"` ou `"error"` ; toute autre valeur lève une erreur, y compris via `status.update(state=...)`.
- Placez le statut là où le travail s'exécute, pour que ses étapes apparaissent au fil de la tâche. Ne le cachez pas derrière un bouton dont le seul rôle est de lancer la tâche : l'exécuter en réponse à une vraie saisie, par exemple `if prompt := st.chat_input(...)`, est le cas normal.

## Avatars des messages

Streamlit fournit des avatars par défaut pour les rôles "user" et "assistant" ; ne les personnalisez que si vous en avez vraiment besoin. Vous pouvez utiliser des icônes ou des images :

```python
# Avec des icônes
with st.chat_message("assistant", avatar=":material/robot:"):
    st.write(assistant_message)

# Avec des images
with st.chat_message("user", avatar="https://example.com/avatar.png"):
    st.write(user_message)
```

## Suggestions cliquables

Proposez des suggestions cliquables avant le premier message. Une suggestion choisie devient le premier prompt, et les pastilles disparaissent dès que la conversation commence :

```python
SUGGESTIONS = {
    ":blue[:material/help:] Qu'est-ce que Streamlit ?": "Explique ce qu'est Streamlit",
    ":green[:material/code:] Montre-moi un exemple": "Montre un exemple simple de Streamlit",
}

# Remplace le `if prompt := st.chat_input(...)` de l'exemple de base
prompt = st.chat_input("Posez une question")

if not st.session_state.messages:
    suggestions = st.empty()
    selected = suggestions.pills(
        "Essayez :", list(SUGGESTIONS.keys()), label_visibility="collapsed"
    )
    if selected:
        prompt = SUGGESTIONS[selected]
    if prompt:
        suggestions.empty()  # Cache les pastilles avant d'afficher la première réponse

if prompt:
    ...  # Même traitement qu'une saisie tapée : ajouter, afficher et générer la réponse
```

N'affichez les suggestions que tant que `st.session_state.messages` est vide, et faites passer la suggestion choisie par le même `if prompt:` que la saisie tapée. Ajouter la suggestion puis appeler `st.rerun()` saute la réponse, car à cette nouvelle exécution `st.chat_input` renvoie `None`. Affichez les pastilles dans un emplacement `st.empty()` et videz-le dès qu'il y a un prompt ; sinon elles restent à l'écran au-dessus de la première réponse jusqu'à l'exécution suivante.

## Envoi de fichiers

Activez les pièces jointes avec `accept_file`. Dans ce cas, `st.chat_input` renvoie un objet de type dictionnaire avec les attributs `text` et `files` :

```python
prompt = st.chat_input(
    "Posez une question sur une image",
    accept_file=True,
    file_type=["jpg", "jpeg", "png"],
)

if prompt:
    with st.chat_message("user"):
        if prompt.text:
            st.write(prompt.text)
        if prompt.files:
            st.image(prompt.files[0])

    # Envoie au modèle de vision ; un message peut ne contenir que du texte, donc files peut être vide
    with st.chat_message("assistant"):
        image = prompt.files[0] if prompt.files else None
        response = analyze_image(image, prompt.text)
        st.write(response)
```

Utilisez `accept_file="multiple"` pour autoriser plusieurs fichiers.

Pour typer vos fonctions, importez `ChatInputValue` et `UploadedFile` depuis l'espace de noms public `streamlit.typing`, plutôt que depuis les modules internes de Streamlit :

```python
from streamlit.typing import ChatInputValue, UploadedFile


def first_file(submission: ChatInputValue) -> UploadedFile | None:
    return submission.files[0] if "files" in submission and submission.files else None
```

## Saisie audio

Activez l'enregistrement vocal avec `accept_audio`. L'audio enregistré est disponible sous forme de fichier WAV :

```python
prompt = st.chat_input("Dites quelque chose", accept_audio=True)

if prompt:
    if prompt.audio:
        st.audio(prompt.audio)
    if prompt.text:
        st.write(prompt.text)
```

### Dictée avec reconnaissance vocale

Convertissez l'audio en texte et réinjectez-le dans la zone de saisie du chat :

```python
prompt = st.chat_input("Dites quelque chose", accept_audio=True, key="chat")

if prompt and prompt.audio:
    # Transcrit avec Whisper ou un autre modèle de reconnaissance vocale
    transcript = openai.audio.transcriptions.create(
        model="whisper-1",
        file=prompt.audio,
    )
    # Place le texte transcrit comme prochaine saisie
    st.session_state.chat = transcript.text
    st.rerun()
```

## Références

- `snowflake-connection.md` : requêtes de base de données et exemple de chat Cortex
- `performance.md` : stratégies de cache pour les appels au LLM
- [st.chat_message](https://docs.streamlit.io/develop/api-reference/chat/st.chat_message)
- [st.chat_input](https://docs.streamlit.io/develop/api-reference/chat/st.chat_input)
- [st.write_stream](https://docs.streamlit.io/develop/api-reference/write-magic/st.write_stream)
- [st.status](https://docs.streamlit.io/develop/api-reference/status/st.status)
- [st.expander](https://docs.streamlit.io/develop/api-reference/layout/st.expander)
