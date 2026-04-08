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

local PROTO_KEYS = {
  vmess = "vmess", vless = "vless", trojan = "trojan",
  shadowsocks = "shadowsocks", socks = "socks", http = "http",
  hysteria = "hysteria", hysteria2 = "hysteria2", tuic = "tuic",
  ["naive"] = "naive", shadowtls = "shadowtls",
}

local function user_to_proto_config(user)
  local out = {}
  for k, v in pairs(user) do
    if k ~= "name" then out[k] = v end
  end
  return out
end

function M.extract_clients(config)
  local cfg = deep_copy(config)
  local clients = {}
  local bindings = {}
  local by_name = {}

  for _, inbound in ipairs(cfg.inbounds or {}) do
    local proto = PROTO_KEYS[inbound.type]
    if proto and type(inbound.users) == "table" then
      local ids = {}
      for _, user in ipairs(inbound.users) do
        local name = user.name or ("anon-" .. tostring(#clients + 1))
        local idx = by_name[name]
        if not idx then
          idx = #clients + 1
          clients[idx] = { id = idx, name = name, enable = true, config = {}, inbounds = {} }
          by_name[name] = idx
        end
        clients[idx].config[proto] = user_to_proto_config(user)
        local has_inbound = false
        for _, t in ipairs(clients[idx].inbounds) do
          if t == inbound.tag then has_inbound = true; break end
        end
        if not has_inbound then
          clients[idx].inbounds[#clients[idx].inbounds + 1] = inbound.tag
        end
        ids[#ids + 1] = idx
      end
      bindings[inbound.tag] = ids
    end
  end

  return cfg, clients, bindings
end

local TOP_LEVEL_NON_ARRAY = {
  log = true, dns = true, ntp = true, route = true,
  experimental = true, certificate = true,
}

function M.load(raw_config, existing_meta)
  local cfg, tls_configs, tls_bindings = M.extract_tls(raw_config)
  local cfg2, clients, client_bindings = M.extract_clients(cfg)

  if existing_meta and existing_meta.tlsConfigs then
    for _, new_tc in ipairs(tls_configs) do
      for _, old_tc in ipairs(existing_meta.tlsConfigs) do
        if deep_equal(new_tc.tls, old_tc.tls) then
          new_tc.name = old_tc.name
          break
        end
      end
    end
  end

  local config_only = {}
  for k, v in pairs(cfg2) do
    if TOP_LEVEL_NON_ARRAY[k] then config_only[k] = v end
  end

  return {
    config = config_only,
    inbounds = cfg2.inbounds or {},
    outbounds = cfg2.outbounds or {},
    endpoints = cfg2.endpoints or {},
    services = (cfg2.experimental and cfg2.experimental.services) or {},
    clients = clients,
    tls = tls_configs,
    meta = {
      tlsBindings = tls_bindings,
      clientBindings = client_bindings,
    },
  }
end

function M.validate_clients(inbounds, clients)
  local tag_set = {}
  for _, ib in ipairs(inbounds or {}) do tag_set[ib.tag] = true end
  for _, c in ipairs(clients or {}) do
    for _, tag in ipairs(c.inbounds or {}) do
      if not tag_set[tag] then
        return false, "client '" .. tostring(c.name) .. "' references missing inbound '" .. tag .. "'"
      end
    end
  end
  return true
end

local function build_tls_index(tls_configs)
  local idx = {}
  for _, tc in ipairs(tls_configs) do idx[tc.id] = tc.tls end
  return idx
end

function M.inline_tls(inbounds, outbounds, tls_configs)
  local idx = build_tls_index(tls_configs)
  local in_copy = deep_copy(inbounds or {})
  local out_copy = deep_copy(outbounds or {})

  local function inline(arr, label)
    for _, item in ipairs(arr) do
      if item.tls_id ~= nil then
        local block = idx[item.tls_id]
        if block == nil then
          error(label .. " '" .. tostring(item.tag) .. "' references unknown tls_id " .. tostring(item.tls_id))
        end
        item.tls = deep_copy(block)
        item.tls_id = nil
      end
    end
  end

  inline(in_copy, "inbound")
  inline(out_copy, "outbound")
  return in_copy, out_copy
end

return M
