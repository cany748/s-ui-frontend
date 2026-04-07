<template>
  <v-card subtitle="VMESS">
    <v-row>
      <v-col cols="12" sm="6">
        <v-text-field v-model="data.uuid" label="UUID" hide-details></v-text-field>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-text-field v-model.number="data.alter_id" label="Alter ID" hide-details type="number" min="0"> </v-text-field>
      </v-col>
    </v-row>
    <v-row>
      <v-col cols="12" sm="6" md="4">
        <v-select v-model="data.security" hide-details :label="$t('types.vmess.security')" :items="securities"> </v-select>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-select v-model="packet_encoding" hide-details :label="$t('types.vless.udpEnc')" :items="['none', 'packetaddr', 'xudp']">
        </v-select>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <Network :data="data" />
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-switch v-model="data.global_padding" color="primary" :label="$t('types.vmess.globalPadding')" hide-details></v-switch>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-switch v-model="data.authenticated_length" color="primary" :label="$t('types.vmess.authLen')" hide-details></v-switch>
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
    return {
      securities: ["auto", "none", "zero", "aes-128-gcm", "aes-128-ctr", "chacha20-poly1305"],
    };
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
