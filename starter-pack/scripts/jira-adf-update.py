#!/usr/bin/env python3
"""
jira-adf-update.py — Update a Jira issue description with ADF panel support.

Converts Markdown with :::panel markers to Atlassian Document Format (ADF)
and PUTs it to the Jira Cloud REST API v3.

Panel syntax:
    :::panel info
    ## User Story
    As a [user type]
    I want [goal]
    So that [benefit]
    :::

    :::panel success
    ## Acceptance Criteria
    - Given X, when Y, then Z
    :::

    :::panel note
    ## Open Questions
    - Question 1
    :::

Panel types: info (blue), success (green), note (purple), warning (yellow), error (red)

Usage:
    python3 scripts/jira-adf-update.py IT-22 description.md
    echo "..." | python3 scripts/jira-adf-update.py IT-22 -
    python3 scripts/jira-adf-update.py IT-22 --adf description-adf.json

Environment:
    JIRA_URL           — Jira instance URL (default: https://engrain.atlassian.net)
    JIRA_USER_EMAIL    — User email for auth (also accepts JIRA_USERNAME)
    JIRA_API_TOKEN     — API token (required; auto-sourced from ~/.copilot/credentials.env)

Dependencies: None (Python 3.8+ stdlib only)
"""

import json
import os
import re
import sys
import base64
import urllib.request
import urllib.error


# ---------------------------------------------------------------------------
# Markdown → ADF conversion
# ---------------------------------------------------------------------------

def _parse_inline(text):
    """Parse inline markdown formatting into ADF text nodes."""
    if not text:
        return []
    nodes = []
    pattern = re.compile(
        r"`(?P<code>[^`]+)`"
        r"|\*\*(?P<bold>.+?)\*\*"
        r"|~~(?P<strike>.+?)~~"
        r"|\[(?P<link_text>[^\]]+)\]\((?P<link_href>[^)]+)\)"
        r"|(?<!\*)\*(?!\*)(?P<italic>.+?)(?<!\*)\*(?!\*)"
    )
    pos = 0
    for m in pattern.finditer(text):
        if m.start() > pos:
            plain = text[pos:m.start()]
            if plain:
                nodes.append({"type": "text", "text": plain})
        if m.group("code") is not None:
            nodes.append({"type": "text", "text": m.group("code"), "marks": [{"type": "code"}]})
        elif m.group("bold") is not None:
            nodes.append({"type": "text", "text": m.group("bold"), "marks": [{"type": "strong"}]})
        elif m.group("strike") is not None:
            nodes.append({"type": "text", "text": m.group("strike"), "marks": [{"type": "strike"}]})
        elif m.group("link_text") is not None:
            nodes.append({"type": "text", "text": m.group("link_text"),
                          "marks": [{"type": "link", "attrs": {"href": m.group("link_href")}}]})
        elif m.group("italic") is not None:
            nodes.append({"type": "text", "text": m.group("italic"), "marks": [{"type": "em"}]})
        pos = m.end()
    if pos < len(text):
        tail = text[pos:]
        if tail:
            nodes.append({"type": "text", "text": tail})
    if not nodes and text:
        nodes.append({"type": "text", "text": text})
    return nodes


def _paragraph(text):
    content = _parse_inline(text)
    if not content:
        content = [{"type": "text", "text": ""}]
    return {"type": "paragraph", "content": content}


def _list_item(text):
    return {"type": "listItem", "content": [_paragraph(text)]}


def md_to_adf_nodes(markdown):
    """Convert a markdown string to a list of ADF block nodes."""
    nodes = []
    if not markdown:
        return nodes
    lines = markdown.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]

        # Fenced code block
        if line.startswith("```"):
            lang = line[3:].strip()
            code = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code.append(lines[i])
                i += 1
            if i < len(lines):
                i += 1
            node = {"type": "codeBlock", "content": [{"type": "text", "text": "\n".join(code)}]}
            if lang:
                node["attrs"] = {"language": lang}
            nodes.append(node)
            continue

        stripped = line.strip()

        # Horizontal rule
        if stripped in ("---", "***", "___"):
            nodes.append({"type": "rule"})
            i += 1
            continue

        # Heading
        hm = re.match(r"^(#{1,6})\s+(.+)$", line)
        if hm:
            nodes.append({"type": "heading", "attrs": {"level": len(hm.group(1))},
                          "content": _parse_inline(hm.group(2))})
            i += 1
            continue

        # Blockquote
        if line.startswith("> "):
            bq = []
            while i < len(lines) and lines[i].startswith("> "):
                bq.append(lines[i][2:])
                i += 1
            nodes.append({"type": "blockquote", "content": [_paragraph(l) for l in bq]})
            continue

        # Unordered list
        if re.match(r"^[-*]\s+", line):
            items = []
            while i < len(lines) and re.match(r"^[-*]\s+", lines[i]):
                items.append(_list_item(re.sub(r"^[-*]\s+", "", lines[i])))
                i += 1
            nodes.append({"type": "bulletList", "content": items})
            continue

        # Ordered list
        if re.match(r"^\d+\.\s+", line):
            items = []
            while i < len(lines) and re.match(r"^\d+\.\s+", lines[i]):
                items.append(_list_item(re.sub(r"^\d+\.\s+", "", lines[i])))
                i += 1
            nodes.append({"type": "orderedList", "content": items})
            continue

        # Table
        if line.startswith("|") and "|" in line[1:]:
            raw_rows = []
            while i < len(lines) and lines[i].startswith("|"):
                raw_rows.append(lines[i])
                i += 1
            data_rows = []
            for row in raw_rows:
                cells = [c.strip() for c in row.strip("|").split("|")]
                if all(re.match(r"^:?-+:?$", c) for c in cells if c):
                    continue
                data_rows.append(cells)
            if data_rows:
                adf_rows = []
                for idx, cells in enumerate(data_rows):
                    ct = "tableHeader" if idx == 0 else "tableCell"
                    adf_cells = []
                    for cell in cells:
                        content = _parse_inline(cell)
                        if not content:
                            content = [{"type": "text", "text": ""}]
                        adf_cells.append({"type": ct, "content": [{"type": "paragraph", "content": content}]})
                    adf_rows.append({"type": "tableRow", "content": adf_cells})
                nodes.append({"type": "table",
                              "attrs": {"isNumberColumnEnabled": False, "layout": "default"},
                              "content": adf_rows})
            continue

        # Empty line
        if not stripped:
            i += 1
            continue

        # Paragraph (default)
        nodes.append(_paragraph(line))
        i += 1

    return nodes


