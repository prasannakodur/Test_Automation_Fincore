import os
import pytest
import sqlalchemy


@pytest.fixture(scope="session")
def db_engine():
    connection_string = (
        f"postgresql+psycopg2://{os.getenv('PGUSER', 'admin')}:"
        f"{os.getenv('PGPASSWORD', 'fincore123')}@"
        f"{os.getenv('PGHOST', 'localhost')}:"
        f"{os.getenv('PGPORT', '5432')}/"
        f"{os.getenv('PGDATABASE', 'fincore')}"
    )
    engine = sqlalchemy.create_engine(connection_string)
    yield engine
    engine.dispose()


@pytest.fixture(scope="session")
def api_base_url():
    host = os.getenv("API_HOST", "localhost")
    port = os.getenv("API_PORT", "4000")
    return f"http://{host}:{port}/api/v1"
