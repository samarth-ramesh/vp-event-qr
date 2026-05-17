# vp-event-qr

Static event page for Vidya Parampara, served by nginx inside a container.

The image is built and published to GHCR by `.github/workflows/docker-publish.yml`
on every push to `main`:

```
ghcr.io/samarth-ramesh/vp-event-qr:latest
```

## Serving with Podman

The container listens on port 80 internally. Map it to host port **4003**.

### Run

```sh
podman pull ghcr.io/samarth-ramesh/vp-event-qr:latest
podman run -d --name vp-event-qr -p 4003:80 --restart=unless-stopped \
    ghcr.io/samarth-ramesh/vp-event-qr:latest
```

The page is now reachable at <http://localhost:4003>.

### Update

Pull the latest image and recreate the container:

```sh
podman pull ghcr.io/samarth-ramesh/vp-event-qr:latest
podman stop vp-event-qr
podman rm vp-event-qr
podman run -d --name vp-event-qr -p 4003:80 --restart=unless-stopped \
    ghcr.io/samarth-ramesh/vp-event-qr:latest
```

### Run as a systemd service (rootless)

Generate a unit so the container comes back after reboot:

```sh
mkdir -p ~/.config/systemd/user
podman generate systemd --new --name vp-event-qr \
    > ~/.config/systemd/user/container-vp-event-qr.service
systemctl --user daemon-reload
systemctl --user enable --now container-vp-event-qr.service
loginctl enable-linger "$USER"
```

### Logs and status

```sh
podman ps
podman logs -f vp-event-qr
```

## Caching (Cloudflare + upstream nginx)

The container's nginx (see `default.conf`) already emits

```
Cache-Control: public, max-age=21600, s-maxage=21600
```

on all PDFs and images. That's 6 hours, with `s-maxage` directing any CDN
to cache for the same window and `max-age` doing the same in browsers.

### Cloudflare

Nothing extra to configure for standard caching — CF honors `s-maxage`
out of the box and will cache PDFs/images at the edge for 6 h. If you
want HTML cached too, add a Cache Rule ("Cache Everything") for this
host; the HTML response has no `Cache-Control`, so CF will fall back to
its default Edge Cache TTL (or whatever you set in the rule).

After a deploy, purge the cached assets if they changed:

```sh
# Dashboard: Caching → Configuration → Purge Cache → Custom Purge
# or via API:
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"files":["https://vp.samarthr.com/qr.png"]}'
```

### Upstream nginx (reverse proxy in front of the container)

If you front the container with another nginx on the host (e.g. for TLS
termination), it will already **forward** the container's
`Cache-Control` headers to Cloudflare — no proxy config is required for
CF caching to work.

To also cache **at the reverse proxy itself**, enable `proxy_cache`. Add
to the `http {}` block in `/etc/nginx/nginx.conf`:

```nginx
proxy_cache_path /var/cache/nginx/vp-event-qr
                 levels=1:2
                 keys_zone=vp_cache:10m
                 max_size=200m
                 inactive=24h
                 use_temp_path=off;
```

Then in the `server {}` block that proxies to the container:

```nginx
location / {
    proxy_pass         http://127.0.0.1:4003;
    proxy_http_version 1.1;
    proxy_set_header   Host              $host;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;

    proxy_cache            vp_cache;
    proxy_cache_valid      200 6h;
    proxy_cache_use_stale  error timeout updating;
    add_header             X-Cache-Status $upstream_cache_status;
}
```

`proxy_cache_valid 200 6h` is a hard cap; nginx will still honour the
shorter of that and the origin's `s-maxage`/`max-age`. The
`X-Cache-Status` header (`HIT`/`MISS`/`EXPIRED`) is handy for verifying
the proxy cache is doing its job.

