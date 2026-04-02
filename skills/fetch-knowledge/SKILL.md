---
name: fetch-knowledge
description: >
  Manage a local knowledge base of web-crawled documentation. Use this when asked
  to fetch docs, add a knowledge source, update knowledge files, crawl a website,
  or refresh external documentation for use in Copilot context.
version: 1.0.0
requires:
  bins:
    - python3
    - bash
---

# Fetch Knowledge Skill

You help users manage a local knowledge base built by crawling public URLs and
saving them as markdown files. The knowledge base lives in a `knowledge/` directory
alongside two config files: `knowledge-sources.txt` and `fetch-knowledge.sh`.

💡 Check for `local.md` in this skill's directory for workspace-specific paths,
folder conventions, or a default list of sources before starting.

---

## Workspace Layout

```
<workspace>/
├── fetch-knowledge.sh        # crawler script (runs Python inline)
├── knowledge-sources.txt     # tab-separated list of URLs to fetch
└── knowledge/                # output directory
    ├── api/                  # API docs, OpenAPI specs
    ├── products/             # product/marketing pages
    ├── integrations/         # third-party integration docs
    └── ...                   # any folder structure you define
```

---

## knowledge-sources.txt Format

Tab-separated, three columns:

```
URL<TAB>TARGET_PATH<TAB>[crawl=N]
```

| Column | Required | Description |
|--------|----------|-------------|
| URL | ✅ | Full https:// URL to fetch |
| TARGET_PATH | ✅ | Path relative to `knowledge/`. Use `.md` or `.json` for single pages, a folder name for crawls |
| crawl=N | optional | Recursion depth. `crawl=0` (default) = single page. `crawl=3` = seed + 3 levels of same-domain links |

Lines starting with `#` and blank lines are ignored.

**Example:**
```
# API docs — crawl 3 levels
https://docs.example.com/api/	api/example-docs/	crawl=3

# Single spec file
https://api.example.com/openapi.json	api/example-openapi.json

# Product page (single)
https://www.example.com/product	products/example-product.md
```

---

## Commands / Intents

Determine what the user wants from their message and follow the matching steps.

---

### Add a Source — "add this URL", "track this doc", "crawl this site"

**Steps:**

1. Ask for (or extract from the message):
   - The URL to fetch
   - Whether to crawl recursively (and how deep), or just fetch the single page
   - A target path under `knowledge/` (suggest one based on the URL if not given)

2. Read the current `knowledge-sources.txt` to avoid duplicates. If the URL already
   exists, tell the user and ask if they want to update the target path or depth.

3. Determine the correct tab-separated line to append:
   - Single page: `{url}\t{target_path}`
   - Crawl: `{url}\t{target_folder}/\tcrawl={depth}`
   - JSON spec: use a `.json` extension on the target path

4. Add a comment line above the new entry if it's the first entry in a new category
   (e.g., `# New integration docs`).

5. Append the line to `knowledge-sources.txt` using the edit tool.

6. Confirm: "Added `{url}` → `knowledge/{target_path}`. Run 'fetch knowledge' to
   download it."

---

### Fetch / Refresh — "fetch knowledge", "update docs", "run fetch-knowledge", "refresh"

**Steps:**

1. Locate `fetch-knowledge.sh` in the workspace root. If not found, tell the user
   the script is missing and show the expected path.

2. Check that `python3` is available:
   ```bash
   which python3
   ```

3. Check that required Python packages are installed:
   ```bash
   python3 -c "import html2text, bs4" 2>&1
   ```
   If missing, tell the user to install them:
   ```bash
   pip3 install html2text beautifulsoup4
   ```

4. Run the script:
   ```bash
   cd <workspace_root> && bash fetch-knowledge.sh 2>&1
   ```

5. Parse the output:
   - Count `✓` lines (successful fetches)
   - Note any `ERROR` or `SKIP` lines
   - Show a summary: "Fetched N pages. K errors."

6. If there were errors, show the affected URLs and suggest:
   - Check if the URL is still live
   - Check if the site blocks crawlers (User-Agent restrictions)
   - Try reducing crawl depth

---

### Fetch One Source — "fetch just {url}", "re-fetch {target}", "update only {name}"

**Steps:**

1. Find the matching line in `knowledge-sources.txt` by URL or target path substring.

