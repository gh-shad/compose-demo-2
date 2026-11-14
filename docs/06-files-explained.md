# 06 - Every file explained

What each file in this project does, and how the important parts work inside.

**Back to:** [README](../README.md) · **Previous:** [05 - Git and GitHub](05-git-and-github.md) · **Next:** [07 - Commands reference](07-commands-reference.md)

---

## Overview

| File | Runs on | Purpose |
|---|---|---|
| `demo.sh` | Linux (the VM, Codespaces) | The automatic, narrated demo (all 13 parts) |
| `docker-compose.yml` | Linux (Docker) | The application: 4 services, 1 network, 1 volume |
| `html/index.html` | Inside the `web` container | The page that NGINX shows on port 8080 |
| `nginx/security.conf` | Inside the `web` container | Security settings for NGINX: hidden version, security headers |
| `Start-Demo.bat` | Windows | Double-click file. Starts `Start-Demo.ps1` |
| `Start-Demo.ps1` | Windows (PowerShell) | The launcher: VM, copy, browser, demo, GitHub page |
| `cloud-init.yaml` | Linux (first start of the VM) | Installs Docker, Git, gh and the images |
| `.github/workflows/demo-test.yml` | GitHub's computers | Automatic tests after every push |
| `.github/scripts/check-links.py` | GitHub's computers (or any computer with Python 3) | Checks every link in the documentation |
| `.github/dependabot.yml` | GitHub | Monthly update suggestions for the actions, images and Codespaces features |
| `.devcontainer/devcontainer.json` | GitHub Codespaces | What a codespace contains: Docker, Compose, Git, gh, and the ports |
| `results/latest-run.md` | — | The report of the newest run (written by `demo.sh`) |
| `results/run-history.md` | — | One line per run that was saved with Git |
| `.gitignore` | Git | Files that must never be saved |
| `.gitattributes` | Git | Line-ending rules, pictures as binary files |
| `.editorconfig` | Text editors | The same text format (spaces, line endings) in every editor |
| `LICENSE` | — | MIT license |
| `SECURITY.md` | — | The security policy |
| `CITATION.cff` | GitHub | How to cite the project (the **Cite this repository** button) |
| `README.md`, `docs/*.md` | GitHub / any text viewer | The documentation |
| `docs/README.md` | — | The documentation index, with a learning path |
| `docs/images/*.png`, `docs/images/README.md` | — | The screenshots used in the README, and their index |
| `CHANGELOG.md` | — | The version history of the project |

---

## demo.sh

A **bash script** (about 1,750 lines, with comments). It is organised in sections:

