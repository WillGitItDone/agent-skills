#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Copilot CLI Setup Wizard — Engrain
#
# Automates the setup of a Copilot CLI workspace for Engrain employees.
# Supports both fresh installs and updating existing workspaces.
#
# Usage: ./setup.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── Compatibility (macOS ships Bash 3.2) ────────────────────
lowercase() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
capitalize() { echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'; }

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ── Helpers ─────────────────────────────────────────────────
info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC}  $*"; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}\n"; }
divider() { echo -e "${DIM}─────────────────────────────────────────────${NC}"; }

prompt() {
    local var_name="$1" prompt_text="$2" default="${3:-}"
    if [[ -n "$default" ]]; then
        echo -en "${YELLOW}?${NC}  ${prompt_text} ${DIM}[${default}]${NC}: "
        read -r input
        eval "$var_name=\"${input:-$default}\""
    else
        echo -en "${YELLOW}?${NC}  ${prompt_text}: "
        read -r input
        while [[ -z "$input" ]]; do
            echo -en "${RED}   Required.${NC} ${prompt_text}: "
            read -r input
        done
        eval "$var_name=\"$input\""
    fi
}

confirm() {
    local prompt_text="$1" default="${2:-y}"
    local yn_hint="[Y/n]"
    [[ "$default" == "n" ]] && yn_hint="[y/N]"
    echo -en "${YELLOW}?${NC}  ${prompt_text} ${DIM}${yn_hint}${NC}: "
    read -r input
    input="${input:-$default}"
    local lower
    lower="$(lowercase "$input")"
    [[ "$lower" == "y" || "$lower" == "yes" ]]
}

# ── Resolve script directory (where the starter-pack lives) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPILOT_DIR="$HOME/.copilot"
SKILLS_DIR="$COPILOT_DIR/skills"
CREDS_FILE="$COPILOT_DIR/credentials.env"

# ── Banner ──────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║   🚀 Copilot CLI Setup Wizard — Engrain      ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  This wizard will set up your Copilot CLI workspace"
echo "  with Engrain context, templates, and skills."
echo ""
divider

# ── Mode Selection ──────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Do you already have a Copilot workspace set up?${NC}"
echo ""
echo -e "    ${CYAN}1${NC}  No  — set up from scratch"
echo -e "    ${CYAN}2${NC}  Yes — update my existing workspace"
echo ""
echo -en "  ${YELLOW}?${NC}  Choose [1/2]: "
read -r MODE_CHOICE
echo ""

case "$MODE_CHOICE" in
    2) MODE="update" ;;
    *) MODE="fresh" ;;
esac

