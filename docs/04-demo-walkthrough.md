# 04 - Demo walkthrough: every part, every command

This page follows the demo from the first screen to the last. For each part you see
**what it shows**, **every command it runs**, and **what to look at** in the result.

**Back to:** [README](../README.md) · **Previous:** [03 - The compose file](03-docker-compose-file.md) · **Next:** [05 - Git and GitHub](05-git-and-github.md)

---

## How the screen works

| On the screen | Meaning |
|---|---|
| `PART 5 of 12 - Start the whole app` | The title of a new part. The screen is cleared first. |
| **EXPLANATION** box (blue) | What is happening, in simple English. |
| **NEXT COMMAND** box (blue) | What the next command does, **before** it runs. |
| Green line starting with `$` | The real command. Everything below it is its real output. |
| **LOOK AT THE RESULT** box (green) | What the output means. |
| `[OK]` (green) | A check that passed. |
| `[PROBLEM]` (red) | A check that failed, with a hint how to fix it. |
| `NOTE:` (yellow) | Extra information. |

Keys while it runs: **Enter** skips the current pause, **p** pauses, **Ctrl+C** stops.

```mermaid
flowchart LR
    S["Getting ready"] --> P1["1-4 Explain"]
    P1 --> P5["5 Start"]
    P5 --> P6["6 Talk"]
    P6 --> P7["7 Data survives"]
    P7 --> P8["8 Scale"]
    P8 --> P9["9 Stop"]
    P9 --> P10["10 Clean up + safety check"]
    P10 --> P11["11 Git"]
    P11 --> P12["12 GitHub"]
    P12 --> F["Final confirmation"]
```

---

## Getting ready (before Part 1)

The script checks everything and prints one `[OK]` line per check. Nothing is changed yet,
except that old containers of **this** project from an earlier run are removed, for a fresh start.

| Check | How |
|---|---|
| Docker is running | `docker info` (if your user may not use Docker, it tries `sudo docker`) |
| Docker Compose is installed | `docker compose version` |
| A temporary folder is created | `mktemp -d /tmp/compose-demo-run.XXXXXX` (removed again in Part 10) |
| Safety fingerprint of every project file | `sha256sum` of every file (checked again in Part 10) |
| The compose file has no mistakes | `docker compose config --quiet` |
| The 4 images are on the computer | `docker image inspect` (if one is missing: `docker compose pull`) |
| No old containers of this project | counts containers, networks and volumes with this project's label |
| The VM's address | `hostname -I` |
| Git is installed | `git --version` |
| GitHub is connected | `gh auth status` (if not: asks if you want to log in, see [01 - Setup](01-setup-from-zero.md)) |
| The `workflow` permission | needed to upload `.github/workflows/`. If missing, asked once |

Then you see a short plan of all parts and **Press Enter to start the demo**.

---

## Part 1 - Opening (1 minute)

No commands. The topic and the plan: one file and one command start a whole application,
and at the end the project is cleaned up, checked, saved with Git and uploaded to GitHub.

## Part 2 - The problem (1.5 minutes)

No commands are run. The screen shows the **6 long commands** that you would need **without**
Docker Compose (create a network, create a volume, 4 × `docker run` with many options), and then
the **1 command** with Docker Compose: `docker compose up -d`. Then the band-leader picture.

## Part 3 - Three building blocks (1.5 minutes)

No commands. A table and a diagram of **services** (the workers), the **network** (the road)
and the **volume** (the locker).

## Part 4 - The YAML file (2 minutes)

| Command | What it does | What to look at |
|---|---|---|
| `cat docker-compose.yml` | Prints the content of the file | The whole application in about 40 lines |
| *(highlighted lines)* | The script shows the important lines one by one, with their line numbers, and explains each | `ports`, the `html` bind mount, `depends_on`, the password, the volume |
| `docker compose version` | Shows the installed Docker Compose version | Version 2 or newer (`docker compose` with a space) |

Three updates compared to older material are explained: `docker compose` instead of
`docker-compose`, no `version:` line, and MySQL 8.4 instead of 5.7.
Full line-by-line explanation: [03 - The compose file](03-docker-compose-file.md).

## Part 5 - Start the whole app (2 minutes)

| Command | What it does | What to look at |
|---|---|---|
| `docker compose up -d` | Reads the file, creates the network and the volume, starts all 4 containers. `-d` = in the background | Network and volume **Created**, then each container **Started**, the database first |
| `docker compose ps` | Lists this project's containers | 4 lines, STATUS **Up**, PORTS `0.0.0.0:8080->80/tcp` and `0.0.0.0:8081->8080/tcp` |
| `curl -s http://localhost:8080 -o <temp>/page.html && grep -o '<title>.*</title>' <temp>/page.html` | `curl` downloads the web page into the temporary folder, `grep` finds its title | `<title>Docker Compose Demo</title>` |

