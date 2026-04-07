import { defineStore } from "pinia";
import { push } from "notivue";
import HttpUtils from "@/plugins/httputil";
import { i18n } from "@/locales";
import type { Inbound } from "@/types/inbounds";
import type { Client } from "@/types/clients";

const Data = defineStore("Data", {
  state: () => ({
    lastLoad: 0,
    reloadItems: localStorage.getItem("reloadItems")?.split(",") ?? ([] as string[]),
    subURI: "",
    enableTraffic: false,
    onlines: { inbound: [] as string[], outbound: [] as string[], user: [] as string[] },
    config: {} as any,
    inbounds: [] as any[],
    outbounds: [] as any[],
    services: [] as any[],
    endpoints: [] as any[],
    clients: [] as any,
    tlsConfigs: [] as any[],
  }),
  actions: {
    async loadData() {
      const msg = await HttpUtils.get("api/load", this.lastLoad > 0 ? { lu: this.lastLoad } : {});
      if (msg.success) {
        this.onlines = msg.obj.onlines;
        if (msg.obj.lastLog) {
          push.error({
            title: i18n.global.t("error.core"),
            duration: 5000,
            message: msg.obj.lastLog,
          });
        }

        if (msg.obj.config) {
          this.setNewData(msg.obj);
        }
      }
    },
    setNewData(data: any) {
      this.lastLoad = Math.floor(Date.now() / 1000);
      if (data.subURI) this.subURI = data.subURI;
      if (data.enableTraffic) this.enableTraffic = data.enableTraffic;
      if (data.config) this.config = data.config;
      if (Object.hasOwn(data, "clients")) this.clients = data.clients ?? [];
      if (Object.hasOwn(data, "inbounds")) this.inbounds = data.inbounds ?? [];
      if (Object.hasOwn(data, "outbounds")) this.outbounds = data.outbounds ?? [];
      if (Object.hasOwn(data, "services")) this.services = data.services ?? [];
      if (Object.hasOwn(data, "endpoints")) this.endpoints = data.endpoints ?? [];
      if (Object.hasOwn(data, "tls")) this.tlsConfigs = data.tls ?? [];
    },
    async loadInbounds(ids: number[]): Promise<Inbound[]> {
      const options = ids.length > 0 ? { id: ids.join(",") } : {};
      const msg = await HttpUtils.get("api/inbounds", options);
      if (msg.success) {
        return msg.obj.inbounds;
      }
      return [] as Inbound[];
    },
    async loadClients(id: number): Promise<Client> {
      const options = id > 0 ? { id } : {};
      const msg = await HttpUtils.get("api/clients", options);
      if (msg.success) {
        return (msg.obj.clients[0] as Client) ?? {};
      }
      return {} as Client;
    },
    async save(object: string, action: string, data: any, initUsers?: number[]): Promise<boolean> {
      const postData = {
        object,
        action,
        data: JSON.stringify(data, null, 2),
        initUsers: initUsers?.join(",") ?? undefined,
      };
      const msg = await HttpUtils.post("api/save", postData);
      if (msg.success) {
        const objectName = ["tls", "config"].includes(object) ? object : object.slice(0, Math.max(0, object.length - 1));
        push.success({
          title: i18n.global.t("success"),
          duration: 5000,
          message: `${i18n.global.t(`actions.${action}`)} ${i18n.global.t(`objects.${objectName}`)}`,
        });
        this.setNewData(msg.obj);
      }
      return msg.success;
    },
    // Check duplicate client name
    checkClientName(id: number, newName: string): boolean {
      const oldName = id > 0 ? this.clients.findLast((i: any) => i.id == id)?.name : null;
      if (newName != oldName && this.clients.some((c: any) => c.name == newName)) {
        push.error({
          message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("client.name")}`,
        });
        return true;
      }
      return false;
    },
    // Check bulk client names
    checkBulkClientNames(names: string[]): boolean {
      const newNames = new Set(names);
      const oldNames = new Set(this.clients.map((c: any) => c.name));
      const allNames = new Set([...oldNames, ...newNames]);
      if (newNames.size != names.length || oldNames.size + newNames.size != allNames.size) {
        push.error({
          message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("client.name")}`,
        });
        return true;
      }
      return false;
    },
    // check duplicate tag
    checkTag(object: string, id: number, tag: string): boolean {
      let objects = [] as any[];
      switch (object) {
        case "inbound": {
          objects = this.inbounds;
          break;
        }
        case "outbound": {
          objects = this.outbounds;
          break;
        }
        case "service": {
          objects = this.services;
          break;
        }
        case "endpoint": {
          objects = this.endpoints;
          break;
        }
        default: {
          return false;
        }
      }
      const oldObject = id > 0 ? objects.findLast((i: any) => i.id == id) : null;
      if (tag != oldObject?.tag && objects.some((i: any) => i.tag == tag)) {
        push.error({
          message: `${i18n.global.t("error.dplData")}: ${i18n.global.t("objects.tag")}`,
        });
        return true;
      }
      return false;
    },
  },
});

export default Data;
