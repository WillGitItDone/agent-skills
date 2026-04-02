---
name: fetch-knowledge
description: >
  Manage a local knowledge base of web-crawled documentation. Use this when asked
  to fetch docs, add a knowledge source, update knowledge files, crawl a website,
  or refresh external documentation for use in Copilot context.
version: 1.2.0
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

### Setup / Bootstrap — "set up fetch-knowledge", "bootstrap knowledge base", "install dependencies", "does this work"

This command both health-checks an existing setup AND bootstraps from scratch.

**Steps:**

1. **Determine the workspace root.** Use the current working directory. All files
   will be created here.

2. **Check for `fetch-knowledge.sh`.** If it exists, note ✅. If missing, **create it**
   using the full script below. Use the `create` tool to write it, then make it
   executable:
   ```bash
   chmod +x fetch-knowledge.sh
   ```

3. **Check for `knowledge-sources.txt`.** If it exists, note ✅. If missing, **create it**
   with this starter content:

   ```
   # Knowledge sources to fetch and keep up to date.
   #
   # Format (tab-separated):
   #   URL  TARGET_PATH  [crawl=N]
   #
   # TARGET_PATH is relative to knowledge/
   #   - Single page: use a .md or .json filename  (e.g. products/sightmap.md)
   #   - Crawled site: use a folder name            (e.g. api/example-docs/)
   #
   # crawl=N  (optional, default: 0)
   #   crawl=0  fetch this URL only
   #   crawl=1  fetch this page + all links on it (same domain only)
   #   crawl=2  go 2 levels deep, etc.
   #
   # Lines starting with # are comments. Blank lines are ignored.

   # Developer docs — crawl 3 levels deep to capture all subpages
   https://developers.unitmap.com/	api/unitmap-developers/	crawl=3
   https://developers.sightmap.com/	api/sightmap-developers/	crawl=3

   # OpenAPI specs (saved as JSON, single page)
   # Note: /openapi returns an HTML viewer; /openapi.json returns the raw spec
   https://api.unitmap.com/v1/openapi.json	api/unitmap-openapi.json
   https://api.sightmap.com/v1/openapi.json	api/sightmap-openapi.json

   # Product pages (single page each)
   https://www.engrain.com/sightmap	products/sightmap-product-page.md
   https://www.engrain.com/partners/unit-map-app-custom-app-builders	products/unitmap-partners.md
   ```

4. **Create `knowledge/` directory** if it doesn't exist:
   ```bash
   mkdir -p knowledge
   ```

5. **Check Python dependencies:**
   ```bash
   python3 -c "import html2text, bs4; print('✅ Dependencies OK')" 2>&1
   ```
   If missing, install them:
   ```bash
   pip3 install html2text beautifulsoup4
   ```

6. **Report the health check:**

   | Check | Status |
   |-------|--------|
   | fetch-knowledge.sh | ✅ Found / ✅ Created |
   | knowledge-sources.txt | ✅ Found / ✅ Created |
   | python3 | ✅ Found / ❌ Not in PATH |
   | html2text | ✅ Installed / ✅ Installed |
   | beautifulsoup4 | ✅ Installed / ✅ Installed |
   | knowledge/ dir | ✅ Exists / ✅ Created |

7. If everything was freshly bootstrapped, tell the user:
   > ✅ Knowledge base bootstrapped! Next steps:
   > 1. Add URLs to `knowledge-sources.txt` (or ask me to "add a source")
   > 2. Run `bash fetch-knowledge.sh` (or ask me to "fetch knowledge")

---

### fetch-knowledge.sh — Full Script

When bootstrapping, create `fetch-knowledge.sh` with **exactly** this content:

