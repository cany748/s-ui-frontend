local util = require("util")

local M = {}
M._exec = util.exec  -- injection point

function M.handler(env, sui_config)
  local pid_out, pid_code = M._exec("pidof " .. sui_config.singbox_service)
  local pid = tonumber(pid_out:match("%d+"))
  local ver_out = M._exec("sing-box version")
  local version = ver_out:match("version ([%w%p]+)") or "unknown"
  return require("sui").envelope(true, "", {
    running = pid_code == 0 and pid ~= nil,
    pid = pid,
    version = version,
    uptime = 0,
  })
end

return M
