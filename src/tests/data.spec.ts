import { beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";

import api from "@/plugins/api";
import Data from "@/store/modules/data";

vi.mock("@/plugins/api", () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));
vi.mock("notivue", () => ({ push: { success: vi.fn(), error: vi.fn(), warning: vi.fn() } }));
vi.mock("@/locales", () => ({ i18n: { global: { t: (k: string) => k } } }));

const mockLoadResponse = {
  data: {
    success: true,
    msg: "",
    obj: {
      config: { log: { level: "info" } },
      inbounds: [{ id: 1, type: "vmess", tag: "vmess-in", users: [] }],
      outbounds: [{ id: 1, type: "direct", tag: "direct" }],
      services: [],
      endpoints: [],
      clients: [{ id: 1, name: "alice", config: {}, inbounds: [] }],
      tls: [],
      meta: { tlsBindings: { inbound: {}, outbound: {} }, clientBindings: {} },
      mtime: 1_234_567_890,
      warnings: [],
    },
  },
};

describe("data store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it("loadData populates store from api/load", async () => {
    vi.mocked(api.get).mockResolvedValue(mockLoadResponse);
    const store = Data();
    await store.loadData();
    expect(api.get).toHaveBeenCalledWith("api/load");
    expect(store.mtime).toBe(1_234_567_890);
    expect(store.inbounds).toHaveLength(1);
    expect(store.inbounds[0].tag).toBe("vmess-in");
    expect(store.clients).toHaveLength(1);
    expect(store.clients[0].name).toBe("alice");
  });

  it("save posts full state and updates mtime on success", async () => {
    vi.mocked(api.get).mockResolvedValue(mockLoadResponse);
    vi.mocked(api.post).mockResolvedValue({
      data: { success: true, msg: "saved", obj: { mtime: 9999 } },
    });
    // second call (reload after save)
    vi.mocked(api.get)
      .mockResolvedValueOnce(mockLoadResponse)
      .mockResolvedValue({ ...mockLoadResponse, data: { ...mockLoadResponse.data, obj: { ...mockLoadResponse.data.obj, mtime: 9999 } } });

    const store = Data();
    await store.loadData();
    const result = await store.save("inbounds", "add", { id: 2, type: "vless", tag: "vless-in" });
    expect(result).toBe(true);
    expect(api.post).toHaveBeenCalledWith("api/save", expect.objectContaining({ mtime: 1_234_567_890 }));
    expect(store.mtime).toBe(9999);
  });

  it("save returns false and reloads on conflict", async () => {
    vi.mocked(api.get).mockResolvedValue(mockLoadResponse);
    vi.mocked(api.post).mockResolvedValue({
      data: { success: false, msg: "config modified", obj: { code: "conflict" } },
    });
    vi.mocked(api.get).mockResolvedValueOnce(mockLoadResponse).mockResolvedValue(mockLoadResponse);

    const store = Data();
    await store.loadData();
    const result = await store.save("inbounds", "add", { id: 2, tag: "x" });
    expect(result).toBe(false);
    expect(api.get).toHaveBeenCalledTimes(2);
  });

  it("loadInbounds filters from store state", async () => {
    vi.mocked(api.get).mockResolvedValue(mockLoadResponse);
    const store = Data();
    await store.loadData();
    const result = await store.loadInbounds([1]);
    expect(result).toHaveLength(1);
    expect(result[0].tag).toBe("vmess-in");
  });

  it("checkTag returns true for duplicate", async () => {
    vi.mocked(api.get).mockResolvedValue(mockLoadResponse);
    const store = Data();
    await store.loadData();
    const isDuplicate = store.checkTag("inbound", 0, "vmess-in");
    expect(isDuplicate).toBe(true);
  });
});