def _make_panel(panel_type, inner_md):
    """Wrap markdown content in an ADF panel node."""
    return {
        "type": "panel",
        "attrs": {"panelType": panel_type},
        "content": md_to_adf_nodes(inner_md),
    }


def markdown_with_panels_to_adf(text):
    """
    Parse markdown with :::panel markers into a full ADF document.

    Panel markers:
        :::panel info       — opens a panel (info, success, note, warning, error)
        :::                 — closes the current panel

    Everything outside panels is converted as regular markdown.
    """
    doc_content = []
    panel_pattern = re.compile(r"^:::panel\s+(info|success|note|warning|error)\s*$")
    lines = text.split("\n")
    buffer = []
    in_panel = False
    panel_type = None

    for line in lines:
        if not in_panel:
            pm = panel_pattern.match(line.strip())
            if pm:
                # Flush any buffered markdown before the panel
                if buffer:
                    doc_content.extend(md_to_adf_nodes("\n".join(buffer)))
                    buffer = []
                in_panel = True
                panel_type = pm.group(1)
                continue
            buffer.append(line)
        else:
            if line.strip() == ":::":
                # Close the panel
                doc_content.append(_make_panel(panel_type, "\n".join(buffer)))
                buffer = []
                in_panel = False
                panel_type = None
                continue
            buffer.append(line)

    # Flush remaining buffer
    if in_panel and buffer:
        # Unclosed panel — wrap it anyway
        doc_content.append(_make_panel(panel_type, "\n".join(buffer)))
    elif buffer:
        doc_content.extend(md_to_adf_nodes("\n".join(buffer)))

    return {"version": 1, "type": "doc", "content": doc_content}


# ---------------------------------------------------------------------------
# Jira REST API v3
# ---------------------------------------------------------------------------

def _source_credentials():
    """Auto-source ~/.copilot/credentials.env if key env vars are missing."""
    creds_path = os.path.expanduser("~/.copilot/credentials.env")
    if not os.path.isfile(creds_path):
        return
    with open(creds_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # Strip optional 'export ' prefix
            if line.startswith("export "):
                line = line[7:]
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and value and (key not in os.environ or not os.environ[key]):
                os.environ[key] = value


def update_jira_description(issue_key, adf_doc, url=None, email=None, token=None):
    """PUT an ADF document as the issue description via Jira REST API v3."""
    _source_credentials()
    url = url or os.environ.get("JIRA_URL", "https://engrain.atlassian.net")
    email = email or os.environ.get("JIRA_USER_EMAIL") or os.environ.get("JIRA_USERNAME")
    token = token or os.environ.get("JIRA_API_TOKEN")
    if not token:
        print("ERROR: JIRA_API_TOKEN environment variable is required.", file=sys.stderr)
        print("  Set it in ~/.copilot/credentials.env or export it in your shell.", file=sys.stderr)
        sys.exit(1)

    auth = base64.b64encode(f"{email}:{token}".encode()).decode()
    payload = json.dumps({"fields": {"description": adf_doc}})

    api_url = f"{url.rstrip('/')}/rest/api/3/issue/{issue_key}"
    req = urllib.request.Request(api_url, data=payload.encode("utf-8"), method="PUT")
    req.add_header("Authorization", f"Basic {auth}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            print(f"✅ {issue_key} updated (HTTP {resp.status})")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"❌ Error {e.code}: {body[:500]}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 jira-adf-update.py <ISSUE-KEY> <file.md | - | --adf file.json>")
        sys.exit(1)

    issue_key = sys.argv[1]

    if sys.argv[2] == "--adf":
        # Raw ADF JSON input
        if len(sys.argv) < 4:
            print("Usage: python3 jira-adf-update.py <ISSUE-KEY> --adf <file.json>")
            sys.exit(1)
        with open(sys.argv[3]) as f:
            adf_doc = json.load(f)
    else:
        # Markdown with panel markers
        path = sys.argv[2]
        if path == "-":
            md = sys.stdin.read()
        else:
            with open(path) as f:
                md = f.read()
        adf_doc = markdown_with_panels_to_adf(md)

    update_jira_description(issue_key, adf_doc)


if __name__ == "__main__":
    main()
