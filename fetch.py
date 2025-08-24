#!/usr/bin/env python3
"""
Strava Activity Fetcher

A modern Python script to authenticate with Strava API and fetch all activities.
Uses httpx for async HTTP requests and follows Python best practices.
"""

import asyncio
import json
import os
import webbrowser
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import urlencode

import httpx
from aiohttp import web


class StravaFetcher:
    """Handles Strava API authentication and activity fetching."""

    def __init__(self, client_id: str, client_secret: str, port: int = 8000):
        self.client_id = client_id
        self.client_secret = client_secret
        self.port = port
        self.redirect_uri = f"http://localhost:{port}"

    async def exchange_code_for_tokens(
        self, auth_code: str
    ) -> Optional[Dict[str, Any]]:
        """Exchange authorization code for access tokens."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://www.strava.com/oauth/token",
                    data={
                        "client_id": self.client_id,
                        "client_secret": self.client_secret,
                        "code": auth_code,
                        "grant_type": "authorization_code",
                    },
                )
                response.raise_for_status()
                tokens = response.json()

                print("\n✅ Success! New tokens obtained.")
                print("Update your .env file with:")
                print(f"STRAVA_REFRESH_TOKEN={tokens['refresh_token']}")
                os.environ["STRAVA_REFRESH_TOKEN"] = tokens["refresh_token"]

                return tokens

        except httpx.HTTPStatusError as e:
            print(f"❌ Token exchange failed: {e.response.text}")
        except Exception as e:
            print(f"❌ Error exchanging token: {e}")

        return None

    async def fetch_athlete_info(self, access_token: str) -> Optional[Dict[str, Any]]:
        """Fetch athlete information."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://www.strava.com/api/v3/athlete",
                    headers={"Authorization": f"Bearer {access_token}"},
                )
                response.raise_for_status()
                return response.json()

        except httpx.HTTPStatusError as e:
            print(f"❌ Failed to fetch athlete info: {e.response.text}")
        except Exception as e:
            print(f"❌ Error fetching athlete info: {e}")

        return None

    async def fetch_all_activities(self, access_token: str) -> List[Dict[str, Any]]:
        """Fetch all activities using pagination."""
        all_activities = []
        page = 1
        per_page = 200  # Maximum allowed by Strava API

        print("📥 Fetching all activities...")

        async with httpx.AsyncClient() as client:
            while True:
                print(f"   Page {page}...")

                try:
                    response = await client.get(
                        "https://www.strava.com/api/v3/athlete/activities",
                        headers={"Authorization": f"Bearer {access_token}"},
                        params={"per_page": per_page, "page": page},
                    )
                    response.raise_for_status()
                    activities = response.json()

                    # If no activities returned, we've reached the end
                    if not activities:
                        break

                    all_activities.extend(activities)
                    print(
                        f"   Got {len(activities)} activities (total: {len(all_activities)})"
                    )

                    # If we got less than per_page activities, we've reached the end
                    if len(activities) < per_page:
                        break

                    page += 1

                    # Add a small delay to be nice to Strava's API
                    await asyncio.sleep(0.1)

                except httpx.HTTPStatusError as e:
                    print(f"❌ Failed to fetch activities: {e.response.text}")
                    break
                except Exception as e:
                    print(f"❌ Error fetching activities: {e}")
                    break

        return all_activities

    def save_activities(self, activities: List[Dict[str, Any]], username: str) -> Path:
        """Save activities to JSON file with timestamp."""
        # Ensure activities directory exists
        activities_dir = Path("activities")
        activities_dir.mkdir(exist_ok=True)

        # Create filename with current date
        today = datetime.now().strftime("%Y-%m-%d")
        filename = activities_dir / f"{username}_{today}_export.json"

        # Save activities
        with open(filename, "w") as f:
            json.dump(activities, f, indent=2)

        print(f"✅ {len(activities)} total activities saved to {filename}")
        return filename

    def print_activity_summary(self, activities: List[Dict[str, Any]]) -> None:
        """Print summary of activities by sport type."""
        sport_summary = Counter()
        for activity in activities:
            sport_type = activity.get("sport_type") or activity.get("type", "Unknown")
            sport_summary[sport_type] += 1

        print("\n📊 Activity summary by sport type:")
        for sport, count in sport_summary.most_common():
            print(f"   {sport}: {count}")

    async def handle_auth_callback(self, request: web.Request) -> web.Response:
        """Handle OAuth callback from Strava."""
        code = request.query.get("code")

        if not code:
            return web.Response(
                text="<h2>No authorization code received</h2>",
                content_type="text/html",
                status=400,
            )

        # Exchange code for tokens
        tokens = await self.exchange_code_for_tokens(code)

        if not tokens:
            return web.Response(
                text="<h2>Authorization failed</h2>",
                content_type="text/html",
                status=400,
            )

        # Fetch activities with new token
        await self.process_activities(tokens["access_token"])

        html_response = """
        <html>
        <body>
        <h2>Authorization successful!</h2>
        <p>You can close this window. Your activities are being fetched...</p>
        <script>setTimeout(() => window.close(), 3000);</script>
        </body>
        </html>
        """

        return web.Response(text=html_response, content_type="text/html")

    async def process_activities(self, access_token: str) -> None:
        """Process activities: fetch athlete info and all activities."""
        # Fetch athlete info
        print("👤 Fetching athlete information...")
        athlete = await self.fetch_athlete_info(access_token)

        if not athlete:
            return

        username = athlete.get("username") or athlete.get("firstname") or "unknown"
        print(
            f"   Athlete: {athlete.get('firstname', '')} {athlete.get('lastname', '')} ({username})"
        )

        # Fetch all activities
        activities = await self.fetch_all_activities(access_token)

        if activities:
            # Save activities
            self.save_activities(activities, username)

            # Show summary
            self.print_activity_summary(activities)

    def create_auth_url(self) -> str:
        """Create Strava authorization URL."""
        params = {
            "client_id": self.client_id,
            "response_type": "code",
            "redirect_uri": self.redirect_uri,
            "approval_prompt": "force",
            "scope": "read,activity:read_all",
        }
        return f"https://www.strava.com/oauth/authorize?{urlencode(params)}"

    def open_browser(self, url: str) -> None:
        """Open browser for authorization."""
        try:
            webbrowser.open(url)
        except Exception as e:
            print(f"📱 Could not open browser automatically. Please open: {url}")
            print(f"Error: {e}")

    async def start_auth_server(self) -> None:
        """Start the OAuth callback server."""
        app = web.Application()
        app.router.add_get("/", self.handle_auth_callback)

        print(f"🚀 Starting auth server on http://localhost:{self.port}")

        # Create auth URL and open browser
        auth_url = self.create_auth_url()
        print("📱 Opening browser for authorization...")
        self.open_browser(auth_url)
        print("⏳ Waiting for authorization callback...")

        # Start server
        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, "localhost", self.port)
        await site.start()

        # Keep server running until we get a callback
        # In a real scenario, you'd want to add a timeout or manual shutdown
        try:
            await asyncio.Future()  # Run forever
        except KeyboardInterrupt:
            print("\n🛑 Interrupted by user")
        finally:
            await runner.cleanup()


async def main() -> None:
    """Main entry point."""
    # Get environment variables (use uv run --env-file .env)
    client_id = os.getenv("STRAVA_CLIENT_ID")
    client_secret = os.getenv("STRAVA_CLIENT_SECRET")

    if not client_id or not client_secret:
        print("❌ STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET not found")
        print("💡 Run with: uv run --env-file .env fetch.py")
        return

    # Create fetcher with proper credentials
    fetcher = StravaFetcher(client_id, client_secret)

    try:
        await fetcher.start_auth_server()
    except KeyboardInterrupt:
        print("\n🎉 Done!")


if __name__ == "__main__":
    asyncio.run(main())
