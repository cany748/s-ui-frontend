<template>
  <v-dialog transition="dialog-bottom-transition" width="90%" max-width="400">
    <v-card class="rounded-lg">
      <v-card-title>
        <v-row>
          <v-col>{{ $t("main.backup.title") }}</v-col>
          <v-spacer></v-spacer>
          <v-col cols="auto">
            <v-icon icon="mdi-close" @click="control.visible = false" />
          </v-col>
        </v-row>
      </v-card-title>
      <v-divider></v-divider>
      <v-card-text>

        <v-row>
          <v-col cols="auto" align-self="center">
            <v-btn color="primary" hide-details @click="backup">{{ $t("main.backup.backup") }}</v-btn>
          </v-col>
          <v-spacer></v-spacer>
          <v-col cols="auto" align-self="center">
            <v-btn color="primary" hide-details :loading="restoring" @click="restore">{{ $t("main.backup.restore") }}</v-btn>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import HttpUtils from "@/plugins/httputil";

export default {
  props: ["control", "visible"],
  data() {
    return {
      restoring: false,
    };
  },
  methods: {
    backup() {
      window.location.href = "/cgi-bin/sui/api/backup";
    },
    restore() {
      const fileInput = document.createElement("input");
      fileInput.type = "file";
      fileInput.accept = ".tar.gz,.tgz";

      fileInput.addEventListener("change", async (event: Event) => {
        const inputElement = event.target as HTMLInputElement;
        const file = inputElement.files?.[0];
        if (!file) return;

        const formData = new FormData();
        formData.append("backup", file);

        this.restoring = true;
        this.control.visible = false;

        const msg = await HttpUtils.post("api/restore", formData);
        this.restoring = false;

        if (msg.success) {
          await new Promise((resolve) => setTimeout(resolve, 500));
          location.reload();
        }
      });

      fileInput.click();
    },
  },
};
</script>
