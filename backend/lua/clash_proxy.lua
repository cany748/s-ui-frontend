local util = require("util")

local M = {}
M._http_request = util.http_request

function M.handler(env, sui_config)
  local rest = env.path:match("^/clash(.*)$") or "/"
  local target = sui_config.clash_api_url .. rest
  if env.query_string and #env.query_string > 0 then
    target = target .. "?" .. env.query_string
  end
  local headers = {}
  if sui_config.clash_api_secret ~= "" then
    headers["Authorization"] = "Bearer " .. sui_config.clash_api_secret
  end
  if env.headers and env.headers["Content-Type"] then
    headers["Content-Type"] = env.headers["Content-Type"]
  end
  local status, body, ct = M._http_request(env.method, target, headers, env.body)
  if not status then
    return require("sui").envelope(false, "clash api unreachable: " .. tostring(body))
  end
  return {
    status = status,
    headers = { ["Content-Type"] = ct or "application/json" },
    body = body or "",
  }
end

return M
