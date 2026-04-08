local util = require("util")

local M = {}
M._exec = util.exec

function M.handler(env, sui_config)
  local cmd = "/etc/init.d/" .. sui_config.singbox_service .. " restart"
  local out, code = M._exec(cmd)
  if code ~= 0 then
    return require("sui").envelope(false, "restart failed: " .. (out or ""))
  end
  return require("sui").envelope(true, "restarted")
end

return M
