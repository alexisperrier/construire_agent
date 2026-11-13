# Installation unique sous Windows : Ollama, uv, le modèle llama3.2:3b et les paquets Python.
# Peut être relancé sans risque : il saute ce qui est déjà installé.
# À lancer avec : powershell -ExecutionPolicy Bypass -File setup\setup-windows.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

# Recharge le PATH pour que les commandes nouvellement installées soient trouvées dans cette fenêtre.
function Update-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
              "$env:USERPROFILE\.local\bin"
}

if (Get-Command ollama -ErrorAction SilentlyContinue) {
  Write-Host "==> Ollama est déjà installé"
} else {
  Write-Host "==> Installation d'Ollama"
  winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
  Update-Path
}

Write-Host "==> Démarrage d'Ollama"
function Test-Ollama { try { Invoke-WebRequest http://localhost:11434 -UseBasicParsing -TimeoutSec 2 | Out-Null; $true } catch { $false } }
if (-not (Test-Ollama)) { Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden }
for ($i = 0; $i -lt 30 -and -not (Test-Ollama); $i++) { Start-Sleep 1 }

if (Get-Command uv -ErrorAction SilentlyContinue) {
  Write-Host "==> uv est déjà installé"
} else {
  Write-Host "==> Installation de uv (il installe aussi Python si besoin)"
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  Update-Path
}

Write-Host "==> Installation des paquets Python"
uv sync

Write-Host "==> Téléchargement des modèles (environ 2 Go, sauté s'ils sont déjà là)"
ollama pull llama3.2:3b
# ollama pull qwen2.5:3b

if (-not (Test-Path .env)) {
  Copy-Item .env.template .env
  Write-Host "==> .env créé à partir de .env.template : ajoutez-y vos clés"
}

Write-Host "==> Terminé. Modèles installés :"
ollama list
