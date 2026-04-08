local M = {}

local function deep_copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = deep_copy(v) end
  return out
end

local function deep_equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deep_equal(v, b[k]) then return false end end
  for k, _ in pairs(b) do if a[k] == nil then return false end end
  return true
end

M._deep_copy = deep_copy
M._deep_equal = deep_equal

function M.extract_tls(config)
  local cfg = deep_copy(config)
  local tls_configs = {}
  local bindings = { inbound = {}, outbound = {} }

  local function find_or_add(tls_block, hint_name)
    for _, tc in ipairs(tls_configs) do
      if deep_equal(tc.tls, tls_block) then return tc.id end
    end
    local id = #tls_configs + 1
    tls_configs[#tls_configs + 1] = {
      id = id,
      name = "auto-" .. (hint_name or ("tls-" .. id)),
      tls = tls_block,
    }
    return id
  end

  for _, inbound in ipairs(cfg.inbounds or {}) do
    if type(inbound.tls) == "table" then
      local id = find_or_add(inbound.tls, inbound.tag)
      bindings.inbound[inbound.tag] = id
      inbound.tls_id = id
      inbound.tls = nil
    end
  end

  for _, outbound in ipairs(cfg.outbounds or {}) do
    if type(outbound.tls) == "table" then
      local id = find_or_add(outbound.tls, outbound.tag)
      bindings.outbound[outbound.tag] = id
      outbound.tls_id = id
      outbound.tls = nil
    end
  end

  return cfg, tls_configs, bindings
end

return M
