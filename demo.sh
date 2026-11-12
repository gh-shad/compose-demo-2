#!/usr/bin/env bash
# =============================================================================
#  Docker Compose Demo  -  Running Multi-Container Applications
#  ---------------------------------------------------------------------------
#  A fully automatic, narrated demo. Press Enter once to start. After that, the
#  script runs every command by itself and explains each one in simple English.
#
#    Parts 1-9  : Docker Compose (start the app, network, volume, scaling, stop)
#    Part 10    : Clean up + safety check (before anything is uploaded)
#    Part 11    : Git (save the project and its history)
#    Part 12    : GitHub (upload the project and verify the upload)
#    At the end : a final confirmation screen with the result of every check
#
#  Usage:   ./demo.sh             automatic (the normal way: press Enter once)
#           ./demo.sh --slow      automatic, with more time to read each step
#           ./demo.sh --manual    you press Enter before every step
#           ./demo.sh --fast      quick run, no pauses (also used by the automatic tests)
#           ./demo.sh --setup     one-time checks + GitHub login, then stop
#           ./demo.sh --keep      leave the containers running (skips the Docker clean up)
#           ./demo.sh --no-git    Docker part + clean up only (Parts 1-10)
#           ./demo.sh --git-only  clean up + Git + GitHub only (Parts 10-12)
#           ./demo.sh --no-push   use Git, but do not upload to GitHub
#           ./demo.sh --push      log in to GitHub without asking first
#           ./demo.sh --help
#
#  While it runs:  Enter = skip the current pause    p = pause    Ctrl+C = stop
#  New GitHub repository name: compose-demo  (change with  REPO_NAME=my-name ./demo.sh)
#  Full documentation: README.md and the docs/ folder.
# =============================================================================

set -u
set -o pipefail

# ----------------------------------------------------------------------------
# Settings
# ----------------------------------------------------------------------------
MODE="auto"            # auto | manual | fast
SPEED="normal"         # normal | slow
KEEP=0
DO_DOCKER=1            # Parts 1-9
DO_GIT=1               # Part 11
DO_PUSH=1              # Part 12
FORCE_PUSH=0           # --push: log in to GitHub without asking
SETUP_ONLY=0
IMPORT_FILE=""         # --import-update FILE (used by the Windows launcher)
REPO_NAME="${REPO_NAME:-compose-demo}"
MYSQL_WAIT_MAX=240             # seconds to wait for MySQL before giving up
PUSH_ASK_TIMEOUT="${PUSH_ASK_TIMEOUT:-30}"   # seconds to answer the GitHub question
URL_FILE="$HOME/.compose-demo-github-url"    # read by the Windows launcher at the end
PLACEHOLDER="your-username/compose-demo"     # replaced by the real GitHub address

while [ $# -gt 0 ]; do
  case "$1" in
    --manual|-m) MODE="manual" ;;
    --fast|-f)   MODE="fast" ;;
    --slow|-s)   SPEED="slow" ;;
    --keep|-k)   KEEP=1 ;;
    --setup)     SETUP_ONLY=1 ;;
    --no-git)    DO_GIT=0; DO_PUSH=0 ;;
    --git-only)  DO_DOCKER=0 ;;
    --no-push)   DO_PUSH=0 ;;
    --push)      FORCE_PUSH=1 ;;
    --import-update)
      shift; IMPORT_FILE="${1:-}"
      [ -z "$IMPORT_FILE" ] && { echo "--import-update needs a file name"; exit 1; } ;;
    --help|-h)   sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1   (see ./demo.sh --help)"; exit 1 ;;
  esac
  shift
done

# Reading speed: words per second the audience gets to read each explanation
if [ "$SPEED" = "slow" ]; then WPS=2; TYPE_DELAY=0.03; else WPS=3; TYPE_DELAY=0.02; fi
[ "$MODE" = "fast" ] && TYPE_DELAY=0

# Always work inside the folder of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PROJECT="$(basename "$SCRIPT_DIR" | tr '[:upper:]' '[:lower:]')"
START_TIME=$(date +%s)