**Checks recorded:** all 4 containers running · the website answered on port 8080.

**In the browser:** `http://<VM-address>:8080` shows the page from `html/index.html`.
(The Windows launcher opens it by itself.)

## Part 6 - Containers talking to each other (2 minutes)

| Command | What it does | What to look at |
|---|---|---|
| `docker compose exec worker ping -c 3 db` | Runs `ping` **inside** the worker container. `-c 3` = send 3 messages. Uses only the **name** `db` | 3 replies, `0% packet loss` |
| `docker compose exec web getent hosts db` | Asks the network's phone book (DNS) for the address of `db`, from inside the web container (NGINX has no `ping`) | A line like `172.18.0.2   db` |
| *(waiting for MySQL)* | Waits until MySQL is really ready: its log shows `ready for connections ... port: 3306` and a test query works | `[OK] MySQL is ready` |
| `docker compose exec adminer php -r '... new mysqli("db", ...) ...'` | A tiny PHP program inside the Adminer container connects to the database | `Connected to MySQL 8.4.x` |

**Checks recorded:** worker reached `db` · web found `db` · MySQL ready · Adminer connected.

**In the browser:** `http://<VM-address>:8081` → System **MySQL**, Server **db**,
Username **root**, Password **examplepassword**, Database empty → **Login**.

Why wait for MySQL? On its very first start, MySQL first runs a **temporary setup server**
(it logs `port: 0`), then restarts as the real server on port 3306. The script waits for the real one.

## Part 7 - Data survives a restart (2 minutes)

| Command | What it does | What to look at |
|---|---|---|
| `docker compose exec db mysql -uroot -pexamplepassword -e "CREATE DATABASE college; CREATE TABLE college.students (name VARCHAR(50)); INSERT INTO college.students VALUES ('Shad'), ('Classmate');"` | Runs the MySQL client inside the db container. `-u` = user, `-p` = password, `-e` = run this SQL | A warning about the password on the command line (normal for a demo) |
| `docker compose exec db mysql ... -e "SELECT * FROM college.students;"` | Reads the table | `Shad` and `Classmate` |
| `docker compose down` | Stops and **removes all containers and the network**. Volumes are kept | Containers and network **Removed** |
| `docker compose ps` | Lists the containers | An empty list |
| `docker volume ls` | Lists all volumes | `compose-demo_db-data` is **still there** |
| `docker compose up -d` | Starts **brand-new** containers | Created, Started |
| *(waiting for MySQL)* | Waits until the new MySQL is ready | `[OK] MySQL is ready` |
| `docker compose exec db mysql ... -e "SELECT * FROM college.students;"` | Reads the table again | **Both names are still there** |

**SQL words used:** `CREATE DATABASE` makes a new database. `CREATE TABLE` makes a table with a
column `name` (text up to 50 letters, `VARCHAR(50)`). `INSERT INTO ... VALUES` adds rows.
`SELECT * FROM` reads all rows.

**Checks recorded:** 2 students saved · the data survived `down` and `up`.

## Part 8 - Scaling and logs (1.5 minutes)

| Command | What it does | What to look at |
|---|---|---|
| `docker compose up -d --scale worker=3` | Runs **3 copies** of the worker service | `worker-2` and `worker-3` Started |
| `docker compose ps` | Lists the containers | `worker-1`, `worker-2`, `worker-3` |
| `docker compose logs worker --tail 6` | Shows the last 6 messages of each worker | Three **different** names in `Worker <name> is working` |

**Check recorded:** 3 worker copies running.

Why not `--scale web=3`? Only one container can use door 8080 at a time. Real projects put a
load balancer in front of many web copies.

## Part 9 - Stop and remove the app (1 minute)

| Command | What it does | What to look at |
|---|---|---|
| `docker compose down --volumes` | Removes the containers, the network **and** the volume | Everything **Removed** |
| `docker volume ls` | Lists all volumes | `compose-demo_db-data` is gone |

With `--keep`, this part is skipped and the containers keep running.

## Part 10 - Clean up and safety check (2 minutes)

This part runs **before** anything is uploaded. Rule: **only remove what this demo created.**
Full details: [08 - Clean up and safety](08-cleanup-and-safety.md).

