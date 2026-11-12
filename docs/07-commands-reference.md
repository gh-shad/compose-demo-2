# 07 - Commands reference

Every command used in this project, in one place, grouped by tool.

**Back to:** [README](../README.md) · **Previous:** [06 - Every file explained](06-files-explained.md) · **Next:** [08 - Clean up and safety](08-cleanup-and-safety.md)

Words in `<angle brackets>` are placeholders: replace them with your own value.

---

## Windows (PowerShell)

| Command | What it does |
|---|---|
| `winver` (in Win+R) | Shows your Windows edition and version |
| `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All` | Turns on Hyper-V (Admin window) |
| `multipass version` | Shows that Multipass is installed |
| `Start-Demo.bat` / `Start-Demo.bat --slow` | Runs the whole demo (double-click, or type it in the project folder) |

## Multipass (Windows, macOS or Linux)

| Command | What it does |
|---|---|
| `multipass launch 24.04 --name compose-lab --cpus 2 --memory 4G --disk 15G --cloud-init cloud-init.yaml --timeout 1500` | Creates the VM and sets it up |
| `multipass list` | Lists all VMs and their state |
| `multipass info compose-lab` | Details of the VM (state, IP address, disk) |
| `multipass start compose-lab` / `multipass stop compose-lab` | Starts / stops the VM |
| `multipass shell compose-lab` | Opens a terminal inside the VM (`exit` to leave) |
| `multipass exec compose-lab -- <command>` | Runs one command inside the VM |
| `multipass transfer <file> compose-lab:<path>` | Copies a file into the VM |
| `multipass delete compose-lab` then `multipass purge` | Deletes the VM completely |

## The demo script

| Command | What it does |
|---|---|
| `./demo.sh` | The whole demo, automatic (press Enter once) |
| `./demo.sh --help` | Shows all options |
| `./demo.sh --setup` | Checks + one-time GitHub login, then stops |
| `./demo.sh --fast --no-git` | Quick Docker test without Git (what GitHub Actions runs) |
| `./demo.sh --git-only` | Clean up + Git + GitHub only |

