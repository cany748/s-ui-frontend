#!/bin/sh
# Smoke test: calls sui.handle directly via lua CLI, without uhttpd.
set -e
cd "$(dirname "$0")/.."

mkdir -p dev/sandbox
cat > dev/sandbox/config.json <<'EOF'
{"log":{"level":"info"},"inbounds":[],"outbounds":[{"type":"direct","tag":"direct"}]}
EOF
rm -f dev/sandbox/sui-meta.json

export PATH="$PWD/dev:$PATH"
ln -sf singbox-mock.sh dev/sing-box 2>/dev/null || true

lua5.1 -e '
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
local sui = require("sui")
sui.config = require("sui_config").load("dev/sui.conf")
require("config_io").singbox_cmd = "dev/singbox-mock.sh"

local cjson = require("cjson")

local function call(method, fullpath, body)
  local path, qs = fullpath:match("^([^?]*)%??(.*)$")
  local query = {}
  for k, v in (qs or ""):gmatch("([^&=]+)=([^&]*)") do query[k] = v end
  local resp = sui.handle({ method=method, path=path, body=body or "", query=query, query_string=qs or "" })
  print(method, fullpath, "=>", resp.status, (resp.body or ""):sub(1,200))
  return resp
end

call("GET", "/api/load")
local state = cjson.decode(call("GET", "/api/load").body).obj
state.inbounds = {{ type="vmess", tag="smoke", users={} }}
call("POST", "/api/save", cjson.encode(state))
call("GET", "/api/load")
call("GET", "/api/keypairs?type=uuid")
'
