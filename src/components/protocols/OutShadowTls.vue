<template>
  <v-card subtitle="ShadowTls">
    <v-row>
      <v-col cols="12" sm="6" md="4">
        <v-select v-model="version" hide-details :items="[1, 2, 3]" :label="$t('version')"> </v-select>
      </v-col>
      <v-col v-if="data.version > 1" cols="12" sm="6" md="4">
        <v-text-field v-model="data.password" :label="$t('types.pw')" hide-details> </v-text-field>
      </v-col>
    </v-row>
  </v-card>
</template>

<script lang="ts">
export default {
  props: ["data"],
  data() {
    return {};
  },
  computed: {
    version: {
      get() {
        return this.$props.data.version ?? 3;
      },
      set(v: number) {
        this.$props.data.version = v;
        if (v == 1) {
          delete this.$props.data.password;
        } else if (this.$props.data.password === undefined) {
          this.$props.data.password = "";
        }
      },
    },
  },
};
</script>
