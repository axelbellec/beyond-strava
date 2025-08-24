#!/usr/bin/env -S deno run --allow-net --allow-read --allow-write --allow-run

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_at: number;
  token_type: string;
}

async function loadEnvFile(): Promise<Record<string, string>> {
  const env: Record<string, string> = {};

  try {
    const envContent = await Deno.readTextFile(".env");
    for (const line of envContent.split("\n")) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith("#") && trimmed.includes("=")) {
        const [key, ...valueParts] = trimmed.split("=");
        env[key] = valueParts.join("=");
      }
    }
  } catch (error) {
    console.log("⚠️ Could not read .env file:", error instanceof Error ? error.message : String(error));
  }

  return env;
}

async function exchangeCodeForTokens(authCode: string, env: Record<string, string>): Promise<boolean> {
  try {
    const clientId = env.STRAVA_CLIENT_ID || Deno.env.get("STRAVA_CLIENT_ID");
    const clientSecret = env.STRAVA_CLIENT_SECRET || Deno.env.get("STRAVA_CLIENT_SECRET");

    if (!clientId || !clientSecret) {
      console.log("❌ Missing STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET");
      return false;
    }

    const response = await fetch("https://www.strava.com/oauth/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        code: authCode,
        grant_type: "authorization_code",
      }),
    });

    if (response.ok) {
      const tokens: TokenResponse = await response.json();

      console.log("\n✅ Success! New tokens obtained.");
      console.log("Update your .env file with:");
      console.log(`STRAVA_REFRESH_TOKEN=${tokens.refresh_token}`);

      // Fetch activities with new token
      await fetchActivities(tokens.access_token);
      return true;
    } else {
      const errorText = await response.text();
      console.log(`❌ Token exchange failed: ${errorText}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Error exchanging token: ${error instanceof Error ? error.message : String(error)}`);
    return false;
  }
}

async function fetchActivities(accessToken: string): Promise<void> {
  try {
    // First, fetch athlete info to get username
    console.log("👤 Fetching athlete information...");
    const athleteResponse = await fetch("https://www.strava.com/api/v3/athlete", {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!athleteResponse.ok) {
      const errorText = await athleteResponse.text();
      console.log(`❌ Failed to fetch athlete info: ${errorText}`);
      return;
    }

    const athlete = await athleteResponse.json();
    const username = athlete.username || athlete.firstname || "unknown";
    console.log(`   Athlete: ${athlete.firstname} ${athlete.lastname} (${username})`);

    const allActivities = [];
    let page = 1;
    const perPage = 200; // Maximum allowed by Strava API

    console.log("📥 Fetching all activities...");

    while (true) {
      console.log(`   Page ${page}...`);

      const response = await fetch(
        `https://www.strava.com/api/v3/athlete/activities?per_page=${perPage}&page=${page}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        console.log(`❌ Failed to fetch activities: ${errorText}`);
        return;
      }

      const activities = await response.json();

      // If no activities returned, we've reached the end
      if (activities.length === 0) {
        break;
      }

      allActivities.push(...activities);
      console.log(`   Got ${activities.length} activities (total: ${allActivities.length})`);

      // If we got less than perPage activities, we've reached the end
      if (activities.length < perPage) {
        break;
      }

      page++;

      // Add a small delay to be nice to Strava's API
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Ensure activities directory exists
    try {
      await Deno.mkdir("activities", { recursive: true });
    } catch (error) {
      // Directory might already exist, which is fine
    }

    // Save all activities to file with new naming pattern
    const today = new Date().toISOString().split('T')[0]; // yyyy-mm-dd format
    const filename = `activities/${username}_${today}_export.json`;
    await Deno.writeTextFile(filename, JSON.stringify(allActivities, null, 2));
    console.log(`✅ ${allActivities.length} total activities saved to ${filename}`);

    // Show summary by sport type
    const sportSummary = allActivities.reduce((acc, activity) => {
      const sportType = activity.sport_type || activity.type;
      acc[sportType] = (acc[sportType] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    console.log("\n📊 Activity summary by sport type:");
    Object.entries(sportSummary)
      .sort(([, a], [, b]) => (b as number) - (a as number))
      .forEach(([sport, count]) => {
        console.log(`   ${sport}: ${count}`);
      });

  } catch (error) {
    console.log(`❌ Error fetching activities: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function handleRequest(request: Request, env: Record<string, string>): Promise<Response> {
  const url = new URL(request.url);

  if (url.pathname === "/" && url.searchParams.has("code")) {
    const authCode = url.searchParams.get("code")!;

    // Exchange code for tokens
    const success = await exchangeCodeForTokens(authCode, env);

    if (success) {
      const htmlResponse = `
        <html>
        <body>
        <h2>Authorization successful!</h2>
        <p>You can close this window. Your activities are being fetched...</p>
        <script>setTimeout(() => window.close(), 3000);</script>
        </body>
        </html>
      `;

      return new Response(htmlResponse, {
        status: 200,
        headers: { "Content-Type": "text/html" },
      });
    } else {
      return new Response("<h2>Authorization failed</h2>", {
        status: 400,
        headers: { "Content-Type": "text/html" },
      });
    }
  } else {
    return new Response("<h2>No authorization code received</h2>", {
      status: 400,
      headers: { "Content-Type": "text/html" },
    });
  }
}

async function openBrowser(url: string): Promise<void> {
  try {
    const os = Deno.build.os;
    let cmd: string[];

    switch (os) {
      case "darwin":
        cmd = ["open", url];
        break;
      case "linux":
        cmd = ["xdg-open", url];
        break;
      case "windows":
        cmd = ["cmd", "/c", "start", url];
        break;
      default:
        console.log(`📱 Please open this URL manually: ${url}`);
        return;
    }

    const process = new Deno.Command(cmd[0], {
      args: cmd.slice(1),
      stdout: "null",
      stderr: "null",
    });

    await process.output();
  } catch (error) {
    console.log(`📱 Could not open browser automatically. Please open: ${url}`);
    console.log(`Error: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function main(): Promise<void> {
  // Load environment variables
  const env = await loadEnvFile();
  const clientId = env.STRAVA_CLIENT_ID || Deno.env.get("STRAVA_CLIENT_ID");

  if (!clientId) {
    console.log("❌ STRAVA_CLIENT_ID not found in .env file or environment");
    return;
  }

  const port = 8000;
  console.log(`🚀 Starting auth server on http://localhost:${port}`);

  // Create auth URL
  const authUrl = `https://www.strava.com/oauth/authorize?client_id=${clientId}&response_type=code&redirect_uri=http://localhost:${port}&approval_prompt=force&scope=read,activity:read_all`;

  console.log("📱 Opening browser for authorization...");
  await openBrowser(authUrl);

  console.log("⏳ Waiting for authorization callback...");

  // Create server that handles one request and then shuts down
  const abortController = new AbortController();
  const serverShutdown = () => abortController.abort();

  const handler = async (request: Request): Promise<Response> => {
    const response = await handleRequest(request, env);

    // Shutdown server after handling the request
    setTimeout(() => {
      serverShutdown();
      console.log("🎉 Done!");
      Deno.exit(0);
    }, 1000);

    return response;
  };

  Deno.serve({
    port,
    signal: abortController.signal,
  }, handler);
}

if (import.meta.main) {
  await main();
}
