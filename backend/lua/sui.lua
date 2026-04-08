local cjson = require("cjson")

local M = {}

M.routes = {}
M.config = require("sui_config").load()

function M.register(method, path_pattern, handler)
  M.routes[method .. " " .. path_pattern] = handler
end

local function envelope(success, msg, obj, status)
  return {
    status = status or 200,
    headers = { ["Content-Type"] = "application/json" },
    body = cjson.encode({ success = success, msg = msg or "", obj = obj }),
  }
end

M.envelope = envelope

function M.handle(env)
  if env.path and env.path:sub(1, 7) == "/clash/" then
    local ok, proxy = pcall(require, "clash_proxy")
    if ok then return proxy.handler(env, M.config) end
  end

  local key = env.method .. " " .. env.path
  local handler = M.routes[key]
  if not handler then
    return envelope(false, "not found: " .. env.path, nil, 404)
  end
  local ok, result = pcall(handler, env)
  if not ok then
    return envelope(false, "internal error: " .. tostring(result), nil, 500)
  end
  return result
end

local load_handler = require("api.load")
M.register("GET", "/api/load", function(env)
  return load_handler(env, M.config)
end)

local save_handler = require("api.save")
M.register("POST", "/api/save", function(env) return save_handler(env, M.config) end)

local status_mod = require("api.status")
M.register("GET", "/api/status", function(env) return status_mod.handler(env, M.config) end)

local logs_mod = require("api.logs")
M.register("GET", "/api/logs", function(env) return logs_mod.handler(env, M.config) end)

local restart_mod = require("api.restart")
M.register("POST", "/api/restart", function(env) return restart_mod.handler(env, M.config) end)

return M
