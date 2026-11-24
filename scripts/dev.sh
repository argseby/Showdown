#!/usr/bin/env bash
# One-command dev loop: picks two free ports, starts the Go API on one and
# `flutter run` on the other, and wires them together (API_BASE on the client,
# DEV_CORS_ORIGIN on the server). Ctrl+C (or quitting flutter with `q`) stops both.
#
# Overrides: DEV_API_PORT / DEV_WEB_PORT pin a port instead of searching,
# FLUTTER_DEVICE picks the flutter device (chrome by default, web-server for
# no browser), DATA_DIR / LOG_LEVEL go through to the API.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

# A port is free when we can bind it ourselves. Binding is the honest test:
# a Docker-published port is held by docker-proxy, which `ss` shows without an
# owner unless you are root, but a bind still fails on it.
port_free() {
	python3 - "$1" <<'PY' 2>/dev/null
import socket, sys
p = int(sys.argv[1])
for fam, addr in ((socket.AF_INET, "0.0.0.0"), (socket.AF_INET6, "::")):
    s = socket.socket(fam, socket.SOCK_STREAM)
    try:
        if fam == socket.AF_INET6:
            s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        s.bind((addr, p))
    except OSError as e:
        if fam == socket.AF_INET6 and e.errno in (97, 99):  # no IPv6 here
            continue
        sys.exit(1)
    finally:
        s.close()
PY
}

# First free port at or above $1, skipping any in $2.
find_port() {
	local p=$1 skip=${2:-}
	while ((p < 65535)); do
		if [[ $p != "$skip" ]] && port_free "$p"; then
			echo "$p"
			return
		fi
		((p++))
	done
	echo "no free port found from $1 upwards" >&2
	exit 1
}

# Own names on purpose: WEB_PORT/API_PORT already mean something to the
# compose stack and the Makefile, and make exports them into this script.
if [[ -n ${DEV_API_PORT:-} ]]; then
	port_free "$DEV_API_PORT" || { echo "DEV_API_PORT=$DEV_API_PORT is in use" >&2; exit 1; }
	API_PORT=$DEV_API_PORT
else
	API_PORT=$(find_port 8081)
fi
if [[ -n ${DEV_WEB_PORT:-} ]]; then
	port_free "$DEV_WEB_PORT" || { echo "DEV_WEB_PORT=$DEV_WEB_PORT is in use" >&2; exit 1; }
	WEB_PORT=$DEV_WEB_PORT
else
	WEB_PORT=$(find_port 3000 "$API_PORT")
fi

api_base="http://localhost:$API_PORT"
web_origin="http://localhost:$WEB_PORT"
device=${FLUTTER_DEVICE:-chrome}

echo "==> api  $api_base"
echo "==> web  $web_origin  (flutter device: $device)"

# The API runs in its own process group so that stopping it also stops the
# binary `go run` spawned, not just the go tool.
setsid bash -c '
	cd "$1/backend" &&
	LISTEN_ADDR=":$2" DEV_CORS_ORIGIN="$3" DATA_DIR="${DATA_DIR:-./data}" \
	LOG_FORMAT=text LOG_LEVEL="${LOG_LEVEL:-debug}" \
	exec go run ./cmd/server 2>&1 | sed -u "s/^/[api] /"
' _ "$root" "$API_PORT" "$web_origin" &
api_pid=$!

cleanup() {
	trap - EXIT INT TERM
	kill -TERM -- "-$api_pid" 2>/dev/null || true
	wait "$api_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for the API so the app does not start against a dead backend; the
# first `go run` compiles, which can take a while.
printf '==> waiting for the api'
for _ in $(seq 1 240); do
	if curl -fsS "$api_base/healthz" >/dev/null 2>&1; then
		echo ' ready'
		break
	fi
	if ! kill -0 "$api_pid" 2>/dev/null; then
		echo ' api exited during startup' >&2
		exit 1
	fi
	printf '.'
	sleep 0.5
done
curl -fsS "$api_base/healthz" >/dev/null 2>&1 || echo ' still not up after 2 min, starting flutter anyway'

cd "$root/frontend"
# flutter stays in the foreground so its hot-reload keys (r, R, q) work.
flutter run -d "$device" --web-port "$WEB_PORT" --web-hostname localhost \
	--dart-define=API_BASE="$api_base"