# ═══════════════════════════════════════════════════════════
# UPDATE MODE
# ═══════════════════════════════════════════════════════════
if [[ "$MODE" == "update" ]]; then
    header "Update Existing Workspace"

    prompt WORKSPACE_PATH "Where is your workspace? (full path or ~/folder)" ""
    # Expand tilde
    WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"

    # Validate
    if [[ ! -d "$WORKSPACE_PATH" ]]; then
        error "Directory not found: $WORKSPACE_PATH"
        exit 1
    fi
    if [[ ! -f "$WORKSPACE_PATH/.github/copilot-instructions.md" ]]; then
        error "Doesn't look like a Copilot workspace (no .github/copilot-instructions.md)"
        error "Make sure you entered the right path."
        exit 1
    fi
    success "Found workspace at $WORKSPACE_PATH"
    echo ""

    # ── Diff updatable files ────────────────────────────────
    header "Checking for Updates"

    # Files safe to diff/overwrite (no personalization placeholders)
    UPDATABLE_FILES=(
        "data-lake/technical/tech-stack.md"
        "data-lake/technical/sightmap-api.md"
        "data-lake/integrations/pms-systems.md"
        "data-lake/_contributing.md"
        ".github/instructions/jira.instructions.md"
        "templates/jira/story-template.md"
        "templates/jira/bug-template.md"
        "templates/jira/epic-template.md"
        "templates/jira/examples/README.md"
        "templates/docs/prd-template.md"
        "templates/docs/integration-doc-template.md"
        "templates/docs/integration-external-guide-template.md"
        "templates/project/README.md"
        "scripts/jira-adf-update.py"
        "scripts/refresh.sh"
    )

    # Files with {{PLACEHOLDERS}} — skip in update mode since they're personalized
    # (data-lake/_context.md and .github/copilot-instructions.md)

    UPDATED=0
    SKIPPED=0
    ADDED=0

    for file in "${UPDATABLE_FILES[@]}"; do
        src="$SCRIPT_DIR/$file"
        dst="$WORKSPACE_PATH/$file"

        if [[ ! -f "$src" ]]; then
            continue
        fi

        if [[ ! -f "$dst" ]]; then
            echo -e "  ${GREEN}NEW${NC}  $file"
            if confirm "    Add this file?"; then
                mkdir -p "$(dirname "$dst")"
                cp "$src" "$dst"
                success "    Added $file"
                ((ADDED++))
            else
                ((SKIPPED++))
            fi
        elif diff -q "$src" "$dst" > /dev/null 2>&1; then
            echo -e "  ${DIM}  ✓  $file (up to date)${NC}"
        else
            echo -e "  ${YELLOW}CHANGED${NC}  $file"
            echo ""
            diff --color=always -u "$dst" "$src" 2>/dev/null | head -40 || true
            echo ""
            echo -e "    ${CYAN}K${NC} = Keep mine  |  ${CYAN}O${NC} = Overwrite with new  |  ${CYAN}S${NC} = Skip"
            echo -en "    ${YELLOW}?${NC}  Choice [K/O/S]: "
            read -r choice
            case "$(lowercase "${choice:-k}")" in
                o)
                    cp "$dst" "${dst}.bak"
                    cp "$src" "$dst"
                    success "    Updated (backup at ${file}.bak)"
                    ((UPDATED++))
                    ;;
                s)
                    info "    Skipped"
                    ((SKIPPED++))
                    ;;
                *)
                    info "    Kept your version"
                    ((SKIPPED++))
                    ;;
            esac
        fi
    done

    # ── Check for new Data Lake files ────────────────────────
    DL_SRC="$SCRIPT_DIR/data-lake"
    DL_DST="$WORKSPACE_PATH/data-lake"
    if [[ -d "$DL_SRC" && ! -d "$DL_DST" ]]; then
        echo ""
        echo -e "  ${GREEN}NEW${NC}  data-lake/ (entire directory)"
        if confirm "    Add the Engrain Data Lake knowledge base?"; then
            cp -R "$DL_SRC" "$DL_DST"
            success "    Added Data Lake"
            ((ADDED++))
        else
            ((SKIPPED++))
        fi
    fi

    # ── Skill check ──────────────────────────────────────────
    header "Checking Skills"

    BUNDLED_SKILLS=("skill-share" "qa-review" "jira-ticket")
    SKILLS_INSTALLED=0

    for skill in "${BUNDLED_SKILLS[@]}"; do
        skill_src="$SCRIPT_DIR/skills/$skill"
        skill_dst="$SKILLS_DIR/$skill"

        if [[ ! -d "$skill_dst" ]]; then
            echo -e "  ${GREEN}NEW${NC}  $skill — not installed"
            if confirm "    Install $skill skill?"; then
                mkdir -p "$skill_dst"
                # Copy all files except local.md (user creates their own)
                for f in "$skill_src"/*; do
                    fname="$(basename "$f")"
                    [[ "$fname" == "local.md" ]] && continue
                    cp "$f" "$skill_dst/$fname"
                done
                # Create local.md stub if it doesn't exist
                if [[ ! -f "$skill_dst/local.md" ]]; then
                    cat > "$skill_dst/local.md" << 'LOCALEOF'
# Local Overrides

> This file is yours to customize. It is never overwritten by skill updates
> and never published to the shared repo. Add team-specific context,
> workflow tweaks, or personal preferences here.
>
> Copilot reads both SKILL.md and local.md when this skill is invoked.
> Guidance in local.md takes precedence over SKILL.md for any conflicts.

<!-- Add your overrides below -->
LOCALEOF
                fi
                success "    Installed $skill"
                ((SKILLS_INSTALLED++))
            fi
        else
            # Compare SKILL.md versions
            if [[ -f "$skill_src/SKILL.md" ]] && ! diff -q "$skill_src/SKILL.md" "$skill_dst/SKILL.md" > /dev/null 2>&1; then
                echo -e "  ${YELLOW}UPDATE${NC}  $skill — SKILL.md has changes"
                if confirm "    Update $skill? (your local.md will be preserved)"; then
                    # Backup local.md if it exists
                    [[ -f "$skill_dst/local.md" ]] && cp "$skill_dst/local.md" "/tmp/_${skill}_local_backup.md"
                    # Copy new files (except local.md)
                    for f in "$skill_src"/*; do
                        fname="$(basename "$f")"
                        [[ "$fname" == "local.md" ]] && continue
                        cp "$f" "$skill_dst/$fname"
                    done
                    # Restore local.md
                    [[ -f "/tmp/_${skill}_local_backup.md" ]] && mv "/tmp/_${skill}_local_backup.md" "$skill_dst/local.md"
                    success "    Updated $skill (local.md preserved)"
                    ((SKILLS_INSTALLED++))
                fi
            else
                echo -e "  ${DIM}  ✓  $skill (up to date)${NC}"
            fi
        fi
    done

    # ── Credentials check ────────────────────────────────────
    header "Checking Credentials"

    if [[ ! -f "$CREDS_FILE" ]]; then
        warn "No credentials.env found"
        if confirm "Set up credentials.env now?"; then
            # Jump to credentials setup (shared function below)
            SETUP_CREDS=true
        else
            SETUP_CREDS=false
        fi
    else
        success "credentials.env exists"
        # Show which vars are set (names only, never values)
        echo "  Configured variables:"
        grep -E "^export " "$CREDS_FILE" | grep -v '=""' | sed 's/=.*//' | sed 's/export /    /' || true
        echo ""
        # Check .zshrc sourcing
        if grep -q "credentials.env" "$HOME/.zshrc" 2>/dev/null; then
            success ".zshrc sources credentials.env"
        else
            warn ".zshrc doesn't source credentials.env"
            if confirm "Add sourcing line to .zshrc?"; then
                echo '[ -f ~/.copilot/credentials.env ] && source ~/.copilot/credentials.env' >> "$HOME/.zshrc"
                success "Added to .zshrc"
            fi
        fi
        SETUP_CREDS=false
    fi

    # Check mcp-config
    if [[ ! -f "$COPILOT_DIR/mcp-config.json" ]]; then
        warn "No mcp-config.json found — Jira/Confluence integration won't work"
        if confirm "Set up Jira connection now?"; then
            SETUP_CREDS=true
        fi
    else
        success "mcp-config.json exists"
    fi

    # If credentials need setup, handle inline
    if [[ "$SETUP_CREDS" == true ]]; then
        echo ""
        echo -e "  ${DIM}Generate an API token at:${NC}"
        echo -e "  ${CYAN}https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
        echo ""

        prompt UPDATE_EMAIL "Your Engrain email" ""
        echo -en "${YELLOW}?${NC}  Paste your API token (input is hidden): "
        read -rs UPDATE_TOKEN
        echo ""

        if [[ -n "$UPDATE_TOKEN" ]]; then
            cat > "$CREDS_FILE" << CREDEOF
# Engrain Copilot CLI credentials
# Sourced by .zshrc — keep this file secure (chmod 600)

# Atlassian (Jira + Confluence)
export JIRA_URL="https://engrain.atlassian.net"
export JIRA_USERNAME="$UPDATE_EMAIL"
export JIRA_USER_EMAIL="$UPDATE_EMAIL"
export JIRA_API_TOKEN="$UPDATE_TOKEN"
export CONFLUENCE_URL="https://engrain.atlassian.net/wiki"
export CONFLUENCE_USERNAME="$UPDATE_EMAIL"
export CONFLUENCE_API_TOKEN="$UPDATE_TOKEN"

