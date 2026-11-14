# Docker Compose Demo: Running Multi-Container Applications

[![Demo test](https://github.com/gh-shad/compose-demo-2/actions/workflows/demo-test.yml/badge.svg)](https://github.com/gh-shad/compose-demo-2/actions/workflows/demo-test.yml)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/gh-shad/compose-demo-2?quickstart=1)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![For beginners](https://img.shields.io/badge/level-beginner-brightgreen)

> **A fully automatic demo that teaches Docker Compose, Git and GitHub from zero.**
> Type one command (or double-click one file) and press **Enter** once. The script runs every
> command by itself, explains each one in simple English, checks every result, writes a report,
> and can upload the project and your results to **your own** GitHub account.

**For students and teachers.** No experience needed. Every word is explained in [docs/02-concepts.md](docs/02-concepts.md).

---

## Contents

1. [What is this project?](#1-what-is-this-project)
2. [Quick start: choose one way](#2-quick-start-choose-one-way)
3. [What happens when you run it](#3-what-happens-when-you-run-it)
4. [Your results](#4-your-results)
5. [GitHub: where your work is uploaded](#5-github-where-your-work-is-uploaded)
6. [Signing out of GitHub](#6-signing-out-of-github)
7. [How the application looks](#7-how-the-application-looks)
8. [The project files](#8-the-project-files)
9. [Options](#9-options)
10. [Safety: what is deleted, and what is never deleted](#10-safety-what-is-deleted-and-what-is-never-deleted)
11. [Full documentation](#11-full-documentation)
12. [About this project](#12-about-this-project)

---

## 1. What is this project?

Most real applications are **several programs that work together**: a website, a database and
some helpers. **Docker Compose** describes all of them in **one file** (`docker-compose.yml`) and
starts them with **one command**.

The script `demo.sh` is a live, self-explaining lesson. It:

1. starts an application of **4 containers** (website, database, database viewer, helper),
2. proves that they **talk to each other**, that the **data survives** a restart, and that a service can be **scaled**,
3. **cleans up** everything temporary and proves with SHA-256 fingerprints that **no file was damaged**,
4. writes a **results report** (`results/latest-run.md`),
5. saves everything with **Git**, uploads it to **your GitHub**, and **verifies** the upload,
6. ends with a **final screen** that shows every check, the key results and your project link.

Before every command, a box explains what it does. After it, a box explains the result.

---

## 2. Quick start: choose one way

| | Way | Install | GitHub sign-in | Best for |
|---|---|---|---|---|
| **A** | [GitHub Codespaces](#a-github-codespaces-recommended-nothing-to-install) | Nothing | Automatic | Students and teachers, any computer, even a tablet |
| **B** | [Windows, one click](#b-windows-one-click-offline-classroom-demo) | Multipass | One-time code | Presenting in class, works without Wi-Fi after setup |
| **C** | [Any Linux with Docker](#c-any-linux-computer-with-docker) | Docker, Git, gh | One-time code | People who already use Linux |
| **D** | [Just watch it](#d-just-watch-it-nothing-to-install-no-account-needed) | Nothing | Not needed | Seeing a complete real run in 1 minute |

### A. GitHub Codespaces (recommended, nothing to install)

A **codespace** is a free computer in the cloud that opens in your browser. It already has Docker,
Git and the GitHub CLI, and it is already signed in to your GitHub account.
Free GitHub accounts include a monthly amount of free Codespaces time.

1. Sign in to <https://github.com> (make a free account if you have none).
2. On this page, click **Fork** (top right) → **Create fork**. Now you have your own copy.
3. On **your fork**, click the green **Code** button → **Codespaces** → **Create codespace on main**.
4. Wait 1 to 2 minutes. In the terminal at the bottom, type:

   ```bash
   ./demo.sh
   ```

5. Press **Enter** when it says **Press Enter to start the demo**. Everything else is automatic.
   The website and Adminer appear in the **Ports** tab (ports 8080 and 8081).
   At the end, your results are in **your fork** on GitHub.

Just want to try it, without saving anything? Click the **Open in GitHub Codespaces** badge at the top.
(The demo runs completely. Only the upload is skipped, because the codespace is not on your own fork.)

When you are done, stop the codespace at <https://github.com/codespaces> to save your free hours.

### B. Windows, one click (offline classroom demo)

You need Windows 10 or 11 **Pro** (it uses Hyper-V).

1. Install **Multipass** from <https://canonical.com/multipass/install> and restart Windows.
2. Download this project: **Code** → **Download ZIP**, then right-click it → **Extract All**.
3. Double-click **`Start-Demo.bat`**. The first time, it builds the demo VM (about 10 minutes).
4. It asks if you want to upload to GitHub. Type **y** for a one-time sign-in with a code, or press **Enter** for No.
5. Press **Enter** to start. The website and Adminer open in your browser by themselves.

Every click is explained in [docs/01-setup-from-zero.md](docs/01-setup-from-zero.md).

### C. Any Linux computer with Docker

```bash
git clone https://github.com/<you>/compose-demo.git    # clone your fork
cd compose-demo
./demo.sh
```

You need Docker with the Compose plugin (`docker compose version` must work) and Git.
The GitHub CLI (`gh`) is only needed for the upload.

### D. Just watch it (nothing to install, no account needed)

GitHub runs the whole demo by itself after every upload. Open the
[**Actions** tab](https://github.com/gh-shad/compose-demo-2/actions), click the newest
**Demo test** run, and scroll down: the **results report** is on the summary page.
Click **Run the whole Docker demo** → **Run demo.sh** to see every command and explanation.

---

## 3. What happens when you run it

About **15 minutes** at normal speed (`./demo.sh --fast` takes about 2 minutes).

| Part | Title | What happens |
|---|---|---|
| Start | Getting ready | Checks Docker, Compose, images, Git and GitHub. Makes a SHA-256 fingerprint of every file |
| 1 | Opening | What the demo is about |
| 2 | The problem | Why starting many containers by hand is hard |
| 3 | Three building blocks | Services, networks and volumes, with a diagram |
| 4 | The YAML file | `docker-compose.yml`, explained line by line |
| 5 | Start the whole app | `docker compose up -d`, `docker compose ps`, the web page |
| 6 | Containers talking | `ping db`, `getent hosts db`, Adminer connects to the database |
| 7 | Data survives a restart | Save data, delete all containers, start again: the data is still there |
| 8 | Scaling and logs | `--scale worker=3` and `docker compose logs` |
| 9 | Stop and remove the app | `docker compose down --volumes` |
| 10 | Clean up and safety check | Removes everything temporary, checks every file with SHA-256 |
| 11 | Save with Git | Writes the results report, then `git init`, `add`, `commit`, `log`, `diff` |
| 12 | Upload to GitHub | `git push` (or a fork, or a new project), then proof that GitHub has the same commit |
| End | Final confirmation | Every check, the key results, the time, and your project and report links |

Every command of every part: [docs/04-demo-walkthrough.md](docs/04-demo-walkthrough.md).

---

## 4. Your results

Every run writes real results, not just messages on the screen:

| Where | What |
|---|---|
| **The final screen** | Every check with **PASSED** / **FAILED**, the key results (page title, ping result, database address, MySQL version, data before and after the restart, worker names, files checked), the total time, and your GitHub links |
| [`results/latest-run.md`](results/latest-run.md) | The full report of the newest run: result, date, where it ran, every check, key results, time per part, tool versions |
| [`results/run-history.md`](results/run-history.md) | One line per run |
| On GitHub | The same files in **your** project, plus the **Actions** tab (report on the summary page, downloadable under **Artifacts**) |

Example of the final screen:

```text
+==============================================================================+
|                   SUCCESS - THE WHOLE PROCESS IS COMPLETE                    |
+==============================================================================+
  Result of every check (15 passed, 0 failed):
    [PASSED] All 4 containers started and are running
    ...
  Execution results:
    Network test: ping db from the worker:          3 packets transmitted, 3 packets received, 0% packet loss
    Students found after down + up (volume test):   2
    ...
  The project and the results have been uploaded to GitHub, and the upload was verified.
    Project page:      https://github.com/<you>/compose-demo
    Results report:    https://github.com/<you>/compose-demo/blob/main/results/latest-run.md
```

---

## 5. GitHub: where your work is uploaded

The upload is **optional** and always goes to **your own** account. The script never overwrites
or deletes anything on GitHub (it never uses `git push --force`).

| Your situation | What the script does |
|---|---|
| You work in **your fork** or your own project | `git push` into it |
| You downloaded **someone else's** project with `git clone` | `gh repo fork --remote`: creates **your fork**, then pushes into it |
| You downloaded the ZIP (no Git connection yet) | `gh repo create compose-demo --public ...`: creates your project |
| The name is already used by a different project | Uses a free name: `compose-demo-2`, ... |
| A codespace on someone else's project | Skips the upload and tells you to fork first |
| Not signed in, or you answered No | Saves everything with Git on the computer only |

How it decides, and how to do every step yourself (fork, push, **pull**, sync, pull requests):
[docs/05-git-and-github.md](docs/05-git-and-github.md) and [docs/10-github-by-hand.md](docs/10-github-by-hand.md).

---

## 6. Signing out of GitHub

Signing out on the github.com **website does not sign out the VM or terminal**. The GitHub CLI keeps
its own key (a token) on that computer, and Git is set up to use it. Sign out completely with:

```bash
./demo.sh --logout          # in the VM, Linux or a terminal
Start-Demo.bat --logout     # on Windows, for the Multipass VM
```

It removes the key and Git's GitHub settings, checks that you are signed out, and shows the last
step on the website (**revoke** the key at <https://github.com/settings/applications>).
For shared computers: `./demo.sh --logout-after` uploads, then signs out.
In Codespaces nothing is stored on your computer: just stop the codespace.

Details: [docs/10-github-by-hand.md](docs/10-github-by-hand.md#signing-in-and-signing-out).

---

## 7. How the application looks

```mermaid
flowchart LR
    browser1(["Browser: port 8080"]) --> web
    browser2(["Browser: port 8081"]) --> adminer
    subgraph net ["app-network (the private road between the containers)"]
        web["web: NGINX web server"]
        adminer["adminer: database viewer"]
        worker["worker: BusyBox helper"]
        db[("db: MySQL 8.4 database")]
    end
    web -. "finds 'db' by name" .-> db
    adminer -- "connects to 'db'" --> db
    worker -- "ping db" --> db
    db --- volume[("db-data volume: the safe locker for the data")]
```

| Service | Image | What it does | How to reach it |
|---|---|---|---|
| `web` | `nginx:latest` | A web server. Shows `html/index.html` | Port **8080** |
| `db` | `mysql:8.4` | A MySQL database. Keeps its data in the `db-data` volume | Only inside the network, by the name `db` |
| `adminer` | `adminer:latest` | A web page to look inside the database | Port **8081** |
| `worker` | `busybox:latest` | Prints a message every 5 seconds. Used to show scaling | (no port) |

---

## 8. The project files

```text
compose-demo/
├── README.md                  <- this page
├── demo.sh                    <- the automatic demo script
├── docker-compose.yml         <- the application: 4 services, 1 network, 1 volume
├── html/index.html            <- the web page of the web container
├── results/
│   ├── latest-run.md          <- the report of the newest run (written by demo.sh)
│   └── run-history.md         <- one line per run
├── .devcontainer/
│   └── devcontainer.json      <- the settings for GitHub Codespaces
├── .github/workflows/
│   └── demo-test.yml          <- automatic tests that GitHub runs after every upload
├── Start-Demo.bat             <- double-click this on Windows
├── Start-Demo.ps1             <- the Windows launcher (Start-Demo.bat runs it)
├── cloud-init.yaml            <- sets up the Linux VM: installs Docker, Git and gh
├── docs/                      <- the full documentation
├── .gitignore                 <- files that Git must never upload
├── .gitattributes             <- line-ending rules for Windows and Linux files
└── LICENSE                    <- MIT license
```

Every file explained: [docs/06-files-explained.md](docs/06-files-explained.md).

---

## 9. Options

| Option | What it does |
|---|---|
| *(none)* | Automatic: press Enter once, then it runs by itself |
| `--slow` | Automatic, with more time to read each explanation |
| `--manual` | Waits for Enter before every step (good for presenting) |
| `--fast` | No pauses (about 2 minutes) |
| `--setup` | Only the checks and the one-time GitHub sign-in |
| `--keep` | Leaves the containers running at the end, so you can explore them |
| `--no-git` | Docker part and clean up only (Parts 1 to 10) |
| `--git-only` | Clean up, Git and GitHub only (Parts 10 to 12) |
| `--no-push` | Uses Git, but does not upload |
| `--push` | Signs in to GitHub without asking first |
| `--logout` | Signs out of GitHub on this computer, completely |
| `--logout-after` | Uploads, then signs out (for shared computers) |
| `--help` | Shows the list of options |

While it runs: **Enter** skips the current pause, **p** pauses, **Ctrl+C** stops.
On Windows, add options to the launcher: `Start-Demo.bat --slow`.

---

## 10. Safety: what is deleted, and what is never deleted

Part 10 cleans up **before** anything is uploaded, with one rule: **only remove what this demo created.**

| Removed | Never touched |
|---|---|
| This project's containers, network and volume (found by their Docker label) | Your other Docker containers, images and projects |
| The script's own temporary folder `/tmp/compose-demo-run.XXXXXX` (the path is checked first) | Any other file or folder |
| Old update packages of the Windows launcher in `/tmp` | The project files (they are checked with SHA-256 instead) |
| | Your Git history, and anything on GitHub |

The 4 Docker images are kept on purpose, so the next run works without internet.
Details: [docs/08-cleanup-and-safety.md](docs/08-cleanup-and-safety.md).

---

## 11. Full documentation

| Document | What is inside |
|---|---|
| [01 - Setup from zero](docs/01-setup-from-zero.md) | Every step for Codespaces, Windows, macOS and Linux |
| [02 - Concepts](docs/02-concepts.md) | Every idea and word, explained simply |
| [03 - The docker-compose.yml file](docs/03-docker-compose-file.md) | The application file, line by line |
| [04 - Demo walkthrough](docs/04-demo-walkthrough.md) | All 12 parts: every command, what it does, and what you see |
| [05 - Git and GitHub](docs/05-git-and-github.md) | How the script saves, uploads and verifies, and the automatic tests |
| [06 - Every file explained](docs/06-files-explained.md) | What each file does |
| [07 - Commands reference](docs/07-commands-reference.md) | Every command, in one place |
| [08 - Clean up and safety](docs/08-cleanup-and-safety.md) | What is created, removed and protected |
| [09 - Troubleshooting](docs/09-troubleshooting.md) | Problems, fixes, questions and answers |
| [10 - GitHub by hand](docs/10-github-by-hand.md) | Fork, clone, change, run Compose again, push, pull, sync, sign out |

---

## 12. About this project

Made by **Mohamed Shadhil H**, B.Tech CSE (Cyber Security), as a classroom demonstration of
running multi-container applications with Docker Compose.

Free to use, copy, change and share under the [MIT License](LICENSE). If it helped you, give it a star.
