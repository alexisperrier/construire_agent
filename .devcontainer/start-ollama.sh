#!/usr/bin/env bash
# Lance le serveur Ollama en arrière-plan (s'il ne tourne pas déjà) et attend qu'il réponde.
if ! curl -s http://localhost:11434 > /dev/null; then
  if command -v setsid > /dev/null; then LAUNCH="setsid nohup"; else LAUNCH="nohup"; fi
  $LAUNCH ollama serve > /tmp/ollama.log 2>&1 < /dev/null &
fi
for _ in $(seq 1 30); do
  curl -s http://localhost:11434 > /dev/null && echo "Ollama tourne" && exit 0
  sleep 1
done
echo "Ollama n'a pas démarré ; voir /tmp/ollama.log" && exit 1
