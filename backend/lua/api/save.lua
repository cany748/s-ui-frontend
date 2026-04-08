local cjson = require("cjson")
local config_io = require("config_io")

return function(env, sui_config)
  local ok, state = pcall(cjson.decode, env.body or "")
  if not ok or type(state) ~= "table" then
    return require("sui").envelope(false, "invalid JSON body")
  end
  local result = config_io.write(state, sui_config.singbox_config_path,
                                  sui_config.meta_path, state.mtime)
  if not result.ok then
    return require("sui").envelope(false, tostring(result.error), { code = result.code })
  end
  return require("sui").envelope(true, "saved", { mtime = result.mtime })
end
