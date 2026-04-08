local util = require("util")

local M = {}
M._exec = util.exec

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function gen_uuid()
  local out = M._exec("sing-box generate uuid")
  return { uuid = out:match("[%w%-]+") }
end

local function parse_keypair(out, priv_label, pub_label)
  return {
    private_key = out:match(priv_label .. ":%s*([%w%+/=]+)"),
    public_key = out:match(pub_label .. ":%s*([%w%+/=]+)"),
  }
end

local function gen_reality()
  local out = M._exec("sing-box generate reality-keypair")
  return parse_keypair(out, "PrivateKey", "PublicKey")
end

local function gen_wireguard()
  local out = M._exec("sing-box generate wireguard-keypair")
  return parse_keypair(out, "PrivateKey", "PublicKey")
end

local function gen_tls(server_name)
  local out = M._exec("sing-box generate tls-keypair " .. shell_quote(server_name or "localhost"))
  local function extract_pem(label)
    -- Match PEM block including newlines using [%s%S] which matches any character
    local pattern = "%-%-%-%-%-BEGIN " .. label .. "%-%-%-%-%-[%s%S]-%-%-%-%-%-END " .. label .. "%-%-%-%-%-"
    return out:match("(" .. pattern .. ")")
  end
  return {
    private_key = extract_pem("PRIVATE KEY"),
    certificate = extract_pem("CERTIFICATE"),
  }
end

function M.handler(env, sui_config)
  local q = env.query or {}
  local t = q.type
  local result
  if t == "uuid" then result = gen_uuid()
  elseif t == "reality" then result = gen_reality()
  elseif t == "wireguard" then result = gen_wireguard()
  elseif t == "tls" then result = gen_tls(q.server_name)
  else
    return require("sui").envelope(false, "unknown keypair type: " .. tostring(t))
  end
  return require("sui").envelope(true, "", result)
end

return M
