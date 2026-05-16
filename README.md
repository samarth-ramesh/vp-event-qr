# vp-event-qr

Static event page for Vidya Parampara, served by nginx inside a container.

## Serving with Podman

The container listens on port 80 internally. Map it to host port **4003**.

### Build

```sh
podman build -t vp-event-qr .
```

### Run

```sh
podman run -d --name vp-event-qr -p 4003:80 --restart=unless-stopped vp-event-qr
```

The page is now reachable at <http://localhost:4003>.

### Update

```sh
podman stop vp-event-qr
podman rm vp-event-qr
podman build -t vp-event-qr .
podman run -d --name vp-event-qr -p 4003:80 --restart=unless-stopped vp-event-qr
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
