# Data Science Patterns

## xarray & Zarr (Scientific Data)

### Loading from S3

```python
import xarray as xr

# Lazy load from Zarr store on S3
ds = xr.open_zarr(
    "s3://bucket/path/dataset.zarr",
    consolidated=True,
)
# Data loads lazily — computation deferred until .compute() or .values

# With explicit credentials
ds = xr.open_zarr(
    "s3://bucket/path/dataset.zarr",
    storage_options={"anon": False},  # Uses AWS credentials from environment
)
```

### Dataset Stitching Pipeline

Combine multiple data sources along the time dimension (e.g., reanalysis → blended → short-range forecast → long-range forecast → climatology):

```python
def get_inference_dataset(self) -> xr.Dataset:
    """Stitch: source_a → blended → forecast_short → forecast_long → climatology."""

    source_a = self.get_source_a(start_date="2000-01-01")
    blended = self.get_blended()
    forecast_short = self.get_forecast_short()
    forecast_long = self.get_forecast_long()
    climatology = self.get_climatology()  # Climatology backfill

    # Expand ensemble members to match (N members)
    source_a_expanded = xr.concat([blended_combined] * N_MEMBERS, dim="member")
    forecast_short_expanded = self._expand_ensemble_members(forecast_short, members_to_add=20)

    # Stack along time axis
    stitched = xr.concat(
        [source_a_expanded, forecast_short_expanded, forecast_long, climatology],
        dim="time",
    )

    return stitched  # Shape: (member=N, number=locations, time=days)
```

### NaN Handling

```python
def _check_nan_ratio(ds: xr.Dataset, threshold: float = 0.1) -> bool:
    """Check if NaN ratio is acceptable."""
    for var in ds.data_vars:
        nan_ratio = float(ds[var].isnull().mean().values)
        if nan_ratio > threshold:
            return False
    return True

def _forward_fill_dataset(ds: xr.Dataset) -> xr.Dataset:
    """Forward fill NaNs along time dimension."""
    ds_filled = ds.copy(deep=True)
    for var in ds.data_vars:
        ds_filled[var] = ds[var].ffill(dim="time")
    return ds_filled
```

### Temporal Operations

```python
# Time slicing
ds_slice = ds.sel(time=slice("2020-01", "2024-12"))

# Monthly resampling
monthly_mean = ds.resample(time="M").mean()

# Seasonal groupby
seasonal = ds.groupby("time.season").mean()

# Point selection (nearest neighbor)
point = ds.sel(lat=40.0, lon=-105.0, method="nearest")

# Bounding box
region = ds.sel(lat=slice(30, 50), lon=slice(-120, -100))
```

### Writing

```python
# Local
ds.to_zarr("output.zarr", mode="w")

# Append along time
ds_new.to_zarr("output.zarr", mode="a", append_dim="time")

# Cloud
ds.to_zarr("s3://bucket/output.zarr", storage_options={...})
```

## Lazy Loading with Caching

```python
from dataclasses import dataclass, field

@dataclass
class DataEngine:
    """Lazy data loader with in-memory caching."""

    s3_path: str
    _cache: dict = field(default_factory=dict, repr=False)

    def get_source_a(self, start_date: str | None = None) -> xr.Dataset:
        """Load source_a data, cached after first access."""
        cache_key = f"source_a_{start_date}"
        if cache_key not in self._cache:
            ds = xr.open_zarr(f"{self.s3_path}/source_a.zarr")
            if start_date:
                ds = ds.sel(time=slice(start_date, None))
            self._cache[cache_key] = ds
        return self._cache[cache_key]
```

## NumPy Risk Computation

### Tensor Organization

Standard shape for risk tensors: `(member, number, time, season)`

- `member`: Ensemble members (N members — set by the ensemble source used)
- `number`: Locations
- `time`: Days within season
- `season`: Historical seasons (e.g., 20 years)

