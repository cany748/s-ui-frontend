# s-ui Lua backend

Минимальный бэк для управления `sing-box` на OpenWRT через `uhttpd-mod-lua`.

## Разработка

```bash
cd backend && busted
```

## Зависимости

- Lua 5.1, lua-cjson, busted (тесты)
- На устройстве: uhttpd, uhttpd-mod-lua, lua-cjson, sing-box

## Структура

См. lua/ и спеку docs/superpowers/specs/2026-04-07-openwrt-singbox-frontend-design.md