# ----------------------------------------------------------------------------
# Colours (switched off automatically when the output is not a terminal)
# ----------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\e[1m'; DIM=$'\e[2m'; R=$'\e[0m'
  CYAN=$'\e[36m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; MAG=$'\e[35m'; BLUE=$'\e[34m'
else
  B=""; DIM=""; R=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; MAG=""; BLUE=""
fi

COLS=$(tput cols 2>/dev/null || echo 100)
[ "$COLS" -gt 100 ] && COLS=100
[ "$COLS" -lt 60 ] && COLS=60
WRAP=$((COLS - 6))

HAVE_TTY=0
if [ -t 0 ] || { [ -r /dev/tty ] && : </dev/tty; } 2>/dev/null; then HAVE_TTY=1; fi

# ----------------------------------------------------------------------------
# Printing helpers
# ----------------------------------------------------------------------------
line() { printf '%s\n' "${DIM}$(printf '%*s' "$COLS" '' | tr ' ' '-')${R}"; }

banner() {
  local text="$1" colour="${2:-$BLUE}"
  local pad=$(( (COLS - 4 - ${#text}) / 2 )); [ $pad -lt 0 ] && pad=0
  local bar; bar=$(printf '%*s' $((COLS-2)) '' | tr ' ' '=')
  local blank; blank=$(printf '%*s' $((COLS-2)) '')
  echo
  printf '%s\n' "${B}${colour}+${bar}+${R}"
  printf '%s\n' "${B}${colour}|${R}${blank}${B}${colour}|${R}"
  printf '%s%*s%s%*s%s\n' "${B}${colour}|${R}" $((pad+1)) '' "${B}${text}${R}" $((COLS-3-pad-${#text})) '' "${B}${colour}|${R}"
  printf '%s\n' "${B}${colour}|${R}${blank}${B}${colour}|${R}"
  printf '%s\n' "${B}${colour}+${bar}+${R}"
}

part() {   # part <number> <title> <time>
  if [ "$MODE" != "fast" ] && [ -t 1 ]; then clear; fi
  echo
  line
  printf '%s\n' "${B}${MAG}  PART $1 of 12  -  $2${R}   ${DIM}(about $3)${R}"
  line
}

typeout() {   # print one line word by word (typing effect)
  local text="$1"
  if [ "$TYPE_DELAY" = "0" ]; then printf '%s\n' "$text"; return; fi
  local w first=1
  set -f
  for w in $text; do
    if [ $first = 1 ]; then printf '%s' "$w"; first=0; else printf ' %s' "$w"; fi
    sleep "$TYPE_DELAY"
  done
  set +f
  printf '\n'
}

box() {   # box <colour> <label> <paragraph>...
  local colour="$1" label="$2"; shift 2
  printf '%s\n' "${colour}${B}  ${label}${R}"
  local para l
  for para in "$@"; do
    while IFS= read -r l; do
      printf '%s' "${colour}  |${R} "
      typeout "$l"
    done < <(printf '%s\n' "$para" | fold -s -w "$WRAP")
    printf '%s\n' "${colour}  |${R}"
  done
}

note() { printf '%s\n' "${YELLOW}${B}  NOTE:${R} $*"; }
ok()   { printf '%s\n' "${GREEN}${B}  [OK]${R} $*"; }
fail() { printf '%s\n' "${RED}${B}  [PROBLEM]${R} $*"; }
info() { printf '%s\n' "${DIM}  ...${R} $*"; }
link() { printf '%s\n' "  ${B}${YELLOW}>>> $*${R}"; }

# ----------------------------------------------------------------------------
# Results: every important check is recorded here and shown at the very end
# ----------------------------------------------------------------------------
RESULTS_OK=()
RESULTS_FAIL=()
pass_check() { RESULTS_OK+=("$1"); ok "$1"; }
fail_check() { RESULTS_FAIL+=("$1"); fail "$1"; }
verify() {     # verify "<description>" <command...>   (runs quietly, records the result)
  local what="$1"; shift
  if "$@" >/dev/null 2>&1; then pass_check "$what"; else fail_check "$what"; fi
}

# ----------------------------------------------------------------------------
# Pauses
#   auto  : waits a few seconds by itself (Enter skips, p pauses)
#   manual: waits for Enter
#   fast  : no waiting
# ----------------------------------------------------------------------------
pause() {
  local secs="${1:-3}" key=""
  case "$MODE" in
    fast) return 0 ;;
    manual)
      if [ "$HAVE_TTY" = 1 ]; then
        printf '%s' "${DIM}  Press Enter to continue >${R} "
        read -r _ </dev/tty
      fi ;;
    auto)
      [ "$secs" -le 0 ] && return 0
      if [ "$HAVE_TTY" = 1 ]; then
        if read -r -s -n 1 -t "$secs" key </dev/tty; then
          if [ "$key" = "p" ] || [ "$key" = "P" ]; then
            printf '%s' "${YELLOW}  PAUSED. Press Enter to continue >${R} "
            read -r _ </dev/tty
          fi
        fi
      else
        sleep "$secs"
      fi ;;
  esac
  return 0
}

reading_time() {   # seconds the audience needs to read a text
  local words; words=$(printf '%s' "$*" | wc -w)
  local t=$(( words / WPS )); [ $t -lt 2 ] && t=2; [ $t -gt 15 ] && t=15
  echo "$t"
}

explain() { box "$CYAN" "EXPLANATION" "$@"; pause "$(reading_time "$*")"; }
notice()  { box "$GREEN" "LOOK AT THE RESULT" "$@"; pause "$(reading_time "$*")"; }

run() {   # run "<command shown on screen>" <real command...>
  local shown="$1"; shift
  echo
  printf '%s\n' "  ${B}${GREEN}\$ ${shown}${R}"
  "$@"
}

step() {  # step "<explanation>" "<command shown>" <real command...>
  local text="$1" shown="$2"; shift 2
  echo
  box "$CYAN" "NEXT COMMAND" "$text"
  pause "$(reading_time "$text")"
  run "$shown" "$@"
  local rc=$?
  echo
  return $rc
}

# ----------------------------------------------------------------------------
# Temporary files: everything temporary goes into ONE private folder in /tmp.
# Part 10 checks the path and deletes only that folder.
# ----------------------------------------------------------------------------
TMP_DIR=""
make_tmp_dir() { TMP_DIR=$(mktemp -d /tmp/compose-demo-run.XXXXXX) || { echo "Could not create a temporary folder"; exit 1; }; }

remove_tmp_dir() {   # deletes TMP_DIR only if it really is this script's own temp folder
  case "$TMP_DIR" in
    /tmp/compose-demo-run.??????) ;;
    *) return 1 ;;
  esac
  [ -d "$TMP_DIR" ] && [ -O "$TMP_DIR" ] || return 1
  rm -rf -- "$TMP_DIR"
}

# ----------------------------------------------------------------------------
# Docker helpers (uses sudo automatically if needed)
# ----------------------------------------------------------------------------
DOCKER=(docker)
dc() { "${DOCKER[@]}" compose "$@"; }
dk() { "${DOCKER[@]}" "$@"; }

EXEC_T=()   # 'docker compose exec' needs -T when there is no terminal
if ! [ -t 0 ] || ! [ -t 1 ]; then EXEC_T=(-T); fi

IP="localhost"
server_ip() { local ip; ip=$(hostname -I 2>/dev/null | awk '{print $1}'); echo "${ip:-localhost}"; }

mysql_ready() {
  # Ready when the REAL server (port 3306) is up and a test query works.
  # (The first time, MySQL runs a temporary setup server on port 0 first.)
  dc logs db 2>/dev/null | grep -qE "ready for connections.*port: 3306" || return 1
  dc exec -T db mysql -uroot -pexamplepassword -e "SELECT 1" >/dev/null 2>&1
}

wait_for_mysql() {
  info "Waiting for MySQL to be ready (the first start can take 30 to 60 seconds)"
  local waited=0
  printf '  '
  while ! mysql_ready; do
    if [ $waited -ge $MYSQL_WAIT_MAX ]; then
      echo
      fail "MySQL did not start in ${MYSQL_WAIT_MAX} seconds. Its last messages:"
      dc logs --tail 15 db
      return 1
    fi
    printf '.'; sleep 3; waited=$((waited + 3))
  done
  echo
  ok "MySQL is ready (it took about ${waited} seconds)"
}

project_leftovers() {   # how many containers/networks/volumes of THIS project still exist
  local label="label=com.docker.compose.project=$PROJECT"
  echo $(( $(dk ps -aq --filter "$label" | wc -l) + $(dk network ls -q --filter "$label" | wc -l) + $(dk volume ls -q --filter "$label" | wc -l) ))
}

on_interrupt() {
  echo; echo
  note "The demo was stopped with Ctrl+C. Some containers may still be running."
  note "To remove them, run:  docker compose down --volumes"
  remove_tmp_dir 2>/dev/null
  exit 130
}
trap on_interrupt INT

# ----------------------------------------------------------------------------
# --import-update FILE : used by the Windows launcher (Start-Demo.ps1).
# Copies the newest project files from a .tar package into this folder.
#  - never touches the .git folder (your Git history)
#  - keeps docs/demo-runs.md (your run history) if it already exists
#  - before replacing a file that has changes not saved in Git, makes a backup
#    in ~/compose-demo-backups/<date-time>/
# ----------------------------------------------------------------------------
import_update() {
  local tarfile="$1"
  [ -f "$tarfile" ] || { echo "Update file not found: $tarfile"; exit 1; }
  local stage; stage=$(mktemp -d /tmp/compose-demo-import.XXXXXX) || exit 1
  if ! tar -xf "$tarfile" -C "$stage"; then
    echo "The update file could not be unpacked."; rm -rf -- "$stage"; exit 1
  fi
  local backup_dir; backup_dir="$HOME/compose-demo-backups/$(date +%Y-%m-%d_%H-%M-%S)"
  local copied=0 backed=0 f rel has_git=0
  [ -d .git ] && has_git=1
  while IFS= read -r -d '' f; do
    rel="${f#"$stage"/}"
    case "$rel" in .git|.git/*) continue ;; esac
    [ "$rel" = "demo.sh" ] && continue   # already copied separately by the launcher (it is running now)
    if [ "$rel" = "docs/demo-runs.md" ] && [ -f "$rel" ]; then continue; fi
    if [ -f "$rel" ] && ! cmp -s "$f" "$rel"; then
      local unsaved=1
      if [ $has_git = 1 ] && git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 \
         && git diff --quiet HEAD -- "$rel" 2>/dev/null; then
        unsaved=0   # the current version is safely stored in Git already
      fi
      if [ $unsaved = 1 ]; then
        mkdir -p "$backup_dir/$(dirname "$rel")" && cp -p "$rel" "$backup_dir/$rel" && backed=$((backed + 1))
      fi
    fi
    mkdir -p "$(dirname "$rel")"
    cp "$f" "$rel" && copied=$((copied + 1))
    case "$rel" in *.sh|*.yml|*.yaml|*.md|*.html|.gitignore|.gitattributes) sed -i 's/\r$//' "$rel" ;; esac
  done < <(find "$stage" -type f -print0)
  chmod +x demo.sh 2>/dev/null
  rm -rf -- "$stage"
  rm -f -- "$tarfile"
  echo "Updated $copied project files."
  [ $backed -gt 0 ] && echo "Made a backup of $backed changed files in: $backup_dir"
  exit 0
}
[ -n "$IMPORT_FILE" ] && import_update "$IMPORT_FILE"

# ----------------------------------------------------------------------------
# GitHub helpers
# ----------------------------------------------------------------------------
GH_USER=""; GH_ID=""; GH_NAME=""
TARGET_NAME=""; TARGET_MODE=""; FOREIGN=""; UPLOADED=0; REPO_URL=""; PUSHED_SHA=""

gh_logged_in() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }

gh_has_workflow_scope() { gh auth status 2>&1 | grep -q "'workflow'"; }

gh_read_account() {
  local data
  data=$(gh api user --jq '"\(.id)|\(.login)|\(.name // "")"' 2>/dev/null) || return 1
  GH_ID="${data%%|*}"; data="${data#*|}"
  GH_USER="${data%%|*}"; GH_NAME="${data#*|}"
  [ -z "$GH_NAME" ] && GH_NAME="$GH_USER"
  [ -n "$GH_USER" ]
}

device_code_help() {   # the same 5 steps for login and for adding a permission
  box "$CYAN" "$1" "$2" \
    "1. A one-time code (like ABCD-1234) appears below. Copy it." \
    "2. If it asks 'Authenticate Git with your GitHub credentials?', press Enter (this means Yes)." \
    "3. If it says 'Press Enter to open github.com in your browser', press Enter. (This VM has no browser, so nothing opens here.)" \
    "4. On your laptop, open  https://github.com/login/device  , type the code, and click Authorize." \
    "5. Wait here. When it is finished, the script continues by itself."
}

github_login() {
  echo
  device_code_help "ONE-TIME GITHUB LOGIN" \
    "The script needs to log in to your GitHub account once. After this, it remembers the login, and the demo never asks again."
  run "gh auth login --hostname github.com --git-protocol https --web --scopes workflow" \
      gh auth login --hostname github.com --git-protocol https --web --scopes workflow
  echo
  gh_logged_in
}

github_add_workflow_scope() {
  echo
  device_code_help "ONE-TIME GITHUB PERMISSION" \
    "This project includes automatic tests that run on GitHub (in the .github/workflows folder). GitHub only accepts these files if your login has one extra permission, called 'workflow'. You approve it once, the same way as the first login."
  run "gh auth refresh --hostname github.com --scopes workflow" \
      gh auth refresh --hostname github.com --scopes workflow
  echo
  gh_has_workflow_scope
}

create_files_if_missing() {
  if [ ! -f docker-compose.yml ]; then
    info "docker-compose.yml was missing, so it was created again"
    cat > docker-compose.yml <<'YAML'
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: examplepassword
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - app-network

  adminer:
    image: adminer:latest
    ports:
      - "8081:8080"
    depends_on:
      - db
    networks:
      - app-network

  worker:
    image: busybox:latest
    command: sh -c 'while true; do echo "Worker $$(hostname) is working"; sleep 5; done'
    networks:
      - app-network

networks:
  app-network:

volumes:
  db-data:
YAML
  fi

  if [ ! -f html/index.html ]; then
    info "html/index.html was missing, so it was created again"
    mkdir -p html
    cat > html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Docker Compose Demo</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: "Segoe UI", Ubuntu, Arial, sans-serif;
      background: #0f172a; color: #e2e8f0;
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      padding: 32px;
    }
    .card {
      max-width: 820px; width: 100%;
      background: #1e293b; border: 1px solid #334155; border-radius: 16px;
      padding: 40px;
    }
    .tag {
      display: inline-block; font-size: 13px; letter-spacing: 1px; text-transform: uppercase;
      color: #38bdf8; border: 1px solid #38bdf8; border-radius: 999px; padding: 4px 12px;
    }
    h1 { font-size: 34px; margin: 18px 0 8px; color: #f8fafc; }
    p.lead { font-size: 18px; color: #94a3b8; margin-bottom: 28px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 14px; }
    .box { background: #0f172a; border: 1px solid #334155; border-radius: 12px; padding: 16px; }
    .box b { display: block; font-size: 16px; color: #f8fafc; margin-bottom: 6px; }
    .box span { font-size: 14px; color: #94a3b8; line-height: 1.5; }
    .ok { color: #4ade80; font-weight: 600; margin-top: 28px; font-size: 16px; }
    code { background: #0f172a; padding: 2px 6px; border-radius: 6px; color: #fbbf24; }
    footer { margin-top: 22px; font-size: 13px; color: #64748b; }
  </style>
</head>
<body>
  <div class="card">
    <span class="tag">Live demo</span>
    <h1>Running Multi-Container Applications with Docker Compose</h1>
    <p class="lead">This page is served by the <b>web</b> container (NGINX). It was placed inside
      the container from my own <code>./html</code> folder by the <code>docker-compose.yml</code> file.</p>

    <div class="grid">
      <div class="box"><b>web</b><span>NGINX web server.<br>Door 8080 &rarr; 80</span></div>
      <div class="box"><b>db</b><span>MySQL 8.4 database.<br>Data kept in the <code>db-data</code> volume</span></div>
      <div class="box"><b>adminer</b><span>Web page to look inside the database.<br>Door 8081 &rarr; 8080</span></div>
      <div class="box"><b>worker</b><span>Tiny BusyBox helper.<br>Used to show scaling</span></div>
    </div>

    <p class="ok">&#10004; All services share one private network: <code>app-network</code></p>
    <footer>One file &middot; one command &middot; the whole application.</footer>
  </div>
</body>
</html>
HTML
  fi

  if [ ! -f .gitignore ]; then
    info ".gitignore was missing, so it was created again"
    cat > .gitignore <<'IGNORE'
# .gitignore - files that Git must NEVER save or upload
# Secret settings (real projects keep passwords in a .env file)
.env
.env.*
# Log files
*.log
# Temporary files from editors and operating systems
*.swp
*~
.DS_Store
Thumbs.db
# Update packages used by the Windows launcher
*.tar
IGNORE
  fi

  if [ ! -f README.md ]; then
    printf '# Docker Compose Demo\n\nRun the demo with: ./demo.sh\n' > README.md
  fi

  if [ ! -f docs/demo-runs.md ]; then
    mkdir -p docs
    cat > docs/demo-runs.md <<'RUNS'
# Demo run history

Every time `demo.sh` saves the project with Git (Part 11), it adds one line to this table.
This is a small, real example of how Git tracks a change: `git diff` shows the new line,
and `git commit` saves it in the history.

| Date and time | Result |
|---|---|
RUNS
  fi
}

# ============================================================================
# GETTING READY (checks before the demo starts)
# ============================================================================
make_fingerprint() {   # SHA-256 fingerprint of every project file (not .git)
  find . -type f ! -path './.git/*' -print0 | sort -z | xargs -0 sha256sum > "$TMP_DIR/fingerprint.sha256"
}

ask_github() {   # returns 0 if the user wants to upload to GitHub
  local answer=""
  echo
  printf '%s\n' "  ${B}Upload the project to GitHub at the end?${R}"
  printf '%s\n' "  This needs a free GitHub account and a one-time login with a code."
  printf '%s' "  Type y and press Enter for Yes. Just press Enter for No. (No after ${PUSH_ASK_TIMEOUT} seconds): "
  read -r -t "$PUSH_ASK_TIMEOUT" answer </dev/tty || true
  echo
  case "$answer" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

preflight() {
  banner "Getting ready: checking everything"
  echo
  make_tmp_dir

  if [ "$DO_DOCKER" = 1 ]; then
    if ! command -v docker >/dev/null 2>&1; then
      fail "Docker is not installed on this machine."
      note "Use the compose-lab VM made with cloud-init.yaml (it installs Docker for you)."
      remove_tmp_dir; exit 1
    fi
    if docker info >/dev/null 2>&1; then
      DOCKER=(docker)
    elif sudo -n docker info >/dev/null 2>&1 || sudo docker info >/dev/null 2>&1; then
      DOCKER=(sudo docker)
      note "Docker is used with sudo this time. (Permanent fix: type exit, then open the VM shell again.)"
    else
      fail "Cannot talk to Docker (permission denied, or Docker is stopped)."
      note "Fix: type exit, then: multipass shell compose-lab   (or run: sudo ./demo.sh)"
      remove_tmp_dir; exit 1
    fi
    ok "Docker is running  (version $(dk version --format '{{.Server.Version}}' 2>/dev/null))"

    if ! dc version >/dev/null 2>&1; then
      fail "Docker Compose (the 'docker compose' command) is missing."
      note "Install it with: sudo apt install -y docker-compose-plugin"
      remove_tmp_dir; exit 1
    fi
    ok "Docker Compose is installed  (version $(dc version --short 2>/dev/null))"
  fi

  create_files_if_missing
  make_fingerprint
  ok "Made a safety fingerprint of all $(wc -l < "$TMP_DIR/fingerprint.sha256") project files (checked again in Part 10)"

  if [ "$DO_DOCKER" = 1 ]; then
    if ! dc config --quiet; then
      fail "docker-compose.yml has a mistake (see the message above)."
      remove_tmp_dir; exit 1
    fi
    ok "docker-compose.yml is correct"

    local missing=() img
    for img in nginx:latest mysql:8.4 adminer:latest busybox:latest; do
      dk image inspect "$img" >/dev/null 2>&1 || missing+=("$img")
    done
    if [ ${#missing[@]} -eq 0 ]; then
      ok "All 4 images are already downloaded (the demo works even without internet)"
    else
      info "Downloading missing images: ${missing[*]}"
      if ! dc pull; then
        fail "Could not download the images. Check the internet connection and try again."
        remove_tmp_dir; exit 1
      fi
      ok "Images downloaded"
    fi

    if [ "$(project_leftovers)" -gt 0 ]; then
      dc down --volumes --remove-orphans >/dev/null 2>&1
      ok "Removed old containers and data of this project from an earlier run (fresh start)"
    else
      ok "Fresh start: no old containers or data"
    fi
    IP=$(server_ip)
    ok "Address of this machine for the browser: ${B}${IP}${R}"
  fi

  if [ "$DO_GIT" = 1 ]; then
    if command -v git >/dev/null 2>&1; then
      ok "Git is installed  ($(git --version | awk '{print $3}'))"
    else
      fail "Git is not installed, so Parts 11 and 12 will be skipped."
      note "Install it with: sudo apt install -y git"
      DO_GIT=0; DO_PUSH=0
    fi
  fi

  if [ "$DO_PUSH" = 1 ]; then
    if ! command -v gh >/dev/null 2>&1; then
      fail "The GitHub CLI (gh) is not installed, so the upload to GitHub will be skipped."
      note "Install it with: sudo apt install -y gh"
      DO_PUSH=0
    elif ! gh_logged_in; then
      if [ "$HAVE_TTY" = 1 ] && [ "$MODE" != "fast" ]; then
        if [ "$FORCE_PUSH" = 1 ] || [ "$SETUP_ONLY" = 1 ] || ask_github; then
          if ! github_login; then
            fail "GitHub login did not finish. The project will be saved with Git, but not uploaded."
            note "To try the login again later, run:  ./demo.sh --setup"
            DO_PUSH=0
          fi
        else
          info "OK, no upload this time. (To upload later: ./demo.sh --setup, then ./demo.sh)"
          DO_PUSH=0
        fi
      else
        info "GitHub is not logged in, so the upload is skipped. (Log in with: ./demo.sh --setup)"
        DO_PUSH=0
      fi
    fi
    if [ "$DO_PUSH" = 1 ]; then
      if gh_read_account; then
        ok "GitHub account: ${B}${GH_USER}${R}"
      else
        fail "Could not read your GitHub account (no internet?). The upload will be skipped."
        DO_PUSH=0
      fi
    fi
    if [ "$DO_PUSH" = 1 ] && [ -d .github/workflows ] && ! gh_has_workflow_scope; then
      if [ "$HAVE_TTY" = 1 ] && [ "$MODE" != "fast" ] && github_add_workflow_scope; then
        ok "GitHub permission 'workflow' added"
      else
        note "Without the 'workflow' permission, the automatic test files (.github/workflows) are not uploaded this time."
        note "To add the permission later, run:  ./demo.sh --setup"
        WORKFLOW_EXCLUDED=1
      fi
    fi
  fi
}
WORKFLOW_EXCLUDED=0

start_screen() {
  echo
  line
  printf '%s\n' "  ${B}Everything is ready.${R}"
  echo
  printf '%s\n' "  What will happen:"
  [ "$DO_DOCKER" = 1 ] && printf '%s\n' "    Parts 1-9   Docker Compose: start a website + database app, test it, stop it"
  printf '%s\n'                        "    Part 10     Clean up: remove temporary things, check that every project file is safe"
  [ "$DO_GIT" = 1 ]    && printf '%s\n' "    Part 11     Git: save the project and its history"
  if [ "$DO_PUSH" = 1 ]; then
    printf '%s\n' "    Part 12     GitHub: upload the project to the GitHub account '${GH_USER}' and verify it"
  elif [ "$DO_GIT" = 1 ]; then
    printf '%s\n' "    Part 12     GitHub: skipped this time (see the notes above)"
  fi
  printf '%s\n'                        "    At the end  A final confirmation screen with the result of every check"
  echo
  if [ "$DO_DOCKER" = 1 ]; then
    printf '%s\n' "  Browser pages (they work during Parts 5 to 8):"
    printf '%s\n' "    Website:  http://${IP}:8080"
    printf '%s\n' "    Adminer:  http://${IP}:8081"
    echo
  fi
  case "$MODE" in
    auto)   printf '%s\n' "  The demo runs by itself. While it runs: Enter = skip a pause, p = pause, Ctrl+C = stop." ;;
    manual) printf '%s\n' "  Manual mode: press Enter before every step." ;;
    fast)   printf '%s\n' "  Fast mode: no pauses." ;;
  esac
  line
  if [ "$MODE" != "fast" ] && [ "$HAVE_TTY" = 1 ]; then
    echo
    printf '%s' "  ${B}${GREEN}Press Enter to start the demo >${R} "
    read -r _ </dev/tty
  fi
}

part1() {
  part 1 "Opening" "1 min"
  explain "Hello everyone. My topic today is: Running Multi-Container Applications with Docker Compose." \
          "Docker Compose lets us start a complete application, with a website and a database, using one file and one command." \
          "Everything you see on this screen is real. Every command runs live, right now, and I explain each one before it runs." \
          "At the end, the script cleans up, checks that every file is safe, saves the project with Git, and uploads it to GitHub."
}

# ============================================================================
# PART 2 - The problem
# ============================================================================
part2() {
  part 2 "The problem" "1.5 min"
  explain "First, what is a container? A container is like a small box. Inside the box is one program, plus everything that program needs to run. Docker is the tool that runs these boxes." \
          "One box is easy to run. But a real application needs many boxes that work together: one box for the website, one box for the database, and maybe more."
  explain "Without Docker Compose, I must start every box by hand, with a long command. I must also connect the boxes and create their storage myself. If I make one small mistake, the application does not work. And if a friend wants to run my application, I must send him all these commands."
  echo
  printf '%s\n' "  ${B}Without Docker Compose, our 4 boxes need all of this:${R}"
  cat <<EOF
${DIM}    docker network create app-network
    docker volume create db-data
    docker run -d --name db --network app-network -e MYSQL_ROOT_PASSWORD=examplepassword \\
               -v db-data:/var/lib/mysql mysql:8.4
    docker run -d --name web --network app-network -p 8080:80 \\
               -v ./html:/usr/share/nginx/html:ro nginx:latest
    docker run -d --name adminer --network app-network -p 8081:8080 adminer:latest
    docker run -d --name worker --network app-network busybox:latest sh -c '...'${R}
EOF
  echo
  printf '%s\n' "  ${B}With Docker Compose, it is one command:${R}   ${GREEN}docker compose up -d${R}"
  echo
  explain "Think of a music band. Each musician is a container. Without a leader, everyone starts at a different time, and it sounds bad." \
          "Docker Compose is the band leader with one sheet of music. The sheet says who plays, who sits together, and when to start. In Docker Compose, this sheet of music is a simple text file called docker-compose.yml."
}

# ============================================================================
# PART 3 - Three building blocks
# ============================================================================
part3() {
  part 3 "Three building blocks" "1.5 min"
  box "$CYAN" "EXPLANATION" "Inside the docker-compose.yml file, we describe only three things: services, networks and volumes."
  echo
  printf '%s\n' "  ${B}BLOCK       SIMPLE MEANING                                  IN OUR DEMO${R}"
  printf '  %-11s %-47s %s\n' "Services" "The containers. Each one does one job"          "web, db, adminer, worker"
  printf '  %-11s %-47s %s\n' "Networks" "A private road between the containers, so"     "app-network"
  printf '  %-11s %-47s %s\n' ""         "they find each other by name (like 'db')"      ""
  printf '  %-11s %-47s %s\n' "Volumes"  "A safe storage locker outside the container."  "db-data"
  printf '  %-11s %-47s %s\n' ""         "Delete the container, and the data stays"      ""
  echo
  cat <<EOF
${DIM}      Browser :8080       Browser :8081${R}
${DIM}           |                   |${R}
     +-----v-----+       +-----v-----+     +-----------+     +-----------+
     |    ${B}web${R}    |       |  ${B}adminer${R}  |     |  ${B}worker${R}   |     |    ${B}db${R}     |
     |  (nginx)  |       |           |     | (busybox) |     | (mysql)   |
     +-----+-----+       +-----+-----+     +-----+-----+     +-----+-----+
           |                   |                 |                 |
  ${CYAN}=========+===================+=================+=================+=====${R}
                ${CYAN}app-network  (the private road)${R}                    |
                                                             +-----v-----+
                                                             |  ${YELLOW}db-data${R}  |
                                                             | (locker)  |
                                                             +-----------+
EOF
  echo
  pause 8
  explain "So: the services are the workers, the network is the road between them, and the volume is the locker where the important data is kept safe."
}

# ============================================================================
# PART 4 - The YAML file
# ============================================================================
show_lines() {   # highlight the lines of docker-compose.yml that match a pattern
  grep -n -E "$1" docker-compose.yml | sed "s/^/      ${YELLOW}line /; s/:/${R}  /"
}

yaml_point() {   # yaml_point <pattern> <title> <explanation>
  echo
  show_lines "$1" | head -2
  printf '%s\n' "  ${GREEN}${B}*${R} ${B}$2${R}"
  printf '%s\n' "$3" | fold -s -w $((WRAP-4)) | sed 's/^/      /'
  pause "$(reading_time "$3")"
}

part4() {
  part 4 "The YAML file" "2 min"
  step "The 'cat' command shows what is inside a file. Let us open docker-compose.yml. This one file describes the whole application." \
       "cat docker-compose.yml" cat docker-compose.yml
  pause 5
  explain "This file is written in YAML. YAML is a simple text format. The spaces at the start of each line are important: a line that is pushed to the right belongs to the line above it, like items and sub-items in a shopping list."

  printf '%s\n' "  ${B}Now, the file part by part:${R}"
  yaml_point '^services:'                 "services:"               "This is the list of all my containers."
  yaml_point 'image: nginx'               "web  ->  image: nginx:latest" "The web service uses NGINX, a ready-made web server. Docker downloads it automatically."
  yaml_point '"8080:80"'                  "ports: \"8080:80\""      "Think of ports as door numbers. When someone knocks on door 8080 of my computer, Docker sends them to door 80 inside the web container."
  yaml_point '\./html:'                   "volumes: ./html:...:ro"  "This puts my own web page inside the container, instead of the default NGINX page. ':ro' means read-only: the container can read the page, but cannot change it."
  yaml_point '^    depends_on:'           "depends_on: db"          "Start the database first, then the website."
  yaml_point 'mysql:8.4|MYSQL_ROOT'       "db  ->  image: mysql:8.4 and MYSQL_ROOT_PASSWORD" "The db service is the MySQL database. Its password is given as a setting, called an environment variable."
  yaml_point 'db-data:/var/lib/mysql'     "db-data:/var/lib/mysql"  "The database keeps its files in the db-data locker (the volume), not inside the container. So the data is safe even if the container is deleted."
  yaml_point '^  adminer:|^  worker:'     "adminer: and worker:"    "Two small extras. Adminer is a web page to look inside the database. The worker is a tiny helper that I use to show scaling."
  yaml_point '^networks:|^volumes:'       "networks: and volumes: (at the bottom)" "Here the road (app-network) and the locker (db-data) are created, so the services can use them."

  echo
  explain "Three small updates compared to the reference material:" \
          "One: the command is now 'docker compose', with a space. The old 'docker-compose', with a dash, is version 1. It is not supported since 2023. All the commands work the same way." \
          "Two: the line \"version: '3.8'\" is not needed any more. Docker ignores it." \
          "Three: MySQL 5.7 reached its end of life in 2023, so I use MySQL 8.4, the current long-term version."
  step "'docker compose version' shows which version of Docker Compose is installed." \
       "docker compose version" dc version
  pause 3
}

# ============================================================================
# PART 5 - Start the whole app
# ============================================================================
part5() {
  part 5 "Start the whole app" "2 min"
  explain "Now the live part. Four containers, one command."
  if ! step "'docker compose up' reads the file and starts everything: it creates the network, creates the volume, and starts all four containers. '-d' means detached: the containers run in the background, so I can keep using this terminal." \
       "docker compose up -d" dc up -d; then
    fail_check "Start the application with docker compose up"
    note "If it says a port is already in use, another program is using port 8080 or 8081."
    final_screen; exit 1
  fi
  notice "Read the lines above from top to bottom: first the network and the volume were Created. Then each container was Started. The database started before the website, because of depends_on."

  step "'docker compose ps' lists the containers of this project and shows if they are running." \
       "docker compose ps" dc ps
  notice "All four services are in the list, and STATUS says 'Up'. That means they are running. In the PORTS column, door 8080 goes to the website and door 8081 goes to Adminer."
  verify "All 4 containers started and are running" test "$(dc ps --status running -q | wc -l)" -eq 4

  # make sure the web server answers before showing it
  local _i
  for _i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null --max-time 2 http://localhost:8080 && break; sleep 1; done
  step "'curl' opens a web page from the terminal, like a browser without pictures. It saves the page as page.html in the script's temporary folder (Part 10 deletes this folder again). Then 'grep' finds the page title inside the file." \
       "curl -s http://localhost:8080 -o $TMP_DIR/page.html && grep -o '<title>.*</title>' $TMP_DIR/page.html" \
       sh -c "curl -s --max-time 5 http://localhost:8080 -o '$TMP_DIR/page.html' && grep -o '<title>.*</title>' '$TMP_DIR/page.html'"
  verify "The website answered on port 8080" grep -q "<title>Docker Compose Demo</title>" "$TMP_DIR/page.html"
  echo
  link "The website in the browser:  http://${IP}:8080"
  notice "This page comes from the NGINX container. It is my own page, which the compose file put inside the container."
}

# ============================================================================
# PART 6 - Containers talking to each other
# ============================================================================
part6() {
  part 6 "Containers talking to each other" "2 min"
  explain "Can the containers find each other? Let us test it."
  if step "'docker compose exec' runs a command inside a container that is already running. I ask the worker container to 'ping' the database. Ping sends small test messages and waits for replies. I use only the name 'db', not an IP address." \
       "docker compose exec worker ping -c 3 db" dc exec "${EXEC_T[@]}" worker ping -c 3 db; then
    pass_check "The worker container reached the database by its name (ping db)"
  else
    fail_check "The worker container reached the database by its name (ping db)"
  fi
  notice "The database replied 3 times, and '0% packet loss' means no message was lost. So the private network works. Docker has a small built-in phone book (DNS) that turns the name 'db' into the right address."

  if step "The NGINX image is kept very small and has no ping tool, so for the web container I use 'getent hosts'. It asks the phone book: what is the address of 'db'?" \
       "docker compose exec web getent hosts db" dc exec "${EXEC_T[@]}" web getent hosts db; then
    pass_check "The web container found the database by its name (getent hosts db)"
  else
    fail_check "The web container found the database by its name (getent hosts db)"
  fi
  notice "The web container also found the database by its name. Every service can reach the others by name."

  if step "MySQL needs some time to start the first time, because it sets up its files. The script now waits until the database is ready." \
       "(waiting for MySQL)" wait_for_mysql; then
    pass_check "MySQL started and is ready"
  else
    fail_check "MySQL started and is ready"
  fi

  # Adminer proof: connect from the adminer container to the database
  local php_out
  php_out=$(dc exec -T adminer php -r '$m = @new mysqli("db", "root", "examplepassword"); if ($m->connect_errno) { exit(1); } echo "Connected to MySQL ", $m->server_info, "\n";' 2>/dev/null)
  if printf '%s' "$php_out" | grep -q '^Connected to MySQL'; then
    step "Adminer runs in its own container. I ask the Adminer container to connect to the database, again using only the name 'db'." \
         "docker compose exec adminer php -r '... new mysqli(\"db\", \"root\", \"examplepassword\") ...'" \
         printf '%s\n' "$php_out"
    pass_check "The Adminer container connected to the database"
    notice "Two separate containers, Adminer and MySQL, are talking to each other over the network."
  fi

  echo
  link "Adminer in the browser:  http://${IP}:8081"
  printf '      %-12s %s\n' "System"   "MySQL" "Server" "db" "Username" "root" "Password" "examplepassword" "Database" "(leave empty)"
  echo
  explain "In the browser, Adminer shows the database as a web page. To log in, the server name is just 'db'. Adminer reaches the database over the private network."
}

# ============================================================================
# PART 7 - Data survives a restart
# ============================================================================
students_count() { dc exec -T db mysql -uroot -pexamplepassword -N -e "SELECT COUNT(*) FROM college.students;" 2>/dev/null | tr -d '[:space:]'; }

part7() {
  part 7 "Data survives a restart" "2 min"
  explain "Now I will prove that the volume keeps the data safe. First, I save some data in the database."
  wait_for_mysql >/dev/null || { fail_check "MySQL is ready for Part 7"; final_screen; exit 1; }

  step "This command runs the MySQL program inside the db container. It creates a database called 'college', creates a table called 'students', and adds two names." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"CREATE DATABASE college; CREATE TABLE college.students (name VARCHAR(50)); INSERT INTO college.students VALUES ('Shad'), ('Classmate');\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "CREATE DATABASE college; CREATE TABLE college.students (name VARCHAR(50)); INSERT INTO college.students VALUES ('Shad'), ('Classmate');"
  note "MySQL warns about using a password on the command line. That is normal for a demo."

  step "SELECT reads the data back from the table." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"SELECT * FROM college.students;\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "SELECT * FROM college.students;"
  verify "Saved 2 students in the database" test "$(students_count)" = "2"
  notice "The two students are saved in the database."

  step "Now I delete ALL the containers. 'docker compose down' stops and removes every container and the network." \
       "docker compose down" dc down
  step "Let us check: is anything still running?" \
       "docker compose ps" dc ps
  notice "The list is empty. Nothing is running. All the containers are gone."

  step "But 'down' does not delete volumes. 'docker volume ls' lists the volumes (the lockers)." \
       "docker volume ls" dk volume ls
  notice "The ${PROJECT}_db-data volume is still there. The locker was not deleted."

  if ! step "Now I bring everything back with the same command as before. These are brand-new containers." \
       "docker compose up -d" dc up -d; then
    fail_check "Start the application again"; final_screen; exit 1
  fi
  wait_for_mysql || { fail_check "MySQL came back after the restart"; final_screen; exit 1; }

  step "The moment of truth: I read the students table again, in the brand-new database container." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"SELECT * FROM college.students;\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "SELECT * FROM college.students;"
  verify "The data survived: both students are still there after down and up" test "$(students_count)" = "2"
  notice "The containers are new, but the data is still here. It was kept safe in the db-data volume, outside the containers."
}

# ============================================================================
# PART 8 - Scaling and logs
# ============================================================================
part8() {
  part 8 "Scaling and logs" "1.5 min"
  explain "Right now there is one worker. What if there is more work to do? I can run more copies of it."
  step "'--scale worker=3' tells Docker Compose: run 3 copies of the worker service." \
       "docker compose up -d --scale worker=3" dc up -d --scale worker=3
  step "Let us look at the list again." \
       "docker compose ps" dc ps
  verify "Scaled the worker service to 3 running copies" test "$(dc ps --status running -q worker | wc -l)" -eq 3
  notice "Now there are three workers: worker-1, worker-2 and worker-3. This is how an application handles more work: run more copies."

  info "Waiting a few seconds, so the workers can print some messages"
  sleep 7
  step "'docker compose logs' shows the messages that containers print. '--tail 6' shows only the last 6 messages of each worker." \
       "docker compose logs worker --tail 6" dc logs worker --tail 6
  notice "Each worker prints a different name (its container ID). These are three separate containers doing the same job."
  explain "The reference material scales the web service instead (--scale web=3). That works only if the web service has no fixed port, because only one container can use door 8080 at a time. In real projects, a 'load balancer' stands in front of the web copies and shares the visitors between them."
}

# ============================================================================
# PART 9 - Stop and remove the app
# ============================================================================
part9() {
  part 9 "Stop and remove the app" "1 min"
  if [ "$KEEP" = 1 ]; then
    note "--keep was used, so the containers keep running."
    note "To remove them later, run:  docker compose down --volumes"
    pause 3
    return 0
  fi
  explain "The demo of the application is finished. Now I remove it with one command."
  step "'docker compose down --volumes' removes the containers, the network, and this time also the volume with the data." \
       "docker compose down --volumes" dc down --volumes
  step "Let us check the volumes again." \
       "docker volume ls" dk volume ls
  notice "The ${PROJECT}_db-data volume is gone from the list. This is very useful for testing: you can start fresh in seconds."
}

# ============================================================================
# PART 10 - Clean up and safety check (before anything is uploaded)
# ============================================================================
part10() {
  part 10 "Clean up and safety check" "2 min"
  explain "Before I upload anything, I clean up. I remove everything this demo created that is not needed any more. Then I check that no project file was lost or damaged." \
          "The safety rule: the script only removes things that THIS demo created. It never touches your other files, your other Docker projects, or your Git history."

  # --- A. Docker resources of this project -------------------------------------
  if [ "$DO_DOCKER" = 1 ] && [ "$KEEP" = 0 ]; then
    step "'docker compose down --volumes --remove-orphans' removes this project's containers, network and volume. '--remove-orphans' also removes old containers of this project that are no longer in the file. If everything is already gone, it simply does nothing." \
         "docker compose down --volumes --remove-orphans" dc down --volumes --remove-orphans
    local label="label=com.docker.compose.project=$PROJECT"
    step "Docker puts a label on everything that Compose creates: com.docker.compose.project=$PROJECT. With '--filter', I list ONLY the things with this project's label: containers, networks and volumes. All three lists should be empty." \
         "docker ps -a --filter $label ; docker network ls --filter $label ; docker volume ls --filter $label" \
         sh -c "$(printf '%q ' "${DOCKER[@]}") ps -a --filter '$label'; echo; $(printf '%q ' "${DOCKER[@]}") network ls --filter '$label'; echo; $(printf '%q ' "${DOCKER[@]}") volume ls --filter '$label'"
    verify "Clean up: no containers, networks or volumes of this project are left" test "$(project_leftovers)" -eq 0
    notice "The three lists only show their headings. Nothing of this project is left."

    step "Some things are kept on purpose. The 4 images are not temporary: the next run uses them again, so the demo works even without internet. 'docker image ls' lists them." \
         "docker image ls --filter reference=nginx:latest --filter reference=mysql:8.4 --filter reference=adminer:latest --filter reference=busybox:latest" \
         dk image ls --filter reference=nginx:latest --filter reference=mysql:8.4 --filter reference=adminer:latest --filter reference=busybox:latest
    local others; others=$(dk ps -aq | wc -l)
    info "Other containers on this computer: $others (not touched by this script)"
    notice "The images stay. To remove them too, you could run 'docker image rm nginx:latest mysql:8.4 adminer:latest busybox:latest', but then the next run must download them again."
  elif [ "$KEEP" = 1 ]; then
    note "--keep was used, so the containers keep running and the Docker clean up is skipped."
  fi

  # --- B. Safety check of the project files --------------------------------------
  local nfiles; nfiles=$(wc -l < "$TMP_DIR/fingerprint.sha256")
  if step "Safety check. At the start, the script made a 'fingerprint' of every project file with 'sha256sum'. A fingerprint is a long number calculated from the content of a file. If even one letter changes, the fingerprint changes. Now I check all files again: are they all still there and unchanged? '--quiet' means: print only problems." \
       "sha256sum --check --quiet $TMP_DIR/fingerprint.sha256" sha256sum --check --quiet "$TMP_DIR/fingerprint.sha256"; then
    pass_check "Safety check: all $nfiles project files are present and unchanged (SHA-256)"
    notice "No problems were printed. All $nfiles project files are safe."
  else
    fail_check "Safety check: all $nfiles project files are present and unchanged (SHA-256)"
  fi

  # --- C. Temporary files -----------------------------------------------------------
  local tmp_what="the fingerprint list"
  [ -f "$TMP_DIR/page.html" ] && tmp_what="the saved web page (page.html) and the fingerprint list"
  step "While it ran, the script kept its temporary files in ONE private folder in /tmp: $tmp_what. 'ls -la' shows what is inside." \
       "ls -la $TMP_DIR" ls -la "$TMP_DIR"
  local tmp_path="$TMP_DIR"
  step "'rm -rf' deletes a folder and everything inside it. Before deleting, the script checks that the path really is its own temporary folder (/tmp/compose-demo-run.XXXXXX) and that it belongs to this user. It never deletes anything else." \
       "rm -rf $tmp_path" remove_tmp_dir
  verify "Clean up: the temporary folder was deleted" test ! -e "$tmp_path"
  TMP_DIR=""

  local stale
  stale=$(find /tmp -maxdepth 1 -user "$(id -u)" \( -name 'compose-demo-update*.tar' -o -name 'compose-demo-import.??????' \) 2>/dev/null)
  if [ -n "$stale" ]; then
    printf '%s\n' "$stale" | while IFS= read -r p; do rm -rf -- "$p"; done
    info "Also removed old update files of the Windows launcher from /tmp"
  fi

  notice "Clean: nothing temporary is left. Safe: every project file is still there and unchanged. Kept on purpose: the images, the VM, and the Git history. Now the project is ready to be saved and uploaded."
}

# ============================================================================
# PART 11 - Save the project with Git
# ============================================================================
free_repo_name() {   # first unused name on GitHub: compose-demo-2, compose-demo-3, ...
  local n candidate
  for n in 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    candidate="${REPO_NAME}-${n}"
    gh repo view "$GH_USER/$candidate" >/dev/null 2>&1 || { echo "$candidate"; return 0; }
  done
  return 1
}

same_history() {   # same_history owner/name : is GitHub's main branch part of my history (or empty)?
  local check=compose-demo-check rc=1
  git remote remove "$check" >/dev/null 2>&1
  git remote add "$check" "https://github.com/$1.git"
  if git fetch -q "$check" 2>/dev/null; then
    if ! git rev-parse -q --verify "refs/remotes/$check/main" >/dev/null; then
      rc=0                       # the project on GitHub is empty
    elif git rev-parse -q --verify HEAD >/dev/null && git merge-base --is-ancestor "refs/remotes/$check/main" HEAD; then
      rc=0                       # GitHub has an older version of this same project
    fi
  fi
  git remote remove "$check" >/dev/null 2>&1
  return $rc
}

resolve_target() {   # decide where to upload: TARGET_MODE = push | connect | create
  TARGET_NAME="$REPO_NAME"; TARGET_MODE="create"; FOREIGN=""
  local url p owner name
  url=$(git remote get-url origin 2>/dev/null)
  if [ -n "$url" ]; then
    p="${url%.git}"; name="${p##*/}"; p="${p%/*}"; owner="${p##*[/:]}"
    if [ "$owner" = "$GH_USER" ]; then
      TARGET_NAME="$name"; TARGET_MODE="push"; return 0     # my existing repository
    fi
    FOREIGN="$owner/$name"                                  # downloaded from someone else
  fi
  if gh repo view "$GH_USER/$TARGET_NAME" >/dev/null 2>&1; then
    if same_history "$GH_USER/$TARGET_NAME"; then TARGET_MODE="connect"; return 0; fi
    TARGET_NAME=$(free_repo_name) || return 1
  fi
  TARGET_MODE="create"
}

part11() {
  part 11 "Save the project with Git" "3 min"
  explain "The application works, and everything is clean. Now I save my work properly and share it. For this I use two tools." \
          "Git is a 'version control' tool. Every time I 'commit', Git saves a snapshot of all my files, like a save point in a game. Later I can see what changed, when, and by whom, and I can go back to any older version." \
          "GitHub is a website that keeps Git projects online. gh, the GitHub CLI, is GitHub's own command-line tool. It logs in to GitHub, creates the online project, and uploads it, all from this terminal."

  step "'git --version' shows that Git is installed." "git --version" git --version

  # --- who am I (name + email in every commit) -------------------------------
  local name email
  name=$(git config --global user.name 2>/dev/null); email=$(git config --global user.email 2>/dev/null)
  if [ -n "$name" ] && [ -n "$email" ]; then
    step "Git writes a name and an email into every commit, so everyone can see who made each change. They are already set on this computer. 'git config' shows them." \
         "git config --global user.name ; git config --global user.email" \
         sh -c 'git config --global user.name; git config --global user.email'
  else
    if [ -n "$GH_USER" ]; then
      name="$GH_NAME"; email="${GH_ID}+${GH_USER}@users.noreply.github.com"
      explain "Git writes a name and an email into every commit. The script takes them from my GitHub account. It uses GitHub's private 'noreply' email address, so my real email is never shown in public."
    else
      name="${GIT_NAME:-Docker Compose Demo}"; email="${GIT_EMAIL:-demo@example.com}"
      explain "Git writes a name and an email into every commit. GitHub is not connected, so the script uses a simple demo name for now."
    fi
    step "'git config --global user.name' sets the name for all my projects on this computer." \
         "git config --global user.name \"$name\"" git config --global user.name "$name"
    step "'git config --global user.email' sets the email." \
         "git config --global user.email \"$email\"" git config --global user.email "$email"
  fi

  # --- start tracking ----------------------------------------------------------
  if [ -d .git ]; then
    step "This folder is already a Git repository from an earlier run. 'git log --oneline' shows the save points that already exist." \
         "git log --oneline" git --no-pager log --oneline -5
  else
    step "Step 1: 'git init' turns this folder into a Git repository. It creates a hidden folder called .git, where Git keeps the whole history. '-b main' names the main line of work 'main'." \
         "git init -b main" git init -b main || { fail_check "Create the Git repository"; return 1; }
  fi

  # --- where will it be uploaded? Put the real address into the documentation --
  if [ "$DO_PUSH" = 1 ]; then
    if ! resolve_target; then
      fail "Could not decide where to upload on GitHub. The upload will be skipped."
      DO_PUSH=0
    fi
  fi
  if [ "$DO_PUSH" = 1 ]; then
    local files_with_placeholder
    files_with_placeholder=$(grep -rl --include='*.md' "$PLACEHOLDER" README.md docs 2>/dev/null | tr '\n' ' ')
    if [ -n "$files_with_placeholder" ]; then
      # shellcheck disable=SC2086
      step "The documentation contains example links like '$PLACEHOLDER'. 'sed' replaces them with my real GitHub address, '$GH_USER/$TARGET_NAME', so every link and the test badge work." \
           "sed -i \"s#$PLACEHOLDER#$GH_USER/$TARGET_NAME#g\" $files_with_placeholder" \
           sed -i "s#$PLACEHOLDER#$GH_USER/$TARGET_NAME#g" $files_with_placeholder
    fi
  fi
  if [ "$WORKFLOW_EXCLUDED" = 1 ]; then
    grep -qx '.github/workflows/' .git/info/exclude 2>/dev/null || echo ".github/workflows/" >> .git/info/exclude
    info "The .github/workflows folder is left out of Git this time (the 'workflow' permission is missing)."
  elif grep -qx '.github/workflows/' .git/info/exclude 2>/dev/null; then
    sed -i '\#^\.github/workflows/$#d' .git/info/exclude   # the permission is there now: include the tests again
  fi

  step "Step 2: the .gitignore file is a list of files that Git must NOT save, for example log files, or the .env file where real projects keep passwords. 'cat' shows the list." \
       "cat .gitignore" cat .gitignore

  step "Step 3: 'git status' shows what Git sees in the folder right now." \
       "git status --short" git status --short
  notice "'??' means a new file that Git does not track yet. 'M' means a file that was changed since the last save point."

  step "Step 4: 'git add .' puts the files into the 'staging area'. Think of it as a box: everything in the box goes into the next save point. The dot means: everything in this folder (except the files in .gitignore)." \
       "git add ." git add .
  step "'git status --short' again. 'A' means Added to the box, 'M' means a Modified file in the box." \
       "git status --short" git status --short

  if git rev-parse --verify HEAD >/dev/null 2>&1 && git diff --cached --quiet; then
    info "Nothing new to save. Everything is already in a save point."
  else
    local msg="Add Docker Compose multi-container demo with documentation"
    git rev-parse --verify HEAD >/dev/null 2>&1 && msg="Update project files and documentation"
    step "Step 5: 'git commit' creates the save point. '-m' adds a short message that says what was done." \
         "git commit -m \"$msg\"" git commit -m "$msg" || { fail_check "Save the project with git commit"; return 1; }
    notice "Git saved the files. The first line shows a short ID for this save point. Below it, Git shows how many files were saved."
  fi

  step "'git log --oneline' shows the history: one line for each save point, newest first." \
       "git log --oneline" git --no-pager log --oneline -5

  # --- make a change and track it ---------------------------------------------
  explain "Step 6: Git notices every change I make. Let me add one line to the run history file, docs/demo-runs.md, and then ask Git what changed."
  local stamp total
  stamp=$(date '+%d %b %Y, %H:%M:%S')
  total=$(( ${#RESULTS_OK[@]} + ${#RESULTS_FAIL[@]} ))
  local entry="| $stamp | ${#RESULTS_OK[@]} of $total checks passed |"
  step "'echo ... >> file' adds one new line at the end of a file. This line records today's run and its result." \
       "echo \"$entry\" >> docs/demo-runs.md" \
       sh -c 'printf "%s\n" "$1" >> docs/demo-runs.md' _ "$entry"
  step "'git diff' shows exactly what changed inside the files since the last save point." \
       "git diff" git --no-pager diff
  notice "The line that starts with a plus (+) is the new line. (A line that starts with a minus (-) would be a removed line.)"
  step "'git commit -am' adds all changed files and saves them in one step. '-a' means all changed files, '-m' is the message." \
       "git commit -am \"Record demo run on $stamp\"" git commit -q -am "Record demo run on $stamp"
  step "The history now has one more save point at the top." \
       "git log --oneline" git --no-pager log --oneline -5

  verify "Saved with Git: every change is in a commit (nothing left unsaved)" test -z "$(git status --porcelain)"
  pass_check "Git history: $(git rev-list --count HEAD) save points, newest $(git rev-parse --short HEAD)"
}

# ============================================================================
# PART 12 - Upload the project to GitHub (and verify the upload)
# ============================================================================
create_repo() {   # create_repo <name>
  local name="$1"
  local desc="Beginner-friendly, fully automatic Docker Compose demo: web + MySQL + Adminer + worker, explained step by step"
  git remote remove origin >/dev/null 2>&1
  step "'gh repo create' does three jobs in one command: it creates a new public project called '$name' on GitHub, connects this folder to it (the connection is called 'origin'), and uploads all my save points ('--push')." \
       "gh repo create $name --public --source=. --remote=origin --push --description \"...\"" \
       gh repo create "$name" --public --source=. --remote=origin --push --description "$desc"
}

part12() {
  part 12 "Upload the project to GitHub" "3 min"
  if [ "$DO_PUSH" = 0 ]; then
    explain "In this part, the project is uploaded to GitHub. This time it is skipped (see the notes at the start), so the project is saved only on this computer." \
            "To upload it, run './demo.sh --setup' once to log in to GitHub, and then './demo.sh --git-only'."
    return 0
  fi

  explain "Now I upload the project to GitHub. Uploading is called 'push': my computer pushes the save points to GitHub. The opposite is 'pull': downloading from GitHub to my computer."
  step "'gh --version' shows that the GitHub CLI is installed." "gh --version" sh -c 'gh --version | head -1'
  step "'gh auth status' shows which GitHub account this computer is logged in to. The secret token is hidden with stars." \
       "gh auth status" gh auth status
  step "'gh auth setup-git' tells Git to use this GitHub login when it uploads. So Git never asks for a password." \
       "gh auth setup-git" gh auth setup-git

  if [ -n "$FOREIGN" ]; then
    explain "This folder was downloaded from another person's GitHub project ($FOREIGN). Nobody can upload to someone else's project, so the script keeps that link under the name 'upstream' and creates my own copy."
    if git remote get-url upstream >/dev/null 2>&1; then
      run "git remote remove origin" git remote remove origin
    else
      step "'git remote rename origin upstream' keeps the link to the original project, under a new name." \
           "git remote rename origin upstream" git remote rename origin upstream
    fi
  fi

  local name="$TARGET_NAME" pushed=0
  case "$TARGET_MODE" in
    push)
      if step "This folder is already connected to my GitHub project '$name' (the connection is called 'origin'). 'git push' uploads only the new save points." \
              "git push -u origin main" git push -u origin main; then
        pushed=1
      else
        note "GitHub did not accept the push into '$name' (GitHub has changes that this computer does not have)."
        note "To be safe, nothing on GitHub is overwritten. The script uploads to a new project name instead."
        name=$(free_repo_name) || { fail_check "Upload to GitHub"; return 1; }
      fi ;;
    connect)
      step "A project called '$name' already exists on my GitHub, and it has an older version of this same history. 'git remote add' connects this folder to it." \
           "git remote add origin https://github.com/$GH_USER/$name.git" \
           git remote add origin "https://github.com/$GH_USER/$name.git"
      if step "'git push' uploads the new save points. '-u' remembers the connection for next time." \
              "git push -u origin main" git push -u origin main; then
        pushed=1
      else
        note "GitHub did not accept the push. The script uploads to a new project name instead. Nothing on GitHub is overwritten."
        git remote remove origin >/dev/null 2>&1
        name=$(free_repo_name) || { fail_check "Upload to GitHub"; return 1; }
      fi ;;
  esac
  if [ "$TARGET_MODE" = "create" ] && [ "$name" != "$REPO_NAME" ] && [ -z "$FOREIGN" ]; then
    note "A different project called '$REPO_NAME' already exists on GitHub, so this one is called '$name'. Nothing on GitHub is deleted."
  fi
  if [ "$pushed" = 0 ]; then
    if ! create_repo "$name"; then
      fail_check "Upload to GitHub"
      note "Check the internet connection, then run:  ./demo.sh --git-only"
      return 1
    fi
  fi
  REPO_URL="https://github.com/$GH_USER/$name"
  TARGET_NAME="$name"

  # --- make the project easy to find and public ------------------------------
  local vis
  vis=$(gh repo view "$GH_USER/$name" --json visibility --jq .visibility 2>/dev/null)
  if [ "$vis" = "PRIVATE" ]; then
    step "This project is private, but it should be public so that anyone can use it and learn from it. 'gh repo edit --visibility public' changes that." \
         "gh repo edit $GH_USER/$name --visibility public --accept-visibility-change-consequences" \
         gh repo edit "$GH_USER/$name" --visibility public --accept-visibility-change-consequences
  fi
  step "'gh repo edit' also sets a short description and 'topics'. Topics are tags that help people find the project when they search on GitHub." \
       "gh repo edit $GH_USER/$name --description \"...\" --add-topic docker,docker-compose,mysql,nginx,git,github-cli,beginner-friendly,tutorial" \
       gh repo edit "$GH_USER/$name" \
         --description "Beginner-friendly, fully automatic Docker Compose demo: web + MySQL + Adminer + worker, explained step by step" \
         --add-topic docker,docker-compose,mysql,nginx,adminer,git,github-cli,beginner-friendly,tutorial,devops

  # --- verify the upload ---------------------------------------------------------
  step "'git status' now compares my computer with GitHub." "git status" git status
  notice "'Your branch is up to date with origin/main' means GitHub has exactly the same save points as my computer."

  local local_sha remote_sha="" _t
  local_sha=$(git rev-parse HEAD)
  for _t in 1 2 3 4 5; do
    remote_sha=$(gh api "repos/$GH_USER/$name/commits/main" --jq .sha 2>/dev/null)
    [ "$remote_sha" = "$local_sha" ] && break
    sleep 2
  done
  step "Now the real proof: I ask GitHub itself for the newest save point of the project, and compare it with the newest save point on this computer. 'git rev-parse HEAD' prints the full ID of my newest save point." \
       "git rev-parse HEAD ; gh api repos/$GH_USER/$name/commits/main --jq .sha" \
       printf '  this computer: %s\n  GitHub:        %s\n' "$local_sha" "${remote_sha:-"(no answer)"}"
  if [ "$remote_sha" = "$local_sha" ]; then
    UPLOADED=1; PUSHED_SHA="$local_sha"
    pass_check "Uploaded to GitHub and verified: GitHub has commit ${local_sha:0:7}"
    notice "Both IDs are exactly the same. GitHub has the newest version of the project."
  else
    fail_check "Uploaded to GitHub and verified (the IDs do not match)"
  fi

  step "'gh api' can also list the files and folders of the project on GitHub." \
       "gh api repos/$GH_USER/$name/contents --jq '.[].name'" \
       gh api "repos/$GH_USER/$name/contents" --jq '.[].name'

  # --- the automatic tests on GitHub ---------------------------------------------
  if [ -d .github/workflows ] && [ "$WORKFLOW_EXCLUDED" = 0 ]; then
    local runs=""
    for _t in 1 2 3 4 5 6 7 8; do
      runs=$(gh run list --repo "$GH_USER/$name" --commit "$local_sha" --limit 3 2>/dev/null)
      [ -n "$runs" ] && break
      sleep 3
    done
    if [ -n "$runs" ]; then
      step "The project has automatic tests (GitHub Actions). After every upload, GitHub starts its own computer, runs the whole Docker demo there, and checks the files. 'gh run list' shows the test run that just started." \
           "gh run list --repo $GH_USER/$name --commit ${local_sha:0:7}" printf '%s\n' "$runs"
      notice "The test run has started on GitHub. It takes about 3 to 5 minutes. When it is finished, the badge at the top of the README turns green: 'passing'."
    else
      info "GitHub will start the automatic tests in a moment: $REPO_URL/actions"
    fi
  fi

  printf '%s\n' "$REPO_URL" > "$URL_FILE" 2>/dev/null
  ok "The project is on GitHub"
  link "Open it in the browser:  $REPO_URL"
  echo
  explain "On that page, anyone can read the documentation, see every file and the full history. To download the project and run the same demo, they only need: git clone $REPO_URL.git"
}

# ============================================================================
# Summary speech + final confirmation
# ============================================================================
closing() {
  banner "Summary"
  echo
  box "$CYAN" "CLOSING" \
    "To finish. Without Docker Compose, I would need many long commands, typed in the right order, every time." \
    "With Docker Compose, one file describes the services, the network and the volumes. One command starts everything, and one command removes everything." \
    "Before uploading, the script cleaned up everything temporary and proved with fingerprints that no project file was damaged."
  if [ "$DO_GIT" = 1 ]; then
    box "$CYAN" "CLOSING" "With Git, the project and its full history are saved. With the GitHub CLI, it is uploaded to GitHub, so anyone can download it, learn from it, and run it."
  fi
  box "$CYAN" "CLOSING" "Thank you. Any questions?"
  echo
  printf '%s\n' "  ${B}Docker Compose commands used:${R}"
  printf '    %-40s %s\n' "docker compose up -d"                  "start everything in the background"
  printf '    %-40s %s\n' "docker compose ps"                     "list the containers"
  printf '    %-40s %s\n' "docker compose exec <service> <cmd>"   "run a command inside a container"
  printf '    %-40s %s\n' "docker compose down"                   "remove containers + network (keeps volumes)"
  printf '    %-40s %s\n' "docker compose up -d --scale worker=3" "run 3 copies of a service"
  printf '    %-40s %s\n' "docker compose logs <service>"         "show the messages of containers"
  printf '    %-40s %s\n' "docker compose down --volumes"         "remove everything, including the data"
  if [ "$DO_GIT" = 1 ]; then
    echo
    printf '%s\n' "  ${B}Git and GitHub commands used:${R}"
    printf '    %-40s %s\n' "git init -b main"                      "start tracking this folder"
    printf '    %-40s %s\n' "git status"                            "what changed, what is in the box"
    printf '    %-40s %s\n' "git add ."                             "put all files in the box (staging area)"
    printf '    %-40s %s\n' "git commit -m \"message\""             "create a save point"
    printf '    %-40s %s\n' "git log --oneline"                     "show the history"
    printf '    %-40s %s\n' "git diff"                              "show exactly what changed"
    printf '    %-40s %s\n' "gh auth login"                         "log in to GitHub (once)"
    printf '    %-40s %s\n' "gh repo create NAME --source=. --push" "create the GitHub project and upload"
    printf '    %-40s %s\n' "git push"                              "upload new save points to GitHub"
  fi
  echo
  pause 8
}

final_screen() {
  [ -n "$TMP_DIR" ] && remove_tmp_dir
  local secs=$(( $(date +%s) - START_TIME ))
  local nok=${#RESULTS_OK[@]} nfail=${#RESULTS_FAIL[@]}
  if [ "$MODE" != "fast" ] && [ -t 1 ]; then clear; fi
  if [ "$nfail" -eq 0 ]; then
    banner "SUCCESS - THE WHOLE PROCESS IS COMPLETE" "$GREEN"
  else
    banner "FINISHED WITH $nfail PROBLEM(S)" "$RED"
  fi
  echo
  printf '%s\n' "  ${B}Result of every check ($nok passed, $nfail failed):${R}"
  local r
  for r in "${RESULTS_OK[@]}";   do printf '%s\n' "    ${GREEN}${B}[PASSED]${R} $r"; done
  for r in "${RESULTS_FAIL[@]}"; do printf '%s\n' "    ${RED}${B}[FAILED]${R} $r"; done
  echo
  if [ "$UPLOADED" = 1 ]; then
    line
    printf '%s\n' "  ${GREEN}${B}The entire project has been uploaded to GitHub, and the upload was verified.${R}"
    echo
    printf '    %-18s %s\n' "Project page:"     "$REPO_URL"
    printf '    %-18s %s\n' "Automatic tests:"  "$REPO_URL/actions"
    printf '    %-18s %s\n' "Latest commit:"    "${PUSHED_SHA:0:7}  (GitHub and this computer match)"
    printf '    %-18s %s\n' "Download it with:" "git clone $REPO_URL.git"
    line
  elif [ "$DO_GIT" = 1 ] && [ "$DO_PUSH" = 0 ]; then
    note "The project is saved with Git on this computer. The upload to GitHub was skipped this time."
  fi
  echo
  printf '%s\n' "  Total time: $((secs / 60)) min $((secs % 60)) s"
  if [ "$nfail" -eq 0 ]; then
    printf '%s\n' "  ${GREEN}${B}All done. Thank you!${R}"
  else
    printf '%s\n' "  ${RED}${B}Some checks failed. Read the [PROBLEM] messages above, or see docs/09-troubleshooting.md${R}"
  fi
  echo
}

# ============================================================================
# Main
# ============================================================================
banner "Running Multi-Container Applications with Docker Compose"
[ "$SETUP_ONLY" = 0 ] && rm -f "$URL_FILE" 2>/dev/null
preflight

if [ "$SETUP_ONLY" = 1 ]; then
  remove_tmp_dir
  echo
  if [ "$DO_PUSH" = 1 ]; then
    ok "Setup complete. GitHub is connected. Next time, just run:  ./demo.sh"
  else
    note "Setup finished, but GitHub is not connected (see the messages above)."
  fi
  exit 0
fi

start_screen

if [ "$DO_DOCKER" = 1 ]; then
  part1; part2; part3; part4; part5; part6; part7; part8; part9
fi
part10

if [ "$DO_GIT" = 1 ]; then
  if part11; then
    part12 || note "Part 12 did not finish. Fix the problem shown above, then run:  ./demo.sh --git-only"
  else
    note "Part 11 did not finish. Fix the problem shown above, then run:  ./demo.sh --git-only"
  fi
fi

closing
final_screen
[ ${#RESULTS_FAIL[@]} -eq 0 ]
