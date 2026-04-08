---
applyTo: "repos/app-sightmap/geojson/**,repos/app-sightmap/navigation/**,repos/app-sightmap/tilesets/**,repos/app-smctl/**"
---

# Deno / TypeScript Instructions

**Always read the relevant AGENTS.md first** — each service has specific conventions.

## Service Map

| Service | Deno Version | Purpose |
|---------|-------------|---------|
| `geojson/` | 1.14.1 | Pixel → geographic coordinate projection |
| `navigation/` | 2.3.7 | Indoor wayfinding with Valhalla |
| `tilesets/` | 1.42.1 | Vector tile generation (MBTiles) |
| `app-smctl` | Latest | CLI for API operations and PMS integrations |

## Critical: Version Differences

- **geojson** and **tilesets** use Deno 1.x — `import` maps, no `npm:` specifiers
- **navigation** uses Deno 2.x — `deno.json` imports, `npm:` specifiers OK
- **smctl** uses latest Deno — modern patterns, `deno.json` workspace

## Common Patterns

- **Test**: `./test.sh` in each service root
- **Format**: `deno fmt`
- **Lint**: `deno lint`
- **smctl specifics**: `./fmt.sh` / `./lint.sh` / `./test.sh`

## Don't Forget

- Run `deno fmt` and `deno lint` before committing
- Each service has its own `deno.json` / `deno.jsonc` config
- Navigation depends on external Valhalla service
- GeoJSON and Tilesets are part of the Unit Map pipeline
