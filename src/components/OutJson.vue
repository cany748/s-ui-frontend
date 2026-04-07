<template>
  <v-card :subtitle="$t('pages.basics')">
    <v-row>
      <v-col v-if="type == inTypes.SOCKS" cols="12" sm="6" md="4">
        <v-select v-model="inData.out_json.version" hide-details :items="['4', '4a', '5']" :label="$t('version')"> </v-select>
      </v-col>
      <v-col v-if="needNetwork" cols="12" sm="6" md="4">
        <Network :data="inData.out_json" />
      </v-col>
      <v-col v-if="needUot" cols="12" sm="6" md="4">
        <UoT :data="inData.out_json" />
      </v-col>
      <v-col v-if="type == inTypes.HTTP" cols="12" sm="6" md="4">
        <v-text-field v-model="inData.out_json.path" :label="$t('transport.path')" hide-details> </v-text-field>
      </v-col>
      <v-col v-if="type == inTypes.VMess || type == inTypes.VLESS" cols="12" sm="6" md="4">
        <v-select v-model="packet_encoding" hide-details :label="$t('types.vless.udpEnc')" :items="['none', 'packetaddr', 'xudp']">
        </v-select>
      </v-col>
      <template v-if="type == inTypes.VMess">
        <v-col cols="12" sm="6" md="4">
          <v-select v-model="inData.out_json.security" hide-details :label="$t('types.vmess.security')" :items="vmessSecurities">
          </v-select>
        </v-col>
        <v-col cols="12" sm="6" md="4">
          <v-switch
            v-model="inData.out_json.global_padding"
            color="primary"
            :label="$t('types.vmess.globalPadding')"
            hide-details
          ></v-switch>
        </v-col>
        <v-col cols="12" sm="6" md="4">
          <v-switch
            v-model="inData.out_json.authenticated_length"
            color="primary"
            :label="$t('types.vmess.authLen')"
            hide-details
          ></v-switch>
        </v-col>
      </template>
      <v-col v-if="type == inTypes.Hysteria" cols="12" sm="6" md="4">
        <v-text-field v-model.number="inData.out_json.recv_window" label="Recv window" hide-details type="number" min="0"> </v-text-field>
      </v-col>
      <template v-if="type == inTypes.TUIC">
        <v-col cols="12" sm="6" md="4">
          <v-select
            v-model="inData.out_json.udp_relay_mode"
            hide-details
            label="UDP Relay Mode"
            :items="['native', 'quic']"
            clearable
            @click:clear="delete inData.out_json.udp_relay_mode"
          >
          </v-select>
        </v-col>
        <v-col cols="12" sm="6" md="4">
          <v-switch v-model="inData.out_json.udp_over_stream" color="primary" label="UDP Over Stream" hide-details></v-switch>
        </v-col>
      </template>
    </v-row>
    <v-row v-if="[inTypes.Hysteria, inTypes.Hysteria2].includes(type)">
      <v-col cols="12" sm="8">
        <v-text-field v-model="server_ports" :label="`${$t('rule.portRange')} ${$t('commaSeparated')}`"> </v-text-field>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-text-field v-model.number="hop_interval" :label="$t('ruleset.interval')" type="number" min="0" :suffix="$t('date.s')">
        </v-text-field>
      </v-col>
    </v-row>
    <Headers v-if="type == inTypes.HTTP" :data="inData.out_json" />
    <AnyTls v-if="type == inTypes.AnyTls" :data="inData.out_json" direction="out_json" />
    <Naive v-if="type == inTypes.Naive" :data="inData.out_json" direction="out_json" />
  </v-card>
</template>

<script lang="ts">
import Network from "./Network.vue";
import UoT from "./UoT.vue";
import Headers from "./Headers.vue";
import AnyTls from "./protocols/AnyTls.vue";
import Naive from "./protocols/Naive.vue";
import { InTypes } from "@/types/inbounds";

export default {
  components: { Network, UoT, Headers, AnyTls, Naive },
  props: ["inData", "type"],
  data() {
    return {
      inTypes: InTypes,
      vmessSecurities: ["auto", "none", "zero", "aes-128-gcm", "aes-128-ctr", "chacha20-poly1305"],
      haveNetwork: [
        InTypes.SOCKS,
        InTypes.Shadowsocks,
        InTypes.VMess,
        InTypes.Trojan,
        InTypes.Hysteria,
        InTypes.VLESS,
        InTypes.TUIC,
        InTypes.Hysteria2,
      ],
      havUoT: [InTypes.SOCKS, InTypes.Shadowsocks],
    };
  },
  computed: {
    needNetwork(): boolean {
      return this.haveNetwork.includes(this.$props.type);
    },
    needUot(): boolean {
      return this.havUoT.includes(this.$props.type);
    },
    packet_encoding: {
      get() {
        return this.$props.inData.out_json.packet_encoding == undefined ? "none" : this.$props.inData.out_json.packet_encoding;
      },
      set(v: string) {
        this.$props.inData.out_json.packet_encoding = v == "none" ? undefined : v;
      },
    },
    server_ports: {
      get() {
        return this.$props.inData.out_json.server_ports?.join(",") ?? [];
      },
      set(v: string) {
        this.$props.inData.out_json.server_ports = v.length > 0 ? v.split(",") : undefined;
      },
    },
    hop_interval: {
      get() {
        return this.$props.inData.out_json.hop_interval ? Number.parseInt(this.$props.inData.out_json.hop_interval.replace("s", "")) : 0;
      },
      set(v: number) {
        this.$props.inData.out_json.hop_interval = v > 0 ? `${v}s` : undefined;
      },
    },
  },
};
</script>
