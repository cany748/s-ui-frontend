<template>
  <v-card subtitle="OCM (OpenAI Codex Multiplexer)">
    <v-row>
      <v-col cols="12" sm="6">
        <v-text-field v-model="data.credential_path" :label="$t('types.ocm.credentialPath')" hide-details> </v-text-field>
      </v-col>
      <v-col cols="12" sm="6">
        <v-text-field v-model="data.usages_path" :label="$t('types.ocm.usagesPath')" hide-details> </v-text-field>
      </v-col>
      <v-col cols="12" sm="6">
        <v-select v-model="data.detour" :label="$t('dial.detourText')" hide-details :items="outTags"> </v-select>
      </v-col>
    </v-row>
    <v-card-title>
      {{ $t("types.ocm.users") }}
      <v-chip color="primary" density="compact" variant="elevated" @click="addUser"><v-icon icon="mdi-plus" /></v-chip>
    </v-card-title>
    <v-card v-for="(user, index) in data.users || []" :key="index" class="border" style="margin: 4px; padding: 8px" rounded="xl">
      <v-row>
        <v-col cols="auto" align-self="center">
          <v-icon color="error" icon="mdi-delete" @click="delUser(index)" />
        </v-col>
        <v-col cols="12" sm="4">
          <v-text-field v-model="user.name" :label="$t('types.ocm.userName')" hide-details />
        </v-col>
        <v-col cols="12" sm="6">
          <v-text-field v-model="user.token" :label="$t('types.ocm.userToken')" hide-details type="password" />
        </v-col>
      </v-row>
    </v-card>
  </v-card>
</template>

<script lang="ts">
import Data from "@/store/modules/data";

export default {
  props: ["data"],
  computed: {
    outTags() {
      return [...(Data().outbounds?.map((o: any) => o.tag) ?? []), ...(Data().endpoints?.map((e: any) => e.tag) ?? [])];
    },
  },
  methods: {
    addUser() {
      if (!this.$props.data.users) this.$props.data.users = [];
      this.$props.data.users.push({ name: "", token: "" });
    },
    delUser(i: number | string) {
      this.$props.data.users?.splice(Number(i), 1);
    },
  },
};
</script>
