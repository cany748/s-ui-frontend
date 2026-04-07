<template>
  <v-card subtitle="VLESS">
    <v-row>
      <v-col cols="12" sm="6">
        <v-text-field v-model="data.uuid" label="UUID" hide-details></v-text-field>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-select v-model="data.flow" hide-details :label="$t('types.vless.flow')" :items="['', 'xtls-rprx-vision']"> </v-select>
      </v-col>
    </v-row>
    <v-row>
      <v-col cols="12" sm="6" md="4">
        <v-select v-model="packet_encoding" hide-details :label="$t('types.vless.udpEnc')" :items="['none', 'packetaddr', 'xudp']">
        </v-select>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <Network :data="data" />
      </v-col>
    </v-row>
  </v-card>
</template>

<script lang="ts">
import Network from "@/components/Network.vue";

export default {
  components: { Network },
  props: ["data"],
  data() {
    return {};
  },
  computed: {
    packet_encoding: {
      get() {
        return this.$props.data.packet_encoding == undefined ? "none" : this.$props.data.packet_encoding;
      },
      set(newValue: string) {
        this.$props.data.packet_encoding = newValue == "none" ? undefined : newValue;
      },
    },
  },
};
</script>
