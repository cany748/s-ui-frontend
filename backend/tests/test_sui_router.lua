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