```bash
#!/bin/bash
# Fetches and updates knowledge files from public URLs defined in knowledge-sources.txt.
# Supports single-page fetch and recursive crawling (crawl=N).
# Run manually or automatically via LaunchAgent / cron.

SCRIPT_DIR="$(dirname "$0")"
SOURCES="${SOURCES:-$SCRIPT_DIR/knowledge-sources.txt}"
KNOWLEDGE_DIR="$SCRIPT_DIR/knowledge"

# Python crawler: handles single pages and recursive crawls
CRAWLER=$(cat << 'PYEOF'
import sys, os, re, json, html2text, datetime
from urllib.request import Request, urlopen
from urllib.parse import urljoin, urlparse
from urllib.error import URLError
from bs4 import BeautifulSoup

url      = sys.argv[1]   # seed URL
target   = sys.argv[2]   # output path (file for single, dir for crawl)
depth    = int(sys.argv[3]) if len(sys.argv) > 3 else 0

HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; KnowledgeBot/1.0)"}
base_domain = urlparse(url).netloc

def fetch(u):
    try:
        req = Request(u, headers=HEADERS)
        with urlopen(req, timeout=15) as r:
            ct = r.headers.get("Content-Type", "")
            return r.read().decode("utf-8", errors="replace"), ct
    except Exception as e:
        return None, str(e)

def to_markdown(html, source_url):
    h = html2text.HTML2Text()
    h.ignore_links = False
    h.ignore_images = True
    h.body_width = 0
    ts = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    return f"<!-- Source: {source_url} -->\n<!-- Fetched: {ts} -->\n\n" + h.handle(html)

def url_to_filename(u):
    parsed = urlparse(u)
    path = parsed.path.strip("/").replace("/", "__") or "index"
    if parsed.query:
        path += "__" + re.sub(r'[^a-zA-Z0-9_-]', '_', parsed.query)
    return path + ".md"

def extract_links(html, base):
    soup = BeautifulSoup(html, "html.parser")
    links = set()
    for tag in soup.find_all("a", href=True):
        href = urljoin(base, tag["href"])
        parsed = urlparse(href)
        if parsed.netloc == base_domain and parsed.scheme in ("http", "https"):
            clean = parsed._replace(fragment="").geturl()
            links.add(clean)
    return links

def save_json(content, path):
    try:
        parsed = json.loads(content)
        with open(path, "w") as f:
            json.dump(parsed, f, indent=2)
    except Exception:
        with open(path, "w") as f:
            f.write(content)

# --- Single page (crawl=0) ---
if depth == 0:
    content, ct = fetch(url)
    if content is None:
        print(f"  ERROR: {ct}", file=sys.stderr)
        sys.exit(1)
    if target.endswith(".json"):
        save_json(content, target)
    else:
        with open(target, "w") as f:
            f.write(to_markdown(content, url))
    print(f"  ✓ {url}")

# --- Recursive crawl (crawl=N) ---
else:
    os.makedirs(target, exist_ok=True)
    visited = set()
    queue = [(url, 0)]
    saved = 0

    while queue:
        current_url, current_depth = queue.pop(0)
        if current_url in visited:
            continue
        visited.add(current_url)

        content, ct = fetch(current_url)
        if content is None:
            print(f"  SKIP (error): {current_url}")
            continue

        fname = url_to_filename(current_url)
        out_path = os.path.join(target, fname)
        with open(out_path, "w") as f:
            f.write(to_markdown(content, current_url))
        saved += 1
        print(f"  ✓ [{current_depth}] {current_url}")

        if current_depth < depth:
            for link in extract_links(content, current_url):
                if link not in visited:
                    queue.append((link, current_depth + 1))

    print(f"  📁 {saved} pages saved to {target}")
PYEOF
)

echo "🌐 Fetching knowledge from web sources..."
echo ""

while IFS=$'\t' read -r url target_path crawl_opt || [[ -n "$url" ]]; do
    # Skip comments and blank lines
    [[ "$url" =~ ^#.*$ || -z "$url" ]] && continue

    # Parse crawl depth from optional 3rd column (e.g. "crawl=3")
    depth=0
    if [[ "$crawl_opt" =~ crawl=([0-9]+) ]]; then
        depth="${BASH_REMATCH[1]}"
    fi

    target="$KNOWLEDGE_DIR/$target_path"

    if [[ "$depth" -gt 0 ]]; then
        echo "🕸️  $url (crawl depth=$depth)"
        mkdir -p "$target"
    else
        echo "📄 $url"
        mkdir -p "$(dirname "$target")"
    fi

    python3 -c "$CRAWLER" "$url" "$target" "$depth"
    echo ""

done < "$SOURCES"

echo "✅ Done."
```

**Important notes about the script:**
- The `SOURCES` variable defaults to `knowledge-sources.txt` beside the script, but
  can be overridden via environment variable (e.g., `SOURCES=/dev/stdin`)
- The User-Agent is generic (`KnowledgeBot/1.0`) — not team-specific
- The script is self-contained: Python code is embedded inline, no external files needed

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
