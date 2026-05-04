<template>
  <v-card :loading="loading">
    <v-card-title>{{ $t("pages.settings") }}</v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" sm="6" md="4">
          <v-list-item :title="$t('main.info.running')" :subtitle="status.running ? $t('yes') : $t('no')">
            <template #prepend>
              <v-icon :icon="status.running ? 'mdi-check-circle' : 'mdi-close-circle'" :color="status.running ? 'success' : 'error'" />
            </template>
          </v-list-item>
        </v-col>
        <v-col cols="12" sm="6" md="4" v-if="status.version">
          <v-list-item :title="$t('main.info.version')" :subtitle="status.version">
            <template #prepend>
              <v-icon icon="mdi-tag" color="primary" />
            </template>
          </v-list-item>
        </v-col>
        <v-col cols="12" sm="6" md="4" v-if="status.uptime">
          <v-list-item :title="$t('main.info.uptime')" :subtitle="HumanReadable.formatSecond(status.uptime)">
            <template #prepend>
              <v-icon icon="mdi-clock-outline" color="info" />
            </template>
          </v-list-item>
        </v-col>
        <v-col cols="12" sm="6" md="4" v-if="status.pid">
          <v-list-item title="PID" :subtitle="String(status.pid)">
            <template #prepend>
              <v-icon icon="mdi-identifier" />
            </template>
          </v-list-item>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="auto">
          <v-btn color="warning" variant="outlined" :loading="restarting" @click="restart">
            {{ $t("actions.restartSb") }}
            <v-icon icon="mdi-restart" end />
          </v-btn>
        </v-col>
        <v-col cols="auto">
          <v-btn color="primary" variant="tonal" :loading="loading" @click="loadStatus">
            {{ $t("actions.update") }}
            <v-icon icon="mdi-refresh" end />
          </v-btn>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { onMounted, ref } from "vue";
import { push } from "notivue";
import { i18n } from "@/locales";
import HttpUtils from "@/plugins/httputil";
import { HumanReadable } from "@/plugins/utils";

const loading = ref(false);
const restarting = ref(false);
const status = ref<{ running: boolean; version?: string; uptime?: number; pid?: number }>({ running: false });

const loadStatus = async () => {
  loading.value = true;
  const msg = await HttpUtils.get("api/status");
  if (msg.success && msg.obj) {
    status.value = msg.obj;
  }
  loading.value = false;
};

const restart = async () => {
  restarting.value = true;
  const msg = await HttpUtils.post("api/restart", {});
  if (msg.success) {
    push.success({ title: i18n.global.t("success"), message: i18n.global.t("actions.restartSb"), duration: 3000 });
    await new Promise((resolve) => setTimeout(resolve, 2000));
    await loadStatus();
  } else {
    push.error({ title: i18n.global.t("failed"), message: msg.msg ?? "restart failed" });
  }
  restarting.value = false;
};

onMounted(loadStatus);
</script>
