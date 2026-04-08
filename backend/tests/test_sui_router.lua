local sui = require("sui")

describe("GET /api/load", function()
  local cp, mp
  before_each(function()
    cp = os.tmpname()
    local f = io.open(cp, "w")
    f:write([[{"log":{"level":"info"},"inbounds":[],"outbounds":[]}]])
    f:close()
    mp = os.tmpname(); os.remove(mp)
    -- inject config paths
    sui.config = { singbox_config_path = cp, meta_path = mp }
  end)
  after_each(function() os.remove(cp); pcall(os.remove, mp) end)

  it("returns full state envelope", function()
    local resp = sui.handle({ path = "/api/load", method = "GET", body = "" })
    assert.equal(200, resp.status)
    local body = require("cjson").decode(resp.body)
    assert.is_true(body.success)
    assert.is_table(body.obj)
    assert.is_table(body.obj.config)
    assert.is_number(body.obj.mtime)
  end)
end)

describe("POST /api/save", function()
  local cp, mp
  before_each(function()
    cp = os.tmpname()
    local f = io.open(cp, "w")
    f:write([[{"inbounds":[],"outbounds":[]}]])
    f:close()
    mp = os.tmpname(); os.remove(mp)
    sui.config = { singbox_config_path = cp, meta_path = mp }
    require("config_io").singbox_cmd = "true --"
  end)
  after_each(function() os.remove(cp); pcall(os.remove, mp) end)

  it("saves new state and returns updated mtime", function()
    local load_resp = sui.handle({ path="/api/load", method="GET", body="" })
    local state = require("cjson").decode(load_resp.body).obj
    state.inbounds = {{ type="vmess", tag="t", users={} }}
    local body = require("cjson").encode(state)
    local resp = sui.handle({ path="/api/save", method="POST", body=body })
    local r = require("cjson").decode(resp.body)
    assert.is_true(r.success, r.msg)
    assert.is_number(r.obj.mtime)
  end)

  it("returns error on mtime conflict", function()
    local load_resp = sui.handle({ path="/api/load", method="GET", body="" })
    local state = require("cjson").decode(load_resp.body).obj
    state.mtime = 1  -- stale mtime
    local resp = sui.handle({ path="/api/save", method="POST", body=require("cjson").encode(state) })
    local r = require("cjson").decode(resp.body)
    assert.is_false(r.success)
    assert.matches("modified", r.msg)
  end)
end)

describe("GET /api/status", function()
  it("returns status envelope", function()
    sui.config = sui.config or {}
    sui.config.singbox_service = "sing-box"
    -- mock sing-box version
    require("api.status")._exec = function(cmd)
      if cmd:match("version") then return "sing-box version 1.10.0\n", 0 end
      if cmd:match("pidof") then return "", 1 end
      return "", 0
    end
    local resp = sui.handle({ path="/api/status", method="GET", body="" })
    local body = require("cjson").decode(resp.body)
    assert.is_true(body.success)
    assert.is_false(body.obj.running)
    assert.matches("1.10.0", body.obj.version)
  end)
end)

describe("GET /api/logs", function()
  it("returns log lines", function()
    require("api.logs")._exec = function(cmd)
      assert.matches("logread", cmd)
      assert.matches("tail %-n 50", cmd)
      return "line1\nline2\n", 0
    end
    local resp = sui.handle({ path="/api/logs", method="GET", body="",
                              query={ count="50", level="info" } })
    local body = require("cjson").decode(resp.body)
    assert.is_true(body.success)
    assert.same({"line1","line2"}, body.obj.lines)
  end)
end)

describe("sui.handle", function()
  it("returns 404 for unknown path", function()
    local resp = sui.handle({ path = "/api/nope", method = "GET", body = "" })
    assert.equal(404, resp.status)
  end)

  it("returns Msg-shaped JSON envelope", function()
    local resp = sui.handle({ path = "/api/nope", method = "GET", body = "" })
    local body = require("cjson").decode(resp.body)
    assert.is_false(body.success)
    assert.is_string(body.msg)
  end)
end)
