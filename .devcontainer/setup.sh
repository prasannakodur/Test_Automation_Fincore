#!/bin/bash

# ── Output to both terminal AND log file in real time ──
exec > >(tee /tmp/setup.log) 2>&1

WORKSPACE="${CODESPACE_VSCODE_FOLDER:-/workspaces/$(ls /workspaces | head -1)}"
cd "$WORKSPACE"

echo "======================================"
echo " FinCore Bank — Codespace Setup"
echo " Log: /tmp/setup.log"
echo " Started: $(date)"
echo "======================================"
echo "Workspace: $WORKSPACE"

# ── Helper: print step result ──────────────
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ FAILED: $1"; }
warn() { echo "  ⚠ WARNING: $1"; }

# ── [1/8] Install PostgreSQL ─────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/8] Installing PostgreSQL..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt-get update -qq && pass "apt-get update" || fail "apt-get update"
sudo apt-get install -y postgresql postgresql-client && pass "PostgreSQL installed" || fail "PostgreSQL install"
echo "[1/8] DONE ✓"

# ── [2/8] Configure PostgreSQL ───────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[2/8] Configuring PostgreSQL..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo service postgresql start && pass "PostgreSQL started" || fail "PostgreSQL start"
sleep 5

PG_HBA=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
echo "  pg_hba.conf: $PG_HBA"

if [ -n "$PG_HBA" ]; then
  sudo sed -i 's/\bpeer\b/md5/g' "$PG_HBA"
  sudo sed -i 's/\bscram-sha-256\b/md5/g' "$PG_HBA"
  sudo sed -i 's/\btrust\b/md5/g' "$PG_HBA"
  sudo service postgresql restart && pass "PostgreSQL restarted with md5 auth" || fail "PostgreSQL restart"
  sleep 5
else
  warn "pg_hba.conf not found — auth may fail"
fi

sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'fincore123' SUPERUSER;" 2>/dev/null \
  && pass "User admin created" || pass "User admin already exists"
sudo -u postgres psql -c "CREATE DATABASE fincore OWNER admin;" 2>/dev/null \
  && pass "Database fincore created" || pass "Database fincore already exists"

PGPASSWORD=fincore123 psql -h localhost -U admin -d fincore -c "SELECT 1;" >/dev/null 2>&1 \
  && pass "DB connection verified — admin:fincore123 works" \
  || fail "DB connection failed — check pg_hba.conf"
echo "[2/8] DONE ✓"

# ── [3/8] JAVA_HOME ──────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[3/8] Setting JAVA_HOME..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
JAVA_BIN=$(which java 2>/dev/null)
if [ -n "$JAVA_BIN" ]; then
  JAVA_REAL=$(readlink -f "$JAVA_BIN")
  export JAVA_HOME=$(dirname $(dirname "$JAVA_REAL"))
  export PATH="$JAVA_HOME/bin:$PATH"
  export PYSPARK_PYTHON=python3
  export PYSPARK_DRIVER_PYTHON=python3
  echo "export JAVA_HOME=$JAVA_HOME"            >> ~/.bashrc
  echo "export PATH=\$JAVA_HOME/bin:\$PATH"     >> ~/.bashrc
  echo "export PYSPARK_PYTHON=python3"           >> ~/.bashrc
  echo "export PYSPARK_DRIVER_PYTHON=python3"    >> ~/.bashrc
  pass "JAVA_HOME=$JAVA_HOME"
  java -version 2>&1 | head -1 && pass "Java version confirmed" || fail "java -version"
else
  fail "java not found — PySpark will not work"
fi
echo "[3/8] DONE ✓"

# ── [4/8] Pipeline venv + PySpark ────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[4/8] Pipeline virtual environment..."
echo "      PySpark ~300MB — expect 5-8 min"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$WORKSPACE/pipeline"
python3 -m venv venv && pass "venv created" || fail "venv creation"
source venv/bin/activate && pass "venv activated" || fail "venv activation"
echo "  Installing dependencies (you will see progress)..."
pip install -r requirements.txt
PIP_EXIT=$?
if [ $PIP_EXIT -eq 0 ]; then
  pass "pip install completed"
