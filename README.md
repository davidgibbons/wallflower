# wallflower

A small container that runs an Xorg dashboard on Kubernetes: X and a
full-screen Chromium on a display plugged into a node, with the panel powered
off when nobody is around. It is built for the Corsair Xeneon Edge, a
2560×720 USB-C touchscreen, and works with any display X can drive.

For Home Assistant cards sized for that panel, see
[edgelit](https://github.com/davidgibbons/edgelit).

## Install

```sh
helm install wallflower oci://ghcr.io/davidgibbons/charts/wallflower \
  --set dashboardUrl=https://homeassistant.example.lan/lovelace/0
```

The image is `ghcr.io/davidgibbons/wallflower`. Chart and image versions match.
Chromium's profile lives on a PVC, so a dashboard login survives restarts.

## Values

| Value | Default | Purpose |
|---|---|---|
| `dashboardUrl` | — | **Required.** The page Chromium shows. |
| `presence.haUrl` | `""` | Home Assistant base URL for presence sync. |
| `presence.entity` | `""` | Entity that decides whether the panel is lit. |
| `presence.tokenSecret.name` / `.key` | `""` / `HA_TOKEN` | Secret holding a Home Assistant long-lived access token. |
| `presence.pollSeconds` | `30` | Seconds between polls. |
| `presence.offConfirms` | `3` | Off reads in a row before the panel blanks. |
| `panelResource` | `""` | Extended resource that marks the panel's node, such as one from a USB device plugin. The pod requests one, which also places it there. |
| `persistence.*` | enabled, 1Gi | PVC for Chromium's profile. Set `existingClaim` to bring your own. |
| `env` | `[]` | Extra environment. See below. |
| `hostNetwork` | `true` | Needed for input hotplug. See below. |
| `shmSize` | `512Mi` | Memory-backed `/dev/shm` for Chromium. |
| `resources`, `nodeSelector`, `tolerations`, `affinity` | | As usual. |

These environment variables tune the display and browser:

| Variable | Default | Purpose |
|---|---|---|
| `CHROMIUM_FLAGS` | empty | Extra flags, split on spaces, such as `--disable-gpu` to keep Chromium off a shared GPU. |
| `OUTPUT` | first connected | xrandr output driving the panel. |
| `MODE` | from EDID | Force a mode, such as `2560x720`. |
| `ROTATE` | `normal` | xrandr rotation. |
| `RESTART_SEC` | `15` | Wait before relaunching Chromium. |
| `TZ` | `Etc/UTC` | Time zone. |

## Presence sync

With `presence.haUrl`, `presence.entity` and a token all set, wallflower polls
the entity. An `on`, `playing`, `idle` or `paused` state lights the panel.
`offConfirms` consecutive `off`, `standby` or `unavailable` reads blank it with
`xrandr --output <out> --off`, which drops the CRTC so the panel really powers
down. When it wakes, the touchscreen is remapped once USB has re-enumerated.

Leave any of the three unset and the panel stays lit. Screen blanking and DPMS
are off either way.

## What the pod needs

- **Privileged**, for the GPU, a VT and the input devices.
- **Host `/dev/input` and `/run/udev`.** The touchscreen re-enumerates every
  time the panel wakes, so the devices captured at pod start go stale.
- **Host network.** X learns about input hotplug from udev netlink, which only
  reaches the host network namespace.
- **The panel's node.** Use `panelResource` with a device plugin, or a
  `nodeSelector`.

## How it runs

- **`kiosk-container`** is the entrypoint. It writes `/run/kiosk.conf` from
  `/etc/kiosk.defaults` plus any environment variable of the same name, then
  starts Xorg as root and `kiosk-session` as the `kiosk` user under `xinit`.
  Chromium refuses to run as root with its sandbox on. When X exits, the
  container exits and Kubernetes restarts it.
- **`kiosk-session`** starts `ha-display-sync`, then loops Chromium with a
  `RESTART_SEC` backoff. It clears Chromium's singleton locks and
  session-restore state before every launch, because those wedge a kiosk
  browser after an unclean exit.
- **`ha-display-sync`** runs presence sync.

## Screenshot

```sh
kubectl exec deploy/wallflower -- env DISPLAY=:0 scrot -o - > panel.png
```

## Release

Versions are semver, in `VERSION`, and follow
[Conventional Commits](https://www.conventionalcommits.org/). CI runs
[knope](https://knope.tech) on every push to `main`:

1. Releasable commits since the last tag open or refresh a `chore: release
   X.Y.Z` pull request that bumps `VERSION`, the chart version and
   `CHANGELOG.md`.
2. Merging it tags `vX.Y.Z`, and `publish.yml` pushes the image and chart to
   ghcr.io.

## Develop

```sh
./test/test-display-sync.sh
helm lint chart --set dashboardUrl=https://example.test
```
