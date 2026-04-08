local config_io = require("config_io")

return function(env, sui_config)
  local state, mtime, warnings = config_io.read(
    sui_config.singbox_config_path,
    sui_config.meta_path
  )
  state.mtime = mtime
  state.warnings = warnings
  return require("sui").envelope(true, "", state)
end