else
  fail "pip install failed with exit code $PIP_EXIT"
fi
python3 -c "import pyspark; print('  PySpark version:', pyspark.__version__)" \
  && pass "PySpark import verified" \
  || fail "PySpark import failed"
cd "$WORKSPACE"
echo "[4/8] DONE ✓"

# ── [5/8] PostgreSQL JDBC jar ────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[5/8] PostgreSQL JDBC jar..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PYSPARK_JARS=$(python3 -c \
  "import pyspark, os; print(os.path.join(os.path.dirname(pyspark.__file__), 'jars'))" \
  2>/dev/null)
if [ -n "$PYSPARK_JARS" ]; then
  pass "PySpark jars dir: $PYSPARK_JARS"
  curl -L "https://jdbc.postgresql.org/download/postgresql-42.7.3.jar" \
    -o "$PYSPARK_JARS/postgresql-42.7.3.jar" \
    && pass "JDBC jar downloaded" || fail "JDBC jar download"
  sudo mkdir -p /usr/share/java
  sudo cp "$PYSPARK_JARS/postgresql-42.7.3.jar" /usr/share/java/postgresql.jar \
    && pass "JDBC jar copied to /usr/share/java/postgresql.jar" || fail "JDBC jar copy"
else
  fail "PySpark jars dir not found — JDBC jar not installed"
fi
echo "[5/8] DONE ✓"

# ── [6/8] Generate data ──────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[6/8] Generating CSV data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$WORKSPACE/data"
pip install -q -r requirements.txt && pass "data deps installed" || fail "data deps"
python3 generate_data.py && pass "Data generated" || fail "Data generation"
ls good_data/*.csv 2>/dev/null | wc -l | xargs -I{} echo "  CSV files in good_data: {}"
ls bad_data/*.csv  2>/dev/null | wc -l | xargs -I{} echo "  CSV files in bad_data:  {}"
cd "$WORKSPACE"
echo "[6/8] DONE ✓"

# ── [7/8] App env + Node deps ────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[7/8] App environment + Node deps..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ -f "$WORKSPACE/app/.env" ] \
  && pass "app/.env exists" \
  || (cp "$WORKSPACE/app/.env.example" "$WORKSPACE/app/.env" && pass "app/.env created from template")

[ -f "$WORKSPACE/pipeline/.env" ] \
  && pass "pipeline/.env exists" \
  || (cp "$WORKSPACE/pipeline/.env.example" "$WORKSPACE/pipeline/.env" && pass "pipeline/.env created from template")

sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=fincore123/' "$WORKSPACE/pipeline/.env" \
  && pass "DB password set in pipeline/.env"

echo "  Installing app Node deps..."
cd "$WORKSPACE/app" && npm install --silent \
  && pass "app Node deps installed" || fail "app npm install"

echo "  Installing client Node deps..."
cd "$WORKSPACE/app/client" && npm install --silent \
  && pass "client Node deps installed" || fail "client npm install"

cd "$WORKSPACE"
echo "[7/8] DONE ✓"

# ── [8/8] UC1 test deps ──────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[8/8] UC1 test dependencies..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
deactivate 2>/dev/null || true
pip install \
  pytest==7.4.4 \
  pytest-html==4.1.1 \
  "great-expectations==0.18.15" \
  psycopg2-binary==2.9.9 \
  python-dotenv==1.0.0
pip show great-expectations 2>/dev/null | grep "Version" \
  && pass "great-expectations installed" \
  || fail "great-expectations not found"
echo "[8/8] DONE ✓"

# ── SUMMARY ──────────────────────────────────
echo ""
echo "======================================"
echo " Setup complete! $(date)"
echo ""
echo " Full log: /tmp/setup.log"
echo ""
echo " Next — load data:"
echo "   cd pipeline"
echo "   source venv/bin/activate"
echo "   JAVA_HOME=$JAVA_HOME PYSPARK_PYTHON=python3 \\"
echo "   python3 ingest.py good_data"
echo "======================================"
