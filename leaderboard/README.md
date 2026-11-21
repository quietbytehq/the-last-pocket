# The Last Pocket global scoreboard

Cloudflare Worker + D1, adapted from the public Nudge leaderboard structure. The game submits only typed name, points, run category and version. One combined AI Championship board ranks each uppercase name's best score. Two fixed category ids, `championship` and `champion_all_48`, distinguish ordinary runs from completion claims. Champion status is aggregated separately from the highest score so a higher unfinished run cannot erase a previous champion badge. Names are not authenticated identities; champion claims and scores are self-reported, not verified.

## First deployment (user performs login and deployment)

Do not resolve, curl, browse or otherwise probe the new subdomain before this succeeds: the owner's router caches negative DNS answers.

```bash
cd /path/to/the-last-pocket/leaderboard
npm ci && npx wrangler login
./deploy.sh
```

The first line after `cd` installs the pinned tools and lets you log in. The second publishes the service. Select the Cloudflare account that owns quietbytehq.uk. The script creates/reuses `lastpocket-scores`, applies schema.sql, replaces the placeholder database ID, and deploys the Worker, custom domain and secrets together. It does not probe the public hostname. Reruns preserve the secret values and scores.

The admin URL is saved privately to `~/.config/lastpocket-scores-admin.txt`. The 256-bit random admin key and IP salt are stored in Cloudflare Worker secrets; a mode-0600 recovery copy is at `~/.config/lastpocket-scores/secrets.json`. Private deployment errors are in that directory's deploy.log. Do not paste or commit these files. If the admin link exists but the secrets copy is missing, deployment stops rather than rotating the key. Keep a private backup. The database ID written to wrangler.toml is not a secret and can be committed after deployment.

## Local checks

```bash
cd /path/to/the-last-pocket/leaderboard
npm ci
npm test
```

Tests launch `wrangler dev --local` on 127.0.0.1:8793 with a disposable local D1 database and random test secrets outside the repository. They never access the future domain or Cloudflare account. The local server and temporary files are cleaned up.

## After deployment

```bash
cd /path/to/the-last-pocket/leaderboard
python3 verify_live.py --deployed
```

This explicitly opts into the first public-domain request. It posts one temporary QA score, confirms storage and public appearance when it ranks, deletes only that submission through admin, then checks removal. On a fresh deployment the board must end empty. It never clears genuine players' entries. After this, run the new game, end a qualifying championship, confirm a test name on the explicit posting screen with online posting enabled, check it appears, and remove that test through admin. A name outside the top 100 can still be seen in the private recent-entry list. After the user confirmed deployment on 21 November 2026, a temporary score appeared and was removed through admin. A separate test invoked the actual game completion/share code; its score and champion badge appeared, were checked in admin and were deleted. The board was confirmed empty after cleanup. The game test simulated a qualifying completed tournament; it was not a manual 48-frame playthrough.

## API and abuse controls

- `GET /api/top`: top 100, each name's best score. Equal scores sort by name for stable ordering.
- `POST /api/submit`: `{name, score, mode, version}`. Name is uppercase, stripped to A–Z, 0–9, space, dot, underscore and hyphen, limited to 12. Blocked substrings are checked with separators removed, both literally and with 0/1/3/4/5 mapped to o/i/e/a/s.
- Integer scores only; variables MIN_SCORE=1000, MAX_SCORE=1000000; score must be a multiple of 50. JSON numeric strings are refused. Only `championship` and `champion_all_48` are accepted. Version is a bounded string.
- Six submission attempts per hour per salted SHA-256 address hash. Count-and-insert is atomic. Deleting a score does not erase rate-limit records. No raw addresses are stored by this application. Old hashes are removed on subsequent submissions after their hour expires; an idle database may retain expired hashes until the next submission.
- `/admin?key=…`: recent entries and delete controls. Missing/wrong key returns 404. Deletion uses a confirmation and authenticated POST so link previews cannot delete scores. Keep the URL private; whoever has it can moderate. No-referrer, no-store and a restrictive Content Security Policy are set.
- Prepared SQL with bound values only; UI data is inserted with textContent. No external fonts, trackers or embedded resources. Unexpected failures return only `server error` without details.

The score ceiling is intentionally generous, not a plausibility/cheat detector. Championship wins award `1000 + rank*500 + max(0,18-shots)*50`; clearing all 48 adds 1000 per unused retry diamond. Points are multiples of 50 and the theoretical full-run maximum is 130,200. The generous 1,000,000 ceiling filters junk. No extra score-vs-time or completion-vs-points check is added. Local-versus modes do not produce comparable championship points and are not submitted.

Fake scores remain possible: the game and endpoint are public, there is no client secret, and no scores are claimed verified. Salted IP limits can be evaded by changing address and can affect users behind a shared address. Same-name impersonation is possible. Cloudflare processes network addresses to serve requests; our database stores only a temporary salted hash. Unlike Nudge's original, this implementation uses a full SHA-256 hash, atomic limits, separate rate rows, POST deletion and DOM-built admin rows.

The client never waits for submission, retries offline posts, or uploads the local score history. F2 / gamepad X / the privacy control remembers local-only. Only confirming the optional share screen sends a post; this screen appears after ending a qualifying tournament or completing it. Manual save slots remain local and never post scores. No previous score history is uploaded. A failed post does not prevent local saving or restart.
