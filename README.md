# FinCore Bank - Test Automation Training System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org/)

A complete banking system designed for test automation training. Features a multi-layered architecture with PySpark data pipeline, PostgreSQL database, REST API, and modern dark-themed React UI.

## 🚀 Quick Start

### Option 0: No‑Docker Quickstart (Local Only - Works on Windows/macOS/Linux)

**🎯 Use this if you DON'T want Docker and want to run everything locally on your laptop.**

#### Linux/macOS

```bash
# 1) Prereqs: PostgreSQL 15, Python 3.10+, Java 11/17, Node.js 20+

# 2) (Optional) Generate datasets
cd data && pip install -r requirements.txt && python generate_data.py && cd -

# 3) Load data to local PostgreSQL (NO DOCKER - runs on your laptop)
cd pipeline && python3 -m venv venv && source venv/bin/activate \
  && pip install -r requirements.txt && bash run_pipeline.sh good_data && cd -

# 4) Start BOTH Backend + Frontend with single script
bash start-app.sh
# Backend: http://localhost:4000/api/docs
# Frontend: http://localhost:3000
```

#### Windows (PowerShell)

```powershell
# 1) Prereqs: PostgreSQL 15, Python 3.10+, Java 11/17, Node.js 20+

# 2) (Optional) Generate datasets
cd data; pip install -r requirements.txt; python generate_data.py; cd ..

# 3) Load data to local PostgreSQL (NO DOCKER - runs on your laptop)
cd pipeline; python -m venv venv; .\venv\Scripts\Activate.ps1; `
  pip install -r requirements.txt; .\run_pipeline.ps1 good_data; cd ..

# 4) Start BOTH Backend + Frontend with single script
.\start-app.ps1
# Backend: http://localhost:4000/api/docs
# Frontend: http://localhost:3000
```

**✅ This runs 100% locally without Docker. Pipeline loads data to your local PostgreSQL.**

### Option 1: Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/fincore-bank.git
cd fincore-bank

# Start all services
docker compose up -d

# Run the pipeline with good data
bash pipeline/run_pipeline.sh good_data

# Access the application
# UI: http://localhost:3000
# API: http://localhost:4000/api/v1
# Swagger: http://localhost:4000/api/docs
# Jenkins: http://localhost:8080
```

### Option 2: Local Setup

See [SETUP.md](SETUP.md) for detailed local installation instructions.

## 📋 Prerequisites

### For Docker Setup

- **Docker Desktop** 4.x+ with Docker Compose v2
- **Minimum RAM**: 8 GB (16 GB recommended for all services)
- **Disk Space**: 10 GB free

### For Local Setup

- **Python** 3.10+
- **Node.js** 20.x LTS
- **PostgreSQL** 15.x
- **Java JDK** 11 or 17 (for PySpark)
- **Git** 2.x

## 🏗️ Architecture

```
CSV Files (good_data / bad_data)
        ↓
PySpark Pipeline (Transform & Load)
        ↓
PostgreSQL 15 (Central Data Store)
        ↓
    ┌───┴───┐
    ↓       ↓
Node.js   Great Expectations
REST API  (Data Quality)
    ↓
React 18 UI
```

## 🔌 Service Ports

| Service     | Port | URL                            | Purpose           |
| ----------- | ---- | ------------------------------ | ----------------- |
| PostgreSQL  | 5432 | `localhost:5432`             | Database          |
| React UI    | 3000 | http://localhost:3000          | Web Portal        |
| Node.js API | 4000 | http://localhost:4000/api/v1   | REST API          |
| Swagger UI  | 4000 | http://localhost:4000/api/docs | API Documentation |
| Jenkins     | 8080 | http://localhost:8080          | CI/CD             |

### 🔧 Changing Default Ports

**If you want to use different ports**, update these files:

| Component   | File                          | Variable         | Default                      |
| ----------- | ----------------------------- | ---------------- | ---------------------------- |
| Backend API | `app/.env`                  | `API_PORT`     | 4000                         |
| Frontend UI | `app/client/.env`           | `VITE_API_URL` | http://localhost:4000/api/v1 |
| Frontend UI | `app/client/vite.config.js` | `server.port`  | 3000                         |
| PostgreSQL  | `app/.env`                  | `DB_PORT`      | 5432                         |
| PostgreSQL  | `pipeline/.env`             | `DB_PORT`      | 5432                         |

**Example**: To run API on port 5000 instead of 4000:

