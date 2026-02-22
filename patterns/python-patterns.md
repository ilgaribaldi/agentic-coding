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
            'SELECT * FROM "<table>" WHERE "<fk-column>" = %s AND "<flag>" = %s',
            (<fk_value>, True)
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
        INSERT INTO "<table>" ("id", "<col-a>", "<col-b>", "<col-c>")
        VALUES %s
        ON CONFLICT ("<col-a>", "<col-c>")
        DO UPDATE SET "<col-b>" = EXCLUDED."<col-b>"
        RETURNING "id"
    '''

    with self._conn() as conn:
        with conn.cursor() as cur:
            for start in range(0, len(records), batch_size):
                batch = records[start:start + batch_size]

                data_tuples = [
                    (
                        str(uuid.uuid4()),
                        row["<col-a>"],
                        row["<col-b>"],
                        row["<col-c>"],
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

class <Model>(db.Model):
    __tablename__ = "<table>"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255), nullable=False)
    coordinates = db.Column(Geography("POINT", srid=4326))
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())

    # Relationships
    records = relationship("<RelatedModel>", back_populates="<parent>")
```

### Query Patterns

```python
# Filtered query with ordering
results = (
    db.session.query(<Model>)
    .filter(
        <Model>.granularity == "<GRANULARITY>",
        <Model>.variable.in_(["<var-a>", "<var-b>"]),
        <Model>.<dim> == <dim_value>,
        <Model>.time >= start_dt,
        <Model>.time < end_dt,
    )
    .order_by(<Model>.time)
    .all()
)

# Aggregate query
latest = (
    db.session.query(<ModelA>, <ModelB>)
    .filter(<ModelB>.<fk> == <ModelA>.id)
    .filter(<ModelB>.status == 1)
    .order_by(<ModelB>.create_time.desc())
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
class <Domain>Factory:
    """Route to correct model class based on type."""

    @staticmethod
    def get_table(kind: str, scope: str | None):
        if kind == "<kind-a>":
            if scope == "<scope-a>":
                return <VariantA>
            if scope == "<scope-b>":
                return <VariantB>
            if scope == "<scope-c>":
                return <VariantC>
        elif kind == "<kind-b>":
            return <VariantD>
        elif kind == "<kind-c>":
            return <VariantE>
        raise ValueError(f"Unknown dataset: kind={kind}, scope={scope}")
```

## Service Pattern

```python
class <Domain>Service:
    """Service encapsulating business logic."""

    def __init__(self, session=None):
        self.session = session or db.session

    def get_data(self, <param-a>: float, <param-b>: float, variables: list[str]) -> dict:
        """Fetch data with caching and fallback logic."""
        # 1. Check cache
        cached = self._check_cache(<param-a>, <param-b>, variables)
        if cached:
            return cached

        # 2. Query database
        results = self._query_db(<param-a>, <param-b>, variables)

        # 3. Format response
        return self._format_response(results)
```

## Caching (Flask-Caching)

```python
from flask_caching import Cache

# Granularity-specific cache instances
caches = {
    "<category-a>": Cache(config={"CACHE_DIR": "./cache/<category-a>"}),
    "<category-b>": Cache(config={"CACHE_DIR": "./cache/<category-b>"}),
    "default": Cache(config={"CACHE_DIR": "./cache/default"}),
}

class CachingLayer:
    def __init__(self, dataset, granularity, request_url, cache_key):
        self.cache_key = f"{cache_key}_{granularity}"
        self.cache = caches.get(self.cache_key, caches["default"])

    def process_response(self, <param-a>, <param-b>, variables, response_format):
        """Check cache, fetch if miss, store result."""
        cached = self.cache.get(self.request_url)
        if cached:
            return cached
        result = self._fetch_fresh(<param-a>, <param-b>, variables)
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

    with patch("<module>.psycopg2.connect") as mock_connect:
        mock_connect.return_value.__enter__ = lambda s: mock_conn
        mock_connect.return_value.__exit__ = MagicMock(return_value=False)
        yield mock_cursor

@pytest.fixture
def sample_data():
    """Reusable test data."""
    return [
        {"id": "<id-1>", "<field-a>": <value-a>, "<field-b>": <value-b>},
        {"id": "<id-2>", "<field-a>": <value-c>, "<field-b>": <value-d>},
    ]
```

### Test Pattern

```python
def test_get_<resources>(mock_db, sample_data):
    """Test <resource> retrieval."""
    mock_db.fetchall.return_value = [
        (d["id"], d["<field-a>"], d["<field-b>"]) for d in sample_data
    ]
    mock_db.description = [("id",), ("<field-a>",), ("<field-b>",)]

    result = client.get_<resources>("<resource-id>")

    assert len(result) == 2
    assert result[0]["id"] == "<id-1>"
    mock_db.execute.assert_called_once()
```

## Connection Reinit Pattern

```python
def run_all(items: list[dict], connection_string: str, n_jobs: int):
    """Process items with fresh connection per item."""
    for item in items:
        # Reinit to avoid stale connections between long-running tasks
        client = <Client>(connection_string, verbose=False)

        try:
            process(item["id"], client, n_jobs)
        except Exception as e:
            logging.error(f"Failed {item['id']}: {e}")
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
