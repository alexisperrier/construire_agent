import os

import ollama
import streamlit as st

# Un bouton pour repartir d'une conversation vide.
def nouvelle_conversation():
    st.session_state.messages = []


with st.sidebar:
    st.button("Nouvelle conversation", on_click=nouvelle_conversation)

    # Le modèle est choisi dans la barre latérale ; une seule option pour l'instant.
    MODEL = st.selectbox("Modèle", ["llama3.2:3b"])

# La conversation est gardée pendant toute la session.
st.session_state.setdefault("messages", [])

# La mémoire persistante est lue une seule fois par session, à l'ouverture de la page.
if "memoire" not in st.session_state:
    st.session_state.memoire = ""
    if os.path.isfile("memory.md"):
        with open("memory.md", encoding="utf-8") as fichier:
            st.session_state.memoire = fichier.read()

# Dans la barre latérale : la taille approximative en tokens (caractères / 4)
# de la conversation et, à côté, celle de la mémoire.
taille_conversation = sum(len(m["content"]) for m in st.session_state.messages)
st.sidebar.write(
    f"{len(st.session_state.messages)} messages, environ {taille_conversation // 4} tokens"
    f" · mémoire : environ {len(st.session_state.memoire) // 4} tokens"
)

st.title("Le super agent")

# Affiche toute la conversation.
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

prompt = st.chat_input("Votre message")

if prompt:
    # Ajoute le message de l'utilisateur et l'affiche.
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.write(prompt)

    # Le contenu de la mémoire part en premier, comme message système,
    # suivi de la conversation de la session.
    messages_envoyes = [
        {
            "role": "system",
            "content": "Conversations précédentes :\n" + st.session_state.memoire,
        }
    ] + st.session_state.messages

    # Demande la réponse au modèle et l'affiche au fur et à mesure.
    with st.chat_message("assistant"):
        stream = ollama.chat(model=MODEL, messages=messages_envoyes, stream=True)
        reponse = st.write_stream(
            morceau["message"]["content"] for morceau in stream
        )

    # Enregistre le texte complet diffusé comme réponse.
    st.session_state.messages.append({"role": "assistant", "content": reponse})

    # Ajoute l'échange, mot pour mot, à la mémoire persistante.
    echange = f"Utilisateur : {prompt}\nAgent : {reponse}\n\n"
    with open("memory.md", "a", encoding="utf-8") as fichier:
        fichier.write(echange)
    st.session_state.memoire += echange
