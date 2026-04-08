# Dev sandbox

Local smoke test of the backend without OpenWRT or a real sing-box.

## Usage

```bash
./dev/smoke.sh
```

Uses the mock sing-box CLI (`singbox-mock.sh`) and validates configs via
`python3 -c json.load`. On a real device, replace with the `sing-box` binary
configured via `/etc/sui.conf` or `/etc/config/sui`.
