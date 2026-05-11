"""
Standalone trigger for the FinCore GX checkpoint.
Exits 0 on all suites passing, 1 on any failure.

Usage:
    python run_gx.py            # good_data run  → reports written to tests/reports/dq_good/
    python run_gx.py --bad      # bad_data run   → reports written to tests/reports/dq_bad/
    GX_RUN_MODE=bad python run_gx.py  # same via env var
"""
import os
import shutil
import sys
import pathlib

import great_expectations as gx


GX_ROOT = pathlib.Path(__file__).parent / "gx"
REPORTS_ROOT = pathlib.Path(__file__).parent.parent / "reports"


def _build_connection_string() -> str:
    return (
        f"postgresql+psycopg2://{os.getenv('PGUSER', 'admin')}:"
        f"{os.getenv('PGPASSWORD', 'fincore123')}@"
        f"{os.getenv('PGHOST', 'localhost')}:"
        f"{os.getenv('PGPORT', '5432')}/"
        f"{os.getenv('PGDATABASE', 'fincore')}"
    )


def _is_bad_run() -> bool:
    return "--bad" in sys.argv or os.getenv("GX_RUN_MODE", "").lower() == "bad"


def run_checkpoint() -> bool:
    context = gx.get_context(context_root_dir=str(GX_ROOT))

    # Inject the live connection string so the YAML env-var substitution works
    # even when the shell vars are not exported (e.g. during pytest runs).
    datasource_config = context.get_datasource("fincore_postgres")
    datasource_config.execution_engine.connection_string = _build_connection_string()

    result = context.run_checkpoint(checkpoint_name="fincore_checkpoint")

    context.build_data_docs()

    # Copy the generated local_site into the run-specific report directory.
    local_site_path = GX_ROOT / "uncommitted" / "data_docs" / "local_site"
    dest_dir = REPORTS_ROOT / ("dq_bad" if _is_bad_run() else "dq_good")
    if local_site_path.exists():
        if dest_dir.exists():
            shutil.rmtree(dest_dir)
        shutil.copytree(str(local_site_path), str(dest_dir))

    return result.success


def main() -> None:
    success = run_checkpoint()
    report_label = "dq_bad" if _is_bad_run() else "dq_good"
    if success:
        print(f"GX checkpoint PASSED — all suites green. Report: tests/reports/{report_label}/index.html")
        sys.exit(0)
    else:
        print(f"GX checkpoint FAILED — one or more suites have failures. Report: tests/reports/{report_label}/index.html")
        sys.exit(1)


if __name__ == "__main__":
    main()
