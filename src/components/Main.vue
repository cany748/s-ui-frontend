<template>
  <LogVue v-model="logModal.visible" :control="logModal" :visible="logModal.visible" />
  <Backup v-model="backupModal.visible" :control="backupModal" :visible="backupModal.visible" />
  <UsageStats v-model:visible="usageStatsModal.visible" />
  <v-container class="fill-height" :loading="loading">
    <v-responsive class="align-center">
      <v-row class="d-flex align-center justify-center">
        <v-col cols="auto">
          <v-img src="@/assets/logo.svg" width="200"></v-img>
        </v-col>
      </v-row>
      <v-row class="d-flex align-center justify-center">
        <v-col cols="auto">
          <v-btn variant="tonal" hide-details elevation="3" @click="backupModal.visible = true"
            >{{ $t("main.backup.title") }}<v-icon icon="mdi-backup-restore" />
          </v-btn>
          <v-btn variant="tonal" hide-details style="margin-inline-start: 10px" elevation="3" @click="logModal.visible = true"
            >{{ $t("basic.log.title") }} <v-icon icon="mdi-list-box-outline" />
          </v-btn>
          <v-btn variant="tonal" hide-details style="margin-inline-start: 10px" elevation="3" @click="usageStatsModal.visible = true"
            >{{ $t("main.stats.title") }} <v-icon icon="mdi-chart-box-outline" />
          </v-btn>
        </v-col>
      </v-row>
      <v-row class="d-flex align-center justify-center mt-4">
        <v-col cols="12" sm="8" md="6" lg="4">
          <v-card class="rounded-lg" variant="outlined" elevation="5">
            <v-card-title>{{ $t("main.info.sbd") }}</v-card-title>
            <v-card-text>
              <v-row>
                <v-col cols="4">{{ $t("main.info.running") }}</v-col>
                <v-col cols="8">
                  <v-chip density="compact" color="success" variant="flat" v-if="sbdData.running">{{ $t("yes") }}</v-chip>
                  <v-chip density="compact" color="error" variant="flat" v-else>{{ $t("no") }}</v-chip>
                  <v-chip
                    density="compact"
                    color="transparent"
                    v-if="sbdData.running && !loading"
                    style="cursor: pointer"
                    @click="restartSingbox"
                  >
                    <v-tooltip activator="parent" location="top">{{ $t("actions.restartSb") }}</v-tooltip>
                    <v-icon icon="mdi-restart" color="warning" />
                  </v-chip>
                </v-col>
                <v-col cols="4" v-if="sbdData.version">{{ $t("main.info.version") }}</v-col>
                <v-col cols="8" v-if="sbdData.version">
                  <v-chip density="compact" color="blue">{{ sbdData.version }}</v-chip>
                </v-col>
                <v-col cols="4" v-if="sbdData.uptime">{{ $t("main.info.uptime") }}</v-col>
                <v-col cols="8" v-if="sbdData.uptime">{{ HumanReadable.formatSecond(sbdData.uptime) }}</v-col>
                <v-col cols="4">{{ $t("online") }}</v-col>
                <v-col cols="8">
                  <template v-if="sbdData.running">
                    <v-chip density="compact" color="primary" variant="flat" v-if="Data().onlines.user?.length">
                      <v-tooltip activator="parent" location="top" overflow="auto">
                        <span v-text="$t('pages.clients')" style="font-weight: bold"></span><br />
                        <span v-for="user in Data().onlines.user" :key="user">{{ user }}<br /></span>
                      </v-tooltip>
                      {{ Data().onlines.user.length }}
                    </v-chip>
                    <v-chip density="compact" color="success" variant="flat" v-if="Data().onlines.inbound?.length">
                      <v-tooltip activator="parent" location="top">
                        <span v-text="$t('pages.inbounds')" style="font-weight: bold"></span><br />
                        <span v-for="i in Data().onlines.inbound" :key="i">{{ i }}<br /></span>
                      </v-tooltip>
                      {{ Data().onlines.inbound.length }}
                    </v-chip>
                    <v-chip density="compact" color="info" variant="flat" v-if="Data().onlines.outbound?.length">
                      <v-tooltip activator="parent" location="top">
                        <span v-text="$t('pages.outbounds')" style="font-weight: bold"></span><br />
                        <span v-for="o in Data().onlines.outbound" :key="o">{{ o }}<br /></span>
                      </v-tooltip>
                      {{ Data().onlines.outbound.length }}
                    </v-chip>
                  </template>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-responsive>
  </v-container>
</template>

<script lang="ts" setup>
import HttpUtils from "@/plugins/httputil";
import { HumanReadable } from "@/plugins/utils";
import Data from "@/store/modules/data";
import { onBeforeUnmount, onMounted, ref } from "vue";
import LogVue from "@/layouts/modals/Logs.vue";
import Backup from "@/layouts/modals/Backup.vue";
import UsageStats from "@/layouts/modals/UsageStats.vue";

const loading = ref(false);
const sbdData = ref<{ running: boolean; version?: string; uptime?: number; pid?: number }>({ running: false });

const reloadData = async () => {
  const data = await HttpUtils.get("api/status");
  if (data.success && data.obj) {
    sbdData.value = data.obj;
  }
};

let intervalId: ReturnType<typeof setInterval> | null = null;

onMounted(async () => {
  loading.value = true;
  await reloadData();
  loading.value = false;
  intervalId = setInterval(reloadData, 10000);
});

onBeforeUnmount(() => {
  if (intervalId) clearInterval(intervalId);
});

const logModal = ref({ visible: false });
const backupModal = ref({ visible: false });
const usageStatsModal = ref({ visible: false });

const restartSingbox = async () => {
  loading.value = true;
  await HttpUtils.post("api/restart", {});
  await reloadData();
  loading.value = false;
};
</script>
