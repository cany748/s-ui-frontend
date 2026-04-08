local M = {}
local cjson = require("cjson")

function M.load_fixture(name)
  local path = debug.getinfo(1, "S").source:sub(2):match("(.*/)") .. "fixtures/" .. name
  local f = assert(io.open(path, "r"), "fixture not found: " .. path)
  local content = f:read("*a")
  f:close()
  return cjson.decode(content)
end

function M.deep_equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do
    if not M.deep_equal(v, b[k]) then return false end
  end
  for k, _ in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

return M
