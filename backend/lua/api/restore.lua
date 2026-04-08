local util = require("util")
local config_io = require("config_io")

local M = {}
M._exec = util.exec

function M.handler(env, sui_config)
  local body = env.body or ""
  if #body == 0 then
    return require("sui").envelope(false, "empty body")
  end
  local tmp_tar = "/tmp/sui-restore-" .. tostring(os.time()) .. ".tar.gz"
  local f = io.open(tmp_tar, "wb")
  if not f then return require("sui").envelope(false, "cannot write tmp file") end
  f:write(body); f:close()

  local extract_dir = tmp_tar .. ".d"
  M._exec("mkdir -p " .. extract_dir)
  local _, code = M._exec("tar -xzf " .. tmp_tar .. " -C " .. extract_dir)
  if code ~= 0 then
    M._exec("rm -rf " .. tmp_tar .. " " .. extract_dir)
    return require("sui").envelope(false, "invalid archive")
  end

  -- Validate via sing-box check
  local cfg_in_archive = extract_dir .. "/config.json"
  local out, code2 = M._exec(config_io.singbox_cmd .. " check -c " .. cfg_in_archive)
  if code2 ~= 0 then
    M._exec("rm -rf " .. tmp_tar .. " " .. extract_dir)
    return require("sui").envelope(false, "invalid config: " .. (out or ""))
  end

  os.rename(cfg_in_archive, sui_config.singbox_config_path)
  local meta_in_archive = extract_dir .. "/sui-meta.json"
  if util.read_file(meta_in_archive) then
    os.rename(meta_in_archive, sui_config.meta_path)
  end
  M._exec("rm -rf " .. tmp_tar .. " " .. extract_dir)
  return require("sui").envelope(true, "restored")
end

return M