# Uncomment and fill in as needed:
# export GITHUB_TOKEN=""
# export BITBUCKET_APP_PASSWORD=""
# export SIGHTMAP_API_KEY=""
CREDEOF
            chmod 600 "$CREDS_FILE"
            success "Created credentials.env"

            if ! grep -q "credentials.env" "$HOME/.zshrc" 2>/dev/null; then
                echo '' >> "$HOME/.zshrc"
                echo '# Copilot CLI credentials' >> "$HOME/.zshrc"
                echo '[ -f ~/.copilot/credentials.env ] && source ~/.copilot/credentials.env' >> "$HOME/.zshrc"
                success "Added credentials sourcing to .zshrc"
            fi

            # Create mcp-config.json
            MCP_CONFIG="$COPILOT_DIR/mcp-config.json"
            if [[ ! -f "$MCP_CONFIG" ]]; then
                cat > "$MCP_CONFIG" << MCPEOF
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://engrain.atlassian.net",
        "JIRA_USERNAME": "$UPDATE_EMAIL",
        "JIRA_API_TOKEN": "$UPDATE_TOKEN",
        "CONFLUENCE_URL": "https://engrain.atlassian.net/wiki",
        "CONFLUENCE_USERNAME": "$UPDATE_EMAIL",
        "CONFLUENCE_API_TOKEN": "$UPDATE_TOKEN"
      }
    }
  }
}
MCPEOF
                success "Created mcp-config.json"
            fi
        else
            warn "No token entered — you can set this up later"
        fi
    fi

    # ── Summary ──────────────────────────────────────────────
    header "Update Complete"
    echo "  Files updated:          $UPDATED"
    echo "  Files added:            $ADDED"
    echo "  Files skipped:          $SKIPPED"
    echo "  Skills installed/updated: $SKILLS_INSTALLED"
    echo ""
    success "Your workspace is up to date!"
    echo ""
    info "Restart your Copilot CLI session to pick up changes."
    echo ""
    exit 0
fi

# ═══════════════════════════════════════════════════════════
# FRESH INSTALL MODE
# ═══════════════════════════════════════════════════════════

# ── Step 1: Prerequisites ──────────────────────────────────
header "Step 1: Prerequisites"

check_tool() {
    local name="$1" install_cmd="$2" check_cmd="${3:-$1}"
    if command -v "$check_cmd" &> /dev/null; then
        success "$name is installed"
        return 0
    else
        warn "$name is not installed"
        if confirm "Install $name now?"; then
            echo ""
            eval "$install_cmd"
            echo ""
            if command -v "$check_cmd" &> /dev/null; then
                success "$name installed successfully"
                return 0
            else
                error "Failed to install $name — please install manually and re-run"
                return 1
            fi
        else
            error "$name is required. Please install it and re-run."
            return 1
        fi
    fi
}

# Homebrew
if ! command -v brew &> /dev/null; then
    warn "Homebrew is not installed"
    if confirm "Install Homebrew now?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon PATH setup
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                success "Added Homebrew to PATH (Apple Silicon)"
            fi
        fi
    else
        error "Homebrew is required. Install it from https://brew.sh"
        exit 1
    fi
fi
success "Homebrew is installed"

check_tool "Git" "brew install git" "git" || exit 1
check_tool "Copilot CLI" "brew install copilot-cli" "copilot" || exit 1
check_tool "uv (Python runner)" "brew install uv" "uv" || exit 1

echo ""
success "All prerequisites installed!"

# ── Step 2: Personalization ────────────────────────────────
header "Step 2: Personalization"
echo "  Let's set up your agent. These details personalize"
echo "  your workspace and Copilot's behavior."
echo ""

prompt USER_NAME "Your full name (e.g., Jane Smith)"
prompt USER_EMAIL "Your Engrain email" ""

# Validate email format
while [[ ! "$USER_EMAIL" =~ @engrain\.com$ ]]; do
    warn "Email should be your @engrain.com address"
    prompt USER_EMAIL "Your Engrain email"
done

prompt USER_TEAM "Your team (e.g., Product, Engineering, Sales, Data, Design)"
prompt USER_FOCUS "Products you work on (e.g., Atlas, SightMap API, Integrations)"
prompt USER_RESPONSIBILITIES "Key responsibilities (e.g., New feature specs, QA reviews)"

echo ""
divider
echo ""

prompt AGENT_NAME "Name for your agent (e.g., atlas, radar, scout). This becomes your terminal command and folder name"
# Sanitize: lowercase, no spaces
AGENT_NAME=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

WORKSPACE_FOLDER="$(capitalize "$AGENT_NAME")"
# Expand to full path
WORKSPACE_PATH="$HOME/$WORKSPACE_FOLDER"

echo ""
info "Your workspace will be at: ${BOLD}$WORKSPACE_PATH${NC}"
info "Type '${BOLD}$AGENT_NAME${NC}' from anywhere to launch your agent"

# Check if workspace already exists
if [[ -d "$WORKSPACE_PATH" ]]; then
    warn "$WORKSPACE_PATH already exists"
    if ! confirm "Continue anyway? (existing files may be overwritten)"; then
        info "Choose a different folder name and re-run."
        exit 0
    fi
fi

echo ""
echo -e "  ${BOLD}Summary:${NC}"
echo "    Name:             $USER_NAME"
echo "    Email:            $USER_EMAIL"
echo "    Team:             $USER_TEAM"
echo "    Focus:            $USER_FOCUS"
echo "    Responsibilities: $USER_RESPONSIBILITIES"
echo "    Agent alias:      $AGENT_NAME"
echo "    Workspace:        $WORKSPACE_PATH"
echo ""

if ! confirm "Look good? Continue with setup?"; then
    info "Re-run the script to try again."
    exit 0
fi

# ── Step 3: Copy Workspace ─────────────────────────────────
header "Step 3: Creating Workspace"

mkdir -p "$WORKSPACE_PATH"

# ── Step 3a: Content Bundles ──────────────────────────────
echo "  Your workspace starts with a core knowledge base."
echo "  You can add optional packs based on your role."
echo ""

INCLUDE_JIRA=false
INCLUDE_CODE=false

echo -e "  ${BOLD}Optional packs:${NC}"
echo ""
echo -e "    ${CYAN}Jira & PM Tools${NC}"
echo "    Jira ticket templates, examples, jira-ticket skill,"
echo "    PRD template, integration doc templates, ADF script"
echo ""
if confirm "Include Jira & PM Tools?"; then
    INCLUDE_JIRA=true
    success "Jira & PM Tools will be included"
else
    info "Skipped — you can add these later via skill-share"
fi

