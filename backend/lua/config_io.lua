local util = require("util")
local mapper = require("meta_mapper")

local M = {}

M.singbox_cmd = "sing-box"

local function file_mtime(path)
  local out, code = util.exec("stat -c %Y " .. path)
  if code ~= 0 then return 0 end
  return tonumber(out:match("%d+")) or 0
end

function M.read(config_path, meta_path)
  local warnings = {}
  local raw_config, cfg_err = util.read_json(config_path)
  if not raw_config then
    warnings[#warnings + 1] = "config: " .. tostring(cfg_err)
    raw_config = { inbounds = {}, outbounds = {} }
  end

  local meta = util.read_json(meta_path)

  local state = mapper.load(raw_config, meta)
  local mtime = file_mtime(config_path)
  return state, mtime, warnings
end

function M.write(state, config_path, meta_path, expected_mtime)
  local current_mtime = file_mtime(config_path)
  if current_mtime ~= 0 and expected_mtime ~= nil and current_mtime ~= expected_mtime then
    return { ok = false, code = "conflict", error = "config was modified by another session" }
  end

  local ok_save, sb_config, sui_meta = pcall(mapper.save, state)
  if not ok_save then
    return { ok = false, code = "invalid", error = tostring(sb_config) }
  end

  local tmp = config_path .. ".tmp." .. tostring(os.time())
  local sb_json = util.encode_json(sb_config)
  local f, ferr = io.open(tmp, "w")
  if not f then return { ok = false, code = "io", error = ferr } end
  f:write(sb_json); f:close()

  local out, code = util.exec(M.singbox_cmd .. " check -c " .. tmp)
  if code ~= 0 then
    os.remove(tmp)
    return { ok = false, code = "invalid", error = out }
  end

  local ok_rename, rename_err = os.rename(tmp, config_path)
  if not ok_rename then
    os.remove(tmp)
    return { ok = false, code = "io", error = rename_err }
  end

  local ok_meta, meta_err = util.write_json_atomic(meta_path, sui_meta)
  if not ok_meta then
    return { ok = false, code = "io", error = "config saved but meta failed: " .. tostring(meta_err) }
  end

  return { ok = true, mtime = file_mtime(config_path) }
end

return M
