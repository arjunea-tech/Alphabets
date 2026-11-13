/**
 * Shared in-memory cache for public content GETs (letters, games, videos, quizzes, stories...).
 *
 * These lists are the same for every student, so with 100 students opening the app
 * the database is hit once per TTL instead of once per student per screen.
 *
 * Safety rules:
 *  - Only GET requests WITHOUT an Authorization header are cached (never per-user data).
 *  - Only successful (200) JSON responses are stored.
 *  - Any successful write (POST/PUT/PATCH/DELETE) anywhere in the API clears the whole cache,
 *    so admin edits show up immediately.
 */
const TTL_MS = parseInt(process.env.RESPONSE_CACHE_TTL_MS, 10) || 60 * 1000;
const MAX_ENTRIES = 500;

const store = new Map(); // key -> { body, expiresAt }

function clearResponseCache() {
  store.clear();
}

// Student activity writes (progress, login/register, audio synthesis) never change shared
// content, so they must NOT clear the cache — otherwise 100 active students would empty it constantly.
const NON_CONTENT_WRITES = /^\/(progress|users|audio)(\/|$)/;

/** Mount once on the API router: clears the cache after every successful content/admin write. */
function invalidateOnWrite(req, res, next) {
  const isWrite = req.method !== 'GET' && req.method !== 'HEAD' && req.method !== 'OPTIONS';
  if (isWrite && !NON_CONTENT_WRITES.test(req.path)) {
    res.on('finish', () => {
      if (res.statusCode < 400) clearResponseCache();
    });
  }
  next();
}

/** Mount on public read-only routes. */
function cachePublicGet(req, res, next) {
  if (req.method !== 'GET' || req.headers.authorization) return next();

  const key = req.originalUrl;
  const hit = store.get(key);
  if (hit && hit.expiresAt > Date.now()) {
    res.set('X-Cache', 'HIT');
    return res.status(200).json(hit.body);
  }

  const originalJson = res.json.bind(res);
  res.json = (body) => {
    if (res.statusCode === 200) {
      if (store.size >= MAX_ENTRIES) store.delete(store.keys().next().value);
      store.set(key, { body, expiresAt: Date.now() + TTL_MS });
    }
    res.set('X-Cache', 'MISS');
    return originalJson(body);
  };
  next();
}

module.exports = { cachePublicGet, invalidateOnWrite, clearResponseCache };