echo ""
echo -e "    ${CYAN}Code Analysis${NC}"
echo "    Deno/React/Laravel instructions, qa-review skill,"
echo "    tech stack docs, git workflow, repo refresh script"
echo ""
if confirm "Include Code Analysis tools?"; then
    INCLUDE_CODE=true
    success "Code Analysis tools will be included"
else
    info "Skipped — you can add these later via skill-share"
fi

echo ""

# ── Copy core files ───────────────────────────────────────
# Create directory structure for core
for dir in .github data-lake/company data-lake/customers data-lake/integrations \
           data-lake/journeys data-lake/operations data-lake/products \
           data-lake/reference data-lake/technical \
           templates/project projects; do
    mkdir -p "$WORKSPACE_PATH/$dir"
done

# Core: .github/copilot-instructions.md
cp "$SCRIPT_DIR/.github/copilot-instructions.md" "$WORKSPACE_PATH/.github/copilot-instructions.md"

# Core: Data Lake files
CORE_DL_FILES=(
    "_context.md" "_index.md" "_contributing.md"
    "company/_overview.md"
    "customers/_overview.md"
    "integrations/_overview.md"
    "integrations/custom-integrations.md"
    "journeys/_overview.md"
    "operations/_overview.md"
    "operations/quote-to-cash.md"
    "products/_overview.md"
    "reference/_overview.md"
    "reference/data-standards.md"
    "technical/_overview.md"
    "technical/sightmap-api.md"
)
for f in "${CORE_DL_FILES[@]}"; do
    cp "$SCRIPT_DIR/data-lake/$f" "$WORKSPACE_PATH/data-lake/$f"
done

# Core: templates/project
cp "$SCRIPT_DIR/templates/project/README.md" "$WORKSPACE_PATH/templates/project/README.md"

# Core: empty dirs
cp "$SCRIPT_DIR/projects/.gitkeep" "$WORKSPACE_PATH/projects/.gitkeep" 2>/dev/null || touch "$WORKSPACE_PATH/projects/.gitkeep"

success "Core workspace files copied"

# ── Jira & PM Tools ──────────────────────────────────────
if [[ "$INCLUDE_JIRA" == true ]]; then
    for dir in .github/instructions templates/jira/examples templates/docs scripts; do
        mkdir -p "$WORKSPACE_PATH/$dir"
    done

    # Jira instructions
    cp "$SCRIPT_DIR/.github/instructions/jira.instructions.md" "$WORKSPACE_PATH/.github/instructions/jira.instructions.md"

    # Jira templates + examples
    cp "$SCRIPT_DIR/templates/jira/story-template.md" "$WORKSPACE_PATH/templates/jira/story-template.md"
    cp "$SCRIPT_DIR/templates/jira/bug-template.md" "$WORKSPACE_PATH/templates/jira/bug-template.md"
    cp "$SCRIPT_DIR/templates/jira/epic-template.md" "$WORKSPACE_PATH/templates/jira/epic-template.md"
    cp "$SCRIPT_DIR/templates/jira/examples/README.md" "$WORKSPACE_PATH/templates/jira/examples/README.md"

    # Doc templates
    cp "$SCRIPT_DIR/templates/docs/prd-template.md" "$WORKSPACE_PATH/templates/docs/prd-template.md"
    cp "$SCRIPT_DIR/templates/docs/integration-doc-template.md" "$WORKSPACE_PATH/templates/docs/integration-doc-template.md"
    cp "$SCRIPT_DIR/templates/docs/integration-external-guide-template.md" "$WORKSPACE_PATH/templates/docs/integration-external-guide-template.md"

    # Scripts
    cp "$SCRIPT_DIR/scripts/jira-adf-update.py" "$WORKSPACE_PATH/scripts/jira-adf-update.py"

    success "Jira & PM Tools added"
fi

# ── Code Analysis ────────────────────────────────────────
if [[ "$INCLUDE_CODE" == true ]]; then
    mkdir -p "$WORKSPACE_PATH/.github/instructions"
    mkdir -p "$WORKSPACE_PATH/scripts"
    mkdir -p "$WORKSPACE_PATH/repos"

    # Dev instructions
    cp "$SCRIPT_DIR/.github/instructions/deno.instructions.md" "$WORKSPACE_PATH/.github/instructions/deno.instructions.md"
    cp "$SCRIPT_DIR/.github/instructions/react.instructions.md" "$WORKSPACE_PATH/.github/instructions/react.instructions.md"
    cp "$SCRIPT_DIR/.github/instructions/server.instructions.md" "$WORKSPACE_PATH/.github/instructions/server.instructions.md"

    # Tech docs
    cp "$SCRIPT_DIR/data-lake/technical/tech-stack.md" "$WORKSPACE_PATH/data-lake/technical/tech-stack.md"
    cp "$SCRIPT_DIR/data-lake/technical/git-workflow.md" "$WORKSPACE_PATH/data-lake/technical/git-workflow.md"
    cp "$SCRIPT_DIR/data-lake/integrations/pms-systems.md" "$WORKSPACE_PATH/data-lake/integrations/pms-systems.md"
    cp "$SCRIPT_DIR/data-lake/integrations/smctl-commands.md" "$WORKSPACE_PATH/data-lake/integrations/smctl-commands.md"

    # Scripts
    cp "$SCRIPT_DIR/scripts/refresh.sh" "$WORKSPACE_PATH/scripts/refresh.sh"
    chmod +x "$WORKSPACE_PATH/scripts/refresh.sh"

    # Repos placeholder
    touch "$WORKSPACE_PATH/repos/.gitkeep"

    success "Code Analysis tools added"
fi

# ── Tailor copilot-instructions.md based on packs ─────────
INSTRUCTIONS="$WORKSPACE_PATH/.github/copilot-instructions.md"

# Insert pack-specific role bullets after the core role lines
if [[ "$INCLUDE_JIRA" == true ]]; then
    sed -i '' '/^- Help build infrastructure/a\
- Write Jira tickets (stories, epics, bugs) using established templates\
- Research and document for product decisions' "$INSTRUCTIONS"
fi

if [[ "$INCLUDE_CODE" == true ]]; then
    sed -i '' '/^- Help build infrastructure/a\
- Analyze codebases for scoping and technical discovery\
- Prototype features and write code across the monorepo\
- Push branches and PRs for testing' "$INSTRUCTIONS"
fi

