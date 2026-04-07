<template>
  <v-select v-model="Network" hide-details :label="$t('network')" :items="networks"> </v-select>
</template>

<script lang="ts">
export default {
  props: ["data"],
  data() {
    return {
      networks: [
        { title: "TCP/UDP", value: "" },
        { title: "TCP", value: "tcp" },
        { title: "UDP", value: "udp" },
      ],
    };
  },
  computed: {
    Network: {
      get(): string {
        return this.$props.data.network ?? "";
      },
      set(v: string) {
        this.$props.data.network = v == "" ? undefined : v;
      },
    },
  },
};
</script>
