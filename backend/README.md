# s-ui backend

Lua CGI backend for sing-box management on OpenWRT via uhttpd-mod-lua.

## Architecture

- `lua/sui_uhttpd.lua` — uhttpd-mod-lua entry point
- `lua/sui.lua` — request router
- `lua/api/` — endpoint handlers (load, save, status, logs, restart, keypairs, checkOutbound, backup, restore)
- `lua/clash_proxy.lua` — Clash API proxy with secret injection
- `lua/config_io.lua` — sing-box config read/write with mtime conflict guard
- `lua/meta_mapper.lua` — TLS/client metadata round-trip mapper
- `lua/util.lua` — file I/O, exec, HTTP (via curl)
- `lua/sui_config.lua` — runtime config loader

## Running tests

```bash
cd backend
busted tests/
```

Requires: lua 5.1, lua-cjson, busted

## Smoke test

```bash
cd backend
./dev/smoke.sh
```

Requires: lua 5.1, lua-cjson, python3 (for config validation mock)

## Deployment

Install to `/usr/share/sui/lua/` on OpenWRT. Configure uhttpd to use `sui_uhttpd.lua` as the Lua handler.