# Append pack-specific Required Reading rows
if [[ "$INCLUDE_JIRA" == true ]]; then
    sed -i '' '/General Engrain knowledge/a\
| Ticket writing | `templates/jira/` (use appropriate template) |' "$INSTRUCTIONS"
fi

if [[ "$INCLUDE_CODE" == true ]]; then
    sed -i '' '/General Engrain knowledge/a\
| Code analysis | `data-lake/technical/tech-stack.md` |\
| API work | `data-lake/technical/sightmap-api.md` (summary) + `repos/app-sightmap/openapi/` (full specs) |' "$INSTRUCTIONS"
fi

# Append pack-specific skills to the Available Skills table
if [[ "$INCLUDE_JIRA" == true ]]; then
    sed -i '' '/`skill-share`/a\
| `jira-ticket` | Writing Jira stories, epics, or bugs |' "$INSTRUCTIONS"
fi

if [[ "$INCLUDE_CODE" == true ]]; then
    sed -i '' '/`skill-share`/a\
| `qa-review` | QA reviewing a feature branch or PR |' "$INSTRUCTIONS"
fi

# Append code-specific sections if Code Analysis pack was selected
if [[ "$INCLUDE_CODE" == true ]]; then
    cat >> "$INSTRUCTIONS" << 'CODEEOF'

## AGENTS.md Reference

Before working on code, read the relevant AGENTS.md:

| Working on... | Read |
|---------------|------|
| Full monorepo overview | `repos/app-sightmap/AGENTS.md` |
| Backend / API | `repos/app-sightmap/server/AGENTS.md` |
| SightMap embed (renter-facing) | `repos/app-sightmap/clients/app/AGENTS.md` |
| Atlas customer portal | `repos/app-sightmap/clients/customer/AGENTS.md` |
| Atlas admin (employee-facing) | `repos/app-sightmap/clients/manage/AGENTS.md` |
| Map rendering pipeline | `parser/`, `geojson/`, `tilesets/` AGENTS.md files |
| Indoor navigation | `repos/app-sightmap/navigation/AGENTS.md` |
| PMS integrations CLI | `repos/app-smctl/AGENTS.md` |
| API specifications | `repos/app-sightmap/openapi/AGENTS.md` |

## Repo Management

All repos are on Bitbucket. Keep local copies fresh before working:

| Repo | Clone URL | Default Branch | PR Target |
|------|-----------|---------------|-----------|
| `app-sightmap` | `git@bitbucket.org:engrain/app-sightmap.git` | `master` | `develop` |
| `app-smctl` | `git@bitbucket.org:engrain/app-smctl.git` | `main` | `main` |
| `atlas-integrations` | `git@bitbucket.org:engrain/atlas-integrations.git` | `main` | `deploy/*` |
| `xp-data-integrations` | `git@bitbucket.org:engrain/xp-data-integrations.git` | `main` | `main` |

To refresh all repos before a session:
```bash
for repo in repos/*/; do (cd "$repo" && git pull); done
```

## Code Analysis Approach

1. **Start** with AGENTS.md or README.md in any repo
2. **Map** findings to Engrain's data hierarchy
3. **Use** Engrain terminology in all documentation
4. **Output** scoping documents to `projects/[project-name]/`
5. **Reference** `data-lake/technical/tech-stack.md` for architectural context

### Key Repos

| Repo | Tech | Purpose |
|------|------|---------|
| `app-sightmap` | PHP/Laravel, React, Deno | Main monorepo (13 services) |
| `app-smctl` | Deno / TypeScript | CLI for API & PMS integrations |
| `atlas-integrations` | Bash / K8s CronJobs | Production integration scheduling |
| `xp-data-integrations` | Python + Streamlit | Data team scripts and tooling UI |

### Data Pipelines

- **Unit Map**: SVG upload → Parser (Node.js) → GeoJSON (Deno) → Tilesets (Deno) → Browser
- **Feed System**: PMS → FeedSource → Feed → FeedRun → ProcessExecution → Unit pricing/availability
- **Navigation**: SHADE format → Valhalla routing tiles → Multi-floor indoor wayfinding

### Public APIs

| API | Domain | Purpose |
|-----|--------|---------|
| SightMap API | `api.sightmap.com` | Assets, units, pricing, availability, maps |
| Unit Map API | `api.unitmap.com` | Map documents, SVG parsing, geographic data |

Docs: `repos/app-sightmap/openapi/` — OpenAPI 3.0.3 specs

## Development Environment

- **Docker Compose**: All services run in containers (`./run.sh` to start)
- **Local domains**: `sightmap.local`, `api.sightmap.local`, `api.unitmap.local`
- **devtools container**: Node.js/Yarn for client builds (`docker compose run --rm devtools`)
- **Server commands**: `docker compose exec app {command}`
- **smctl**: `./smctl --help` in app-smctl
- **CI**: Codacy runs automatically on PRs

## Prototyping & Code

When writing code or pushing PRs:

1. **Read the relevant AGENTS.md** before touching any service
2. **Branch from `develop`** (app-sightmap) or `main` (other repos)
3. **Run tests and linting** before pushing (see path-specific instructions)
4. **PR title = final commit message** (emoji prefix + description + JIRA ref)

## Git Conventions

- **Commit format**: `:emoji: Description (JIRA-123).` (end with period)
- **Branch naming**: `feature/short-descriptive-name`
- **Branching**: From `develop` (app-sightmap) or `main` (other repos)
- **Squash**: All WIP commits into one final commit per issue
- **PR title**: Must match final commit message exactly
- **Workflow**: Rebase (not merge)

### Commit Emojis

| Emoji | Code | Use |
|-------|------|-----|
| 🎨 | `:art:` | Code structure/format |
| 🐛 | `:bug:` | Bug fix |
| 🐎 | `:racehorse:` | Performance |
| 📝 | `:pencil:` | Documentation |
| 🔥 | `:fire:` | Remove code/files |
| 💥 | `:boom:` | Breaking backward compatibility |
| ✅ | `:white_check_mark:` | Tests |
| 🔒 | `:lock:` | Security |
| ⬆ | `:arrow_up:` | Upgrade deps |
| ⬇ | `:arrow_down:` | Downgrade deps |
| 🚓 | `:police_car:` | Standards/best practices |
| 🚱 | `:non-potable_water:` | Memory leaks |
CODEEOF
fi

