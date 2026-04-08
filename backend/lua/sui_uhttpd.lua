package.path = package.path .. ";/usr/share/sui/lua/?.lua;/usr/share/sui/lua/?/init.lua"

local sui = require("sui")
local uhttpd = uhttpd  -- global provided by uhttpd-mod-lua

function handle_request(env)
  -- env.REQUEST_METHOD, env.PATH_INFO, env.QUERY_STRING, env.HEADERS
  local body = ""
  local clen = tonumber(env.CONTENT_LENGTH or "0") or 0
  if clen > 0 then
    body = uhttpd.recv(clen) or ""
  end

  local query = {}
  for k, v in (env.QUERY_STRING or ""):gmatch("([^&=]+)=([^&]*)") do
    query[k] = v
  end

  local headers = {}
  for k, v in pairs(env.headers or {}) do headers[k] = v end

  local resp = sui.handle({
    path = env.PATH_INFO or "/",
    method = env.REQUEST_METHOD or "GET",
    query_string = env.QUERY_STRING or "",
    query = query,
    headers = headers,
    body = body,
  })

  uhttpd.send("Status: " .. tostring(resp.status) .. " OK\r\n")
  for k, v in pairs(resp.headers or {}) do
    uhttpd.send(k .. ": " .. v .. "\r\n")
  end
  uhttpd.send("\r\n")
  uhttpd.send(resp.body or "")
end
