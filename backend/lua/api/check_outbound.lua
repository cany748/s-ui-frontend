local util = require("util")
local cjson = require("cjson")

local M = {}
M._http_get = util.http_get

function M.handler(env, sui_config)
  local tag = (env.query or {}).tag
  if not tag then
    return require("sui").envelope(false, "missing tag")
  end
  local url = sui_config.clash_api_url ..
              "/proxies/" .. tag ..
              "/delay?url=http://www.gstatic.com/generate_204&timeout=5000"
  local headers = {}
  if sui_config.clash_api_secret ~= "" then
    headers["Authorization"] = "Bearer " .. sui_config.clash_api_secret
  end
  local status, body = M._http_get(url, headers)
  if status ~= 200 then
    return require("sui").envelope(false, "clash api returned " .. tostring(status))
  end
  local ok, parsed = pcall(cjson.decode, body or "")
  if not ok then
    return require("sui").envelope(false, "invalid clash response")
  end
  return require("sui").envelope(true, "", parsed)
end

return M
