#!/usr/bin/env bash
# =============================================================================
#  Docker Compose Demo  -  Running Multi-Container Applications
#  ---------------------------------------------------------------------------
#  A fully automatic demo. Press Enter once to start. After that, the script
#  runs every command by itself and explains each one in simple English:
#
#    Parts 1-9  : Docker Compose (start the app, network, volume, scaling, clean up)
#    Parts 10-11: Git (save the project's history) and GitHub (upload it online)
#
#  Usage:   ./demo.sh             automatic (the normal way: press Enter once)
#           ./demo.sh --slow      automatic, with more time to read each step
#           ./demo.sh --manual    you press Enter before every step
#           ./demo.sh --fast      quick practice run (no pauses)
#           ./demo.sh --setup     one-time check + GitHub login, then stop
#           ./demo.sh --keep      leave the containers running at the end
#           ./demo.sh --no-git    only the Docker part (Parts 1-9)
#           ./demo.sh --git-only  only the Git + GitHub part (Parts 10-11)
#           ./demo.sh --no-push   use Git, but do not upload to GitHub
#           ./demo.sh --help
#
#  While it runs:  Enter = skip the current pause    p = pause    Ctrl+C = stop
#  GitHub repository name: compose-demo  (change with  REPO_NAME=my-name ./demo.sh)
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
DO_GIT=1               # Part 10
DO_PUSH=1              # Part 11
SETUP_ONLY=0
REPO_NAME="${REPO_NAME:-compose-demo}"
MYSQL_WAIT_MAX=240     # seconds to wait for MySQL before giving up
URL_FILE="$HOME/.compose-demo-github-url"

for arg in "$@"; do
  case "$arg" in
    --manual|-m) MODE="manual" ;;
    --fast|-f)   MODE="fast" ;;
    --slow|-s)   SPEED="slow" ;;
    --keep|-k)   KEEP=1 ;;
    --setup)     SETUP_ONLY=1 ;;
    --no-git)    DO_GIT=0; DO_PUSH=0 ;;
    --git-only)  DO_DOCKER=0 ;;
    --no-push)   DO_PUSH=0 ;;
    --help|-h)   sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg   (see ./demo.sh --help)"; exit 1 ;;
  esac
done

# Reading speed: words per second the audience gets to read each explanation
if [ "$SPEED" = "slow" ]; then WPS=2; TYPE_DELAY=0.03; else WPS=3; TYPE_DELAY=0.02; fi
[ "$MODE" = "fast" ] && TYPE_DELAY=0

