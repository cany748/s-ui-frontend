local M = {}

function M.read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

function M.write_file_atomic(path, content)
  local tmp = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1, 1e9))
  local f, err = io.open(tmp, "w")
  if not f then return false, err end
  local ok_write, write_err = f:write(content)
  f:close()
  if not ok_write then
    os.remove(tmp)
    return false, write_err or "write failed"
  end
  local ok_rename, rename_err = os.rename(tmp, path)
  if not ok_rename then
    os.remove(tmp)
    return false, rename_err or "rename failed"
  end
  return true
end

function M.exec(cmd)
  local p = io.popen(cmd .. " 2>&1; echo \"___EXIT___$?\"", "r")
  if not p then return "", 127 end
  local out = p:read("*a") or ""
  p:close()
  local exit_code = tonumber(out:match("___EXIT___(%-?%d+)\n?$")) or 1
  out = out:gsub("___EXIT___%-?%d+\n?$", "")
  return out, exit_code
end

return M