# Append Jira-specific sections if Jira pack was selected
if [[ "$INCLUDE_JIRA" == true ]]; then
    cat >> "$INSTRUCTIONS" << 'JIRAEOF'

## Jira Ticket Writing

When writing tickets, use templates from `templates/jira/`:

- **Stories**: `story-template.md` — 6-section format with user story
- **Bugs**: `bug-template.md` — includes repro steps
- **Epics**: `epic-template.md` — includes story breakdown

Read `templates/jira/examples/README.md` for tone and detail calibration before writing your first ticket.

### Jira Formatting

Use Markdown with `:::panel` markers for colored sections:
- `:::panel info` (blue) — User Story block
- `:::panel success` (green) — Acceptance Criteria block
- `:::panel warning` (yellow) — Open Questions

Push formatted descriptions via `scripts/jira-adf-update.py`.
JIRAEOF
fi

success "Workspace instructions tailored to your packs"

# ── Step 4: Personalization ────────────────────────────────
header "Step 4: Personalizing Files"

# Escape sed special characters in user input (/, &, \)
escape_sed() { printf '%s\n' "$1" | sed 's/[\/&\\]/\\&/g'; }
ESC_NAME="$(escape_sed "$USER_NAME")"
ESC_TEAM="$(escape_sed "$USER_TEAM")"
ESC_FOCUS="$(escape_sed "$USER_FOCUS")"
ESC_RESP="$(escape_sed "$USER_RESPONSIBILITIES")"

# Replace placeholders in all text files
find "$WORKSPACE_PATH" -type f \( -name "*.md" -o -name "*.py" \) -exec \
    sed -i '' \
        -e "s/{{NAME}}/$ESC_NAME/g" \
        -e "s/{{TEAM}}/$ESC_TEAM/g" \
        -e "s/{{FOCUS}}/$ESC_FOCUS/g" \
        -e "s/{{RESPONSIBILITIES}}/$ESC_RESP/g" \
    {} +

success "Files personalized for $USER_NAME"

# ── Step 5: Initialize Git ─────────────────────────────────
header "Step 5: Initialize Git"
cd "$WORKSPACE_PATH"
if [[ ! -d ".git" ]]; then
    git init -q
    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
# OS files
.DS_Store
Thumbs.db

# Cloned repositories (too large for workspace repo)
repos/

# Obsidian vault
.obsidian/
**/.obsidian/

# Environment files
.env
*.env
!scripts/.env.example

# Editor files
*.swp
*.swo
*~
GITIGNORE
    git add -A
    git commit -q -m "Initial workspace setup"
    success "Git initialized with initial commit"
else
    success "Git already initialized"
fi

# ── Step 6: Install Skills ─────────────────────────────────
header "Step 6: Installing Skills"

mkdir -p "$SKILLS_DIR"

# Build skills list based on selected bundles
INSTALL_SKILLS=("skill-share")
[[ "$INCLUDE_JIRA" == true ]] && INSTALL_SKILLS+=("jira-ticket")
[[ "$INCLUDE_CODE" == true ]] && INSTALL_SKILLS+=("qa-review")