# Always work inside the folder of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PROJECT="$(basename "$SCRIPT_DIR" | tr '[:upper:]' '[:lower:]')"

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
  local text="$1"
  local pad=$(( (COLS - 4 - ${#text}) / 2 )); [ $pad -lt 0 ] && pad=0
  local bar; bar=$(printf '%*s' $((COLS-2)) '' | tr ' ' '=')
  local blank; blank=$(printf '%*s' $((COLS-2)) '')
  echo
  printf '%s\n' "${B}${BLUE}+${bar}+${R}"
  printf '%s\n' "${B}${BLUE}|${R}${blank}${B}${BLUE}|${R}"
  printf '%s%*s%s%*s%s\n' "${B}${BLUE}|${R}" $((pad+1)) '' "${B}${text}${R}" $((COLS-3-pad-${#text})) '' "${B}${BLUE}|${R}"
  printf '%s\n' "${B}${BLUE}|${R}${blank}${B}${BLUE}|${R}"
  printf '%s\n' "${B}${BLUE}+${bar}+${R}"
}

part() {   # part <number> <title> <time>
  if [ "$MODE" != "fast" ] && [ -t 1 ]; then clear; fi
  echo
  line
  printf '%s\n' "${B}${MAG}  PART $1 of 11  -  $2${R}   ${DIM}(about $3)${R}"
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

on_interrupt() {
  echo; echo
  note "The demo was stopped with Ctrl+C. Some containers may still be running."
  note "To remove them, run:  docker compose down --volumes"
  exit 130
}
trap on_interrupt INT

# ----------------------------------------------------------------------------
# GitHub helpers
# ----------------------------------------------------------------------------
GH_USER=""; GH_ID=""; GH_NAME=""

gh_logged_in() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }

gh_read_account() {
  local data
  data=$(gh api user --jq '"\(.id)|\(.login)|\(.name // "")"' 2>/dev/null) || return 1
  GH_ID="${data%%|*}"; data="${data#*|}"
  GH_USER="${data%%|*}"; GH_NAME="${data#*|}"
  [ -z "$GH_NAME" ] && GH_NAME="$GH_USER"
  [ -n "$GH_USER" ]
}

github_login() {
  echo
  box "$CYAN" "ONE-TIME GITHUB LOGIN" \
    "The script needs to log in to your GitHub account once. After this, it remembers the login, and the demo never asks again." \
    "1. A one-time code (like ABCD-1234) appears below. Copy it." \
    "2. If it asks 'Authenticate Git with your GitHub credentials?', press Enter (this means Yes)." \
    "3. If it says 'Press Enter to open github.com in your browser', press Enter. (This VM has no browser, so nothing opens here.)" \
    "4. On your laptop, open  https://github.com/login/device  , type the code, and click Authorize." \
    "5. Wait here. When it says 'Logged in', the script continues by itself."
  run "gh auth login --hostname github.com --git-protocol https --web" \
      gh auth login --hostname github.com --git-protocol https --web
  echo
  gh_logged_in
}

# ----------------------------------------------------------------------------
# Re-create the project files if they are missing
# ----------------------------------------------------------------------------
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
    printf '%s\n' '# Files Git must never save or upload' '*.log' '.env' '*.swp' '.DS_Store' > .gitignore
  fi

  if [ ! -f README.md ]; then
    printf '# Docker Compose Demo\n\nRun the demo with: ./demo.sh\n\nLast demo run: not yet\n' > README.md
  fi
}

# ============================================================================
# GETTING READY (checks before the demo starts)
# ============================================================================
preflight() {
  banner "Getting ready: checking everything"
  echo

  if [ "$DO_DOCKER" = 1 ]; then
    if ! command -v docker >/dev/null 2>&1; then
      fail "Docker is not installed on this machine."
      note "Use the compose-lab VM made with cloud-init.yaml (it installs Docker for you)."
      exit 1
    fi
    if docker info >/dev/null 2>&1; then
      DOCKER=(docker)
    elif sudo -n docker info >/dev/null 2>&1 || sudo docker info >/dev/null 2>&1; then
      DOCKER=(sudo docker)
      note "Docker is used with sudo this time. (Permanent fix: type exit, then open the VM shell again.)"
    else
      fail "Cannot talk to Docker (permission denied, or Docker is stopped)."
      note "Fix: type exit, then: multipass shell compose-lab   (or run: sudo ./demo.sh)"
      exit 1
    fi
    ok "Docker is running  (version $(dk version --format '{{.Server.Version}}' 2>/dev/null))"

    if ! dc version >/dev/null 2>&1; then
      fail "Docker Compose (the 'docker compose' command) is missing."
      note "Install it with: sudo apt install -y docker-compose-plugin"
      exit 1
    fi
    ok "Docker Compose is installed  (version $(dc version --short 2>/dev/null))"
  fi

  create_files_if_missing

  if [ "$DO_DOCKER" = 1 ]; then
    if ! dc config --quiet; then
      fail "docker-compose.yml has a mistake (see the message above)."
      exit 1
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
        exit 1
      fi
      ok "Images downloaded"
    fi

    if [ -n "$(dc ps -a -q 2>/dev/null)" ] || dk volume inspect "${PROJECT}_db-data" >/dev/null 2>&1; then
      dc down --volumes --remove-orphans >/dev/null 2>&1
      ok "Removed old containers and data from an earlier run (fresh start)"
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
      fail "Git is not installed, so Parts 10 and 11 will be skipped."
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
        info "GitHub is not logged in yet. Doing the one-time login now."
        if ! github_login; then
          fail "GitHub login did not finish. The project will be saved with Git, but not uploaded."
          note "To try the login again later, run:  ./demo.sh --setup"
          DO_PUSH=0
        fi
      else
        fail "GitHub is not logged in, so the upload to GitHub will be skipped."
        note "Log in once with:  ./demo.sh --setup"
        DO_PUSH=0
      fi
    fi
    if [ "$DO_PUSH" = 1 ]; then
      if gh_read_account; then
        ok "GitHub account: ${B}${GH_USER}${R}  (repository: ${REPO_NAME})"
      else
        fail "Could not read your GitHub account (no internet?). The upload will be skipped."
        DO_PUSH=0
      fi
    fi
  fi
}

start_screen() {
  echo
  line
  printf '%s\n' "  ${B}Everything is ready.${R}"
  echo
  printf '%s\n' "  What will happen:"
  [ "$DO_DOCKER" = 1 ] && printf '%s\n' "    Parts 1-9   Docker Compose: start a website + database app, test it, clean up"
  [ "$DO_GIT" = 1 ]    && printf '%s\n' "    Part 10     Git: save the project and its history"
  if [ "$DO_PUSH" = 1 ]; then
    printf '%s\n' "    Part 11     GitHub: upload the project to github.com/${GH_USER}/${REPO_NAME}"
  elif [ "$DO_GIT" = 1 ]; then
    printf '%s\n' "    Part 11     GitHub: skipped this time (see the notes above)"
  fi
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

# ============================================================================
# PART 1 - Opening
# ============================================================================
part1() {
  part 1 "Opening" "1 min"
  explain "Hello everyone. My topic today is: Running Multi-Container Applications with Docker Compose." \
          "Docker Compose lets us start a complete application, with a website and a database, using one file and one command." \
          "Everything you see on this screen is real. Every command runs live, right now, and I explain each one before it runs." \
          "At the end, I will also save the project with Git and upload it to GitHub."
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
    fail "'docker compose up' did not work. Read the message above."
    note "If it says a port is already in use, another program is using port 8080 or 8081."
    exit 1
  fi
  notice "Read the lines above from top to bottom: first the network and the volume were Created. Then each container was Started. The database started before the website, because of depends_on."

  step "'docker compose ps' lists the containers of this project and shows if they are running." \
       "docker compose ps" dc ps
  notice "All four services are in the list, and STATUS says 'Up'. That means they are running. In the PORTS column, door 8080 goes to the website and door 8081 goes to Adminer."

  # make sure the web server answers before showing it
  local _i
  for _i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null --max-time 2 http://localhost:8080 && break; sleep 1; done
  step "'curl' opens a web page from the terminal, like a browser without pictures. I ask the website for its page title." \
       "curl -s http://localhost:8080 | grep '<title>'" \
       sh -c "curl -s --max-time 5 http://localhost:8080 | grep -o '<title>.*</title>'"
  ok "The web container answered on port 8080"
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
  step "'docker compose exec' runs a command inside a container that is already running. I ask the worker container to 'ping' the database. Ping sends small test messages and waits for replies. I use only the name 'db', not an IP address." \
       "docker compose exec worker ping -c 3 db" dc exec "${EXEC_T[@]}" worker ping -c 3 db
  notice "The database replied 3 times, and '0% packet loss' means no message was lost. So the private network works. Docker has a small built-in phone book (DNS) that turns the name 'db' into the right address."

  step "The NGINX image is kept very small and has no ping tool, so for the web container I use 'getent hosts'. It asks the phone book: what is the address of 'db'?" \
       "docker compose exec web getent hosts db" dc exec "${EXEC_T[@]}" web getent hosts db
  notice "The web container also found the database by its name. Every service can reach the others by name."

  step "MySQL needs some time to start the first time, because it sets up its files. The script now waits until the database is ready." \
       "(waiting for MySQL)" wait_for_mysql || note "If MySQL is still starting, the next part waits again."

  # Adminer proof: connect from the adminer container to the database
  local php_out
  php_out=$(dc exec -T adminer php -r '$m = @new mysqli("db", "root", "examplepassword"); if ($m->connect_errno) { exit(1); } echo "Connected to MySQL ", $m->server_info, "\n";' 2>/dev/null)
  if [ -n "$php_out" ]; then
    step "Adminer runs in its own container. I ask the Adminer container to connect to the database, again using only the name 'db'." \
         "docker compose exec adminer php -r '... new mysqli(\"db\", \"root\", \"examplepassword\") ...'" \
         printf '%s\n' "$php_out"
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
part7() {
  part 7 "Data survives a restart" "2 min"
  explain "Now I will prove that the volume keeps the data safe. First, I save some data in the database."
  wait_for_mysql >/dev/null || { fail "MySQL is not ready."; exit 1; }

  step "This command runs the MySQL program inside the db container. It creates a database called 'college', creates a table called 'students', and adds two names." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"CREATE DATABASE college; CREATE TABLE college.students (name VARCHAR(50)); INSERT INTO college.students VALUES ('Shad'), ('Classmate');\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "CREATE DATABASE college; CREATE TABLE college.students (name VARCHAR(50)); INSERT INTO college.students VALUES ('Shad'), ('Classmate');"
  note "MySQL warns about using a password on the command line. That is normal for a demo."

  step "SELECT reads the data back from the table." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"SELECT * FROM college.students;\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "SELECT * FROM college.students;"
  notice "The two students are saved in the database."

  step "Now I delete ALL the containers. 'docker compose down' stops and removes every container and the network." \
       "docker compose down" dc down
  step "Let us check: is anything still running?" \
       "docker compose ps" dc ps
  notice "The list is empty. Nothing is running. All the containers are gone."

  step "But 'down' does not delete volumes. 'docker volume ls' lists the volumes (the lockers)." \
       "docker volume ls" dk volume ls
  notice "The db-data volume is still there. The locker was not deleted."

  if ! step "Now I bring everything back with the same command as before. These are brand-new containers." \
       "docker compose up -d" dc up -d; then
    fail "'docker compose up' did not work."; exit 1
  fi
  wait_for_mysql || { fail "MySQL did not come back."; exit 1; }

  step "The moment of truth: I read the students table again, in the brand-new database container." \
       "docker compose exec db mysql -uroot -pexamplepassword -e \"SELECT * FROM college.students;\"" \
       dc exec "${EXEC_T[@]}" db mysql -uroot -pexamplepassword -e "SELECT * FROM college.students;"
  ok "The students are still there"
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
  notice "Now there are three workers: worker-1, worker-2 and worker-3. This is how an application handles more work: run more copies."

  info "Waiting a few seconds, so the workers can print some messages"
  sleep 7
  step "'docker compose logs' shows the messages that containers print. '--tail 6' shows only the last 6 messages of each worker." \
       "docker compose logs worker --tail 6" dc logs worker --tail 6
  notice "Each worker prints a different name (its container ID). These are three separate containers doing the same job."
  explain "The reference material scales the web service instead (--scale web=3). That works only if the web service has no fixed port, because only one container can use door 8080 at a time. In real projects, a 'load balancer' stands in front of the web copies and shares the visitors between them."
}

# ============================================================================
# PART 9 - Clean up
# ============================================================================
part9() {
  part 9 "Clean up" "1 min"
  if [ "$KEEP" = 1 ]; then
    note "--keep was used, so the containers keep running."
    note "To remove them later, run:  docker compose down --volumes"
    pause 3
    return 0
  fi
  explain "Last Docker step: remove everything with one command."
  step "'docker compose down --volumes' removes the containers, the network, and this time also the volume with the data." \
       "docker compose down --volumes" dc down --volumes
  step "Let us check the volumes again." \
       "docker volume ls" dk volume ls
  notice "The db-data volume is gone from the list. The machine is clean again, as if nothing was ever there. This is very useful for testing: you can start fresh in seconds."
}

# ============================================================================
# PART 10 - Save the project with Git
# ============================================================================
part10() {
  part 10 "Save the project with Git" "3 min"
  explain "The application works. Now I want to save my work properly and share it. For this I use two tools." \
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
         "git init -b main" git init -b main || { fail "git init did not work."; return 1; }
  fi

  step "Step 2: the .gitignore file is a list of files that Git must NOT save, for example log files, or the .env file where real projects keep passwords. 'cat' shows the list." \
       "cat .gitignore" cat .gitignore

  step "Step 3: 'git status' shows what Git sees in the folder right now." \
       "git status" git status
  notice "Files under 'Untracked files' (or 'Changes') are not in a save point yet."

  step "Step 4: 'git add .' puts the files into the 'staging area'. Think of it as a box: everything in the box goes into the next save point. The dot means: everything in this folder." \
       "git add ." git add .
  step "'git status --short' shows the same thing in a short form. 'A' means the file was Added to the box." \
       "git status --short" git status --short

  if git rev-parse --verify HEAD >/dev/null 2>&1 && git diff --cached --quiet; then
    info "Nothing new to save. Everything is already in a save point."
  else
    local msg="Add Docker Compose multi-container demo"
    git rev-parse --verify HEAD >/dev/null 2>&1 && msg="Update Docker Compose demo files"
    step "Step 5: 'git commit' creates the save point. '-m' adds a short message that says what was done." \
         "git commit -m \"$msg\"" git commit -m "$msg" || { fail "git commit did not work."; return 1; }
    notice "Git saved the files. The line shows a short ID for this save point and how many files were saved."
  fi

  step "'git log --oneline' shows the history: one line for each save point, newest first." \
       "git log --oneline" git --no-pager log --oneline -5

  # --- make a change and track it ---------------------------------------------
  explain "Step 6: Git notices every change I make. Let me change a file, and then ask Git what changed."
  local stamp; stamp=$(date '+%d %b %Y, %H:%M:%S')
  if grep -q '^Last demo run:' README.md; then
    step "'sed' is a tool that changes text inside a file. Here it writes today's date and time into the README.md file." \
         "sed -i \"s/^Last demo run:.*/Last demo run: $stamp/\" README.md" \
         sed -i "s/^Last demo run:.*/Last demo run: $stamp/" README.md
  else
    step "'echo ... >> README.md' adds a new line with today's date at the end of the README.md file." \
         "echo \"Last demo run: $stamp\" >> README.md" \
         sh -c "printf '\nLast demo run: %s\n' \"$stamp\" >> README.md"
  fi

  if git diff --quiet; then
    info "README.md did not change, so there is nothing new to save."
  else
    step "'git status --short' again. 'M' means the file was Modified." \
         "git status --short" git status --short
    step "'git diff' shows exactly what changed inside the file." \
         "git diff" git --no-pager diff
    notice "The line that starts with a minus (-) is the old text. The line that starts with a plus (+) is the new text."
    step "'git commit -am' adds all changed files and saves them in one step. '-a' means all changed files, '-m' is the message." \
         "git commit -am \"Record demo run on $stamp\"" git commit -am "Record demo run on $stamp"
    step "The history now has one more save point at the top." \
         "git log --oneline" git --no-pager log --oneline -5
  fi
  ok "The project and its full history are saved with Git"
  pause 3
}

# ============================================================================
# PART 11 - Upload the project to GitHub
# ============================================================================
free_repo_name() {   # first unused name: compose-demo-2, compose-demo-3, ...
  local n candidate
  for n in 2 3 4 5 6 7 8 9 10 11 12; do
    candidate="${REPO_NAME}-${n}"
    gh repo view "$GH_USER/$candidate" >/dev/null 2>&1 || { echo "$candidate"; return 0; }
  done
  return 1
}

create_and_push() {   # create_and_push <name>
  local name="$1"
  local desc="Docker Compose demo: NGINX, MySQL 8.4, Adminer and a worker on one network, with a volume"
  git remote remove origin >/dev/null 2>&1
  step "'gh repo create' does three jobs in one command: it creates a new public project called '$name' on GitHub, connects this folder to it (the connection is called 'origin'), and uploads all my save points ('--push')." \
       "gh repo create $name --public --source=. --remote=origin --push --description \"...\"" \
       gh repo create "$name" --public --source=. --remote=origin --push --description "$desc"
}

part11() {
  part 11 "Upload the project to GitHub" "2.5 min"
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

  local name="$REPO_NAME" url current
  # If this folder points to a project with a different name, disconnect it first
  current=$(git remote get-url origin 2>/dev/null)
  if [ -n "$current" ] && [[ "$current" != *"/$name" && "$current" != *"/$name.git" ]]; then
    git remote remove origin
    current=""
  fi

  local pushed=0
  if [ -n "$current" ]; then
    # Already connected: just push the new save points
    if step "This folder is already connected to the GitHub project '$name' (the connection is called 'origin'). 'git push' uploads only the new save points." \
            "git push -u origin main" git push -u origin main; then
      pushed=1
    else
      note "GitHub has a different history for '$name'. The script uses a new name instead. Nothing on GitHub is deleted."
      git remote remove origin
      name=$(free_repo_name) || { fail "Could not find a free project name on GitHub."; return 1; }
    fi
  elif gh repo view "$GH_USER/$name" >/dev/null 2>&1; then
    # The name exists on GitHub. Is it this same project (or an empty one)?
    git remote add origin "https://github.com/$GH_USER/$name.git"
    local different=0
    if git fetch -q origin 2>/dev/null && git rev-parse -q --verify origin/main >/dev/null 2>&1 \
       && ! git merge-base --is-ancestor origin/main main 2>/dev/null; then
      different=1
    fi
    if [ "$different" = 0 ] && step "A project called '$name' already exists on my GitHub. I connected this folder to it. Now 'git push' uploads the new save points." \
         "git push -u origin main" git push -u origin main; then
      pushed=1
    else
      note "A different project called '$name' already exists on GitHub. The script uses a new name. Nothing on GitHub is deleted."
      git remote remove origin
      name=$(free_repo_name) || { fail "Could not find a free project name on GitHub."; return 1; }
    fi
  fi

  if [ "$pushed" = 0 ]; then
    if ! create_and_push "$name"; then
      fail "The upload to GitHub did not work (see the message above)."
      note "Check the internet connection, then run:  ./demo.sh --git-only"
      return 1
    fi
  fi
  url="https://github.com/$GH_USER/$name"
  printf '%s\n' "$url" > "$URL_FILE" 2>/dev/null

  step "'git status' now compares my computer with GitHub." "git status" git status
  notice "'Your branch is up to date with origin/main' means GitHub has exactly the same save points as my computer."

  sleep 2   # give GitHub a moment
  step "Now I ask GitHub itself which save points it has. 'gh api' talks directly to GitHub." \
       "gh api repos/$GH_USER/$name/commits --jq '.[] | .sha[0:7] + \"  \" + .commit.message'" \
       gh api "repos/$GH_USER/$name/commits" --jq '.[] | .sha[0:7] + "  " + .commit.message'
  step "And which files are in the project on GitHub." \
       "gh api repos/$GH_USER/$name/contents --jq '.[].name'" \
       gh api "repos/$GH_USER/$name/contents" --jq '.[].name'
  notice "GitHub has the same save points and the same files as this computer. The upload worked."
  ok "The project is on GitHub"
  link "Open it in the browser:  $url"
  echo
  explain "On that page, anyone can see the files and the full history. To download the project and run the same demo, they only need: git clone $url.git"
}

# ============================================================================
# Summary
# ============================================================================
closing() {
  banner "Summary"
  echo
  box "$CYAN" "CLOSING" \
    "To finish. Without Docker Compose, I would need many long commands, typed in the right order, every time." \
    "With Docker Compose, one file describes the services, the network and the volumes. One command starts everything, and one command removes everything." \
    "And because it is just a file, my whole team can run exactly the same application on their computers."
  if [ "$DO_GIT" = 1 ]; then
    box "$CYAN" "CLOSING" "With Git, the project and its full history are saved. With the GitHub CLI, I uploaded it to GitHub, so anyone can download it and run it."
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
  ok "Demo finished."
  echo
}

# ============================================================================
# Main
# ============================================================================
banner "Running Multi-Container Applications with Docker Compose"
[ "$SETUP_ONLY" = 0 ] && rm -f "$URL_FILE" 2>/dev/null
preflight

if [ "$SETUP_ONLY" = 1 ]; then
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

if [ "$DO_GIT" = 1 ]; then
  if part10; then
    part11 || note "Part 11 did not finish. Fix the problem shown above, then run:  ./demo.sh --git-only"
  else
    note "Part 10 did not finish. Fix the problem shown above, then run:  ./demo.sh --git-only"
  fi
fi

closing
