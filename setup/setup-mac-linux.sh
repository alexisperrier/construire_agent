#!/usr/bin/env bash
# Installation unique sur macOS ou Linux : Ollama, uv, le modèle llama3.2:3b et les paquets Python.
# Peut être relancé sans risque : il saute ce qui est déjà installé.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

if command -v ollama > /dev/null; then
  echo "==> Ollama est déjà installé"
else
  echo "==> Installation d'Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "==> Démarrage d'Ollama"
if ! curl -s http://localhost:11434 > /dev/null; then
  if [ "$(uname)" = "Darwin" ]; then open -a Ollama; else (nohup ollama serve > /tmp/ollama.log 2>&1 &); fi
fi
for _ in $(seq 1 30); do curl -s http://localhost:11434 > /dev/null && break; sleep 1; done

if command -v uv > /dev/null; then
  echo "==> uv est déjà installé"
else
  echo "==> Installation de uv (il installe aussi Python si besoin)"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "==> Installation des paquets Python"
uv sync

echo "==> Téléchargement des modèles (environ 2 Go, sauté s'ils sont déjà là)"
ollama pull llama3.2:3b
# ollama pull qwen2.5:3b

[ -f .env ] || { cp .env.template .env; echo "==> .env créé à partir de .env.template : ajoutez-y vos clés"; }

echo "==> Terminé. Modèles installés :"
ollama list
