#!/usr/bin/env bash
# (Re)lance la page web de l'agent (Streamlit, port 8804) en arrière-plan, avec les clés de .env.
# Elle se recharge toute seule dès que app.py change. Fonctionne dans Codespaces, sur macOS et sur Linux.
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "$0")/.."
source .devcontainer/load-env.sh

# Arrête la page si elle tourne déjà, pour qu'elle relise les clés.
[ -f /tmp/streamlit.pid ] && kill "$(cat /tmp/streamlit.pid)" 2>/dev/null && sleep 2

[ -d .venv ] || uv sync -q
# setsid garde la page en marche après la fermeture du terminal (Linux) ; macOS n'en a pas besoin.
if command -v setsid > /dev/null; then LAUNCH="setsid nohup"; else LAUNCH="nohup"; fi
$LAUNCH .venv/bin/streamlit run app.py > /tmp/streamlit.log 2>&1 < /dev/null &
echo $! > /tmp/streamlit.pid

for _ in $(seq 1 60); do
  curl -s http://localhost:8804/_stcore/health > /dev/null && echo "La page de l'agent tourne : http://localhost:8804" && exit 0
  sleep 1
done
echo "La page de l'agent n'a pas démarré ; voir /tmp/streamlit.log" && exit 1
