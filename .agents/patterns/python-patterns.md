# Python Patterns

## Database Access (psycopg2 Raw SQL)

### Connection Context Manager

```python
from contextlib import contextmanager
import psycopg2

@contextmanager
def _conn(self):
    """Open a psycopg2 connection with keepalives and timeouts."""
    conn = None
    try:
        conn = psycopg2.connect(
            self.connection_string,
            connect_timeout=10,
            keepalives=1,
            keepalives_idle=30,
            keepalives_interval=10,
            keepalives_count=3,
        )
        conn.autocommit = False
        with conn.cursor() as cur:
            cur.execute("SET statement_timeout = %s", (60000,))
        yield conn
    finally:
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass
```

### Read with Retry

```python
def _should_retry(self, error: Exception) -> bool:
    """Identify transient DB errors that should trigger retry."""
    if not isinstance(error, psycopg2.OperationalError):
        return False
    message = str(error).lower()
    retry_tokens = [
        "server closed the connection unexpectedly",
        "ssl syscall error", "ssl error", "eof detected",
        "connection not open",
        "terminating connection due to administrator command",
    ]
    return any(token in message for token in retry_tokens)

def _run_read(self, operation):
    """Run read with one automatic retry on transient disconnects."""
    try:
        return operation()
    except psycopg2.OperationalError as e:
        if self._should_retry(e):
            logging.warning(f"Transient DB error, retrying: {e}")
            return operation()
        raise
```

### Parameterized Queries

```python
# ALWAYS use parameterized queries — never string formatting
with self._conn() as conn:
    with conn.cursor() as cur:
        cur.execute(
            'SELECT * FROM "location" WHERE "modelId" = %s AND "active" = %s',
            (model_id, True)
        )
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        return [dict(zip(columns, row)) for row in rows]
```

### Dynamic Identifiers (Safe)

```python
from psycopg2 import sql

# For dynamic table/column names, use sql.Identifier
query = sql.SQL("SELECT {fields} FROM {table} WHERE {key} = %s").format(
    fields=sql.SQL(", ").join([sql.Identifier(f) for f in field_names]),
    table=sql.Identifier(table_name),
    key=sql.Identifier(key_column),
)
cur.execute(query, (value,))
```

## Batch Inserts (execute_values)

```python
from psycopg2.extras import execute_values
import uuid

def add_records(self, records: list[dict], batch_size: int = 50000):
    """Batch insert with ON CONFLICT upsert."""
    insert_query = '''
        INSERT INTO "myTable" ("id", "name", "value", "time")
        VALUES %s
        ON CONFLICT ("name", "time")
        DO UPDATE SET "value" = EXCLUDED."value"
        RETURNING "id"
    '''

    with self._conn() as conn:
        with conn.cursor() as cur:
            for start in range(0, len(records), batch_size):
                batch = records[start:start + batch_size]

                data_tuples = [
                    (
                        str(uuid.uuid4()),
                        row["name"],
                        row["value"],
                        row["time"],
                    )
                    for row in batch
                ]

                result = execute_values(cur, insert_query, data_tuples, fetch=True)
                conn.commit()
                logging.info(f"Inserted {len(result)} rows")
```

- `execute_values` is 3-4x faster than `executemany()` or individual inserts
- Use `page_size` parameter for very large batches (default 100)
- Always commit after each batch to avoid holding locks

## Database Access (SQLAlchemy ORM)

### Declarative Models

```python
from flask_sqlalchemy import SQLAlchemy
from geoalchemy2 import Geography
from sqlalchemy.orm import relationship

db = SQLAlchemy()

class Location(db.Model):
    __tablename__ = "locations"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255), nullable=False)
    coordinates = db.Column(Geography("POINT", srid=4326))
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())

    # Relationships
    records = relationship("SensorData", back_populates="location")
```

### Query Patterns

```python
# Filtered query with ordering
results = (
    db.session.query(SensorData)
    .filter(
        SensorData.granularity == "DAILY",
        SensorData.variable.in_(["metric_a", "metric_b"]),
        SensorData.lat_idx == lat_idx,
        SensorData.time >= start_dt,
        SensorData.time < end_dt,
    )
    .order_by(SensorData.time)
    .all()
)

# Aggregate query
latest_version = (
    db.session.query(ResourceAttributes, ResourceVersion)
    .filter(ResourceVersion.attributes_key == ResourceAttributes.id)
    .filter(ResourceVersion.status == 1)
    .order_by(ResourceVersion.create_time.desc())
    .first()
)
```

## HTTP Client with Retry

```python
import requests
import time

def _make_request_with_retry(
    self,
    method: str,
    endpoint: str,
    json_data: dict | None = None,
    max_retries: int = 3,
    base_retry_delay: float = 1.0,
) -> dict:
    """HTTP request with exponential backoff on retryable errors."""
    for attempt in range(max_retries + 1):
        try:
            response = requests.request(
                method,
                f"{self.base_url}/{endpoint}",
                json=json_data,
                headers={"x-api-key": self.api_key},
                timeout=self.timeout,
            )
            response.raise_for_status()
            return response.json()

        except requests.exceptions.HTTPError as e:
            if e.response and e.response.status_code in [429, 503]:
                if attempt < max_retries:
                    delay = base_retry_delay * (2 ** attempt)
                    logging.warning(
                        f"HTTP {e.response.status_code} on attempt "
                        f"{attempt + 1}/{max_retries + 1}. Retrying in {delay:.1f}s"
                    )
                    time.sleep(delay)
                    continue
            raise

        except requests.exceptions.RequestException as e:
            if attempt < max_retries:
                delay = base_retry_delay * (2 ** attempt)
                logging.warning(f"Connection error, retrying in {delay:.1f}s: {e}")
                time.sleep(delay)
                continue
            raise
```

