<template>
  <v-row density="compact">
    <v-col cols="12" class="v-card-subtitle" style="margin-top: -5px">{{ label }}</v-col>
    <v-col :cols="data.type == 'local' ? 12 : 4">
      <v-select
        v-model="data.type"
        hide-details
        :label="$t('type')"
        :items="['udp', 'tcp', 'local', 'tls', 'quic', 'h3']"
        density="compact"
        :class="data.type != 'local' ? 'noGutters' : ''"
        @update:model-value="updateType($event)"
      >
      </v-select>
    </v-col>
    <v-col v-if="data.type != 'local'" cols="5">
      <v-text-field v-model="data.server" :label="$t('in.addr')" density="compact" class="noGutters" hide-details> </v-text-field>
    </v-col>
    <v-col v-if="data.type != 'local'" cols="3">
      <v-text-field
        v-model.number="data.server_port"
        :label="$t('in.port')"
        density="compact"
        type="number"
        class="noGutters"
        min="1"
        hide-details
      >
      </v-text-field>
    </v-col>
  </v-row>
</template>

<script lang="ts">
export default {
  props: ["data", "label"],
  data() {
    return {};
  },
  methods: {
    updateType(t: string) {
      if (t == "local") {
        delete this.data.server;
        delete this.data.server_port;
      }
    },
  },
};
</script>

<style>
.noGutters .v-field__input,
.noGutters .v-field {
  text-align: center !important;
  padding-inline-end: 0 !important;
}
</style>
