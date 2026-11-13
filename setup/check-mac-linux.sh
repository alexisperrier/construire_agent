#!/usr/bin/env bash
# Vérifie que tout ce qu'il faut pour l'atelier est installé et fonctionne.
# À lancer depuis le dossier du projet : bash setup/check-mac-linux.sh
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"
FAILED=0
ok()   { echo "  OK     $1"; }
fail() { echo "  ÉCHEC  $1"; echo "         -> $2"; FAILED=1; }

echo "Vérification de votre installation..."

if command -v ollama > /dev/null; then ok "Ollama est installé"
else fail "Ollama n'est pas installé" "lancez : bash setup/setup-mac-linux.sh"; fi

if curl -s http://localhost:11434 > /dev/null; then ok "Ollama tourne"
else fail "Ollama ne tourne pas" "lancez l'application Ollama"; fi

if ollama list 2> /dev/null | grep -q '^llama3.2:3b'; then ok "Le modèle llama3.2:3b est téléchargé"
else fail "Le modèle llama3.2:3b manque" "lancez : ollama pull llama3.2:3b"; fi

if command -v uv > /dev/null; then ok "uv est installé"
else fail "uv n'est pas installé" "lancez : bash setup/setup-mac-linux.sh, puis redémarrez OpenCode"; fi

if uv run python -c "import ollama, streamlit, tavily, mcp" > /dev/null 2>&1; then ok "Les paquets Python sont installés"
else fail "Les paquets Python manquent" "lancez : uv sync"; fi

if [ -f .env ]; then ok "Le fichier .env existe"
else fail "Le fichier .env manque" "lancez : bash setup/setup-mac-linux.sh"; fi

echo "Question posée au modèle (jusqu'à une minute la première fois)..."
ANSWER=$(ollama run llama3.2:3b "Réponds en un seul mot : bonjour" 2> /dev/null)
if [ -n "$ANSWER" ]; then ok "Le modèle répond : $ANSWER"
else fail "Le modèle n'a pas répondu" "vérifiez qu'Ollama tourne, puis réessayez"; fi

if curl -s http://localhost:8804/_stcore/health | grep -q ok; then ok "La page de l'agent tourne sur http://localhost:8804"
else echo "  INFO   La page de l'agent ne tourne pas encore (voir le README : Lancer la page de l'agent)"; fi

echo
if [ $FAILED -eq 0 ]; then echo "Tout est bon : vous êtes prêt·e pour l'atelier."
else echo "Il manque quelque chose : suivez les lignes -> ci-dessus, puis relancez cette vérification."; fi
