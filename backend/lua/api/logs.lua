local util = require("util")

local M = {}
M._exec = util.exec

function M.handler(env, sui_config)
  local count = tonumber((env.query or {}).count) or 100
  if count < 1 then count = 1 end
  if count > 5000 then count = 5000 end
  local cmd = "logread -e " .. sui_config.singbox_service ..
              " | tail -n " .. tostring(count)
  local out, _ = M._exec(cmd)
  local lines = {}
  for line in (out or ""):gmatch("[^\n]+") do
    lines[#lines + 1] = line
  end
  return require("sui").envelope(true, "", { lines = lines })
end

return M