All options: [README, section 7](../README.md#7-options).

## Docker Compose

| Command | What it does |
|---|---|
| `docker compose version` | Shows the Compose version |
| `docker compose config --quiet` | Checks the compose file (no output = no mistakes) |
| `docker compose pull` | Downloads all images in the file |
| `docker compose up -d` | Creates the network and volume, starts all containers in the background |
| `docker compose up -d --scale worker=3` | Runs 3 copies of the `worker` service |
| `docker compose ps` | Lists the running containers of this project |
| `docker compose ps -a` | Also lists stopped containers |
| `docker compose exec <service> <command>` | Runs a command inside a running container |
| `docker compose logs <service>` | Shows what a service printed. `--tail 6` = only the last 6 lines. `-f` = keep following |
| `docker compose down` | Removes the containers and the network (keeps volumes) |
| `docker compose down --volumes` | Also removes the volumes (the data!) |
| `docker compose down --volumes --remove-orphans` | Also removes old containers of this project that are no longer in the file |

## Docker

| Command | What it does |
|---|---|
| `docker info` | Shows that the Docker engine is running |
| `docker version` | Versions of the Docker client and engine |
| `docker ps -a` | Lists all containers on the computer |
| `docker ps -a --filter label=com.docker.compose.project=compose-demo` | Lists only this project's containers |
| `docker volume ls` / `docker network ls` | Lists volumes / networks (`--filter label=...` works here too) |
| `docker image ls` | Lists the images |
| `docker image inspect <image>` | Details of one image (used to check if it is there) |
| `docker pull <image>` | Downloads an image |
| `docker image rm <image>` | Deletes an image |

## Commands used inside the containers

| Command | Where | What it does |
|---|---|---|
| `ping -c 3 db` | worker | Sends 3 test messages to `db` and waits for replies |
| `getent hosts db` | web | Asks the network's DNS for the address of `db` |
| `mysql -uroot -pexamplepassword -e "<SQL>"` | db | Runs SQL as the `root` user |
| `php -r '<code>'` | adminer | Runs a small PHP program (here: connect to `db`) |

## SQL (inside MySQL)

| Statement | What it does |
|---|---|
| `CREATE DATABASE college;` | Creates a database called `college` |
| `CREATE TABLE college.students (name VARCHAR(50));` | Creates a table with one text column `name` (up to 50 letters) |
| `INSERT INTO college.students VALUES ('Shad'), ('Classmate');` | Adds two rows |
| `SELECT * FROM college.students;` | Reads all rows |
| `SELECT COUNT(*) FROM college.students;` | Counts the rows (the script uses this to check) |

## Linux tools

| Command | What it does |
|---|---|
| `cat <file>` | Prints a file |
| `ls -la <folder>` | Lists a folder, including hidden files, with details |
| `curl -s <address> -o <file>` | Downloads a web page into a file (`-s` = silent) |
| `grep -o '<pattern>' <file>` | Finds text in a file (`-o` = print only the matching part) |
| `sed -i 's#old#new#g' <file>` | Replaces text inside a file (`-i` = change the file itself, `g` = every match) |
| `echo "<text>" >> <file>` | Adds a line at the end of a file (`>>` = append) |
| `sha256sum <files> > list` | Makes SHA-256 fingerprints |
| `sha256sum --check --quiet list` | Checks files against their fingerprints (prints only problems) |
| `mktemp -d /tmp/name.XXXXXX` | Creates a new, private, temporary folder with a random name |
| `rm -rf <folder>` | Deletes a folder and everything inside it (careful!) |
| `hostname -I` | Shows the computer's IP addresses |
| `tar -cf <file>.tar -C <folder> .` / `tar -xf <file>.tar` | Packs / unpacks many files into / from one file |

## Git

| Command | What it does |
|---|---|
| `git --version` | Shows the Git version |
| `git config --global user.name "<name>"` | Sets your name for commits |
| `git config --global user.email "<email>"` | Sets your email for commits |
| `git init -b main` | Turns a folder into a repository, with the branch `main` |
| `git status` / `git status --short` | Shows what changed |
| `git add .` | Stages every file (except ignored ones) |
| `git commit -m "<message>"` | Creates a commit |
| `git commit -am "<message>"` | Stages every changed tracked file and commits |
| `git log --oneline` | The history, one line per commit |
| `git diff` | Shows exactly what changed |
| `git rev-parse HEAD` | Prints the full ID of the newest commit |
| `git remote -v` | Lists the connections to GitHub |
| `git remote add origin <address>` | Connects the folder to a GitHub project |
| `git remote rename origin upstream` | Renames a connection |
| `git push -u origin main` | Uploads and remembers the connection |
| `git push` | Uploads new commits |
| `git pull` | Downloads new commits |
| `git clone <address>` | Downloads a whole project |

## GitHub CLI (gh)

| Command | What it does |
|---|---|
| `gh --version` | Shows the gh version |
| `gh auth login --hostname github.com --git-protocol https --web --scopes workflow` | Logs in with a one-time code |
| `gh auth refresh --hostname github.com --scopes workflow` | Adds the `workflow` permission |
| `gh auth status` | Shows the logged-in account and its permissions |
| `gh auth setup-git` | Lets Git use gh's login |
| `gh auth logout` | Logs out on this computer |
| `gh repo create <name> --public --source=. --remote=origin --push` | Creates a public GitHub project from this folder and uploads it |
| `gh repo view <owner>/<name>` | Shows a project (also used to check if a name exists) |
| `gh repo edit <owner>/<name> --description "<text>" --add-topic <a>,<b>` | Sets the description and topics |
| `gh repo edit <owner>/<name> --visibility public --accept-visibility-change-consequences` | Makes a project public |
| `gh api repos/<owner>/<name>/commits/main --jq .sha` | Asks GitHub for the newest commit ID |
| `gh api repos/<owner>/<name>/contents --jq '.[].name'` | Asks GitHub for the list of files |
| `gh run list --repo <owner>/<name>` | Lists the automatic test runs |
| `gh run watch --repo <owner>/<name>` | Follows a running test live |

---

**Next:** [08 - Clean up and safety](08-cleanup-and-safety.md)
