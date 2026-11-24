#!/bin/sh
# Start atomic-server (loopback) and nginx (public $PORT); exit non-zero as soon
# as either one stops, so Railway's ON_FAILURE restart policy restarts the service.
set -eu

PORT="${PORT:-8080}"
INTERNAL_PORT="${ATOMIC_INTERNAL_PORT:-8079}"
[ "$INTERNAL_PORT" = "$PORT" ] && INTERNAL_PORT=8078
DATA_DIR="${ATOMIC_DATA_DIR:-/data}"

# Railway shows the host's CPUs (32+) inside a 1 vCPU service: size thread pools
# from the cgroup CPU quota instead.
CPUS=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != "max" ] && [ "${period:-0}" -gt 0 ] 2>/dev/null; then
    CPUS=$(( (quota + period - 1) / period ))
  else
    CPUS=$(nproc 2>/dev/null || echo 2)
  fi
fi
[ "$CPUS" -lt 1 ] && CPUS=1
[ "$CPUS" -gt 4 ] && CPUS=4
export TOKIO_WORKER_THREADS="${TOKIO_WORKER_THREADS:-$(( CPUS < 2 ? 2 : CPUS ))}"
export MALLOC_ARENA_MAX="${MALLOC_ARENA_MAX:-2}"
# SQLite page caches scale with (1 + read pool) x cache per database; upstream
# defaults (16 readers, 64 MB + 8 MB) are sized for big hosts.
export ATOMIC_SERVER_READ_POOL_SIZE="${ATOMIC_SERVER_READ_POOL_SIZE:-4}"
export ATOMIC_SQLITE_CACHE_KB="${ATOMIC_SQLITE_CACHE_KB:-16000}"
export ATOMIC_SQLITE_READ_CACHE_KB="${ATOMIC_SQLITE_READ_CACHE_KB:-2000}"

# PUBLIC_URL drives OAuth/MCP discovery. Railway can hand over a bare
# "https://" if the domain didn't exist yet; drop anything that isn't a URL.
case "${PUBLIC_URL:-}" in
  http://?*.?*|https://?*.?*) export PUBLIC_URL="${PUBLIC_URL%/}" ;;
  *) unset PUBLIC_URL || true ;;
esac

# The setup token is the only thing between a stranger and claiming the instance.
if [ -z "${ATOMIC_SETUP_TOKEN:-}" ] && [ "${ATOMIC_DANGEROUSLY_SKIP_SETUP_TOKEN:-false}" != "true" ]; then
  echo "atomic-start: ATOMIC_SETUP_TOKEN is empty; refusing to start an instance anyone could claim" >&2
  exit 1
fi

mkdir -p "$DATA_DIR"
chown -R atomic:atomic "$DATA_DIR"

sed -e "s/__PORT__/$PORT/g" -e "s/__INTERNAL_PORT__/$INTERNAL_PORT/g" \
  /etc/atomic/nginx.conf.template > /etc/nginx/conf.d/atomic.conf
# Trust X-Forwarded-Proto from Railway's edge, default to the request scheme.
cat > /etc/nginx/conf.d/00-forwarded.conf <<'NG'
map $http_x_forwarded_proto $forwarded_proto {
    default $http_x_forwarded_proto;
    ''      $scheme;
}
NG
sed -i "s/^worker_processes .*/worker_processes $CPUS;/" /etc/nginx/nginx.conf
nginx -t -q

setpriv --reuid=atomic --regid=atomic --init-groups \
  atomic-server --data-dir "$DATA_DIR" serve --bind 127.0.0.1 --port "$INTERNAL_PORT" &
SERVER_PID=$!

# Wait for the server before opening the public port, so the health check
# only passes once the API answers.
i=0
until curl -fsS -o /dev/null "http://127.0.0.1:$INTERNAL_PORT/health"; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    wait "$SERVER_PID" || code=$?
    echo "atomic-start: atomic-server exited during startup (code ${code:-0})" >&2
    exit 1
  fi
  i=$((i + 1))
  [ "$i" -gt 240 ] && { echo "atomic-start: atomic-server not healthy after 120 s" >&2; exit 1; }
  sleep 0.5
done

nginx -g 'daemon off;' &
NGINX_PID=$!

stop() {
  kill -TERM "$SERVER_PID" "$NGINX_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}
trap stop TERM INT

# BusyBox/dash have no reliable `wait -n`: poll both children.
while kill -0 "$SERVER_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do
  sleep 2
done
if kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "atomic-start: nginx stopped; exiting so Railway restarts the service" >&2
else
  echo "atomic-start: atomic-server stopped; exiting so Railway restarts the service" >&2
fi
kill -TERM "$SERVER_PID" "$NGINX_PID" 2>/dev/null || true
exit 1
