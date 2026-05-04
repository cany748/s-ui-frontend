import { defineStore } from "pinia";
import { push } from "notivue";
import api from "@/plugins/api";
import { i18n } from "@/locales";
import type { Inbound } from "@/types/inbounds";
import type { Client } from "@/types/clients";

interface MetaBindings {
  tlsBindings: { inbound: Record<string, number>; outbound: Record<string, number> };
  clientBindings: Record<string, number[]>;
}

interface DataState {
  mtime: number;
  reloadItems: string[];
  onlines: { inbound: string[]; outbound: string[]; user: string[] };
  config: any;
  inbounds: any[];
  outbounds: any[];
  services: any[];
  endpoints: any[];
  clients: any[];
  tlsConfigs: any[];
  meta: MetaBindings;
}

const Data = defineStore("Data", {
  state: (): DataState => ({
    mtime: 0,
    reloadItems: localStorage.getItem("reloadItems")?.split(",") ?? [],
    onlines: { inbound: [], outbound: [], user: [] },
    config: {},
    inbounds: [],
    outbounds: [],
    services: [],
    endpoints: [],
    clients: [],
    tlsConfigs: [],
    meta: { tlsBindings: { inbound: {}, outbound: {} }, clientBindings: {} },
  }),
  actions: {
    async loadData() {
      let respData: any;
      try {
        const resp = await api.get("api/load");
        respData = resp.data;
      } catch (e: any) {
        push.error({ title: i18n.global.t("failed"), message: e.toString() });
        return;
      }
      if (!respData?.success) {
        push.error({ title: i18n.global.t("failed"), message: respData?.msg ?? "load failed" });
        return;
      }
      const d = respData.obj;
      if (d.warnings?.length) {
        push.warning({
          title: i18n.global.t("warning") ?? "Warning",
          message: d.warnings.join(", "),
          duration: 8000,
        });
      }
      this.mtime = d.mtime ?? 0;
      this.config = d.config ?? {};
      this.inbounds = d.inbounds ?? [];
      this.outbounds = d.outbounds ?? [];
      this.services = d.services ?? [];
      this.endpoints = d.endpoints ?? [];
      this.clients = d.clients ?? [];
      this.tlsConfigs = d.tls ?? [];
      this.meta = d.meta ?? { tlsBindings: { inbound: {}, outbound: {} }, clientBindings: {} };
    },

    async save(object: string, action: string, data: any, initUsers?: number[]): Promise<boolean> {
      this._applyMutation(object, action, data);

      // Services live under config.experimental.services in sing-box config
      const configWithServices = {
        ...this.config,
        experimental: {
          ...(this.config.experimental ?? {}),
          ...(this.services.length > 0 ? { services: this.services } : {}),
        },
      };

      const payload = {
        config: configWithServices,
        inbounds: this.inbounds,
        outbounds: this.outbounds,
        endpoints: this.endpoints,
        services: this.services,
        clients: this.clients,
        tls: this.tlsConfigs,
        meta: this.meta,
        mtime: this.mtime,
      };

      let respData: any;
      try {
        const resp = await api.post("api/save", payload);
        respData = resp.data;
      } catch (e: any) {
        respData = { success: false, msg: e.toString(), obj: null };
      }

      if (respData?.success) {
        this.mtime = respData.obj?.mtime ?? this.mtime;
        const objectName = ["tls", "config"].includes(object)
          ? object
          : object.slice(0, Math.max(0, object.length - 1));
        push.success({
          title: i18n.global.t("success"),
          duration: 5000,
          message: `${i18n.global.t(`actions.${action}`)} ${i18n.global.t(`objects.${objectName}`)}`,
        });
        await this.loadData();
        return true;
      } else {
        await this.loadData();
        if (respData?.obj?.code === "conflict") {
          push.error({
            title: i18n.global.t("error.conflict") ?? "Conflict",
            message: i18n.global.t("error.configModified") ?? "Config was modified externally.",
          });
        } else {
          push.error({
            title: i18n.global.t("failed"),
            message: respData?.msg ?? "save failed",
          });
        }
        return false;
      }
    },

    _applyMutation(object: string, action: string, data: any) {
      if (object === "config" && action === "set") {
        this.config = { ...data };
        return;
      }
      const key = this._objectToStateKey(object);
      if (!key) return;
      const list: any[] = (this as any)[key];
      if (!Array.isArray(list)) return;

      if (action === "add") {
        list.push(data);
      } else if (action === "edit") {
        const idx = list.findIndex((i: any) => i.id === data.id);
        if (idx !== -1) list.splice(idx, 1, data);
      } else if (action === "del") {
        const idx = list.findIndex((i: any) => i.id === data.id);
        if (idx !== -1) list.splice(idx, 1);
      } else if (action === "bulk") {
        if (Array.isArray(data)) list.push(...data);
      }
    },

    _objectToStateKey(object: string): string | null {
      const map: Record<string, string> = {
        inbounds: "inbounds",
        outbounds: "outbounds",
        services: "services",
        endpoints: "endpoints",
        clients: "clients",
        tls: "tlsConfigs",
      };
      return map[object] ?? null;
    },

    async loadRuntime() {
      try {
        const resp = await api.get("clash/connections");
        const connections: any[] = resp.data?.connections ?? [];
        const inboundSet = new Set<string>();
        const outboundSet = new Set<string>();
        const userSet = new Set<string>();
        for (const conn of connections) {
          if (conn.metadata?.inboundName) inboundSet.add(conn.metadata.inboundName);
          if (conn.chains?.[0]) outboundSet.add(conn.chains[0]);
          if (conn.metadata?.user) userSet.add(conn.metadata.user);
        }
        this.onlines = {
          inbound: [...inboundSet],
          outbound: [...outboundSet],
          user: [...userSet],
        };
      } catch {
        // Clash API unavailable — leave onlines unchanged
      }
    },

    async loadInbounds(ids: number[]): Promise<Inbound[]> {
      if (ids.length === 0) return this.inbounds as Inbound[];
      return this.inbounds.filter((i: any) => ids.includes(i.id)) as Inbound[];
    },

    async loadClients(id: number): Promise<Client> {
      if (id <= 0) return {} as Client;
      return (this.clients.find((c: any) => c.id === id) ?? {}) as Client;
    },

    checkClientName(id: number, newName: string): boolean {
      const oldName = id > 0 ? this.clients.findLast((i: any) => i.id == id)?.name : null;
      if (newName != oldName && this.clients.some((c: any) => c.name == newName)) {
        push.error({ message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("client.name")}` });
        return true;
      }
      return false;
    },

    checkBulkClientNames(names: string[]): boolean {
      const newNames = new Set(names);
      const oldNames = new Set(this.clients.map((c: any) => c.name));
      const allNames = new Set([...oldNames, ...newNames]);
      if (newNames.size != names.length || oldNames.size + newNames.size != allNames.size) {
        push.error({ message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("client.name")}` });
        return true;
      }
      return false;
    },

    checkTag(object: string, id: number, tag: string): boolean {
      const normalized = object.endsWith("s") ? object : object + "s";
      const key = this._objectToStateKey(normalized);
      if (!key) return false;
      const objects: any[] = (this as any)[key] ?? [];
      const oldObject = id > 0 ? objects.findLast((i: any) => i.id == id) : null;
      if (tag != oldObject?.tag && objects.some((i: any) => i.tag == tag)) {
        push.error({ message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("objects.tag")}` });
        return true;
      }
      return false;
    },
  },
});

export default Data;
