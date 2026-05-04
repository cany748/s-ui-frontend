import { createRouter, createWebHistory } from "vue-router";
import Data from "@/store/modules/data";

const routes = [
  {
    path: "/",
    component: () => import("@/layouts/default/Default.vue"),
    children: [
      {
        path: "/",
        name: "pages.home",
        component: () => import("@/views/Home.vue"),
      },
      {
        path: "/inbounds",
        name: "pages.inbounds",
        component: () => import("@/views/Inbounds.vue"),
      },
      {
        path: "/clients",
        name: "pages.clients",
        component: () => import("@/views/Clients.vue"),
      },
      {
        path: "/outbounds",
        name: "pages.outbounds",
        component: () => import("@/views/Outbounds.vue"),
      },
      {
        path: "/services",
        name: "pages.services",
        component: () => import("@/views/Services.vue"),
      },
      {
        path: "/endpoints",
        name: "pages.endpoints",
        component: () => import("@/views/Endpoints.vue"),
      },
      {
        path: "/rules",
        name: "pages.rules",
        component: () => import("@/views/Rules.vue"),
      },
      {
        path: "/tls",
        name: "pages.tls",
        component: () => import("@/views/Tls.vue"),
      },
      {
        path: "/basics",
        name: "pages.basics",
        component: () => import("@/views/Basics.vue"),
      },
      {
        path: "/dns",
        name: "pages.dns",
        component: () => import("@/views/Dns.vue"),
      },
      {
        path: "/settings",
        name: "pages.settings",
        component: () => import("@/views/Settings.vue"),
      },
    ],
  },
];

const router = createRouter({
  history: createWebHistory((window as any).BASE_URL),
  routes,
});

let intervalId: ReturnType<typeof setInterval> | undefined;

router.afterEach(() => {
  if (intervalId) return;
  Data().loadData();
  intervalId = setInterval(() => Data().loadData(), 10_000);
});

export default router;