## Parallel Processing (ThreadPoolExecutor)

```python
from concurrent.futures import ThreadPoolExecutor, as_completed

def process_items_parallel(
    self,
    items: list[dict],
    max_workers: int | None = None,
) -> list[dict]:
    """Process items in parallel with configurable concurrency."""
    if not items:
        return []

    if max_workers is None:
        max_workers = min(2 * len(items), 20)

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_map = {
            executor.submit(self.process_item, item): item
            for item in items
        }

        results = []
        for future in as_completed(future_map):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                item = future_map[future]
                logging.error(f"Failed to process {item}: {e}")

    return results
```

## Factory Pattern

```python
class DatasetFactory:
    """Route to correct model class based on dataset type."""

    @staticmethod
    def get_table(kind: str, scope: str | None):
        if kind == "forecast":
            if scope == "short_term":
                return ShortTermForecast
            if scope == "long_term":
                return LongTermForecast
            if scope == "composite":
                return CompositeForecast
        elif kind == "baseline":
            return Baseline
        elif kind == "historical":
            return Historical
        raise ValueError(f"Unknown dataset: kind={kind}, scope={scope}")
```

## Service Pattern

```python
class DataService:
    """Service encapsulating business logic."""

    def __init__(self, session=None):
        self.session = session or db.session

    def get_data(self, lat: float, lon: float, variables: list[str]) -> dict:
        """Fetch data with caching and fallback logic."""
        # 1. Check cache
        cached = self._check_cache(lat, lon, variables)
        if cached:
            return cached

        # 2. Query database
        results = self._query_db(lat, lon, variables)

        # 3. Format response
        return self._format_response(results)
```

## Caching (Flask-Caching)

```python
from flask_caching import Cache

# Granularity-specific cache instances
caches = {
    "baseline_daily": Cache(config={"CACHE_DIR": "./cache/baseline_daily"}),
    "historical_daily": Cache(config={"CACHE_DIR": "./cache/historical_daily"}),
    "default": Cache(config={"CACHE_DIR": "./cache/default"}),
}

class CachingLayer:
    def __init__(self, dataset, granularity, request_url, cache_key):
        self.cache_key = f"{cache_key}_{granularity}"
        self.cache = caches.get(self.cache_key, caches["default"])

    def process_response(self, lat, lon, variables, response_format):
        """Check cache, fetch if miss, store result."""
        cached = self.cache.get(self.request_url)
        if cached:
            return cached
        result = self._fetch_fresh(lat, lon, variables)
        self.cache.set(self.request_url, result)
        return result
```

## Testing (pytest)

### Mock Database Fixtures

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_db():
    """Mock database for unit tests."""
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value.__enter__ = lambda s: mock_cursor
    mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)

    with patch("mymodule.psycopg2.connect") as mock_connect:
        mock_connect.return_value.__enter__ = lambda s: mock_conn
        mock_connect.return_value.__exit__ = MagicMock(return_value=False)
        yield mock_cursor

@pytest.fixture
def sample_data():
    """Reusable test data."""
    return [
        {"id": "loc-1", "lat": 40.7, "lon": -74.0},
        {"id": "loc-2", "lat": 34.0, "lon": -118.2},
    ]
```

### Test Pattern

```python
def test_get_locations(mock_db, sample_data):
    """Test location retrieval."""
    mock_db.fetchall.return_value = [
        (d["id"], d["lat"], d["lon"]) for d in sample_data
    ]
    mock_db.description = [("id",), ("latitude",), ("longitude",)]

    result = agent.get_locations("model-123")

    assert len(result) == 2
    assert result[0]["id"] == "loc-1"
    mock_db.execute.assert_called_once()
```

## Connection Reinit Pattern

```python
def run_all_models(models: list[dict], connection_string: str, n_jobs: int):
    """Process models with fresh connection per model."""
    for model in models:
        # Reinit to avoid stale connections between long-running models
        agent = Agent(connection_string, verbose=False)

        try:
            run_model(model["id"], agent, n_jobs)
        except Exception as e:
            logging.error(f"Failed {model['id']}: {e}")
            continue
```

## Docs

- [psycopg2](https://www.psycopg.org/docs/)
- [psycopg2 extras (execute_values)](https://www.psycopg.org/docs/extras.html)
- [psycopg2 sql composition](https://www.psycopg.org/docs/sql.html)
- [SQLAlchemy 2.0](https://docs.sqlalchemy.org/en/20/)
- [SQLAlchemy Session Basics](https://docs.sqlalchemy.org/en/20/orm/session_basics.html)
- [GeoAlchemy2](https://geoalchemy-2.readthedocs.io/en/stable/)
- [Flask-Caching](https://flask-caching.readthedocs.io/)
- [pytest](https://docs.pytest.org/)
- [requests](https://docs.python-requests.org/)