| Section | What it contains |
|---|---|
| Header comment | What the script does and all options (`./demo.sh --help` prints it) |
| Settings | Defaults: mode, which parts run, repository name, time limits |
| Options | Reads options like `--slow`, `--git-only` or `--logout` |
| Where it runs | `IN_CODESPACES` (the variable `CODESPACES=true`), `IN_CI` (`GITHUB_ACTIONS=true`), `where_running`, and `app_url`, which gives the right browser address: `https://<codespace>-8080.app.github.dev` in Codespaces, `http://<VM address>:8080` elsewhere |
| Colours and printing helpers | `banner`, `part`, `box`, `typeout` (the typing effect), `ok`, `fail`, `note`, `info` |
| Results | `pass_check`, `fail_check`, `verify`: every important check is recorded for the final screen |
| Pauses | `pause`: waits a few seconds (auto), waits for Enter (manual), or not at all (fast). `reading_time` gives about 3 words per second (2 with `--slow`) |
| `explain`, `notice`, `step`, `run` | `explain` = blue box, `notice` = green result box, `step` = explanation + command + output, `run` = prints `$ command` and runs it |
| Temporary files | `make_tmp_dir` and `remove_tmp_dir` (see [08](08-cleanup-and-safety.md)) |
| Docker helpers | `dc` = `docker compose`, `dk` = `docker` (with `sudo` if needed), `mysql_ready`, `wait_for_mysql`, `project_leftovers` |
| `import_update` | Used only by the Windows launcher (see below) |
| Results | `fact` collects key results while the demo runs. `write_report` writes `results/latest-run.md`. The part timer measures every part |
| `github_logout` | Signs out completely (Part 13 and `--logout`): `gh auth logout`, removes Git's GitHub settings and github.com lines in `~/.git-credentials`, then checks |
| GitHub helpers | `gh_logged_in`, `gh_has_workflow_scope`, `gh_read_account`, `github_login`, `github_add_workflow_scope` |
| `create_files_if_missing` | Re-creates `docker-compose.yml`, `html/index.html`, `.gitignore`, `README.md` and the two `results/` files if one is missing. Existing files are never changed. (A run history from an older version in `docs/demo-runs.md` is moved to `results/run-history.md`) |
| `preflight` | "Getting ready": all checks before the demo |
| `start_screen` | The plan and **Press Enter to start the demo** |
| `part1` ... `part13` | The 13 parts |
| `resolve_target`, `same_history`, `free_repo_name`, `create_repo` | Where to upload: push, fork, connect or create (see [05](05-git-and-github.md#how-the-script-decides-where-to-upload)) |
| `closing`, `final_screen` | The summary speech and the final confirmation |
| Main | Runs everything in order |

### Important details

- **`set -u` and `set -o pipefail`**: bash stops on a misspelled variable name, and a failure
  inside a pipe (`a | b`) is not hidden.
- **The script always works in its own folder** (`cd "$SCRIPT_DIR"`), wherever you start it from.
- **Project name** = the `name:` line of `docker-compose.yml` (`compose-demo`). Docker Compose
  uses it in all names and labels. Without that line, the folder name is used, cleaned up the same
  way Compose does it (lowercase, only `a-z`, `0-9`, `-` and `_`).
- **Images** are always read from the compose file (`docker compose config --images`), so the
  script and the file can never disagree about the versions.
- **No terminal?** (for example on GitHub Actions) Then there are no colours, no screen clearing,
  no waiting for keys, and `docker compose exec` gets `-T`. On GitHub Actions nothing is ever uploaded.
- **In Codespaces** there is no sign-in question and no `gh auth setup-git`: the codespace is
  already signed in. The upload only happens if the codespace belongs to your own project or fork.
- **sudo**: if your user is not allowed to use Docker yet, the script uses `sudo docker` and tells you.
- **Exit code**: `0` if every recorded check passed, `1` if one failed, `130` after Ctrl+C.
- **Ctrl+C**: the script removes its temporary folder and tells you how to remove the containers.

### The checks that are recorded

| Part | Check |
|---|---|
| 5 | All 4 containers running · the website answered on port 8080 · security headers sent, NGINX version hidden |
| 6 | `ping db` worked · `getent hosts db` worked · MySQL ready · Adminer connected (when possible) |
| 7 | 2 students saved · the data survived `down` and `up` |
| 8 | 3 worker copies running |
| 10 | No containers, networks or volumes of the project left · all files unchanged (SHA-256) · temporary folder deleted |
| 11 | Nothing left unsaved · the Git history |
| 12 | Upload verified (commit IDs match) |
| 13 and `--logout` | Signed out of GitHub on this computer (GitHub CLI and Git). In Codespaces: only a temporary codespace key |

---

## Start-Demo.bat and Start-Demo.ps1 (Windows)

`Start-Demo.bat` has one real line:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Demo.ps1" %*
```

| Part | Meaning |
|---|---|
| `powershell` | Start Windows PowerShell |
| `-NoProfile` | Do not load personal PowerShell settings (faster, always the same) |
| `-ExecutionPolicy Bypass` | Allow this one script to run, only for this one time. Your Windows settings are not changed |
| `-File "%~dp0Start-Demo.ps1"` | Run `Start-Demo.ps1` from the same folder as the `.bat` file (`%~dp0` = "this file's folder") |
| `%*` | Pass on any options, for example `Start-Demo.bat --slow` |

`Start-Demo.ps1` then does six things:

| Step | What it does | Commands |
|---|---|---|
| 1 | Checks that Multipass is installed, and that `demo.sh` is in the folder | `Get-Command multipass` |
| 2 | Creates the VM the first time, or starts it | `multipass info`, `multipass launch ... --cloud-init cloud-init.yaml`, `multipass start` |
| 2b | Waits until the VM setup is finished | `multipass exec compose-lab -- cloud-init status --wait`, then reads `~/LAB-READY.txt` |
| 3 | Copies the project into the VM folder `~/compose-demo` | `multipass transfer` (demo.sh), `tar` (packs the rest, **without** any `.git` folder), `multipass transfer`, then `demo.sh --import-update` |
| 4 | Finds the VM's address, and opens the website and Adminer in your browser **as soon as they answer** | `hostname -I`; a background job tries `Invoke-WebRequest` every 2 seconds, then `Start-Process <address>` |
| 5 | Runs the demo inside the VM (with your options, for example `--logout`) | `multipass exec compose-lab -- bash -lc "cd ~/compose-demo && ./demo.sh"` |
| 6 | Opens your GitHub project page | reads `~/.compose-demo-github-url` (written by Part 12) |

**Safety:** before step 1, the launcher compares every option with a list of the known `demo.sh`
options (`$Allowed`). An unknown option stops the launcher with a message, so no other text can
ever reach the VM's command line. In step 6, only an address of the form
`https://github.com/<owner>/<project>` is opened.

The temporary package `compose-demo-update.tar` in your Windows `TEMP` folder is deleted right
after it is copied. Inside the VM, `--import-update` deletes it too.

### What `demo.sh --import-update` does

It copies the files from the package into `~/compose-demo`, **safely**:

- The `.git` folder (your Git history in the VM) is **never touched**.
- `results/latest-run.md` and `results/run-history.md` are **kept** if they already exist (they hold your results).
- `demo.sh` is skipped (the launcher copied it already).
- Before a file is replaced, if its current version is **not safely saved in Git**, a backup is
  made in `~/compose-demo-backups/<date-time>/`.
- Windows line endings (CRLF) are changed to Linux line endings (LF) in scripts, YAML, text and configuration files.
- If the folder is already connected to a GitHub project, the example address `gh-shad/compose-demo-2`
  in the documentation is replaced with the real one again, so Git does not report changes that are not real.
- It unpacks into its own temporary folder (`/tmp/compose-demo-import.XXXXXX`) and deletes it afterwards.

---

## cloud-init.yaml

Multipass gives this file to the new VM. cloud-init runs it **once**, on the first start.

| Key | Meaning |
|---|---|
| `#cloud-config` | The first line must be exactly this. It tells cloud-init what kind of file it is |
| `package_update: true` | Update the list of available Ubuntu packages (`apt-get update`) |
| `packages:` | Install these packages: `ca-certificates` (to trust secure websites), `curl` (to download files), `git` |
| `write_files:` | Write the setup script to `/usr/local/sbin/setup-compose-lab.sh`, owned by `root`, permission `0755` (everyone may run it, only root may change it) |
| `runcmd:` | Run the setup script: `bash /usr/local/sbin/setup-compose-lab.sh` |

The **setup script** (inside `cloud-init.yaml`) does:

| Step | What | How |
|---|---|---|
| 1 | Install Docker Engine + the Compose plugin | From Docker's official package repository (`download.docker.com`). If that fails: Ubuntu's own `docker.io` and `docker-compose-v2` packages |
| 2 | Install the GitHub CLI | From GitHub's official package repository (`cli.github.com`). If that fails: Ubuntu's own `gh` package |
| — | Start Docker and allow the user `ubuntu` to use it | `systemctl enable --now docker`, `usermod -aG docker ubuntu` |
| 3 | Download the 4 images in advance, so the demo works without Wi-Fi | `docker pull nginx:1.30 mysql:8.4 adminer:6 busybox:1.37` |
| 4 | Create the empty project folder | `install -d -o ubuntu -g ubuntu /home/ubuntu/compose-demo` |
| 5 | Write `~/LAB-READY.txt` with the versions | `COMPOSE LAB READY` is the sign that the setup is finished |

It uses `set -euxo pipefail` (stop on any error, print every command into the setup log) and a
`retry` helper that tries downloads and installs again (up to 5 times), because Wi-Fi can be slow.
The setup log is in `/var/log/cloud-init-output.log` inside the VM.

---

## .devcontainer/devcontainer.json (GitHub Codespaces)

A codespace is a Linux computer that GitHub creates for you in the cloud. This file says what it contains.

| Setting | Meaning |
|---|---|
| `"image": "mcr.microsoft.com/devcontainers/base:ubuntu"` | Start from Microsoft's standard Ubuntu image for codespaces |
| `"features": docker-in-docker` | Adds Docker Engine and Docker Compose **inside** the codespace |
| `"features": github-cli` | Adds the GitHub CLI (`gh`) |
| `"hostRequirements"` | At least 2 processor cores and 4 GB of memory |
| `"forwardPorts": [8080, 8081]` | Makes the website and Adminer reachable from your browser (the **Ports** tab) |
| `"portsAttributes"` | Names the ports ("Website", "Adminer") and shows a message when they open |
| `"postCreateCommand"` | After the codespace is created: `chmod +x demo.sh` (make the script runnable) |
| `"postAttachCommand"` | When the terminal opens: prints how to start the demo |
| `"openFiles"` | Opens `README.md` in the editor |

## results/latest-run.md and results/run-history.md

`latest-run.md` is **overwritten** by every run that reaches the end (or Part 11). It has these sections:
a summary table (result, date, where it ran, GitHub account, mode, time), **Checks**, **Key results**,
**Time per part**, **Versions**, and **Run it yourself**.
`run-history.md` gets **one new line** per run that is saved with Git.

## .github/workflows/demo-test.yml

| Line | Meaning |
|---|---|
| `name: Demo test` | The name shown in the Actions tab and on the badge |
| `on: push: branches: [main]` | Run after every push to `main` |
| `on: pull_request:` | Also run for proposed changes (pull requests) |
| `on: workflow_dispatch:` | Adds a **Run workflow** button in the Actions tab |
| `permissions: contents: read` | The tests may only read the project |
| `concurrency: ... cancel-in-progress: true` | A newer run for the same branch stops an older one that is still running |
| `jobs:` | The three jobs (see [05](05-git-and-github.md#github-actions-the-automatic-tests)) |
| `runs-on: ubuntu-latest` / `windows-latest` | Which kind of computer GitHub starts |
| `needs: check-files` | The demo job only starts if the file checks passed |
| `timeout-minutes: 20` | Stop the demo job if it takes longer than 20 minutes (the other jobs: 10 minutes) |
| `uses: actions/checkout@3d3c42e...  # v7.0.1` | GitHub's official step that downloads the project onto the test computer. It is **pinned** to one exact version by its full commit ID, so the code that runs cannot change without a visible update (the comment shows the version) |
| `persist-credentials: false` | After the download, do not keep GitHub's key in the project folder |
| `python3 .github/scripts/check-links.py` | Checks every link in the documentation (a broken link fails the test) |
| `run: ...` | A command to run |
| `if: always()` | Run this step even if an earlier step failed (so the report is always shown) |
| `$GITHUB_STEP_SUMMARY` | A file: whatever is written into it appears on the run's summary page. The workflow writes `results/latest-run.md` into it |
| `uses: actions/upload-artifact@cf430e0...  # v7.0.2` | Saves `results/latest-run.md` as a downloadable file called `demo-results` (kept for 30 days: `retention-days: 30`) |
| `shell: powershell` | Run this step with Windows PowerShell 5.1 (not the newer PowerShell 7) |

---

## .gitignore

```text
.env  .env.*     secret settings (passwords)
*.pem  *.key  *.p12  *.pfx  id_rsa*  id_ed25519*  *.token
                 keys, certificates and tokens: they must never be uploaded
*.log            log files
*.swp  *~        temporary files of text editors
.DS_Store        a hidden file macOS creates
Thumbs.db        a hidden file Windows creates
*.tar  *.bundle  update packages
```

`*` means "any text". So `*.log` matches every file that ends with `.log`.

## .gitattributes

```text
*      text=auto eol=lf     every text file is stored with Linux line endings (LF)
*.bat  text eol=crlf        Windows batch files use Windows line endings (CRLF)
*.ps1  text eol=crlf        PowerShell files too
*.png  *.jpg  *.ico  binary pictures: Git never changes a single byte in them
```

**Why?** Windows ends each line with two invisible characters (CRLF), Linux with one (LF).
A bash script with Windows line endings fails with errors like `$'\r': command not found`.
These rules keep every file correct, even when the project is downloaded on Windows.

## LICENSE

The **MIT License**: anyone may use, copy, change and share the project, also for free,
as long as the license text stays with it. There is no warranty.

## html/index.html

A single web page with its own styles (no extra files). It explains the four services.
The `web` container shows it, because the compose file mounts the `html` folder into NGINX.

## nginx/security.conf

Five settings that NGINX loads at start (the compose file mounts the file read-only into
`/etc/nginx/conf.d/`). `server_tokens off;` hides the NGINX version, and four `add_header` lines
send security headers with every page. Each line is explained in
[03 - The compose file](03-docker-compose-file.md#the-security-settings).

## .github/dependabot.yml

Tells **Dependabot** (GitHub's update robot) to check once a month for newer versions of three
kinds of outside parts, and to open a pull request for each update:

| `package-ecosystem` | What is checked |
|---|---|
| `github-actions` | The actions in the workflow (their pinned commit IDs) |
| `docker-compose` | The images in `docker-compose.yml`. MySQL stays on 8.4 (`ignore` major versions) |
| `devcontainers` | The features in `.devcontainer/devcontainer.json` |

The automatic tests run on every Dependabot pull request: merge it only when they are green.

## .github/scripts/check-links.py

A small Python program. It reads every `.md` file of the project and checks each link to another
file (the file must exist) and to a heading (the heading must exist, written the way GitHub turns
headings into link names). Links to websites are not checked. Run it yourself with
`python3 .github/scripts/check-links.py`.

## .editorconfig

Most editors (VS Code, the Codespaces editor, Notepad++, ...) read this file and then use the
same format as the project: UTF-8, Linux line endings (Windows ones for `.bat` and `.ps1`),
2 spaces for indentation, no spaces at line ends.

## SECURITY.md and CITATION.cff

[SECURITY.md](../SECURITY.md) is the **security policy**: every protection, the demo-only
choices, and how to report a problem privately. GitHub shows it in the project's **Security** tab.
`CITATION.cff` describes how to cite the project in a report. GitHub reads it and shows a
**Cite this repository** button on the project page.


---

**Next:** [07 - Commands reference](07-commands-reference.md)
