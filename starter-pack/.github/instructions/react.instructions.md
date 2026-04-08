---
applyTo: "repos/app-sightmap/clients/**"
---

# React Client Instructions

**Always read the relevant AGENTS.md first** — each client has its own conventions.

## Client Map

| Client | React | State | AGENTS.md |
|--------|-------|-------|-----------|
| `clients/app/` | 18 | Redux + Immutable.js | ✅ |
| `clients/customer/` | 18 | Redux Toolkit, Ant Design 5 | ✅ |
| `clients/manage/` | ⚠️ **15** | Redux 3, jQuery, AdminLTE | ✅ |
| `clients/landing-page/` | 18 | Minimal | — |
| `clients/locator/` | 18 | Google Places | — |
| `clients/iframe-api/` | Vanilla JS | postMessage | — |

## ⚠️ clients/manage is React 15

This is the most critical thing to remember:
- No hooks, no functional components with state
- Class components with `createClass` or ES6 classes
- `redux-actions` + `handleActions` pattern
- jQuery is available and used for DOM manipulation
- AdminLTE for layout/UI components
- **Do NOT** introduce React 18 patterns here

## Build & Test

- **Build**: `docker compose run --rm devtools` then `yarn build` in the client dir
- **Test**: `yarn test` (via devtools container)
- **Lint**: ESLint + Prettier (`yarn format`)
- Hot reload available in dev mode

## Shared Patterns

- API calls go through service layers, not directly in components
- i18n via react-intl (app, customer) — all user-facing strings must be translatable
- Styling: CSS Modules (app), Ant Design tokens (customer), AdminLTE (manage)
