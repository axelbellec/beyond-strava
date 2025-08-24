# Beyond Strava

A personal tool to fetch and analyze my Strava activities using the Strava API with OAuth2 authentication.

## Why I Built This

I wanted to get the most out of my training data. Strava gives you the basics, but there's so much more buried in those activity files. By pulling all my data locally, I can dig deeper, run custom analysis, build visualizations that actually matter to me, and discover insights that the standard apps just don't show.

## Setup

1. Create a Strava app: https://www.strava.com/settings/api
2. Get your client ID and secret
3. Get your refresh token
4. Create a `.env` file with your Strava app credentials:

```bash
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
STRAVA_REFRESH_TOKEN=your_refresh_token  # Will be updated after first auth
```

## How to Run

The workflow is the following:

1. `uv run fetch.py` → fetches activities from Strava API
2. `uv run analyze.py` → processes the JSON data into DuckDB database
3. `duckdb strava_activities.duckdb -f queries/<query-name>.sql` → runs analysis queries

> **Note:** Re-run `uv run analyze.py` whenever you fetch new activities to update your DuckDB database with the latest data.

**What it does:**

- Launches a local auth server on http://localhost:8000
- Opens your browser automatically for Strava authorization
- Handles the OAuth callback seamlessly
- **Fetches ALL your historical activities** (using pagination)
- Saves everything to `activities/<username>_yyyy-mm-dd_export.json` with a nice summary breakdown
- Stores activities in a DuckDB database for fast querying

## What You Need

- **uv** (recommended) or **Python 3.11+** installed on your machine
- **DuckDB** for database queries and UI
- A Strava API app (free to create)
- Your Strava credentials in a `.env` file

## What You Get

Your activities get saved to `activities/<username>_yyyy-mm-dd_export.json` with all the juicy details:

- **Performance metrics**: Distance, time, elevation, pace/speed
- **Physiological data**: Heart rate zones, power output, cadence
- **Route data**: GPS coordinates, polyline for mapping
- **Activity metadata**: Kudos, photos, gear used, weather conditions

Perfect for building your own analysis dashboards, tracking progress, or feeding into ML models for performance insights.

## Database Analysis

Your activities are stored in a DuckDB database (`strava_activities.duckdb`) for fast querying. Pre-built queries are organized by sport for personalized analysis:

- `queries/global/` - Overall activity analysis
- `queries/running/` - Running and trail running specific analysis  
- `queries/strength/` - CrossFit and weight training analysis

Run any query with:
```bash
duckdb strava_activities.duckdb -f queries/<folder>/<query-name>.sql
```

Or launch the DuckDB web UI for interactive exploration:
```bash
duckdb -ui strava_activities.duckdb
```

## Common Issues

- **Port 8000 busy?** The app will tell you - just kill whatever's using it
- **Browser won't open?** Copy the authorization URL manually
- **Empty activities?** Check your Strava privacy settings and API permissions
