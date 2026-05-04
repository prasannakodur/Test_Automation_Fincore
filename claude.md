# claude.md — FinCore Bank Test Automation

> This file is the single source of truth for any AI assistant working on this project.
> Read it fully before touching any file. Update the "Current Status" section after every session.

---

## 1. Project Identity

**Project:** FinCore Bank — Test Automation Training Programme
**Repo:** https://github.com/amitbad/fincore-app
**Owner:** Trainee Data Quality Engineer
**Role of AI:** Senior QA Architect (20 years experience) — pair-programming partner

This is a **training project**, not a production system. The goal is to learn enterprise-grade
test automation by building a complete framework against a realistic banking simulation.

---

## 2. System Under Test — Read-Only

These folders are the application. Never modify them. Never add files inside them.

```
fincore-app/
├── app/              ← Node.js REST API + React UI  (READ ONLY)
├── data/             ← CSV source files: good_data/, bad_data/  (READ ONLY)
├── db/               ← PostgreSQL init SQL  (READ ONLY)
└── pipeline/         ← PySpark ingest + transformations.py  (READ ONLY)
```

### What the system does

Data flows in one direction:

```
CSV files (good_data / bad_data)
        ↓
PySpark Pipeline  →  PostgreSQL 15 (db: fincore)
                             ↓
                     Node.js REST API  :4000
                             ↓
                     React UI          :3000
```

### Four tables in PostgreSQL

| Table        | Good data rows | Key fields (inferred)                        |
|--------------|---------------|----------------------------------------------|
| customers    | 10,000        | customer_id, name, email, phone, created_at  |
| accounts     | 25,000        | account_id, customer_id, balance, status     |
| transactions | 500,000       | transaction_id, account_id, amount, date     |
| loans        | 8,000         | loan_id, customer_id, amount, duration_days  |

### Credentials (never hardcode — always read from env or conftest fixture)

| Service    | Host      | Port | DB      | User  | Password   |
|------------|-----------|------|---------|-------|------------|
| PostgreSQL | localhost | 5432 | fincore | admin | fincore123 |
| API        | localhost | 4000 | —       | —     | —          |
| UI         | localhost | 3000 | —       | admin | Admin@123  |

---

## 3. Environment — No Docker

**Constraint:** Docker is not available. All services run natively inside GitHub Codespaces.

**Runtime:** GitHub Codespaces — Ubuntu 22.04, 4-core machine minimum
**Config:** `.devcontainer/devcontainer.json` + `.devcontainer/setup.sh` (committed to repo)

### What setup.sh provisions automatically on first launch

- PostgreSQL 15 (service started, `fincore` DB + `admin` user created)
- Python 3.11 + pipeline venv at `pipeline/venv/`
- Node.js 20 + npm deps for `app/` and `app/client/`
- Base test deps: pytest, great-expectations, psycopg2-binary, pytest-html

### Every Codespace session — run this first

```bash
sudo service postgresql start
```

### Load data (run once per data scenario)

```bash
# Good data — clean, all expectations must PASS
cd pipeline && source venv/bin/activate && bash run_pipeline.sh good_data && cd ..

# Bad data — intentional violations, specific expectations must FAIL
cd pipeline && source venv/bin/activate && bash run_pipeline.sh bad_data && cd ..
```

### Start the application (when needed for UC2, UC3)

```bash
bash start-app.sh
# API: http://localhost:4000/api/v1   Swagger: http://localhost:4000/api/docs
# UI:  http://localhost:3000
```

---

## 4. Your Workspace — tests/ Only

All test code lives exclusively here. This is the only folder you create or modify.

```
tests/
├── conftest.py               ← shared fixtures: DB connection, API base URL
├── requirements.txt          ← all test dependencies pinned
│
├── dq/                       ← UC1: Great Expectations
│   ├── gx/
│   │   ├── great_expectations.yml
│   │   ├── expectations/
│   │   │   ├── customers_suite.json
│   │   │   ├── accounts_suite.json
│   │   │   ├── transactions_suite.json
│   │   │   └── loans_suite.json
│   │   └── checkpoints/
│   │       └── fincore_checkpoint.yml
│   ├── run_gx.py             ← GX trigger script (runs all 4 suites)
│   ├── test_great_expectations.py  ← pytest wrapper (calls run_gx.py)
│   └── reports/              ← Data Docs HTML output
│
├── api/                      ← UC2: pytest-bdd API tests
├── ui/                       ← UC3: pytest-bdd UI tests (Playwright)
├── pipeline/                 ← UC4: PySpark unit tests + E2E
└── Jenkinsfile               ← UC5: CI/CD (adapted to GitHub Actions)
```

---

## 5. Use Cases — Implementation Roadmap

| UC  | Name              | Tools                          | Status      |
|-----|-------------------|-------------------------------|-------------|
| UC1 | Data Quality      | Great Expectations, pytest     | IN PROGRESS |
| UC2 | API Automation    | pytest-bdd, requests, psycopg2 | NOT STARTED |
| UC3 | UI Automation     | pytest-bdd, Playwright         | NOT STARTED |
| UC4 | Pipeline Testing  | PySpark, pytest, GX            | NOT STARTED |
| UC5 | CI/CD             | GitHub Actions                 | NOT STARTED |

> UC5 replaces Jenkins (no Docker) with GitHub Actions workflows under `.github/workflows/`.

---

## 6. UC1 — Detailed Spec (Current Focus)

### What must be built

1. GX Expectation Suites for all 4 tables (`customers`, `accounts`, `transactions`, `loans`)
2. A GX Checkpoint that runs all 4 suites in one command
3. `tests/dq/run_gx.py` — standalone trigger script
4. `tests/dq/test_great_expectations.py` — pytest wrapper so `pytest` can invoke it
5. Data Docs HTML reports generated for both good and bad data runs

