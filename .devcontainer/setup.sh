#!/usr/bin/env bash
# Installation unique du codespace : Ollama + qwen2.5:3b et llama3.2:3b, uv, OpenCode.
set -euo pipefail

echo "==> Installation de zstd (nécessaire à l'installeur d'Ollama)"
sudo apt-get update -qq && sudo apt-get install -y -qq zstd

echo "==> Installation d'Ollama"
curl -fsSL https://ollama.com/install.sh | sh

echo "==> Installation de uv (il installe aussi Python si besoin)"
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

echo "==> Installation d'OpenCode"
curl -fsSL https://opencode.ai/install | bash

echo "==> Téléchargement des modèles qwen2.5:3b et llama3.2:3b (environ 2 Go chacun)"
bash .devcontainer/start-ollama.sh
ollama pull qwen2.5:3b
ollama pull llama3.2:3b

echo "==> Installation des paquets Python de l'agent (pyproject.toml) et du serveur MCP fetch"
uv sync
uv tool install mcp-server-fetch

echo "==> Chargement des clés d'API de .env dans chaque nouveau terminal (pour OpenCode)"
echo "source \"$PWD/.devcontainer/load-env.sh\" \"$PWD\"" >> ~/.bashrc

echo "==> Installation terminée"
