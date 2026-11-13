# Vérifie que tout ce qu'il faut pour l'atelier est installé et fonctionne.
# À lancer depuis le dossier du projet : powershell -ExecutionPolicy Bypass -File setup\check-windows.ps1
Set-Location (Join-Path $PSScriptRoot "..")
$env:Path += ";$env:USERPROFILE\.local\bin"
$script:Failed = $false
function Ok($msg) { Write-Host "  OK     $msg" }
function Fail($msg, $fix) { Write-Host "  ÉCHEC  $msg"; Write-Host "         -> $fix"; $script:Failed = $true }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Answers($url) { try { (Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 3).Content } catch { $null } }

Write-Host "Vérification de votre installation..."

if (Has ollama) { Ok "Ollama est installé" }
else { Fail "Ollama n'est pas installé" "lancez : powershell -ExecutionPolicy Bypass -File setup\setup-windows.ps1" }

if (Answers "http://localhost:11434") { Ok "Ollama tourne" }
else { Fail "Ollama ne tourne pas" "lancez l'application Ollama" }

if ((Has ollama) -and ((ollama list 2>$null) -match '^llama3.2:3b')) { Ok "Le modèle llama3.2:3b est téléchargé" }
else { Fail "Le modèle llama3.2:3b manque" "lancez : ollama pull llama3.2:3b" }

if (Has uv) { Ok "uv est installé" }
else { Fail "uv n'est pas installé" "lancez le script d'installation, puis redémarrez OpenCode" }

if (Has uv) { uv run python -c "import ollama, streamlit, tavily, mcp" *> $null }
if ((Has uv) -and $LASTEXITCODE -eq 0) { Ok "Les paquets Python sont installés" }
else { Fail "Les paquets Python manquent" "lancez : uv sync" }

if (Test-Path .env) { Ok "Le fichier .env existe" }
else { Fail "Le fichier .env manque" "lancez le script d'installation" }

Write-Host "Question posée au modèle (jusqu'à une minute la première fois)..."
$answer = if (Has ollama) { ollama run llama3.2:3b "Réponds en un seul mot : bonjour" 2>$null } else { $null }
if ($answer) { Ok "Le modèle répond : $answer" }
else { Fail "Le modèle n'a pas répondu" "vérifiez qu'Ollama tourne, puis réessayez" }

if ((Answers "http://localhost:8804/_stcore/health") -match "ok") { Ok "La page de l'agent tourne sur http://localhost:8804" }
else { Write-Host "  INFO   La page de l'agent ne tourne pas encore (voir le README : Lancer la page de l'agent)" }

Write-Host ""
if (-not $script:Failed) { Write-Host "Tout est bon : vous êtes prêt·e pour l'atelier." }
else { Write-Host "Il manque quelque chose : suivez les lignes -> ci-dessus, puis relancez cette vérification." }
