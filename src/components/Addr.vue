<template>
  <v-row>
    <v-col cols="12" sm="6" md="4">
      <v-text-field v-model="addr.server" :label="$t('out.addr')" hide-details required> </v-text-field>
    </v-col>
    <v-col cols="12" sm="6" md="4">
      <v-text-field v-model.number="addr.server_port" :label="$t('out.port')" hide-details type="number" required></v-text-field>
    </v-col>
    <v-col v-if="optionRemark" cols="12" sm="6" md="4">
      <v-text-field v-model="addr.remark" :label="$t('in.remark')" hide-details> </v-text-field>
    </v-col>
  </v-row>
  <OutTLS v-if="optionTLS" :outbound="addr" />
  <v-row>
    <v-spacer></v-spacer>
    <v-col cols="auto" align="end" justify="center">
      <v-menu v-model="menu" :close-on-content-click="false" location="start">
        <template #activator="{ props }">
          <v-btn v-bind="props" hide-details variant="tonal">{{ $t("in.mdOption") }}</v-btn>
        </template>
        <v-card>
          <v-list>
            <v-list-item>
              <v-switch v-model="optionRemark" color="primary" :label="$t('in.remark')" hide-details></v-switch>
            </v-list-item>
            <v-list-item v-if="hasTls">
              <v-switch v-model="optionTLS" color="primary" :label="$t('objects.tls')" hide-details></v-switch>
            </v-list-item>
          </v-list>
        </v-card>
      </v-menu>
    </v-col>
  </v-row>
</template>

<script lang="ts">
import OutTLS from "@/components/tls/OutTLS.vue";

export default {
  components: {
    OutTLS,
  },
  props: ["addr", "hasTls"],
  data() {
    return {
      menu: false,
    };
  },
  computed: {
    optionTLS: {
      get(): boolean {
        return this.$props.addr.tls != undefined;
      },
      set(v: boolean) {
        this.$props.addr.tls = v ? { enabled: true } : undefined;
      },
    },
    optionRemark: {
      get(): boolean {
        return this.$props.addr.remark != undefined;
      },
      set(v: boolean) {
        this.$props.addr.remark = v ? "" : undefined;
      },
    },
  },
};
</script>