### Rolling Aggregations (cumsum trick)

```python
import numpy as np

def rolling_sum(values: np.ndarray, window: int, axis: int = 2) -> np.ndarray:
    """Efficient rolling sum using cumulative sum."""
    cumsum = np.cumsum(values, axis=axis)
    # Subtract shifted cumsum to get rolling window
    slices_after = [slice(None)] * values.ndim
    slices_before = [slice(None)] * values.ndim
    slices_after[axis] = slice(window, None)
    slices_before[axis] = slice(None, -window)
    return cumsum[tuple(slices_after)] - cumsum[tuple(slices_before)]

def rolling_mean(values: np.ndarray, window: int = 5, axis: int = 2) -> np.ndarray:
    """5-day rolling mean using cumsum trick."""
    pad_width = [(0, 0)] * values.ndim
    pad_width[axis] = (window - 1, 0)
    padded = np.pad(values, pad_width, mode="constant", constant_values=0)
    cumsum = np.cumsum(padded, axis=axis)

    slices_after = [slice(None)] * padded.ndim
    slices_before = [slice(None)] * padded.ndim
    slices_after[axis] = slice(window, None)
    slices_before[axis] = slice(None, -window)
    return (cumsum[tuple(slices_after)] - cumsum[tuple(slices_before)]) / window
```

### Threshold-Based Index

```python
def heat_index(tensor: np.ndarray, threshold: float) -> np.ndarray:
    """Exceedance above threshold. Shape: (member, number, time, season)."""
    return np.maximum(tensor - threshold, 0)

def drought_index(wb_current: np.ndarray, wb_reference: np.ndarray) -> np.ndarray:
    """Water balance deficit (historical - current, clipped to positive)."""
    wb_ref_expanded = wb_reference[..., np.newaxis]  # Broadcast for season dim
    deficit = wb_ref_expanded - wb_current
    return np.clip(deficit, a_min=0, a_max=None)
```

### Sigmoid Weighting for Time Periods

```python
def weight_func(
    period_length: int,
    start_slope: float = 20,
    end_slope: float = 20,
    start_inflection: float = 0.2,
    end_inflection: float = 0.8,
) -> np.ndarray:
    """Sigmoid curve: high at inflection points, low at edges.

    Useful for weighting values within a period so that mid-period
    observations carry more influence than those near the boundaries.
    """
    lvp = min(period_length, 365)
    fraction = np.arange(0, lvp + 1, 1) / lvp
    weights = 1 / (
        1
        + np.exp(-start_slope * (fraction - start_inflection))
        + np.exp(end_slope * (fraction - end_inflection))
    )
    return weights
```

### Percentile Ranking

```python
from scipy import stats

def percentile_rank(
    current: np.ndarray,
    historical: np.ndarray,
) -> np.ndarray:
    """Rank current values against historical distribution."""
    # current: (members, locations, days)
    # historical: (seasons, locations, days)

    result = np.zeros_like(current)
    for loc in range(current.shape[1]):
        for day in range(current.shape[2]):
            ref = historical[:, loc, day]
            curr = current[:, loc, day]
            result[:, loc, day] = stats.percentileofscore(
                ref, curr, kind="rank", nan_policy="propagate"
            )
    return result
```

### Member Aggregation (Quantiles)

```python
def aggregate_members(
    risk: np.ndarray,
    risk_bounds: tuple[float, float] = (70, 90),
    quantile_bounds: tuple[float, float] = (0.05, 0.95),
) -> dict:
    """Aggregate ensemble members using quantiles and probability bins."""
    lower, upper = np.nanquantile(risk, quantile_bounds)
    total = len(risk)

    return {
        "percentile_mean": float(np.nanmean(risk)),
        "percentile_lower": float(lower),
        "percentile_upper": float(upper),
        "high_prob": float((risk > risk_bounds[1]).sum() / total),
        "mid_prob": float(
            ((risk >= risk_bounds[0]) & (risk <= risk_bounds[1])).sum() / total
        ),
        "low_prob": float((risk < risk_bounds[0]).sum() / total),
    }
```

