local util = require("util")

local M = {}
M._exec = util.exec

function M.handler(env, sui_config)
  local tmp_dir = "/tmp/sui-backup-" .. tostring(os.time())
  M._exec("mkdir -p " .. tmp_dir)
  M._exec("cp " .. sui_config.singbox_config_path .. " " .. tmp_dir .. "/config.json 2>/dev/null")
  M._exec("cp " .. sui_config.meta_path .. " " .. tmp_dir .. "/sui-meta.json 2>/dev/null")
  local tar_path = tmp_dir .. ".tar.gz"
  M._exec("tar -czf " .. tar_path .. " -C " .. tmp_dir .. " . 2>/dev/null")
  local f = io.open(tar_path, "rb")
  local content = ""
  if f then
    content = f:read("*a") or ""
    f:close()
  end
  M._exec("rm -rf " .. tmp_dir .. " " .. tar_path)
  return {
    status = 200,
    headers = {
      ["Content-Type"] = "application/gzip",
      ["Content-Disposition"] = 'attachment; filename="sui-backup.tar.gz"',
    },
    body = content,
  }
end

return M