2. Run the inline Python crawler directly for just that entry:
   ```bash
   python3 -c "$(sed -n '/^CRAWLER=/,/^PYEOF/p' fetch-knowledge.sh | ...)" \
     "{url}" "knowledge/{target}" {depth}
   ```
   
   Or simpler — temporarily set the env and call the script with a filtered sources
   file piped into it. Best approach: write a one-line temp sources file:
   ```bash
   echo -e "{url}\t{target}\t{crawl_opt}" | \
     SOURCES=/dev/stdin bash fetch-knowledge.sh
   ```
   
   Actually, the cleanest approach: just run the full script but note to the user
   it re-fetches all sources. If the user needs selective re-fetch, suggest they
   comment out other lines temporarily.

3. Confirm what was saved.

---

### List Sources — "show knowledge sources", "what are we tracking", "list sources"

**Steps:**

1. Read `knowledge-sources.txt`.

2. Parse non-comment, non-blank lines into a table:

   | URL | Target | Mode |
   |-----|--------|------|
   | https://docs.example.com/api/ | api/example-docs/ | crawl=3 |
   | https://api.example.com/openapi.json | api/example-openapi.json | single |

3. Also show a count of files currently in `knowledge/`:
   ```bash
   find knowledge/ -type f | wc -l
   ```

---

### Show Knowledge — "what's in the knowledge base", "list knowledge files", "what docs do we have"

**Steps:**

1. List the knowledge directory tree:
   ```bash
   find knowledge/ -type f | sort
   ```

2. Group by subdirectory and show file counts per folder.

3. For each `.md` file, optionally show the `<!-- Source: ... -->` header line
   to display which URL it came from:
   ```bash
   grep -r "<!-- Source:" knowledge/ --include="*.md" -l
   ```

4. Present a summary organized by folder, e.g.:
   ```
   knowledge/
   ├── api/          (12 files)
   ├── products/     (3 files)
   └── news/         (4 files)
   ```

---

### Remove a Source — "remove this URL", "stop tracking {name}", "delete source"

**Steps:**

1. Find the line in `knowledge-sources.txt` matching the URL or target path.

2. Show the user the exact line(s) that will be removed and confirm.

3. Use the edit tool to remove the line (and its comment if it's the only entry
   under that comment).

4. Ask if they also want to delete the already-fetched knowledge files:
   - If yes: `rm -rf knowledge/{target_path}`
   - If no: leave existing files in place

---

### Setup / Install — "set up fetch-knowledge", "install dependencies", "does this work"

**Steps:**

1. Check for `fetch-knowledge.sh`:
   ```bash
   ls -la fetch-knowledge.sh
   ```

2. Check for `knowledge-sources.txt`:
   ```bash
   ls -la knowledge-sources.txt
   ```

3. Check Python dependencies:
   ```bash
   python3 -c "import html2text, bs4; print('✅ Dependencies OK')" 2>&1
   ```

4. If `html2text` or `bs4` are missing:
   ```bash
   pip3 install html2text beautifulsoup4
   ```

5. Check the `knowledge/` directory exists (create if not):
   ```bash
   mkdir -p knowledge
   ```

6. Report the health check:

   | Check | Status |
   |-------|--------|
   | fetch-knowledge.sh | ✅ Found / ❌ Missing |
   | knowledge-sources.txt | ✅ Found / ❌ Missing |
   | python3 | ✅ Found / ❌ Not in PATH |
   | html2text | ✅ Installed / ❌ Missing |
   | beautifulsoup4 | ✅ Installed / ❌ Missing |
   | knowledge/ dir | ✅ Exists / ✅ Created |

---

## Output Conventions

- Knowledge files are plain markdown with a comment header:
  ```
  <!-- Source: https://... -->
  <!-- Fetched: 2025-01-01T00:00:00Z -->
  ```
- JSON files (e.g. OpenAPI specs) are saved as pretty-printed JSON.
- Crawled sites create one `.md` per page; filenames are derived from the URL path
  with `/` replaced by `__`.

---

## Tips for Good Knowledge Sources

- **API docs**: Use `crawl=2` or `crawl=3` to capture reference pages, guides, etc.
- **OpenAPI specs**: Always save as `.json` (not `.md`) to preserve structure.
- **Marketing/product pages**: Usually `crawl=0` (single page) is enough.
- **Changelogs**: Single pages usually; use `crawl=1` if the changelog paginates.
- **Avoid crawling login-gated content** — the crawler doesn't authenticate.
- **Avoid very deep crawls on large sites** — `crawl=2` on a large docs site may
  pull hundreds of pages. Start shallow and go deeper as needed.
