// Proxy: GET /api/twitcasting/live?user_id=xxx
// Returns current live movie_id for a user
export default async function handler(req, res) {
  const { user_id } = req.query;
  if (!user_id) {
    return res.status(400).json({ error: "user_id is required" });
  }

  const clientId = process.env.TWITCASTING_CLIENT_ID;
  const clientSecret = process.env.TWITCASTING_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    return res.status(500).json({ error: "Server credentials not configured" });
  }

  const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  try {
    const response = await fetch(
      `https://apiv2.twitcasting.tv/users/${encodeURIComponent(user_id)}/current_live`,
      {
        headers: {
          "Authorization": `Basic ${basicAuth}`,
          "Accept": "application/json",
        },
      }
    );

    const data = await response.json();

    if (response.status === 404) {
      return res.status(404).json({ error: "not_live", message: "配信中ではありません" });
    }
    if (!response.ok) {
      return res.status(response.status).json({ error: "api_error", message: data });
    }

    return res.status(200).json({
      movie_id: String(data.movie?.id || ""),
      title: data.movie?.title || "",
      subtitle: data.movie?.subtitle || "",
    });
  } catch (e) {
    return res.status(500).json({ error: "fetch_error", message: e.message });
  }
}
