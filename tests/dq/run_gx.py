"""
Standalone trigger for the FinCore GX checkpoint.
Exits 0 on all suites passing, 1 on any failure.
"""
import os
import sys
import pathlib

import great_expectations as gx


GX_ROOT = pathlib.Path(__file__).parent / "gx"


def _build_connection_string() -> str:
    return (
        f"postgresql+psycopg2://{os.getenv('PGUSER', 'admin')}:"
        f"{os.getenv('PGPASSWORD', 'fincore123')}@"
        f"{os.getenv('PGHOST', 'localhost')}:"
        f"{os.getenv('PGPORT', '5432')}/"
        f"{os.getenv('PGDATABASE', 'fincore')}"
    )


def run_checkpoint() -> bool:
    context = gx.get_context(context_root_dir=str(GX_ROOT))

    # Inject the live connection string so the YAML env-var substitution works
    # even when the shell vars are not exported (e.g. during pytest runs).
    datasource_config = context.get_datasource("fincore_postgres")
    datasource_config.execution_engine.connection_string = _build_connection_string()

    result = context.run_checkpoint(checkpoint_name="fincore_checkpoint")

    context.build_data_docs()

    return result.success


def main() -> None:
    success = run_checkpoint()
    if success:
        print("GX checkpoint PASSED — all suites green.")
        sys.exit(0)
    else:
        print("GX checkpoint FAILED — one or more suites have failures.")
        sys.exit(1)


if __name__ == "__main__":
    main()