### Two proof runs required

- **Good data run:** pipeline loaded `good_data` → all expectations PASS
- **Bad data run:** pipeline loaded `bad_data` → specific expectations FAIL (proves rules work)

### GX connection to PostgreSQL

```python
# Pattern — always construct from env vars, never hardcode
import os
connection_string = (
    f"postgresql+psycopg2://{os.getenv('PGUSER', 'admin')}:"
    f"{os.getenv('PGPASSWORD', 'fincore123')}@"
    f"{os.getenv('PGHOST', 'localhost')}:"
    f"{os.getenv('PGPORT', '5432')}/"
    f"{os.getenv('PGDATABASE', 'fincore')}"
)
```

### Expectation categories per table

Each suite must cover these categories at minimum:

| Category              | Example expectation                                   |
|-----------------------|-------------------------------------------------------|
| Row count             | expect_table_row_count_to_be_between                  |
| Column existence      | expect_column_to_exist                                |
| Not null              | expect_column_values_to_not_be_null                   |
| Uniqueness            | expect_column_values_to_be_unique (PKs)               |
| Value range           | expect_column_values_to_be_between (amounts, dates)   |
| Regex / format        | expect_column_values_to_match_regex (email, phone)    |
| Referential integrity | expect_column_values_to_be_in_set (status enums)      |
| Computed fields       | expect_column_values_to_not_be_null (loan_duration)   |

> Tip: inspect the actual column names first with `\d tablename` in psql before writing any suite.

---

## 7. The Four Working Principles

These are non-negotiable. They apply to every file, every session, every UC.

---

### Principle 1 — Think Before Coding

Before writing any test code, answer these questions:

- What is the exact schema of the table? (Run `\d tablename` in psql first)
- What does the column actually contain? (Sample 5 rows before writing a regex)
- What is the expected behaviour for good data vs bad data?
- Does a simpler assertion cover this, or do I genuinely need a custom expectation?

**In practice for UC1:** Never write an expectation for a column you haven't seen real data for.
Connect to the DB, run `SELECT * FROM customers LIMIT 5;` before writing the customers suite.

---

### Principle 2 — Simplicity First

Use the simplest tool that solves the problem. Do not reach for complexity until the simple
approach provably fails.

- Use built-in GX expectations before writing custom ones
- Use a single Checkpoint file before building a multi-stage orchestration
- Use a flat `conftest.py` before introducing fixtures hierarchies
- Use `subprocess.run` in run_gx.py before building a full CLI wrapper

**In practice for UC1:** The GX SQLAlchemy datasource + standard expectations covers everything
in this project. No custom expectation classes needed.

---

### Principle 3 — Surgical Changes

Only touch what the task requires. Every file created must have a reason.

- Never modify `app/`, `pipeline/`, `data/`, `db/` — those are the system under test
- Never add debug prints or temp files and forget to remove them
- Each commit should do exactly one thing and be describable in one line
- When fixing a failing expectation, fix only that expectation — do not refactor the whole suite

**In practice:** If a GX suite fails to connect to PostgreSQL, fix the connection string.
Do not rewrite the entire suite file.

---

### Principle 4 — Goal-Driven Execution

Every action maps to a UC deliverable. If it doesn't, don't do it.

The deliverables for UC1 are:
- [ ] `customers_suite.json` exists and runs clean against good_data
- [ ] `accounts_suite.json` exists and runs clean against good_data
- [ ] `transactions_suite.json` exists and runs clean against good_data
- [ ] `loans_suite.json` exists and runs clean against good_data
- [ ] `fincore_checkpoint.yml` runs all 4 suites in one command
- [ ] `run_gx.py` executes the checkpoint and exits 0 on pass, 1 on fail
- [ ] `test_great_expectations.py` passes under `pytest`
- [ ] Data Docs report generated for good_data run (all green)
- [ ] Data Docs report generated for bad_data run (shows failures)
- [ ] All files committed to `tests/dq/` in the repo

When a deliverable is done, tick it off here and move to the next one. No scope creep.

---

## 8. Current Status

```
Session date    : [update each session]
Codespace state : devcontainer config committed, Codespace not yet opened
Pipeline state  : not run yet
UC1 state       : not started — waiting for Codespace verification
```

### Last action taken
- Created `.devcontainer/devcontainer.json`
- Created `.devcontainer/setup.sh`
- Created `tests/.gitkeep`
- Created this file (`claude.md`)

### Next action
Open Codespace on main → let setup.sh complete → verify environment → run pipeline with
good_data → confirm 4 tables exist in PostgreSQL → begin UC1 Suite 1 (customers).

---

## 9. Session Log

| Session | Date | What was done | What is next |
|---------|------|---------------|--------------|
| 1 | 2026-05-02 | Devcontainer config created. claude.md created. Codespace not yet opened. | Open Codespace, verify env, run pipeline |

> Add a new row at the start of every session. Keep entries short — one line per session.

---

## 10. Key Decisions Made

| Decision | Reason |
|----------|--------|
| GitHub Codespaces over Docker | Docker not available on training machines |
| GitHub Actions for UC5 | Replaces Jenkins — no server needed, same YAML logic |
| Playwright for UC3 | Native headless in Codespaces, no display server needed |
| GX 0.18.x (not 1.x) | Onboarding doc specifies 0.18+; 1.x has breaking API changes |
| tests/ as sole workspace | Onboarding doc rule: never modify the system under test |

---

*Keep this file up to date. An outdated claude.md is worse than no claude.md.*