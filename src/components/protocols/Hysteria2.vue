<template>
  <v-card subtitle="Hysteria2">
    <v-row>
      <v-col v-if="direction == 'in'" cols="12" sm="6" md="4">
        <v-switch v-model="data.ignore_client_bandwidth" color="primary" :label="$t('types.hy.ignoreBw')" hide-details></v-switch>
      </v-col>
      <v-col v-if="!data.ignore_client_bandwidth" cols="12" sm="6" md="4">
        <v-text-field v-model.number="up_mbps" :label="$t('stats.upload')" hide-details type="number" :suffix="$t('stats.Mbps')" min="0">
        </v-text-field>
      </v-col>
      <v-col v-if="!data.ignore_client_bandwidth" cols="12" sm="6" md="4">
        <v-text-field
          v-model.number="down_mbps"
          :label="$t('stats.download')"
          hide-details
          type="number"
          :suffix="$t('stats.Mbps')"
          min="0"
        >
        </v-text-field>
      </v-col>
    </v-row>
    <v-row>
      <v-col v-if="data.obfs != undefined" cols="12" sm="6" md="4">
        <v-text-field v-model="data.obfs.password" :label="$t('types.hy.obfs')" hide-details> </v-text-field>
      </v-col>
    </v-row>
    <template v-if="direction == 'in'">
      <v-card v-if="data.masquerade != undefined" subtitle="Hysteria2 Masquerade">
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <v-select v-model="masqueradeType" hide-details :label="$t('type')" :items="masqTypes"></v-select>
          </v-col>
          <v-col v-if="masqueradeType == ''" cols="12" sm="8">
            <v-text-field
              v-model="data.masquerade"
              label="HTTP3 server on auth fails"
              placeholder="file:///var/www | http://127.0.0.1:8080"
              hide-details
            >
            </v-text-field>
          </v-col>
          <v-col v-if="masqueradeType == 'file'" cols="12" sm="8">
            <v-text-field v-model="data.masquerade.directory" label="File server root directory" placeholder="/var/www" hide-details>
            </v-text-field>
          </v-col>
          <v-col v-if="masqueradeType == 'string'" cols="12" sm="6" md="4">
            <v-text-field v-model.number="data.masquerade.status_code" label="HTTP Code" type="number" min="100" max="599" hide-details>
            </v-text-field>
          </v-col>
        </v-row>
        <v-row v-if="masqueradeType == 'proxy'">
          <v-col cols="12" sm="6">
            <v-text-field v-model="data.masquerade.url" label="Target URL" placeholder="http://example.com:8080" hide-details>
            </v-text-field>
          </v-col>
          <v-col cols="12" sm="6" md="4">
            <v-switch v-model="data.masquerade.rewrite_host" label="Rewrite Host" color="primary" hide-details> </v-switch>
          </v-col>
        </v-row>
        <template v-if="masqueradeType == 'string'">
          <v-row>
            <v-col cols="12" sm="8">
              <v-text-field v-model="data.masquerade.content" label="Content" hide-details> </v-text-field>
            </v-col>
          </v-row>
          <Headers :data="data.masquerade" />
        </template>
      </v-card>
    </template>
    <template v-else>
      <v-row>
        <v-col cols="12" sm="6" md="4">
          <v-text-field v-model="data.password" :label="$t('types.pw')" hide-details> </v-text-field>
        </v-col>
        <v-col cols="12" sm="6" md="4">
          <Network :data="data" />
        </v-col>
        <v-col v-if="optionMPort" cols="12" sm="8">
          <v-text-field v-model="server_ports" :label="`${$t('rule.portRange')} ${$t('commaSeparated')}`"> </v-text-field>
        </v-col>
        <v-col v-if="optionMPort" cols="12" sm="6" md="4">
          <v-text-field v-model.number="hop_interval" :label="$t('ruleset.interval')" type="number" min="0" :suffix="$t('date.s')">
          </v-text-field>
        </v-col>
      </v-row>
    </template>
    <v-card-actions>
      <v-spacer></v-spacer>
      <v-menu v-model="menu" :close-on-content-click="false" location="start">
        <template #activator="{ props }">
          <v-btn v-bind="props" hide-details variant="tonal">{{ $t("types.hy.hy2Options") }}</v-btn>
        </template>
        <v-card>
          <v-list>
            <v-list-item>
              <v-switch v-model="optionObfs" color="primary" :label="$t('types.hy.obfs')" hide-details></v-switch>
            </v-list-item>
            <template v-if="direction == 'in'">
              <v-list-item>
                <v-switch v-model="optionMasq" color="primary" label="Masquerade" hide-details></v-switch>
              </v-list-item>
            </template>
            <template v-else>
              <v-list-item>
                <v-switch v-model="optionMPort" color="primary" :label="$t('rule.portRange')" hide-details></v-switch>
              </v-list-item>
            </template>
          </v-list>
        </v-card>
      </v-menu>
    </v-card-actions>
  </v-card>
</template>

<script lang="ts">
import Network from "@/components/Network.vue";
import Headers from "@/components/Headers.vue";
import { i18n } from "@/locales";

export default {
  components: { Network, Headers },
  props: ["direction", "data"],
  data() {
    return {
      menu: false,
      masqTypes: [
        { title: i18n.global.t("rule.simple"), value: "" },
        { title: "File server", value: "file" },
        { title: "Reverse Proxy", value: "proxy" },
        { title: "Fixed response", value: "string" },
      ],
    };
  },
  computed: {
    down_mbps: {
      get() {
        return this.$props.data.down_mbps ?? 0;
      },
      set(v: number) {
        this.$props.data.down_mbps = v > 0 ? v : undefined;
      },
    },
    up_mbps: {
      get() {
        return this.$props.data.up_mbps ?? 0;
      },
      set(v: number) {
        this.$props.data.up_mbps = v > 0 ? v : undefined;
      },
    },
    server_ports: {
      get() {
        return this.$props.data.server_ports?.join(",") ?? [];
      },
      set(v: string) {
        this.$props.data.server_ports = v.length > 0 ? v.split(",") : undefined;
      },
    },
    masqueradeType: {
      get() {
        return typeof this.$props.data.masquerade === "object" ? (this.$props.data.masquerade.type ?? "") : "";
      },
      set(v: string) {
        this.$props.data.masquerade = v == "" ? "" : { type: v };
      },
    },
    hop_interval: {
      get() {
        return this.$props.data.hop_interval ? Number.parseInt(this.$props.data.hop_interval.replace("s", "")) : 0;
      },
      set(v: number) {
        this.$props.data.hop_interval = v > 0 ? `${v}s` : undefined;
      },
    },
    optionObfs: {
      get(): boolean {
        return this.$props.data.obfs != undefined;
      },
      set(v: boolean) {
        this.$props.data.obfs = v ? { type: "salamander", password: "" } : undefined;
      },
    },
    optionMasq: {
      get(): boolean {
        return this.$props.data.masquerade != undefined;
      },
      set(v: boolean) {
        this.$props.data.masquerade = v ? "" : undefined;
      },
    },
    optionMPort: {
      get(): boolean {
        return this.$props.data.server_ports != undefined;
      },
      set(v: boolean) {
        this.$props.data.server_ports = v ? [] : undefined;
      },
    },
  },
};
</script>
