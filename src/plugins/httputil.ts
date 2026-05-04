import { push } from "notivue";
import api from "./api";
import { i18n } from "@/locales";

export interface Msg {
  success: boolean;
  msg: string;
  obj: any | null;
}

function _handleMsg(msg: Msg): void {
  if (!isMsg(msg)) {
    return;
  }
  if (msg.msg) {
    if (msg.success) {
      push.success({
        message: `${i18n.global.t("success")}: ${i18n.global.t(`actions.${msg.msg}`)}`,
      });
    } else {
      push.error({
        title: i18n.global.t("failed"),
        message: msg.msg,
      });
    }
  }
}

function _respToMsg(resp: any): Msg {
  const data = resp.data;
  if (data == null) {
    return { success: true, msg: "", obj: null };
  } else if (isMsg(data)) {
    return Object.hasOwn(data, "success") ? { success: data.success, msg: data.msg ?? "", obj: data.obj || null } : data;
  } else {
    return { success: false, msg: `unknown data: ${JSON.stringify(data)}`, obj: null };
  }
}

function isMsg(obj: any): obj is Msg {
  return Object.hasOwn(obj, "success") && Object.hasOwn(obj, "msg") && Object.hasOwn(obj, "obj");
}

const HttpUtils = {
  async get(url: string, data: object = {}): Promise<Msg> {
    let msg: Msg;
    try {
      const resp = await api.get(url, { params: data });
      msg = _respToMsg(resp);
    } catch (error: any) {
      msg = { success: false, msg: error.toString(), obj: null };
    }
    _handleMsg(msg);
    return msg;
  },
  async post(url: string, data: object | null, options: any = undefined): Promise<Msg> {
    let msg: Msg;
    try {
      const resp = await api.post(url, data, options);
      msg = _respToMsg(resp);
    } catch (error: any) {
      msg = { success: false, msg: error.toString(), obj: null };
    }
    _handleMsg(msg);
    return msg;
  },
};

export default HttpUtils;
