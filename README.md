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
