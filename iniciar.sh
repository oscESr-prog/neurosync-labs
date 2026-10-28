#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE ARRANQUE LOCAL - NEUROSYNC LABS PWA
# ==============================================================================

PORT=8080
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "  Iniciando NeuroSync Labs PWA en http://localhost:$PORT  "
echo "=========================================================="
echo "Directorio base: $DIRECTORY"
echo "Presiona Ctrl + C para detener el servidor local."
echo ""

# Abrir el navegador tras 1.5 segundos
(sleep 1.5 && (xdg-open "http://localhost:$PORT" 2>/dev/null || google-chrome "http://localhost:$PORT" 2>/dev/null || firefox "http://localhost:$PORT" 2>/dev/null)) &

# Iniciar backend Node.js (con stream de telemetría y API) o fallback a Python
if command -v node >/dev/null 2>&1 && [ -f "$DIRECTORY/backend/server.js" ]; then
  echo "[OK] Iniciando Backend Node.js con Telemetría en Tiempo Real..."
  PORT=$PORT node "$DIRECTORY/backend/server.js"
else
  echo "[OK] Iniciando Servidor HTTP Python..."
  python3 -m http.server "$PORT" --directory "$DIRECTORY"
fi
