// Proxy: GET /api/twitcasting/comments?movie_id=xxx&since_id=0
// Returns comments for a live movie
export default async function handler(req, res) {
  const { movie_id, since_id } = req.query;
  if (!movie_id) {
    return res.status(400).json({ error: "movie_id is required" });
  }

  const token = process.env.TWITCASTING_TOKEN;
  if (!token) {
    return res.status(500).json({ error: "Server token not configured" });
  }

  try {
    let url = `https://apiv2.twitcasting.tv/movies/${encodeURIComponent(movie_id)}/comments`;
    if (since_id) {
      url += `?since_id=${encodeURIComponent(since_id)}`;
    }

    const response = await fetch(url, {
      headers: {
        "Authorization": `Bearer ${token}`,
        "Accept": "application/json",
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({ error: "api_error" });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (e) {
    return res.status(500).json({ error: "fetch_error", message: e.message });
  }
}