1. Edit `app/.env`: Change `API_PORT=4000` to `API_PORT=5000`
2. Edit `app/client/.env`: Change `VITE_API_URL=http://localhost:4000/api/v1` to `VITE_API_URL=http://localhost:5000/api/v1`
3. Restart both services

## 🎓 What You Can Ignore

**⚠️ Don't waste time looking into these folders/files during training:**

### ❌ Infrastructure Files (Ignore These)

- `docker-compose.yml` - Docker setup (use if needed, don't modify)
- `Dockerfile` - Container build (already working)
- `.dockerignore`, `.gitignore` - Git/Docker configs
- `package-lock.json`, `venv/`, `node_modules/` - Auto-generated dependencies

### ❌ Configuration Files (Already Set Up)

- `app/src/config/database.js` - Database connection (working)
- `app/src/utils/swagger.js` - API docs (auto-generated)
- `app/client/vite.config.js` - Build tool config
- `app/client/tailwind.config.js` - Styling config
- All `.env.example` files - Just copy to `.env` and use

### ✅ Focus on These for Case study

- **`tests/`** - Write your test automation here (UC1-UC5)
- **`data/`** - Understand good_data vs bad_data
- **`pipeline/transformations.py`** - Study PySpark transformations
- **API endpoints** - Test via Swagger UI (http://localhost:4000/api/docs)
- **UI screens** - Automate via http://localhost:3000

**🎯 Your main task**: Write tests in `tests/` folder, not modify the application code.

## 🔐 Default Credentials

### Application Login

| Username | Password   | Role      | Access Level     |
| -------- | ---------- | --------- | ---------------- |
| admin    | Admin@123  | admin     | Full read access |
| viewer   | Viewer@123 | read_only | Read-only access |
| testuser | Test@123   | standard  | Standard user    |

### Database

- **Host**: localhost
- **Port**: 5432
- **Database**: fincore
- **Username**: admin
- **Password**: fincore123

### Jenkins

- **Username**: admin
- **Password**: (auto-generated on first run, check logs)

## 📊 Dataset Information

### Good Data (Clean)

- **Customers**: 10,000 records
- **Accounts**: 25,000 records
- **Transactions**: 500,000 records
- **Loans**: 8,000 records

### Bad Data (With Violations)

Same volume with intentional data quality issues for testing Great Expectations validation.

## 🔄 Running the Pipeline

### Local Setup (NO DOCKER - Runs on Your Laptop)

**✅ This loads data to your local PostgreSQL database, NOT Docker.**

#### Linux/macOS

```bash
cd pipeline

# Activate virtual environment (if not already active)
source venv/bin/activate

# Good data (clean)
bash run_pipeline.sh good_data

# Bad data (with violations)
bash run_pipeline.sh bad_data
```

#### Windows (PowerShell)

```powershell
cd pipeline

# Activate virtual environment (if not already active)
.\venv\Scripts\Activate.ps1

# Good data (clean)
.\run_pipeline.ps1 good_data

# Bad data (with violations)
.\run_pipeline.ps1 bad_data
```

### With Docker

```bash
# Good data (clean)
docker exec -it fincore-app bash pipeline/run_pipeline.sh good_data

# Bad data (with violations)
docker exec -it fincore-app bash pipeline/run_pipeline.sh bad_data
```

Expected output:

```
Starting FinCore Bank Data Pipeline...
Reading CSVs from data/good_data/...
Applying transformations...
Loading to PostgreSQL...
✓ customers: 10,000 rows loaded
✓ accounts: 25,000 rows loaded
✓ transactions: 500,000 rows loaded
✓ loans: 8,000 rows loaded
Pipeline completed successfully!
```

## ✅ Verifying the System

### Check Database

```bash
# Docker
docker exec -it fincore-postgres psql -U admin -d fincore -c "SELECT COUNT(*) FROM customers;"

# Local
psql -U admin -d fincore -c "SELECT COUNT(*) FROM customers;"
```

### Check API Health

```bash
curl http://localhost:4000/api/v1/health
```

Expected response:

```json
{
  "status": "ok",
  "db": "connected",
  "timestamp": "2024-03-15T10:30:00.000Z",
  "version": "1.0.0"
}
```

### Check UI

Open http://localhost:3000 in your browser and login with `admin` / `Admin@123`

## 🚦 Starting Backend + Frontend Together

**🎯 Use these scripts to start BOTH Backend API and Frontend UI with a single command.**

### Linux/macOS

```bash
# Start both services (verbose output with icons)
bash start-app.sh

# Services will start:
# 🌐 Backend API:    http://localhost:4000/api/v1
# 🌐 Swagger Docs:   http://localhost:4000/api/docs
# 🌐 Frontend UI:    http://localhost:3000

# Press Ctrl+C to stop all services
```

### Windows (PowerShell)

```powershell
# Start both services (verbose output with icons)
.\start-app.ps1

# Services will start:
# 🌐 Backend API:    http://localhost:4000/api/v1
# 🌐 Swagger Docs:   http://localhost:4000/api/docs
# 🌐 Frontend UI:    http://localhost:3000

# Press Ctrl+C to stop all services
```

**Features**:

- ✅ Checks prerequisites (Node.js, npm)
- ✅ Auto-installs dependencies if missing
- ✅ Creates `.env` files from templates
- ✅ Starts both services concurrently
- ✅ Verbose console output with icons
- ✅ Logs saved to `logs/backend.log` and `logs/frontend.log`
- ✅ Single Ctrl+C stops everything

**Alternative**: Start services separately in different terminals:

```bash
# Terminal 1 - Backend API
cd app && npm run dev

# Terminal 2 - Frontend UI
cd app/client && npm run dev
```

## 🧪 Running Tests

### Data Quality Tests (UC1)

```bash
cd tests/dq
pytest test_great_expectations.py --html=reports/dq_report.html
```

### API Automation Tests (UC2)

```bash
cd tests/api
pytest --html=reports/api_report.html
```

### UI Automation Tests (UC3)

```bash
cd tests/ui
pytest --html=reports/ui_report.html
```

### Pipeline Tests (UC4)

```bash
cd tests/pipeline
pytest --html=reports/pipeline_report.html
```

### Full Test Suite (UC5 - Jenkins)

Access Jenkins at http://localhost:8080 and run the `FinCore-Full-Test-Suite` job.

## 🛑 Stopping the System

### Docker

```bash
# Stop all services
docker compose down

# Stop and remove all data
docker compose down -v
```

### Local

```bash
# Stop Node.js API (Ctrl+C in terminal)
# Stop PostgreSQL service
sudo service postgresql stop  # Linux
brew services stop postgresql  # macOS
```

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
lsof -i :3000  # or :4000, :5432, :8080

# Kill the process
kill -9 <PID>
```

### Docker Out of Memory

Increase Docker Desktop memory allocation:

- Docker Desktop → Settings → Resources → Memory → 8 GB minimum

### Pipeline Fails

```bash
# Check logs
docker logs fincore-app

# Verify PostgreSQL is ready
docker exec -it fincore-postgres pg_isready -U admin
```

### Cannot Connect to Database

```bash
# Restart PostgreSQL container
docker restart fincore-postgres

# Wait 10 seconds and retry
```

### UI Not Loading

```bash
# Check if API is running
curl http://localhost:4000/api/v1/health

# Rebuild the app container
docker compose up -d --build fincore-app
```

## 📚 Documentation

- **[SETUP.md](SETUP.md)** - Detailed local setup instructions
- **[comprehensive-guide.md](comprehensive-guide.md)** - Architecture deep dive
- **[API Documentation](http://localhost:4000/api/docs)** - Interactive Swagger UI
- **[Test Automation Guide](tests/README.md)** - UC1-UC5 test scenarios

## 🏦 Use Cases

| UC  | Title                   | Tools                          | Purpose                             |
| --- | ----------------------- | ------------------------------ | ----------------------------------- |
| UC1 | Data Quality Validation | Great Expectations, PostgreSQL | Validate data quality post-pipeline |
| UC2 | API Automation          | pytest-bdd, requests           | Test REST API endpoints             |
| UC3 | UI Automation           | pytest-bdd, Playwright         | Test web portal functionality       |
| UC4 | Pipeline Testing        | PySpark, pytest                | Unit test transformations           |
| UC5 | Jenkins CI/CD           | Jenkins, All above             | Orchestrate full test suite         |

## 🤝 Contributing

This is a training project. For modifications:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

🎯 Training Objectives

This system helps Data Quality Engineers learn:

- ✅ PySpark data transformations
- ✅ Great Expectations data validation
- ✅ REST API testing with pytest-bdd
- ✅ UI automation with Playwright
- ✅ CI/CD pipeline orchestration
- ✅ Database cross-validation
- ✅ Test reporting and documentation

---
