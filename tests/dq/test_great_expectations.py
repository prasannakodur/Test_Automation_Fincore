"""
pytest wrapper for the FinCore GX checkpoint.
Running `pytest tests/dq/test_great_expectations.py` triggers all 4 suites
and reports a single pass/fail result.
"""
import importlib
import pathlib
import sys

import pytest


# Ensure run_gx is importable regardless of working directory
sys.path.insert(0, str(pathlib.Path(__file__).parent))


def test_fincore_data_quality_checkpoint():
    """All four GX expectation suites must pass against the loaded data."""
    run_gx = importlib.import_module("run_gx")
    success = run_gx.run_checkpoint()
    assert success, (
        "GX checkpoint failed — one or more expectation suites have violations. "
        "Open tests/dq/reports/index.html for the full Data Docs report."
    )
