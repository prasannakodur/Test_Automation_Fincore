# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project

FinCore Bank — Test Automation Training Programme. Build a complete test automation framework against a realistic banking simulation. Training project, not production.
Repo: https://github.com/prasannakodur/Test_Automation_Fincore

**Sole workspace: `tests/` only. Never create or modify files inside `app/`, `data/`, `db/`, or `pipeline/` — those are the read-only System Under Test.**

---

## Use Cases

| UC | Name | Tools | Status |
|---|---|---|---|
| UC1 | Data Quality | Great Expectations 0.18.x, pytest | IN PROGRESS |
| UC2 | API Automation | pytest-bdd, requests, psycopg2 | NOT STARTED |
| UC3 | UI Automation | pytest-bdd, Playwright | NOT STARTED |
| UC4 | Pipeline Testing | PySpark, pytest, GX | NOT STARTED |
| UC5 | CI/CD | GitHub Actions (replaces Jenkins — no Docker server needed) | NOT STARTED |

UC1 (good_data) must pass before running UC2 or UC3. GX is the quality gate — if it fails, downstream tests must not run.

---

## Environment (GitHub Codespaces — Ubuntu 22.04, no Docker)

`setup.sh` auto-provisions on first launch: PostgreSQL 15, Python 3.11 venv at `pipeline/venv/`, Node.js 20, base test deps (pytest, great-expectations, psycopg2-binary, pytest-html).

**Every session:**
```bash
sudo service postgresql start
```

**Load data (truncates and reloads all 4 tables):**
```bash
cd pipeline && source venv/bin/activate && bash run_pipeline.sh good_data && cd ..  # all GX must PASS
cd pipeline && source venv/bin/activate && bash run_pipeline.sh bad_data && cd ..   # specific GX must FAIL
```

**Start API + UI (UC2, UC3):**
```bash
bash start-app.sh   # API: http://localhost:4000/api/v1  |  Swagger: /api/docs  |  UI: http://localhost:3000
```

---

## Running Tests

```bash
pip install -r tests/requirements.txt              # first time only

python tests/dq/run_gx.py                          # UC1 standalone, exit 0/1
pytest tests/dq/test_great_expectations.py -v      # UC1 via pytest
pytest tests/api/   --html=tests/reports/api_report.html -v
pytest tests/ui/    --html=tests/reports/ui_report.html -v
pytest tests/pipeline/ --html=tests/reports/pipeline_report.html -v

pytest tests/api/test_customers.py -v -k "test_get_customer_by_id"  # single test
```

---

## Architecture

```
CSV files (data/good_data or bad_data)
    → pipeline/ingest.py  (PySpark: reads, transforms, loads)
    → PostgreSQL 15  (db: fincore, 4 tables)
    → app/src/  (Node.js REST API, port 4000)
    → app/client/  (React 18 UI, port 3000)
```

### PostgreSQL Schema (exact column names — verify with `SELECT * FROM <table> LIMIT 5` before writing expectations)

| Table | Rows | Exact column names |
|---|---|---|
| customers | 10,000 | id, name (UPPERCASE), email (UNIQUE NOT NULL), phone, date_of_birth, status, kyc_verified |
| accounts | 25,000 | id, customer_id (FK), account_number (UNIQUE NOT NULL), account_type, balance, currency, status, opened_date |
| transactions | 500,000 | id, account_id (FK), transaction_type, amount (>0), currency, transaction_date (≤now), status, reference_id (UNIQUE) |
| loans | 8,000 | id, customer_id (FK), loan_type, principal_amount, outstanding_amount (NOT NULL), interest_rate (1–30), start_date, end_date (>start), status, loan_duration_days (computed), emi_amount (computed) |

Enum values — `customers.status`: active/inactive/blocked · `accounts.account_type`: savings/current/fixed_deposit · `accounts.status`: active/dormant/closed · `transactions.transaction_type`: credit/debit/transfer · `transactions.status`: completed/pending/failed/reversed · `loans.loan_type`: home/personal/auto/education · `loans.status`: active/closed/defaulted/restructured

### Pipeline Transformations (`pipeline/transformations.py` — UC4 unit test targets)
`standardise_name` (→ UPPERCASE) · `standardise_date` (dd/MM/yyyy → DATE) · `compute_loan_duration` (end−start days) · `compute_emi` (EMI formula) · `map_status_code` (int → string label) · `fill_default_currency` (NULL → USD) · `filter_zero_amounts` (drop ≤0) · `trim_all_strings` · `remove_duplicates`

### API Endpoints (JWT bearer required on all except health + login)
`POST /auth/login` → JWT · `GET /health` · `GET /customers` (status, page, limit, search) · `GET /customers/:id` (+ accounts + txns) · `GET /accounts` (customer_id, status, type) · `GET /transactions` (account_id, type, status, from_date, to_date, min/max_amount) · `GET /loans` (customer_id, status, type, page) · `GET /loans/:id` (incl. loan_duration_days, emi_amount) · `GET /dashboard/summary`

