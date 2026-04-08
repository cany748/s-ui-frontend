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

describe("POST /api/restart", function()
  it("calls service restart and returns success", function()
    require("api.restart")._exec = function(cmd)
      assert.matches("/etc/init.d/sing%-box restart", cmd)
      return "", 0
    end
    local resp = sui.handle({ path="/api/restart", method="POST", body="" })
    local body = require("cjson").decode(resp.body)
    assert.is_true(body.success)
  end)

  it("returns error if service restart fails", function()
    require("api.restart")._exec = function(cmd) return "boom", 1 end
    local resp = sui.handle({ path="/api/restart", method="POST", body="" })
    local body = require("cjson").decode(resp.body)
    assert.is_false(body.success)
    assert.matches("boom", body.msg)
  end)
end)

describe("GET /api/checkOutbound", function()
  it("returns delay from clash api", function()
    require("api.check_outbound")._http_get = function(url)
      assert.matches("/proxies/myout/delay", url)
      return 200, '{"delay":123}'
    end
    sui.config = sui.config or {}
    sui.config.clash_api_url = "http://127.0.0.1:9090"
    sui.config.clash_api_secret = ""
    local resp = sui.handle({ path="/api/checkOutbound", method="GET", body="",
                              query={tag="myout"} })
    local b = require("cjson").decode(resp.body)
    assert.is_true(b.success)
    assert.equal(123, b.obj.delay)
  end)
end)

describe("GET /api/keypairs", function()
  before_each(function()
    require("api.keypairs")._exec = function(cmd)
      if cmd:match("uuid") then
        return "11111111-1111-1111-1111-111111111111\n", 0
      elseif cmd:match("reality%-keypair") then
        return "PrivateKey: AAA\nPublicKey: BBB\n", 0
      elseif cmd:match("wireguard%-keypair") then
        return "PrivateKey: WGPRIV\nPublicKey: WGPUB\n", 0
      elseif cmd:match("tls%-keypair") then
        return "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----\n" ..
               "-----BEGIN CERTIFICATE-----\nCERT\n-----END CERTIFICATE-----\n", 0
      end
      return "", 1
    end
  end)

  it("generates uuid", function()
    local resp = sui.handle({ path="/api/keypairs", method="GET", body="", query={type="uuid"} })
    local b = require("cjson").decode(resp.body)
    assert.equal("11111111-1111-1111-1111-111111111111", b.obj.uuid)
  end)

  it("generates reality keypair", function()
    local resp = sui.handle({ path="/api/keypairs", method="GET", body="", query={type="reality"} })
    local b = require("cjson").decode(resp.body)
    assert.equal("AAA", b.obj.private_key)
    assert.equal("BBB", b.obj.public_key)
  end)

  it("generates wireguard keypair", function()
    local resp = sui.handle({ path="/api/keypairs", method="GET", body="", query={type="wireguard"} })
    local b = require("cjson").decode(resp.body)
    assert.equal("WGPRIV", b.obj.private_key)
  end)

  it("generates tls keypair", function()
    local resp = sui.handle({ path="/api/keypairs", method="GET", body="",
                              query={ type="tls", server_name="example.com" } })
    local b = require("cjson").decode(resp.body)
    assert.matches("PRIVATE KEY", b.obj.private_key)
    assert.matches("CERTIFICATE", b.obj.certificate)
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
