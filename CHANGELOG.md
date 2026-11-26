## 0.2.3 (2026-11-26)

### Fixes

- look for an open release PR, not any release PR

## 0.2.2 (2026-11-25)

### Fixes

- prune superseded CRLSet versions hourly
- open the release PR again, and fail on a knope error

## 0.2.1 (2026-10-02)

### Features

- pause Chromium while the panel is off

## 0.2.0 (2026-10-01)

First public release.

### Features

- Helm chart in `chart/`, published with the image to ghcr.io
- `DASHBOARD_URL` is required, and presence sync turns on only when `HA_URL`, `HA_ENTITY` and `HA_TOKEN` are all set
