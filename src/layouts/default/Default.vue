<template>
  <v-app style="overflow: auto">
    <Drawer :is-mobile="isMobile" :display-drawer="displayDrawer" @toggle-drawer="toggleDrawer" />
    <DefaultBar :is-mobile="isMobile" @toggle-drawer="toggleDrawer" />
    <DefaultView />
  </v-app>
</template>

<script lang="ts" setup>
import { computed, ref } from "vue";
import { useDisplay } from "vuetify";
import DefaultBar from "./AppBar.vue";
import Drawer from "./Drawer.vue";
import DefaultView from "./View.vue";

const { smAndDown } = useDisplay();
const displayDrawer = ref(false);

const toggleDrawer = () => {
  displayDrawer.value = !displayDrawer.value;
};

const isMobile = computed((): boolean => {
  displayDrawer.value = !smAndDown.value;
  return smAndDown.value;
});
</script>

<style>
.v-card-subtitle {
  text-align: center;
  border-bottom: 1px solid gray;
  min-height: 20px;
}
.v-switch.v-input {
  padding-inline-start: 0.6rem;
}
</style>