| Command | What it does | What to look at |
|---|---|---|
| `docker compose down --volumes --remove-orphans` | Makes sure that this project's containers, network and volume are gone. `--remove-orphans` also removes old containers of this project that are no longer in the file | Nothing (or `Removed`) |
| `docker ps -a --filter label=com.docker.compose.project=compose-demo` (and the same for `docker network ls` and `docker volume ls`) | Lists **only** things with this project's label | Three lists with only their headings |
| `docker image ls --filter reference=nginx:latest ...` | Lists the 4 images | They are **kept on purpose** for the next run |
| `sha256sum --check --quiet <temp>/fingerprint.sha256` | Compares every project file with its fingerprint from the start | **No output** = every file is present and unchanged |
| `ls -la <temp>` | Shows the temporary folder | `fingerprint.sha256` and `page.html` |
| `rm -rf /tmp/compose-demo-run.XXXXXX` | Deletes the temporary folder. The script first checks that the path really is its own temporary folder and belongs to this user | — |

**Checks recorded:** no containers, networks or volumes of this project left · all project
files present and unchanged (SHA-256) · the temporary folder was deleted.

## Part 11 - Save the project with Git (3 minutes)

Every Git command is explained in detail in [05 - Git and GitHub](05-git-and-github.md).

| Command | What it does |
|---|---|
| `git --version` | Shows that Git is installed |
| `git config --global user.name` / `user.email` | Shows (or sets) the name and email written into every commit. If they are not set, the script uses your GitHub name and GitHub's private `noreply` email |
| `git init -b main` | Turns the folder into a repository (first run only). On later runs: `git log --oneline` instead |
| `sed -i "s#gh-shad/compose-demo#<you>/<project>#g" README.md docs/...` | Replaces the example links in the documentation with your real GitHub address (only if they are still there) |
| `cat .gitignore` | Shows the files that Git must never save |
| `git status --short` | Shows new (`??`) and changed (`M`) files |
| `git add .` | Puts all files into the staging area |
| `git status --short` | Now `A` (added) and `M` (modified) |
| `git commit -m "..."` | Creates the save point |
| `git log --oneline` | Shows the history |
| `echo "\| <date> \| <n> of <n> checks passed \|" >> docs/demo-runs.md` | Adds one line to the run history |
| `git diff` | Shows the exact change: one line with `+` |
| `git commit -am "Record demo run on <date>"` | Saves the change |
| `git log --oneline` | One more save point at the top |

**Checks recorded:** nothing left unsaved · the Git history (number of commits, newest ID).

## Part 12 - Upload the project to GitHub (3 minutes)

| Command | What it does |
|---|---|
| `gh --version` | Shows that the GitHub CLI is installed |
| `gh auth status` | Shows which GitHub account is logged in (the token is hidden with stars) |
| `gh auth setup-git` | Lets Git use this login for uploads, so it never asks for a password |
| `git push -u origin main` | **Your existing project:** uploads only the new commits |
| *or* `gh repo create compose-demo --public --source=. --remote=origin --push` | **First time:** creates the public project on GitHub, connects the folder, and uploads |
| `gh repo edit ... --description ... --add-topic ...` | Sets the description and topics (search tags) on GitHub |
| `git status` | `Your branch is up to date with 'origin/main'` |
| `git rev-parse HEAD` and `gh api repos/<you>/<project>/commits/main --jq .sha` | **The proof:** the newest commit ID on this computer and on GitHub. They must be identical |
| `gh api repos/<you>/<project>/contents --jq '.[].name'` | Lists the files that GitHub now has |
| `gh run list --repo <you>/<project> --commit <id>` | Shows that GitHub started the automatic tests |

**Check recorded:** uploaded and verified (both commit IDs match).

How the script decides where to upload, and why it never overwrites anything on GitHub:
[05 - Git and GitHub](05-git-and-github.md#how-the-script-decides-where-to-upload).

## The end: summary and final confirmation

1. **Summary**: a short closing speech and two tables of every Docker and Git command used.
2. **Final confirmation screen**:
   - the title **SUCCESS - THE WHOLE PROCESS IS COMPLETE** (green), or
     **FINISHED WITH n PROBLEM(S)** (red),
   - every recorded check with **[PASSED]** or **[FAILED]**,
   - if uploaded: the project page, the automatic tests page, the verified commit ID, and the
     `git clone` command,
   - the total time.

The script's **exit code** is `0` when every check passed, and `1` when one failed.
The automatic tests on GitHub use this to show green or red.

---

**Next:** [05 - Git and GitHub](05-git-and-github.md)
