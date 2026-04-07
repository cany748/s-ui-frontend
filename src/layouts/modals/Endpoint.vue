<template>
  <v-dialog transition="dialog-bottom-transition" width="800">
    <v-card class="rounded-lg">
      <v-card-title>
        {{ `${$t(`actions.${title}`)} ${$t("objects.endpoint")}` }}
      </v-card-title>
      <v-divider></v-divider>
      <v-card-text style="padding: 0 16px; overflow-y: scroll">
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <v-select
              v-model="endpoint.type"
              hide-details
              :disabled="endpoint.id > 0"
              :label="$t('type')"
              :items="Object.keys(epTypes).map((key, index) => ({ title: key, value: Object.values(epTypes)[index] }))"
              @update:model-value="changeType"
            >
            </v-select>
          </v-col>
          <v-col cols="12" sm="6" md="4">
            <v-text-field v-model="endpoint.tag" :label="$t('objects.tag')" hide-details></v-text-field>
          </v-col>
        </v-row>
        <Wireguard
          v-if="endpoint.type == epTypes.Wireguard"
          :data="endpoint"
          @get-wg-pub-key="getWgPubKey"
          @new-wg-key="newWgKey"
          @add-peer="addWgPeer"
          @del-peer="delWgPeer"
          @refresh-peer-key="refreshWgPeerKey"
        />
        <Warp v-if="endpoint.type == epTypes.Warp" :data="endpoint" />
        <TailscaleVue v-if="endpoint.type == epTypes.Tailscale" :data="endpoint" />
        <Dial :dial="endpoint" />
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="primary" variant="outlined" @click="closeModal">
          {{ $t("actions.close") }}
        </v-btn>
        <v-btn color="primary" variant="tonal" :loading="loading" @click="saveChanges">
          {{ $t("actions.save") }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import { push } from "notivue";
import { EpTypes, createEndpoint } from "@/types/endpoints";
import RandomUtil from "@/plugins/randomUtil";
import Dial from "@/components/Dial.vue";
import Wireguard from "@/components/protocols/Wireguard.vue";
import Warp from "@/components/protocols/Warp.vue";
import TailscaleVue from "@/components/protocols/Tailscale.vue";
import HttpUtils from "@/plugins/httputil";
import { i18n } from "@/locales";
import Data from "@/store/modules/data";

export default {
  components: { Dial, Wireguard, Warp, TailscaleVue },
  props: ["visible", "data", "id", "tags"],
  emits: ["close"],
  data() {
    return {
      endpoint: createEndpoint("wireguard", { tag: "" }),
      title: "add",
      tab: "t1",
      loading: false,
      epTypes: EpTypes,
    };
  },
  watch: {
    visible(v) {
      if (v) {
        this.updateData(this.$props.id);
      }
    },
  },
  methods: {
    async updateData(id: number) {
      if (id > 0) {
        const newData = JSON.parse(this.$props.data);
        this.endpoint = createEndpoint(newData.type, newData);
        this.title = "edit";
      } else {
        this.endpoint.type = "wireguard";
        this.endpoint.listen_port = RandomUtil.randomIntRange(10_000, 60_000);
        this.changeType();
        this.title = "add";
      }
      this.tab = "t1";
    },
    async changeType() {
      // Tag change only in add endpoint
      const tag = `${this.endpoint.type}-${RandomUtil.randomSeq(3)}`;

      // Use previous data
      let prevConfig = {};
      switch (this.endpoint.type) {
        case EpTypes.Wireguard: {
          const wgKeys = await this.genWgKey();
          const randomIPoctet = RandomUtil.randomIntRange(1, 255);
          prevConfig = {
            tag,
            listen_port: this.endpoint.listen_port ?? RandomUtil.randomIntRange(10_000, 60_000),
            address: [`10.0.0.${randomIPoctet.toString()}/32`, `fe80::${randomIPoctet.toString(16)}/128`],
            private_key: wgKeys.private_key,
            peers: [],
            ext: {
              public_key: wgKeys.public_key,
              keys: [],
            },
          };
          break;
        }
        case EpTypes.Warp: {
          prevConfig = {
            tag,
          };
          break;
        }
        case EpTypes.Tailscale: {
          prevConfig = { tag };
          break;
        }
      }
      this.endpoint = createEndpoint(this.endpoint.type, prevConfig);
    },
    closeModal() {
      this.updateData(0); // reset
      this.$emit("close");
    },
    async saveChanges() {
      if (!this.$props.visible) return;

      // check duplicate tag
      const isDuplicatedTag = Data().checkTag("endpoint", this.endpoint.id, this.endpoint.tag);
      if (isDuplicatedTag) return;

      // save data
      this.loading = true;
      const success = await Data().save("endpoints", this.$props.id == 0 ? "new" : "edit", this.endpoint);
      if (success) this.closeModal();
      this.loading = false;
    },
    async genWgKey() {
      this.loading = true;
      const msg = await HttpUtils.get("api/keypairs", { k: "wireguard" });
      this.loading = false;
      const result = { private_key: "", public_key: "" };
      if (msg.success) {
        msg.obj.forEach((line: string) => {
          if (line.startsWith("PrivateKey")) {
            result.private_key = line.slice(12);
          }
          if (line.startsWith("PublicKey")) {
            result.public_key = line.slice(11);
          }
        });
      } else {
        push.error({
          message: `${i18n.global.t("error")}: ${msg.obj}`,
        });
      }
      return result;
    },
    async newWgKey() {
      this.loading = true;
      const newKeys = await this.genWgKey();
      this.endpoint.private_key = newKeys.private_key;
      if (!this.endpoint.ext) this.endpoint.ext = { keys: [] };
      this.endpoint.ext.public_key = newKeys.public_key;
      this.loading = false;
    },
    async getWgPubKey(private_key: string) {
      if (!this.endpoint.ext) this.endpoint.ext = { keys: [] };
      this.loading = true;
      const msg = await HttpUtils.get("api/keypairs", { k: "wireguard", o: private_key });
      if (msg.success) {
        this.endpoint.ext.public_key = msg.obj[0];
      }
      this.loading = false;
    },
    async addWgPeer() {
      if (this.endpoint.type != EpTypes.Wireguard) return;
      this.loading = true;
      const newKeys = await this.genWgKey();
      if (!this.endpoint.ext) this.endpoint.ext = { keys: [] };
      this.endpoint.ext.keys.push(newKeys);
      this.endpoint.peers.push({
        public_key: newKeys.public_key,
        allowed_ips: [this.findFreeIP()],
      });
      this.loading = false;
    },
    findFreeIP(): string {
      const peerAllowedIPs = new Set(this.endpoint.peers.flatMap((peer: any) => peer.allowed_ips));
      for (let i = 2; i < 255; i++) {
        const newIP = `10.0.1.${i.toString()}/32`;
        if (!peerAllowedIPs.has(newIP)) return newIP;
      }
      return "0.0.0.0/0";
    },
    delWgPeer(index: number) {
      if (this.endpoint.type != EpTypes.Wireguard) return;
      this.endpoint.ext.keys = this.endpoint.ext.keys.filter((key: any) => key.public_key != this.endpoint.peers[index].public_key);
      this.endpoint.peers.splice(index, 1);
    },
    async refreshWgPeerKey(index: number) {
      this.loading = true;
      const newKeys = await this.genWgKey();
      if (!this.endpoint.ext) this.endpoint.ext = { keys: [] };
      const indexKeys = this.endpoint.ext.keys.findIndex((key: any) => key.public_key == this.endpoint.peers[index].public_key);
      this.endpoint.ext.keys[indexKeys == -1 ? this.endpoint.ext.keys.length : indexKeys] = newKeys;
      this.endpoint.peers[index].public_key = newKeys.public_key;
      this.loading = false;
    },
  },
};
</script>
