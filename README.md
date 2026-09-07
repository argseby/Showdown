# Showdown

Self-hosted No-Limit Texas Hold'em for friends. One `docker compose up`, no accounts,
no external requests. Anyone on your instance creates a table, shares the link, and
plays in the browser.

![A full table in Showdown: eight players, community cards and the pot](promo.png)

**Features**

- Real No-Limit rules: side pots, odd chips, min-raise rules, staged showdown, optional
  straddle and run-it-twice, blind schedule, time bank, all-in equity.
- Up to 10 seats per table, reconnect into your seat after a refresh, spectators.
- Host controls at the table: settings, start/pause/end, kick, chips, mute, chat
  moderation, hand history.
- Voice chat and a small video tile per player, browser to browser (WebRTC). The server
  only relays the handshake.
- Hand log with replay and export, per-table leaderboard with statistics, quick phrases,
  turn sound and notifications, English and German.
- Two containers, one SQLite file, images published on GitHub's registry.

## Install

You need Docker with the Compose plugin. Nothing is compiled on your machine.

**1. Get the compose file**

```
mkdir showdown && cd showdown
curl -fsSLO https://raw.githubusercontent.com/argseby/Showdown/main/docker-compose.yml
```

**2. Optional: settings**

```
curl -fsSL https://raw.githubusercontent.com/argseby/Showdown/main/.env.example -o .env
```

Edit `.env` if you want a different port, limits, a pinned release or STUN/TURN servers
for voice and video across networks (see [Settings](#settings)).

**3. Start**

```
docker compose up -d
```

Open `http://localhost:8080`, create a table and share the link with your group (the
**Invite** button at the table copies it and shows a QR code).

**Update**

```
docker compose pull && docker compose up -d
```

Migrations run at start. A restart voids the hand that was in progress; players
reconnect into their seats.

## Reach it from the internet

Browsers only allow the microphone and camera on HTTPS (or `localhost`), so for voice
and video you need one of these.

**Behind your existing reverse proxy** (Traefik, nginx, Caddy, Nginx Proxy Manager,
Dokploy): point it at the `web` container on port 80 and let it terminate TLS.
WebSockets on `/ws/*` must be forwarded (Traefik and Caddy do that by default; nginx
needs the usual `Upgrade`/`Connection` headers).

If the proxy has its own Docker network (say `proxy-network`), attach `web` to it
instead of publishing a port. Download `deploy/docker-compose.proxy.yml` next to the
compose file and put this in `.env`:

```
PROXY_NETWORK=proxy-network
COMPOSE_FILE=docker-compose.yml:deploy/docker-compose.proxy.yml
```

Then `docker compose up -d` as usual and point the proxy at `showdown-web-1:80` (the
container name is `<stack name>-web-1`).

**Standalone with automatic HTTPS**: if nothing sits in front of the stack and ports
80/443 are reachable from the internet, download `deploy/docker-compose.tls.yml` and:

```
echo "SITE_ADDRESS=poker.example.com" >> .env
docker compose -f docker-compose.yml -f deploy/docker-compose.tls.yml up -d
```

Caddy obtains and renews the certificate.

**Portainer**: add a repository stack with compose path `docker-compose.yml` and set
the variables from `.env` in the stack environment. Updates are "re-pull image and
redeploy".

## Settings

All settings live in `.env`; everything has a default.

| Variable | Default | Meaning |
|---|---|---|
| `WEB_PORT` | `8080` | port published on the host |
| `SITE_ADDRESS` | `:80` | keep `:80` behind a proxy; a host name switches on automatic HTTPS |
| `WEBRTC_STUN_URLS` | empty | STUN servers for voice and video across networks, comma-separated, e.g. `stun:stun.l.google.com:19302` (public, no account needed). STUN only tells browsers their public address; audio and video stay browser to browser. Empty = same network only. Two servers, e.g. `stun:stun.l.google.com:19302,stun:stun1.l.google.com:19302`, let the app recognise a symmetric NAT and tell the player that a relay is needed. The old name `VOICE_STUN_URLS` still works |
| `WEBRTC_TURN_URLS` | empty | TURN relay for players whose networks block direct connections (strict NAT, mobile carriers), `turn:`/`turns:` URLs, comma-separated. Media then passes through that relay, so it needs your own coturn or a hosted TURN service. Requires `WEBRTC_TURN_USERNAME` and `WEBRTC_TURN_CREDENTIAL` |
| `TABLE_RETENTION_DAYS` | `90` | hands and chat of ended tables are deleted after this many days; tables and final standings stay |
| `MAX_TABLES` | `100` | cap on tables that have not ended |
| `IMAGE_TAG` | `latest` | `latest` = newest release, `v1.1.0` = a fixed release, `edge` = every commit on `main` |
| `IMAGE_OWNER` | `argseby` | only for a fork that publishes its own images |
| `PROXY_NETWORK` | – | with the proxy override: the Docker network of your reverse proxy |

Rarely needed, add them to the `api` service environment: `MAX_CONNECTIONS_PER_IP`
(50), `TRUST_PROXY` (`true`, rate limiting uses `X-Forwarded-For`), `LOG_LEVEL`
(`info`), `LOG_FORMAT` (`json` or `text`).

Table settings (blinds, antes, turn time, time bank, rebuys, straddle, run it twice,
showdown reveal, blind schedule and more) are set per table by its host in the Admin
tab.

## Hosting a table

There is no admin account. Whoever creates a table is its host: the creating browser
stores an **admin key** for that table and shows an **Admin** tab at the table. Copy the
key from that tab to manage the table from another device (the join page has an
"I host this table" field). Anyone with the key can manage the table, so share it only
with co-hosts. Each table has its own leaderboard; there is no instance-wide one, since
display names are chosen freely and are not identities.

## Backups

The whole state is one SQLite file in the `data` volume. `deploy/backup.sh` writes a
consistent copy while the server keeps running:

```
deploy/backup.sh                      # -> backups/showdown-<timestamp>.sqlite
```

Pass your compose flags after the script name if you use overrides. To restore, stop the
stack, replace `showdown.db` in the volume with the backup (delete `showdown.db-wal` and
`showdown.db-shm`), start again.

## Building from source

For development or a fork. The web image compiles the Flutter client: a few minutes and
about 2 GB of disk.

```
git clone https://github.com/argseby/Showdown.git && cd Showdown
cp .env.example .env
make up      # = docker compose -f docker-compose.yml -f deploy/docker-compose.build.yml up -d --build
```

Releases: push a tag `v*` and the CI publishes both images as that version and
`latest`; every green push to `main` publishes `edge`. A fork publishes under its own
owner and sets `IMAGE_OWNER`; make the packages public so they can be pulled without a
login.

## Development

```
make dev-api          # Go API on :8080 with CORS for the dev web server
make dev-web          # flutter run in Chrome on :3000
make lint test check-gen
make bots TABLE=<id>  # scripted players
```

Poker rules: `docs/rules.md`. Wire protocol: `docs/protocol.md`. Load test: see
`deploy/docker-compose.loadtest.yml` and `make loadtest`. The server is a single process
by design (one goroutine per table); there is no horizontal scaling.