install_skill() {
    local skill="$1"
    local skill_src="$SCRIPT_DIR/skills/$skill"
    local skill_dst="$SKILLS_DIR/$skill"

    if [[ -d "$skill_dst" ]]; then
        info "$skill already installed — skipping"
        return
    fi

    mkdir -p "$skill_dst"
    for f in "$skill_src"/*; do
        fname="$(basename "$f")"
        [[ "$fname" == "local.md" ]] && continue
        cp "$f" "$skill_dst/$fname"
    done

    # Create local.md stub
    cat > "$skill_dst/local.md" << 'LOCALEOF'
# Local Overrides

> This file is yours to customize. It is never overwritten by skill updates
> and never published to the shared repo. Add team-specific context,
> workflow tweaks, or personal preferences here.
>
> Copilot reads both SKILL.md and local.md when this skill is invoked.
> Guidance in local.md takes precedence over SKILL.md for any conflicts.

<!-- Add your overrides below -->
LOCALEOF

    success "Installed $skill skill"
}

for skill in "${INSTALL_SKILLS[@]}"; do
    install_skill "$skill"
done

SKILLS_SUMMARY=""
for skill in "${INSTALL_SKILLS[@]}"; do
    [[ -n "$SKILLS_SUMMARY" ]] && SKILLS_SUMMARY="$SKILLS_SUMMARY, "
    SKILLS_SUMMARY="$SKILLS_SUMMARY$skill"
done
success "Skills installed to ~/.copilot/skills/ ($SKILLS_SUMMARY)"

# ── Step 7: Global Persona ─────────────────────────────────
header "Step 7: Global Persona"

PERSONA_FILE="$COPILOT_DIR/copilot-instructions.md"
PERSONA_TEMPLATE="$SCRIPT_DIR/copilot-instructions.md.template"

if [[ -f "$PERSONA_FILE" ]]; then
    warn "Global persona file already exists at $PERSONA_FILE"
    # Generate what the new one would look like
    TEMP_PERSONA=$(mktemp)
    AGENT_DISPLAY=$(capitalize "$AGENT_NAME")
    ESC_DISPLAY="$(escape_sed "$AGENT_DISPLAY")"
    sed -e "s/{{NAME}}/$ESC_NAME/g" -e "s/{{AGENT_NAME}}/$ESC_DISPLAY/g" "$PERSONA_TEMPLATE" > "$TEMP_PERSONA"

    if diff -q "$PERSONA_FILE" "$TEMP_PERSONA" > /dev/null 2>&1; then
        success "Already up to date"
    else
        echo ""
        echo -e "  Your current persona says:"
        echo -e "    ${DIM}$(grep -m1 'You are' "$PERSONA_FILE" | sed 's/^> //')${NC}"
        echo ""
        echo -e "  The new version would say:"
        echo -e "    ${CYAN}$(grep -m1 'You are' "$TEMP_PERSONA" | sed 's/^> //')${NC}"
        echo ""
        echo -e "    ${CYAN}K${NC} = Keep current  |  ${CYAN}O${NC} = Overwrite with new"
        echo -en "    ${YELLOW}?${NC}  Choice [K/O]: "
        read -r choice
        if [[ "$(lowercase "${choice:-k}")" == "o" ]]; then
            cp "$PERSONA_FILE" "${PERSONA_FILE}.bak"
            cp "$TEMP_PERSONA" "$PERSONA_FILE"
            success "Updated (backup at copilot-instructions.md.bak)"
        else
            info "Kept existing persona"
        fi
    fi
    rm -f "$TEMP_PERSONA"
else
    mkdir -p "$COPILOT_DIR"
    AGENT_DISPLAY=$(capitalize "$AGENT_NAME")
    ESC_DISPLAY="$(escape_sed "$AGENT_DISPLAY")"
    sed -e "s/{{NAME}}/$ESC_NAME/g" -e "s/{{AGENT_NAME}}/$ESC_DISPLAY/g" "$PERSONA_TEMPLATE" > "$PERSONA_FILE"
    success "Created global persona at $PERSONA_FILE"
fi

# ── Step 8: Credentials ────────────────────────────────────
header "Step 8: Credentials & Jira Connection"

echo "  This step sets up your Jira/Confluence connection."
echo "  You'll need an Atlassian API token."
echo ""
echo -e "  ${DIM}Generate one at:${NC}"
echo -e "  ${CYAN}https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
echo ""

if [[ -f "$CREDS_FILE" ]]; then
    success "credentials.env already exists"
    if ! confirm "Reconfigure credentials?" "n"; then
        SKIP_CREDS=true
    else
        SKIP_CREDS=false
    fi
else
    SKIP_CREDS=false
fi

if [[ "$SKIP_CREDS" != true ]]; then
    if confirm "Do you have your Atlassian API token ready?"; then
        echo -en "${YELLOW}?${NC}  Paste your API token (input is hidden): "
        read -rs API_TOKEN
        echo ""

        if [[ -z "$API_TOKEN" ]]; then
            warn "No token entered — you can set this up later"
            warn "Run 'Setup credentials' in skill-share, or edit ~/.copilot/credentials.env"
            API_TOKEN=""
        fi
    else
        info "You can set this up later by editing ~/.copilot/credentials.env"
        info "or by asking your agent to 'Setup credentials'"
        API_TOKEN=""
    fi

    # Create credentials.env
    cat > "$CREDS_FILE" << CREDEOF
# Engrain Copilot CLI credentials
# Sourced by .zshrc — keep this file secure (chmod 600)

# Atlassian (Jira + Confluence)
export JIRA_URL="https://engrain.atlassian.net"
export JIRA_USERNAME="$USER_EMAIL"
export JIRA_USER_EMAIL="$USER_EMAIL"
export JIRA_API_TOKEN="$API_TOKEN"
export CONFLUENCE_URL="https://engrain.atlassian.net/wiki"
export CONFLUENCE_USERNAME="$USER_EMAIL"
export CONFLUENCE_API_TOKEN="$API_TOKEN"

# Uncomment and fill in as needed:
# export GITHUB_TOKEN=""
# export BITBUCKET_APP_PASSWORD=""
# export SIGHTMAP_API_KEY=""
CREDEOF
    chmod 600 "$CREDS_FILE"
    success "Created credentials.env (chmod 600)"

    # Add sourcing to .zshrc if not present
    if ! grep -q "credentials.env" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# Copilot CLI credentials' >> "$HOME/.zshrc"
        echo '[ -f ~/.copilot/credentials.env ] && source ~/.copilot/credentials.env' >> "$HOME/.zshrc"
        success "Added credentials sourcing to .zshrc"
    else
        success ".zshrc already sources credentials.env"
    fi

    # Source it now so mcp-config can use the vars
    source "$CREDS_FILE" 2>/dev/null || true

    # Create mcp-config.json
    MCP_CONFIG="$COPILOT_DIR/mcp-config.json"
    if [[ -f "$MCP_CONFIG" ]]; then
        warn "mcp-config.json already exists"
        if confirm "Overwrite with new config?" "n"; then
            cp "$MCP_CONFIG" "${MCP_CONFIG}.bak"
            CREATE_MCP=true
        else
            CREATE_MCP=false
            info "Kept existing mcp-config.json"
        fi
    else
        CREATE_MCP=true
    fi

    if [[ "$CREATE_MCP" == true ]]; then
        cat > "$MCP_CONFIG" << MCPEOF
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://engrain.atlassian.net",
        "JIRA_USERNAME": "$USER_EMAIL",
        "JIRA_API_TOKEN": "$API_TOKEN",
        "CONFLUENCE_URL": "https://engrain.atlassian.net/wiki",
        "CONFLUENCE_USERNAME": "$USER_EMAIL",
        "CONFLUENCE_API_TOKEN": "$API_TOKEN"
      }
    }
  }
}
MCPEOF
        success "Created mcp-config.json"
        if [[ -z "$API_TOKEN" ]]; then
            warn "Remember to add your API token to both credentials.env and mcp-config.json"
        fi
    fi
fi

# ── Step 9: Clone Repos ───────────────────────────────────
if [[ "$INCLUDE_CODE" == true ]]; then
    header "Step 9: Clone Repositories (Optional)"

    echo "  Clone Engrain repos into your workspace for code analysis."
    echo "  Uses HTTPS — you'll need a Bitbucket app password."
    echo ""
    echo -e "  ${DIM}Create one at:${NC}"
    echo -e "  ${CYAN}https://bitbucket.org/account/settings/app-passwords/${NC}"
    echo -e "  ${DIM}(needs Read access to repositories)${NC}"
    echo ""

# Repo definitions (parallel arrays — Bash 3.2 compatible)
REPO_NAMES=("" "app-sightmap" "app-smctl" "atlas-integrations" "xp-data-integrations")
REPO_URLS=("" "https://bitbucket.org/engrain/app-sightmap.git" "https://bitbucket.org/engrain/app-smctl.git" "https://bitbucket.org/engrain/atlas-integrations.git" "https://bitbucket.org/engrain/xp-data-integrations.git")
REPO_DESCS=("" "Main monorepo (Laravel, React, Deno)" "CLI for API & PMS integrations" "Integration scheduling (K8s CronJobs)" "Data team scripts & Streamlit UI")

for key in 1 2 3 4; do
    echo -e "    ${CYAN}$key${NC}  ${REPO_NAMES[$key]} — ${REPO_DESCS[$key]}"
done
echo ""
echo -e "    ${CYAN}a${NC}  All repos"
echo -e "    ${CYAN}n${NC}  None — skip for now"
echo ""
echo -en "  ${YELLOW}?${NC}  Which repos? (e.g., 1 3 or a or n): "
read -r REPO_CHOICE

if [[ "$REPO_CHOICE" != "n" && "$REPO_CHOICE" != "N" && -n "$REPO_CHOICE" ]]; then
    cd "$WORKSPACE_PATH/repos"

    CLONE_KEYS=()
    if [[ "$REPO_CHOICE" == "a" || "$REPO_CHOICE" == "A" ]]; then
        CLONE_KEYS=(1 2 3 4)
    else
        read -ra CLONE_KEYS <<< "$REPO_CHOICE"
    fi

    for key in "${CLONE_KEYS[@]}"; do
        if [[ $key -ge 1 && $key -le 4 ]]; then
            name="${REPO_NAMES[$key]}"
            url="${REPO_URLS[$key]}"
            if [[ -d "$name" ]]; then
                info "$name already cloned — skipping"
                continue
            fi
            info "Cloning $name..."
            if git clone "$url" "$name"; then
                success "Cloned $name"
            else
                error "Failed to clone $name — you can clone it later manually"
            fi
        fi
    done

    cd "$WORKSPACE_PATH"
else
    info "Skipping repo cloning — you can do this later"
fi

fi  # end INCLUDE_CODE check for repo cloning

# ── Step 10: Shell Alias ───────────────────────────────────
header "Step 10: Shell Alias"

ALIAS_LINE="alias $AGENT_NAME=\"cd $WORKSPACE_PATH && copilot\""

if grep -q "alias $AGENT_NAME=" "$HOME/.zshrc" 2>/dev/null; then
    success "Alias '$AGENT_NAME' already exists in .zshrc"
else
    echo '' >> "$HOME/.zshrc"
    echo "# Copilot CLI agent" >> "$HOME/.zshrc"
    echo "$ALIAS_LINE" >> "$HOME/.zshrc"
    success "Added alias: $AGENT_NAME"
    echo ""
    warn "Close this terminal and open a new one for the alias to take effect."
    info "Then type '${BOLD}$AGENT_NAME${NC}' from anywhere to launch your agent."
fi

# ── Step 11: Copilot Config ───────────────────────────────
header "Step 11: Copilot Config"

CONFIG_FILE="$COPILOT_DIR/config.json"

if [[ -f "$CONFIG_FILE" ]]; then
    # Add workspace to trusted_folders if not already there
    if command -v python3 &>/dev/null; then
        python3 - "$CONFIG_FILE" "$WORKSPACE_PATH" << 'PYEOF'
import json, sys
config_path, ws_path = sys.argv[1], sys.argv[2]
with open(config_path) as f:
    cfg = json.load(f)
tf = cfg.get("trusted_folders", [])
if ws_path not in tf:
    tf.append(ws_path)
    cfg["trusted_folders"] = tf
    with open(config_path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("added")
else:
    print("exists")
PYEOF
        success "Workspace trusted (no 'trust this folder?' prompt on launch)"
    else
        info "python3 not found — you may see a 'trust this folder?' prompt on first launch"
    fi
else
    # Create minimal config.json
    cat > "$CONFIG_FILE" << CFGEOF
{
  "trusted_folders": [
    "$WORKSPACE_PATH"
  ],
  "renderMarkdown": true
}
CFGEOF
    success "Created config.json with trusted workspace"
fi

# ── Done! ──────────────────────────────────────────────────
header "Setup Complete! 🎉"

echo -e "  ${BOLD}Your workspace:${NC}     $WORKSPACE_PATH"
echo -e "  ${BOLD}Your alias:${NC}         $AGENT_NAME"
echo -e "  ${BOLD}Skills installed:${NC}   $SKILLS_SUMMARY"
echo -e "  ${BOLD}Credentials:${NC}        ~/.copilot/credentials.env"
PACKS_INCLUDED="Core"
[[ "$INCLUDE_JIRA" == true ]] && PACKS_INCLUDED="$PACKS_INCLUDED + Jira/PM"
[[ "$INCLUDE_CODE" == true ]] && PACKS_INCLUDED="$PACKS_INCLUDED + Code Analysis"
echo -e "  ${BOLD}Content packs:${NC}     $PACKS_INCLUDED"
echo ""
divider
echo ""
echo -e "  ${BOLD}What to try first:${NC}"
echo ""
echo "    1. Open a new terminal tab"
echo -e "    2. Type: ${CYAN}$AGENT_NAME${NC}"
echo -e "    3. On first launch, run: ${CYAN}/login${NC}"
echo "    4. Try one of these prompts:"
echo ""
echo -e "       ${DIM}\"Summarize what's in this workspace\"${NC}"
echo -e "       ${DIM}\"What products does Engrain offer?\"${NC}"
echo -e "       ${DIM}\"What PMS integrations does Engrain support?\"${NC}"
echo -e "       ${DIM}\"List available skills\"${NC}"
echo ""
divider
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo ""
if [[ -z "${API_TOKEN:-}" ]]; then
    echo -e "    ${YELLOW}→${NC}  Add your Atlassian API token to ~/.copilot/credentials.env"
    echo "       and ~/.copilot/mcp-config.json"
fi
if [[ "$INCLUDE_JIRA" != true ]]; then
    echo -e "    ${YELLOW}→${NC}  Run setup again and add Jira & PM Tools when ready"
fi
if [[ "$INCLUDE_CODE" != true ]]; then
    echo -e "    ${YELLOW}→${NC}  Run setup again and add Code Analysis tools when ready"
fi
echo -e "    ${YELLOW}→${NC}  Ask your agent to \"list available skills\" to see what's shared"
echo -e "    ${YELLOW}→${NC}  Drop markdown files into data-lake/ for custom context"
echo -e "    ${YELLOW}→${NC}  Add team-specific overrides in skill local.md files"
echo ""
success "Happy building! 🚀"
echo ""
