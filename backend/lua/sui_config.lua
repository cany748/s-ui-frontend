local M = {}

local DEFAULTS = {
  singbox_config_path = "/etc/sing-box/config.json",
  meta_path = "/etc/sing-box/sui-meta.json",
  clash_api_url = "http://127.0.0.1:9090",
  clash_api_secret = "",
  singbox_service = "sing-box",
}

function M.load(path)
  local cfg = {}
  for k, v in pairs(DEFAULTS) do cfg[k] = v end
  local f = io.open(path or "/etc/sui.conf", "r")
  if not f then return cfg end
  for line in f:lines() do
    local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k and v and cfg[k] ~= nil then cfg[k] = v end
  end
  f:close()
  return cfg
end

return M
