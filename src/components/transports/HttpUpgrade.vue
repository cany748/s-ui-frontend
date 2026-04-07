<template>
  <v-row>
    <v-col cols="12" sm="6" md="4">
      <v-text-field v-model="transport.host" :label="$t('transport.hosts')" hide-details> </v-text-field>
    </v-col>
    <v-col cols="12" sm="6" md="4">
      <v-text-field v-model="transport.path" :label="$t('transport.path')" hide-details> </v-text-field>
    </v-col>
  </v-row>
  <Headers :data="transport" />
</template>

<script lang="ts">
import Headers from "../Headers.vue";

export default {
  components: { Headers },
  props: ["transport"],
  data() {
    return {};
  },
};
</script>
