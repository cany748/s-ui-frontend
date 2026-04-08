local M = {}
local cjson = require("cjson")
cjson.encode_keep_buffer(false)

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

function M.read_json(path)
  local content = M.read_file(path)
  if content == nil then return nil, "file not found" end
  local ok, obj = pcall(cjson.decode, content)
  if not ok then return nil, tostring(obj) end
  return obj
end

function M.encode_json(obj)
  cjson.encode_empty_table_as_object(true)
  return cjson.encode(obj)
end

function M.write_json_atomic(path, obj)
  local s = M.encode_json(obj)
  return M.write_file_atomic(path, s)
end

function M.http_request(method, url, headers, body)
  local hdrs = ""
  for k, v in pairs(headers or {}) do
    hdrs = hdrs .. " -H " .. string.format("%q", k .. ": " .. v)
  end
  local body_arg = ""
  local body_file
  if body and #body > 0 then
    body_file = os.tmpname()
    local f = io.open(body_file, "wb"); f:write(body); f:close()
    body_arg = " --data-binary @" .. body_file
  end
  local cmd = "curl -sS -m 30 -X " .. method ..
              " -w '\\n___HTTP___%{http_code}\\n___CT___%{content_type}'" ..
              hdrs .. body_arg .. " " .. string.format("%q", url)
  local out, code = M.exec(cmd)
  if body_file then os.remove(body_file) end
  if code ~= 0 then return nil, "curl failed: " .. out end
  local resp_body, status, ct = out:match("^(.*)\n___HTTP___(%d+)\n___CT___(.-)$")
  return tonumber(status), resp_body, ct
end

function M.http_get(url, headers)
  local hdrs = ""
  for k, v in pairs(headers or {}) do
    hdrs = hdrs .. " -H " .. string.format("%q", k .. ": " .. v)
  end
  local cmd = "curl -sS -m 10 -w '\\n___HTTP___%{http_code}'" .. hdrs .. " " .. string.format("%q", url)
  local out, code = M.exec(cmd)
  if code ~= 0 then return nil, "curl failed: " .. out end
  local body, status = out:match("^(.*)\n___HTTP___(%d+)$")
  return tonumber(status), body
end

return M
