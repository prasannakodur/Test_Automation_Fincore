#!/bin/bash
set -e

WORKSPACE="${CODESPACE_VSCODE_FOLDER:-/workspaces/$(ls /workspaces | head -1)}"
echo "Workspace: $WORKSPACE"
cd "$WORKSPACE"

echo ""
echo "======================================"
echo " FinCore Bank — Codespace Setup"
echo "======================================"

# ── PostgreSQL via apt (no devcontainer feature needed) ──
echo "[1/6] Installing PostgreSQL 15..."
sudo apt-get update -qq
sudo apt-get install -y -qq postgresql postgresql-client
echo "[1/6] PostgreSQL installed."

echo "[2/6] Starting PostgreSQL and creating DB..."
sudo service postgresql start
sleep 3
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'fincore123' SUPERUSER;" 2>/dev/null || echo "  (user exists)"
sudo -u postgres psql -c "CREATE DATABASE fincore OWNER admin;" 2>/dev/null || echo "  (db exists)"
echo "[2/6] PostgreSQL ready."

# ── Pipeline Python env ──────────────────────
echo "[3/6] Setting up pipeline virtual environment..."
cd "$WORKSPACE/pipeline"
python3 -m venv venv
source venv/bin/activate
pip install --quiet -r requirements.txt
deactivate
cd "$WORKSPACE"
echo "[3/6] Pipeline venv ready."

# ── App env files ────────────────────────────
echo "[4/6] Creating .env files from templates..."
[ -f "$WORKSPACE/app/.env" ]      || cp "$WORKSPACE/app/.env.example" "$WORKSPACE/app/.env"
[ -f "$WORKSPACE/pipeline/.env" ] || cp "$WORKSPACE/pipeline/.env.example" "$WORKSPACE/pipeline/.env"
echo "[4/6] .env files ready."

# ── Node.js dependencies ─────────────────────
echo "[5/6] Installing Node.js dependencies..."
cd "$WORKSPACE/app" && npm install --silent
cd "$WORKSPACE/app/client" && npm install --silent
cd "$WORKSPACE"
echo "[5/6] Node.js dependencies ready."

# ── Test dependencies ────────────────────────
echo "[6/6] Installing base test dependencies..."
pip install --quiet \
  pytest==7.4.4 \
  pytest-html==4.1.1 \
  great-expectations==0.18.15 \
  psycopg2-binary==2.9.9 \
  python-dotenv==1.0.0
echo "[6/6] Test dependencies ready."

echo ""
echo "======================================"
echo " Setup complete!"
echo " Next: cd pipeline && source venv/bin/activate && bash run_pipeline.sh good_data"
echo "======================================"
