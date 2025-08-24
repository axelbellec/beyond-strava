#!/usr/bin/env python3
"""
Strava Activity Analysis with DuckDB

Loads Strava activity data into DuckDB for analysis and visualization.
"""

import json
from pathlib import Path
from typing import List, Dict, Any

import duckdb


class StravaAnalyzer:
    """Analyzes Strava activities using DuckDB."""

    def __init__(self, db_path: str = "strava_activities.duckdb"):
        self.db_path = db_path
        self.conn = duckdb.connect(db_path)

    def create_tables(self) -> None:
        """Create the necessary tables for Strava data."""
        print("📊 Creating database tables...")

        # Main activities table
        self.conn.execute("""
            CREATE OR REPLACE TABLE activities (
                id BIGINT PRIMARY KEY,
                name VARCHAR,
                distance DOUBLE,
                moving_time INTEGER,
                elapsed_time INTEGER,
                total_elevation_gain DOUBLE,
                type VARCHAR,
                sport_type VARCHAR,
                workout_type INTEGER,
                start_date TIMESTAMP,
                start_date_local TIMESTAMP,
                timezone VARCHAR,
                utc_offset INTEGER,
                location_city VARCHAR,
                location_state VARCHAR,
                location_country VARCHAR,
                achievement_count INTEGER,
                kudos_count INTEGER,
                comment_count INTEGER,
                athlete_count INTEGER,
                photo_count INTEGER,
                trainer BOOLEAN,
                commute BOOLEAN,
                manual BOOLEAN,
                private BOOLEAN,
                flagged BOOLEAN,
                gear_id VARCHAR,
                start_latitude DOUBLE,
                start_longitude DOUBLE,
                end_latitude DOUBLE,
                end_longitude DOUBLE,
                average_speed DOUBLE,
                max_speed DOUBLE,
                average_cadence DOUBLE,
                average_temp INTEGER,
                average_watts DOUBLE,
                max_watts INTEGER,
                weighted_average_watts INTEGER,
                device_watts BOOLEAN,
                kilojoules DOUBLE,
                has_heartrate BOOLEAN,
                average_heartrate DOUBLE,
                max_heartrate INTEGER,
                elev_high DOUBLE,
                elev_low DOUBLE,
                upload_id BIGINT,
                external_id VARCHAR,
                pr_count INTEGER,
                total_photo_count INTEGER,
                suffer_score INTEGER
            )
        """)

        # Athlete information table
        self.conn.execute("""
            CREATE OR REPLACE TABLE athletes (
                id INTEGER PRIMARY KEY,
                resource_state INTEGER
            )
        """)

        # Map polylines table (separate due to potentially large size)
        self.conn.execute("""
            CREATE OR REPLACE TABLE activity_maps (
                activity_id BIGINT,
                map_id VARCHAR,
                summary_polyline TEXT,
                resource_state INTEGER,
                FOREIGN KEY (activity_id) REFERENCES activities(id)
            )
        """)

        print("✅ Database tables created")

    def load_json_data(self, json_file: Path) -> None:
        """Load Strava activities from JSON file into DuckDB."""
        print(f"📥 Loading data from {json_file}...")

        if not json_file.exists():
            print(f"❌ File {json_file} does not exist")
            return

        with open(json_file, "r") as f:
            activities = json.load(f)

        print(f"   Found {len(activities)} activities")

        # Process activities
        for activity in activities:
            self._insert_activity(activity)

        print(f"✅ Loaded {len(activities)} activities into database")

    def _insert_activity(self, activity: Dict[str, Any]) -> None:
        """Insert a single activity into the database."""
        # Extract start/end coordinates
        start_lat = start_lon = end_lat = end_lon = None
        if activity.get("start_latlng"):
            start_lat, start_lon = activity["start_latlng"]
        if activity.get("end_latlng"):
            end_lat, end_lon = activity["end_latlng"]

        # Insert main activity
        self.conn.execute(
            """
            INSERT INTO activities VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?, ?, ?
            )
        """,
            [
                activity.get("id"),
                activity.get("name"),
                activity.get("distance"),
                activity.get("moving_time"),
                activity.get("elapsed_time"),
                activity.get("total_elevation_gain"),
                activity.get("type"),
                activity.get("sport_type"),
                activity.get("workout_type"),
                activity.get("start_date"),
                activity.get("start_date_local"),
                activity.get("timezone"),
                activity.get("utc_offset"),
                activity.get("location_city"),
                activity.get("location_state"),
                activity.get("location_country"),
                activity.get("achievement_count"),
                activity.get("kudos_count"),
                activity.get("comment_count"),
                activity.get("athlete_count"),
                activity.get("photo_count"),
                activity.get("trainer"),
                activity.get("commute"),
                activity.get("manual"),
                activity.get("private"),
                activity.get("flagged"),
                activity.get("gear_id"),
                start_lat,
                start_lon,
                end_lat,
                end_lon,
                activity.get("average_speed"),
                activity.get("max_speed"),
                activity.get("average_cadence"),
                activity.get("average_temp"),
                activity.get("average_watts"),
                activity.get("max_watts"),
                activity.get("weighted_average_watts"),
                activity.get("device_watts"),
                activity.get("kilojoules"),
                activity.get("has_heartrate"),
                activity.get("average_heartrate"),
                activity.get("max_heartrate"),
                activity.get("elev_high"),
                activity.get("elev_low"),
                activity.get("upload_id"),
                activity.get("external_id"),
                activity.get("pr_count"),
                activity.get("total_photo_count"),
                activity.get("suffer_score"),
            ],
        )

        # Insert athlete if present
        if "athlete" in activity:
            athlete = activity["athlete"]
            self.conn.execute(
                """
                INSERT OR IGNORE INTO athletes VALUES (?, ?)
            """,
                [athlete.get("id"), athlete.get("resource_state")],
            )

        # Insert map data if present
        if "map" in activity and activity["map"]:
            map_data = activity["map"]
            self.conn.execute(
                """
                INSERT INTO activity_maps VALUES (?, ?, ?, ?)
            """,
                [
                    activity.get("id"),
                    map_data.get("id"),
                    map_data.get("summary_polyline"),
                    map_data.get("resource_state"),
                ],
            )

    def get_activity_summary(self) -> Dict[str, Any]:
        """Get summary statistics of all activities."""
        print("📊 Generating activity summary...")

        # Basic counts
        total_activities = self.conn.execute(
            "SELECT COUNT(*) FROM activities"
        ).fetchone()[0]

        # Sport type breakdown
        sport_breakdown = self.conn.execute("""
            SELECT sport_type, COUNT(*) as count
            FROM activities 
            WHERE sport_type IS NOT NULL
            GROUP BY sport_type 
            ORDER BY count DESC
        """).fetchall()

        # Distance and time totals
        totals = self.conn.execute("""
            SELECT 
                ROUND(SUM(distance)/1000, 2) as total_km,
                ROUND(SUM(moving_time)/3600, 2) as total_hours,
                ROUND(SUM(total_elevation_gain), 2) as total_elevation_m,
                COUNT(*) as activity_count
            FROM activities
            WHERE distance IS NOT NULL
        """).fetchone()

        # Date range
        date_range = self.conn.execute("""
            SELECT 
                MIN(start_date) as first_activity,
                MAX(start_date) as last_activity
            FROM activities
            WHERE start_date IS NOT NULL
        """).fetchone()

        return {
            "total_activities": total_activities,
            "sport_breakdown": sport_breakdown,
            "totals": {
                "distance_km": totals[0],
                "moving_time_hours": totals[1],
                "elevation_gain_m": totals[2],
                "count": totals[3],
            },
            "date_range": {"first": date_range[0], "last": date_range[1]},
        }

    def get_monthly_summary(self) -> List[Dict[str, Any]]:
        """Get monthly activity summary."""
        return self.conn.execute("""
            SELECT 
                strftime('%Y-%m', start_date) as month,
                sport_type,
                COUNT(*) as activities,
                ROUND(SUM(distance)/1000, 2) as total_km,
                ROUND(SUM(moving_time)/3600, 2) as total_hours,
                ROUND(AVG(average_heartrate), 1) as avg_hr
            FROM activities
            WHERE start_date IS NOT NULL
            GROUP BY month, sport_type
            ORDER BY month DESC, activities DESC
        """).fetchall()

    def get_personal_records(self) -> Dict[str, Any]:
        """Get personal records across different metrics."""
        return {
            "longest_distance": self.conn.execute("""
                SELECT name, distance/1000 as km, start_date, sport_type 
                FROM activities 
                WHERE distance IS NOT NULL 
                ORDER BY distance DESC 
                LIMIT 1
            """).fetchone(),
            "longest_time": self.conn.execute("""
                SELECT name, moving_time/3600 as hours, start_date, sport_type 
                FROM activities 
                WHERE moving_time IS NOT NULL 
                ORDER BY moving_time DESC 
                LIMIT 1
            """).fetchone(),
            "highest_elevation": self.conn.execute("""
                SELECT name, total_elevation_gain as elevation_m, start_date, sport_type 
                FROM activities 
                WHERE total_elevation_gain IS NOT NULL 
                ORDER BY total_elevation_gain DESC 
                LIMIT 1
            """).fetchone(),
            "max_heartrate": self.conn.execute("""
                SELECT name, max_heartrate, start_date, sport_type 
                FROM activities 
                WHERE max_heartrate IS NOT NULL 
                ORDER BY max_heartrate DESC 
                LIMIT 1
            """).fetchone(),
        }

    def print_summary(self) -> None:
        """Print a comprehensive summary of the activities."""
        summary = self.get_activity_summary()

        print("\n🏃 Strava Activity Summary")
        print(f"{'=' * 50}")
        print(f"📊 Total Activities: {summary['total_activities']}")
        print(f"🏃 Total Distance: {summary['totals']['distance_km']:.1f} km")
        print(f"⏱️  Total Time: {summary['totals']['moving_time_hours']:.1f} hours")
        print(f"⛰️  Total Elevation: {summary['totals']['elevation_gain_m']:.0f} m")

        if summary["date_range"]["first"]:
            first_date = str(summary["date_range"]["first"])[:10]
            last_date = str(summary["date_range"]["last"])[:10]
            print(f"📅 Date Range: {first_date} to {last_date}")

        print("\n🏃 Activity Types:")
        for sport_type, count in summary["sport_breakdown"]:
            print(f"   {sport_type}: {count}")

        # Personal records
        print("\n🏆 Personal Records:")
        records = self.get_personal_records()

        if records["longest_distance"]:
            name, km, date, sport = records["longest_distance"]
            date_str = str(date)[:10]
            print(f"   Longest Distance: {km:.1f} km - {name} ({sport}, {date_str})")

        if records["longest_time"]:
            name, hours, date, sport = records["longest_time"]
            date_str = str(date)[:10]
            print(f"   Longest Time: {hours:.1f} hours - {name} ({sport}, {date_str})")

        if records["highest_elevation"]:
            name, elevation, date, sport = records["highest_elevation"]
            date_str = str(date)[:10]
            print(
                f"   Highest Elevation: {elevation:.0f} m - {name} ({sport}, {date_str})"
            )

    def close(self) -> None:
        """Close the database connection."""
        if self.conn:
            self.conn.close()


def main() -> None:
    """Main entry point."""
    # Find the most recent activity export file
    activities_dir = Path("activities")

    if not activities_dir.exists():
        print("❌ Activities directory not found. Run fetch.py first.")
        return

    json_files = list(activities_dir.glob("*_export.json"))

    if not json_files:
        print("❌ No activity export files found. Run fetch.py first.")
        return

    # Use the most recent file
    latest_file = max(json_files, key=lambda f: f.stat().st_mtime)
    print(f"📁 Using activity file: {latest_file}")

    # Initialize analyzer
    analyzer = StravaAnalyzer()

    try:
        # Create tables and load data
        analyzer.create_tables()
        analyzer.load_json_data(latest_file)

        # Print summary
        analyzer.print_summary()

        print(f"\n💾 Database saved as: {analyzer.db_path}")
        print("🔍 You can now query the data using DuckDB CLI or any SQL client")

    finally:
        analyzer.close()


if __name__ == "__main__":
    main()