### Test Workspace
```
tests/
├── conftest.py                      — db_engine (SQLAlchemy, session-scoped), api_base_url
├── requirements.txt                 — pinned deps
├── dq/gx/great_expectations.yml    — GX config, PostgreSQL datasource via env vars
├── dq/gx/expectations/             — 4 suite JSON files
├── dq/gx/checkpoints/fincore_checkpoint.yml
├── dq/run_gx.py                    — standalone runner, sys.exit(0/1)
├── dq/test_great_expectations.py   — pytest wrapper
├── api/features/  api/steps/       — UC2: Gherkin + step defs
├── ui/features/   ui/steps/        — UC3: Playwright headless
├── pipeline/test_transformations.py  pipeline/test_e2e.py
└── reports/dq_good/  reports/dq_bad/  reports/*.html
```

---

## Constraints & Working Rules

**Credentials — always construct from env vars, never hardcode:**
```python
connection_string = (
    f"postgresql+psycopg2://{os.getenv('PGUSER','admin')}:{os.getenv('PGPASSWORD','fincore123')}"
    f"@{os.getenv('PGHOST','localhost')}:{os.getenv('PGPORT','5432')}/{os.getenv('PGDATABASE','fincore')}"
)
```

| Service | Host | Port | DB | User | Password |
|---|---|---|---|---|---|
| PostgreSQL | localhost | 5432 | fincore | admin | fincore123 |
| API | localhost | 4000 | — | — | — |
| UI | localhost | 3000 | — | admin | Admin@123 |

**GX version: 0.18.x only** — 1.x has breaking API changes. Context root: `tests/dq/gx/`. Suite files target `"great_expectations_version": "0.18.15"`.

**Simplicity first** — use built-in GX expectations before writing custom classes; flat `conftest.py` before fixture hierarchies; `subprocess.run` before CLI wrappers.

**Think before writing expectations** — always sample actual data before writing a regex or range check. Run `SELECT * FROM <table> LIMIT 5;` first.

**UI selectors** — all React portal elements have `data-testid` attributes; use those, never CSS classes or text content.

---

## UC1 Expectation Categories (every suite must cover all 8)

| Category | Expectation type |
|---|---|
| Row count | `expect_table_row_count_to_be_between` |
| Column existence | `expect_column_to_exist` |
| Not null | `expect_column_values_to_not_be_null` |
| Uniqueness | `expect_column_values_to_be_unique` |
| Value range | `expect_column_values_to_be_between` (amounts, dates) |
| Format / regex | `expect_column_values_to_match_regex` (email, phone) |
| Enum / referential | `expect_column_values_to_be_in_set` (status fields) |
| Computed fields | not_be_null + be_between on loan_duration_days, emi_amount |

---

## UC1 Open Gaps (required by training spec, not yet in code)

- `customers_suite.json` — `be_between` on `date_of_birth` (max = today, no future DOBs)
- `customers_suite.json` — phone regex too permissive; must be digits only, 7–15 chars: `^\d{7,15}$`
- `transactions_suite.json` — `be_between` on `transaction_date` (max = now, no future dates)
- `transactions_suite.json` — `reference_id` uniqueness: remove `"mostly": 1.0`; must be strict
- `loans_suite.json` — `not_be_null` on `outstanding_amount` (missing entirely)
- `loans_suite.json` — `expect_column_pair_values_A_to_be_greater_than_B` for `end_date` > `start_date`
- `run_gx.py` — Data Docs must write to `tests/reports/dq_good/` or `tests/reports/dq_bad/` per run, not one shared dir

## UC1 Deliverable Checklist

- [ ] `customers_suite.json` runs clean against good_data
- [ ] `accounts_suite.json` runs clean against good_data
- [ ] `transactions_suite.json` runs clean against good_data
- [ ] `loans_suite.json` runs clean against good_data
- [ ] `fincore_checkpoint.yml` runs all 4 suites in one command
- [ ] `run_gx.py` exits 0 on pass, 1 on fail
- [ ] `test_great_expectations.py` passes under `pytest`
- [ ] Data Docs good_data report saved to `tests/reports/dq_good/` (all green)
- [ ] Data Docs bad_data report saved to `tests/reports/dq_bad/` (failures visible)

---

## Key Decisions

| Decision | Reason |
|---|---|
| GitHub Codespaces, not Docker | Docker not available on training machines |
| GitHub Actions for UC5 | Replaces Jenkins — no Docker server needed, same YAML logic |
| Playwright for UC3 | Native headless in Codespaces, no display server needed |
| GX 0.18.x not 1.x | Training spec pins 0.18+; 1.x has breaking API changes |
| `tests/dq/gx/` as GX root | Deliberate deviation from PDF spec (`tests/dq/great_expectations/`) — functionally equivalent |
