<template>
  <v-dialog
    :model-value="visible"
    transition="dialog-bottom-transition"
    width="90%"
    max-width="400"
    @update:model-value="$emit('update:visible', $event)"
  >
    <v-card class="rounded-lg" :loading="loading">
      <v-card-title>
        <v-row>
          <v-col>{{ $t("main.stats.title") }}</v-col>
          <v-spacer></v-spacer>
          <v-col cols="auto">
            <v-icon v-tooltip:top="$t('actions.update')" icon="mdi-refresh" class="me-2" @click="refresh" />
            <v-icon icon="mdi-close" @click="$emit('update:visible', false)" />
          </v-col>
        </v-row>
      </v-card-title>
      <v-divider></v-divider>
      <v-card-text>
        <v-table density="compact">
          <tbody>
            <tr v-for="row in tableRows" :key="row.key">
              <td class="pa-2" style="width: 40px">
                <v-icon :icon="row.icon" size="small" :color="row.color || undefined" />
              </td>
              <td class="pa-2">{{ row.label }}</td>
              <td class="pa-2 text-end" style="direction: ltr">{{ row.value }}</td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import { computed, ref, watch } from "vue";
import { getConnections } from "@/plugins/clashApi";
import { HumanReadable } from "@/plugins/utils";
import { i18n } from "@/locales";
import Data from "@/store/modules/data";

export default {
  props: {
    visible: { type: Boolean, default: false },
  },
  emits: ["update:visible"],
  setup(props) {
    const loading = ref(false);
    const downloadTotal = ref(0);
    const uploadTotal = ref(0);
    const activeConns = ref(0);

    const store = Data();

    const tableRows = computed(() => {
      const t = (key: string) => i18n.global.t(key);
      return [
        { key: "clients", icon: "mdi-account-multiple", label: t("pages.clients"), value: store.clients.length, color: undefined },
        { key: "inbounds", icon: "mdi-cloud-download", label: t("pages.inbounds"), value: store.inbounds.length, color: undefined },
        { key: "outbounds", icon: "mdi-cloud-upload", label: t("pages.outbounds"), value: store.outbounds.length, color: undefined },
        { key: "services", icon: "mdi-server", label: t("pages.services"), value: store.services.length, color: undefined },
        { key: "endpoints", icon: "mdi-cloud-tags", label: t("pages.endpoints"), value: store.endpoints.length, color: undefined },
        { key: "activeConns", icon: "mdi-connection", label: t("online"), value: activeConns.value, color: "primary" },
        { key: "upload", icon: "mdi-cloud-upload", label: t("stats.upload"), value: HumanReadable.sizeFormat(uploadTotal.value), color: "orange" },
        { key: "download", icon: "mdi-cloud-download", label: t("stats.download"), value: HumanReadable.sizeFormat(downloadTotal.value), color: "success" },
      ];
    });

    const refresh = async () => {
      loading.value = true;
      const snapshot = await getConnections();
      if (snapshot) {
        downloadTotal.value = snapshot.downloadTotal;
        uploadTotal.value = snapshot.uploadTotal;
        activeConns.value = snapshot.connections?.length ?? 0;
      }
      loading.value = false;
    };

    watch(
      () => props.visible,
      (v) => {
        if (v) refresh();
      },
    );

    return {
      loading,
      downloadTotal,
      uploadTotal,
      activeConns,
      tableRows,
      refresh,
    };
  },
};
</script>
