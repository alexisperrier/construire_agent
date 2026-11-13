# Charge les clés d'API de .env (si le fichier existe) dans le shell courant.
# Utilisé par start-app.sh et par chaque nouveau terminal du codespace. Fonctionne avec bash et zsh.
# Tolère les espaces en trop, les guillemets et les fins de ligne Windows autour des valeurs.
if [ -f "${1:-.}/.env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line=$(printf %s "$line" | tr -d '\r')
    case "$line" in ''|\#*) continue ;; esac
    key=$(printf %s "${line%%=*}" | tr -d ' ')
    value=$(printf %s "${line#*=}" | sed "s/^[[:space:]\"']*//; s/[[:space:]\"']*\$//")
    [ -n "$value" ] && export "$key=$value"
  done < "${1:-.}/.env"
  unset line key value
fi