## Parallel Processing (joblib)

```python
from joblib import Parallel, delayed

def process_categories(categories: list[str], model, n_jobs: int = 1) -> dict:
    """Process multiple categories in parallel."""
    results_list = Parallel(n_jobs=n_jobs)(
        delayed(model.process_category)(category) for category in categories
    )
    return dict(zip(categories, results_list))
```

- `n_jobs=1`: Sequential (debug mode)
- `n_jobs=-1`: Use all CPU cores
- `n_jobs=-2`: All cores except one
- Default backend `loky` (process-based) is best for CPU-bound NumPy work
- Use `backend="threading"` for I/O-bound or GIL-releasing operations

## Date & Period Utilities

```python
from datetime import datetime
import pandas as pd

def get_period_dates(
    periods: list[dict],
    reference_date: datetime | None = None,
) -> dict:
    """Compute start/end dates for a sequence of periods relative to reference date.

    Each period dict must have: name, position, startMonth, startDay, endMonth, endDay.
    The first (lowest position) and last (highest position) periods define the
    overall date range.
    """
    if reference_date is None:
        reference_date = pd.Timestamp.now().normalize()

    first = min(periods, key=lambda s: s["position"])
    last = max(periods, key=lambda s: s["position"])

    end_year = reference_date.year
    end_date = datetime(end_year, last["endMonth"], last["endDay"])

    if reference_date > end_date:
        end_year += 1
        end_date = datetime(end_year, last["endMonth"], last["endDay"])

    start_year = end_year - (1 if first["startMonth"] > last["endMonth"] else 0)
    start_date = datetime(start_year, first["startMonth"], first["startDay"])

    return {
        "start_date": start_date.strftime("%Y-%m-%d"),
        "end_date": end_date.strftime("%Y-%m-%d"),
    }

def get_historical_period_dates(
    period_dates: dict,
    num_years: int = 20,
) -> list[dict]:
    """Generate past N periods (oldest to newest)."""
    start = datetime.strptime(period_dates["start_date"], "%Y-%m-%d")
    end = datetime.strptime(period_dates["end_date"], "%Y-%m-%d")

    return [
        {
            "start_date": start.replace(year=start.year - i).strftime("%Y-%m-%d"),
            "end_date": end.replace(year=end.year - i).strftime("%Y-%m-%d"),
        }
        for i in range(num_years, 0, -1)
    ]
```

## DataFrame → Database Upload

```python
def parse_results_to_db(
    model_id: str,
    results: dict,
    agent,
) -> list[dict]:
    """Convert computation results to database payload format."""
    records = []

    for _, row in results["historical"].iterrows():
        records.append({
            "modelId": model_id,
            "categoryId": agent.get_category(row["category_name"])["id"],
            "value": float(row["value"]),
            "time": f"{int(row['year'])}-01-01",
            "type": "SEASONAL",
            "probHigh": float(row["high_prob"]),
            "probMid": float(row["mid_prob"]),
            "probLow": float(row["low_prob"]),
        })

    return records
```

## Docs

- [xarray](https://docs.xarray.dev/en/stable/)
- [xarray I/O (Zarr)](https://docs.xarray.dev/en/stable/user-guide/io.html)
- [xarray Time Series](https://docs.xarray.dev/en/stable/user-guide/time-series.html)
- [Zarr](https://zarr.readthedocs.io/)
- [NumPy](https://numpy.org/doc/stable/)
- [SciPy Stats](https://docs.scipy.org/doc/scipy/reference/stats.html)
- [joblib Parallel](https://joblib.readthedocs.io/en/stable/parallel.html)
- [pandas](https://pandas.pydata.org/docs/)
- [s3fs](https://s3fs.readthedocs.io/)
