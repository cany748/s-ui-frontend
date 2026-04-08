local mapper = require("meta_mapper")
local helpers = require("tests.helpers")

describe("meta_mapper.extract_tls", function()
  it("returns no tls configs if config has no tls blocks", function()
    local config = helpers.load_fixture("vmess-simple.json")
    local new_config, tls_configs, bindings = mapper.extract_tls(config)
    assert.equal(0, #tls_configs)
    assert.same({}, bindings.inbound)
    assert.same({}, bindings.outbound)
    assert.is_nil(new_config.inbounds[1].tls_id)
  end)

  it("extracts tls block from inbound and replaces with tls_id", function()
    local config = helpers.load_fixture("trojan-tls.json")
    local new_config, tls_configs, bindings = mapper.extract_tls(config)
    assert.equal(1, #tls_configs)
    assert.equal(1, tls_configs[1].id)
    assert.equal("example.com", tls_configs[1].tls.server_name)
    assert.equal(1, bindings.inbound["trojan-in"])
    assert.is_nil(new_config.inbounds[1].tls)
    assert.equal(1, new_config.inbounds[1].tls_id)
  end)

  it("deduplicates identical tls blocks across inbounds", function()
    local config = helpers.load_fixture("multi-tls.json")
    local new_config, tls_configs, bindings = mapper.extract_tls(config)
    assert.equal(2, #tls_configs)
    assert.equal(bindings.inbound["vless-in-1"], bindings.inbound["trojan-in-2"])
    assert.is_truthy(bindings.outbound["vless-out"])
    assert.are_not.equal(bindings.inbound["vless-in-1"], bindings.outbound["vless-out"])
  end)
end)

describe("meta_mapper.extract_clients", function()
  it("extracts users from vmess inbound into clients", function()
    local config = helpers.load_fixture("vmess-simple.json")
    local _, clients, bindings = mapper.extract_clients(config)
    assert.equal(2, #clients)
    assert.equal("alice", clients[1].name)
    assert.is_table(clients[1].config.vmess)
    assert.equal("11111111-1111-1111-1111-111111111111", clients[1].config.vmess.uuid)
    assert.same({1, 2}, bindings["vmess-in"])
  end)

  it("merges identical clients across multiple inbounds by name", function()
    local config = helpers.load_fixture("multi-tls.json")
    local _, clients, bindings = mapper.extract_clients(config)
    assert.equal(1, #clients)
    assert.equal("alice", clients[1].name)
    assert.is_table(clients[1].config.vless)
    assert.is_table(clients[1].config.trojan)
    assert.same({1}, bindings["vless-in-1"])
    assert.same({1}, bindings["trojan-in-2"])
  end)
end)

describe("meta_mapper.inline_tls", function()
  it("inlines tls block by tls_id and removes tls_id", function()
    local inbounds = {
      { type = "trojan", tag = "in1", tls_id = 1, users = {} }
    }
    local outbounds = {
      { type = "vless", tag = "out1", tls_id = 2 }
    }
    local tls_configs = {
      { id = 1, name = "in-tls", tls = { enabled = true, server_name = "a.com" } },
      { id = 2, name = "out-tls", tls = { enabled = true, server_name = "b.com" } },
    }
    local new_in, new_out = mapper.inline_tls(inbounds, outbounds, tls_configs)
    assert.equal("a.com", new_in[1].tls.server_name)
    assert.is_nil(new_in[1].tls_id)
    assert.equal("b.com", new_out[1].tls.server_name)
    assert.is_nil(new_out[1].tls_id)
  end)

  it("leaves elements without tls_id unchanged", function()
    local inbounds = { { type = "vmess", tag = "in1", users = {} } }
    local new_in = mapper.inline_tls(inbounds, {}, {})
    assert.is_nil(new_in[1].tls)
  end)

  it("returns error for unknown tls_id", function()
    local inbounds = { { type = "trojan", tag = "in1", tls_id = 99 } }
    assert.has_error(function() mapper.inline_tls(inbounds, {}, {}) end)
  end)
end)

describe("meta_mapper.validate_clients", function()
  it("passes when all client refs map to existing users", function()
    local inbounds = {
      { type = "vmess", tag = "in1", users = {
        { name = "alice", uuid = "11111111-1111-1111-1111-111111111111" }
      }}
    }
    local clients = {
      { id = 1, name = "alice", enable = true,
        config = { vmess = { uuid = "11111111-1111-1111-1111-111111111111" } },
        inbounds = {"in1"} }
    }
    local ok, err = mapper.validate_clients(inbounds, clients)
    assert.is_true(ok, err)
  end)

  it("fails when client references nonexistent inbound", function()
    local clients = {
      { id = 1, name = "ghost", enable = true, config = {}, inbounds = {"missing"} }
    }
    local ok, err = mapper.validate_clients({}, clients)
    assert.is_false(ok)
    assert.matches("missing", err)
  end)
end)

describe("meta_mapper.save", function()
  it("round-trips simple vmess config", function()
    local original = helpers.load_fixture("vmess-simple.json")
    local state = mapper.load(original, nil)
    local sb_config, sui_meta = mapper.save(state)
    assert.equal(#original.inbounds, #sb_config.inbounds)
    assert.equal("vmess-in", sb_config.inbounds[1].tag)
    assert.equal(2, #sb_config.inbounds[1].users)
    assert.is_nil(sb_config.inbounds[1].tls_id)
  end)

  it("round-trips reality config preserving tls block", function()
    local original = helpers.load_fixture("vless-reality.json")
    local state = mapper.load(original, nil)
    local sb_config, sui_meta = mapper.save(state)
    local tls = sb_config.inbounds[1].tls
    assert.is_table(tls)
    assert.is_true(tls.reality.enabled)
    assert.is_nil(sb_config.inbounds[1].tls_id)
    assert.equal(1, #sui_meta.tlsConfigs)
  end)

  it("round-trips multi-tls config", function()
    local original = helpers.load_fixture("multi-tls.json")
    local state = mapper.load(original, nil)
    local sb_config, sui_meta = mapper.save(state)
    assert.equal("shared.example.com", sb_config.inbounds[1].tls.server_name)
    assert.equal("shared.example.com", sb_config.inbounds[2].tls.server_name)
    assert.equal("remote.example.com", sb_config.outbounds[2].tls.server_name)
    assert.equal(2, #sui_meta.tlsConfigs)
  end)
end)

describe("meta_mapper round-trip idempotence", function()
  local fixtures = {
    "empty.json", "vmess-simple.json", "vless-reality.json",
    "trojan-tls.json", "wireguard-endpoint.json", "multi-tls.json",
  }
  for _, name in ipairs(fixtures) do
    it("is idempotent for " .. name, function()
      local original = helpers.load_fixture(name)
      local state1 = mapper.load(original, nil)
      local sb1, meta1 = mapper.save(state1)
      local state2 = mapper.load(sb1, meta1)
      local sb2, meta2 = mapper.save(state2)
      assert.is_true(helpers.deep_equal(sb1, sb2),
        "second pass differs for " .. name)
    end)
  end
end)

describe("meta_mapper.load", function()
  it("composes extract_tls + extract_clients into store-shaped object", function()
    local config = helpers.load_fixture("vless-reality.json")
    local result = mapper.load(config, nil)
    assert.is_table(result.config)
    assert.equal("info", result.config.log.level)
    assert.equal(1, #result.inbounds)
    assert.equal(1, result.inbounds[1].tls_id)
    assert.is_nil(result.inbounds[1].tls)
    assert.equal(1, #result.tls)
    assert.equal(1, #result.clients)
    assert.equal("alice", result.clients[1].name)
  end)

  it("preserves tls config name from existing meta", function()
    local config = helpers.load_fixture("trojan-tls.json")
    local existing_meta = {
      tlsConfigs = {
        { id = 5, name = "my-cert", tls = config.inbounds[1].tls }
      }
    }
    local result = mapper.load(config, existing_meta)
    assert.equal("my-cert", result.tls[1].name)
  end)
end)
