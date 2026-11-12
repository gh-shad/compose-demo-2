# 06 - Every file explained

What each file in this project does, and how the important parts work inside.

**Back to:** [README](../README.md) · **Previous:** [05 - Git and GitHub](05-git-and-github.md) · **Next:** [07 - Commands reference](07-commands-reference.md)

---

## Overview

| File | Runs on | Purpose |
|---|---|---|
| `demo.sh` | Linux (the VM) | The automatic, narrated demo (all 12 parts) |
| `docker-compose.yml` | Linux (Docker) | The application: 4 services, 1 network, 1 volume |
| `html/index.html` | Inside the `web` container | The page that NGINX shows on port 8080 |
| `Start-Demo.bat` | Windows | Double-click file. Starts `Start-Demo.ps1` |
| `Start-Demo.ps1` | Windows (PowerShell) | The launcher: VM, copy, browser, demo, GitHub page |
| `cloud-init.yaml` | Linux (first start of the VM) | Installs Docker, Git, gh and the images |
| `.github/workflows/demo-test.yml` | GitHub's computers | Automatic tests after every push |
| `.gitignore` | Git | Files that must never be saved |
| `.gitattributes` | Git | Line-ending rules |
| `LICENSE` | — | MIT license |
| `README.md`, `docs/*.md` | GitHub / any text viewer | The documentation |
| `docs/demo-runs.md` | — | One line per demo run that was saved with Git |

---

## demo.sh

A **bash script** (about 1,450 lines, with comments). It is organised in sections:

| Section | What it contains |
|---|---|
| Header comment | What the script does and all options (`./demo.sh --help` prints it) |
| Settings | Defaults: mode, which parts run, repository name, time limits |
| Options | Reads options like `--slow` or `--git-only` |
| Colours and printing helpers | `banner`, `part`, `box`, `typeout` (the typing effect), `ok`, `fail`, `note`, `info` |
| Results | `pass_check`, `fail_check`, `verify`: every important check is recorded for the final screen |
| Pauses | `pause`: waits a few seconds (auto), waits for Enter (manual), or not at all (fast). `reading_time` gives about 3 words per second (2 with `--slow`) |
| `explain`, `notice`, `step`, `run` | `explain` = blue box, `notice` = green result box, `step` = explanation + command + output, `run` = prints `$ command` and runs it |
| Temporary files | `make_tmp_dir` and `remove_tmp_dir` (see [08](08-cleanup-and-safety.md)) |
| Docker helpers | `dc` = `docker compose`, `dk` = `docker` (with `sudo` if needed), `mysql_ready`, `wait_for_mysql`, `project_leftovers` |
| `import_update` | Used only by the Windows launcher (see below) |
| GitHub helpers | `gh_logged_in`, `gh_has_workflow_scope`, `gh_read_account`, `github_login`, `github_add_workflow_scope` |
| `create_files_if_missing` | Re-creates `docker-compose.yml`, `html/index.html`, `.gitignore`, `README.md` and `docs/demo-runs.md` if one is missing. Existing files are never changed |
| `preflight` | "Getting ready": all checks before the demo |
| `start_screen` | The plan and **Press Enter to start the demo** |
| `part1` ... `part12` | The 12 parts |
| `resolve_target`, `same_history`, `free_repo_name`, `create_repo` | Where to upload (see [05](05-git-and-github.md#how-the-script-decides-where-to-upload)) |
| `closing`, `final_screen` | The summary speech and the final confirmation |
| Main | Runs everything in order |

### Important details

- **`set -u` and `set -o pipefail`**: bash stops on a misspelled variable name, and a failure
  inside a pipe (`a | b`) is not hidden.
- **The script always works in its own folder** (`cd "$SCRIPT_DIR"`), wherever you start it from.
- **Project name** = the folder name, for example `compose-demo`. Docker Compose uses it in all
  names and labels.
- **No terminal?** (for example on GitHub Actions) Then there are no colours, no screen clearing,
  no waiting for keys, and `docker compose exec` gets `-T`.
- **sudo**: if your user is not allowed to use Docker yet, the script uses `sudo docker` and tells you.
- **Exit code**: `0` if every recorded check passed, `1` if one failed, `130` after Ctrl+C.
- **Ctrl+C**: the script removes its temporary folder and tells you how to remove the containers.

### The checks that are recorded

| Part | Check |
|---|---|
| 5 | All 4 containers running · the website answered on port 8080 |
| 6 | `ping db` worked · `getent hosts db` worked · MySQL ready · Adminer connected (when possible) |
| 7 | 2 students saved · the data survived `down` and `up` |
| 8 | 3 worker copies running |
| 10 | No containers, networks or volumes of the project left · all files unchanged (SHA-256) · temporary folder deleted |
| 11 | Nothing left unsaved · the Git history |
| 12 | Upload verified (commit IDs match) |

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
| 5 | Runs the demo inside the VM | `multipass exec compose-lab -- bash -lc "cd ~/compose-demo && ./demo.sh"` |
| 6 | Opens your GitHub project page | reads `~/.compose-demo-github-url` (written by Part 12) |

The temporary package `compose-demo-update.tar` in your Windows `TEMP` folder is deleted right
after it is copied. Inside the VM, `--import-update` deletes it too.

### What `demo.sh --import-update` does

It copies the files from the package into `~/compose-demo`, **safely**:

- The `.git` folder (your Git history in the VM) is **never touched**.
- `docs/demo-runs.md` is **kept** if it already exists (it holds your run history).
- `demo.sh` is skipped (the launcher copied it already).
- Before a file is replaced, if its current version is **not safely saved in Git**, a backup is
  made in `~/compose-demo-backups/<date-time>/`.
- Windows line endings (CRLF) are changed to Linux line endings (LF) in scripts, YAML and text files.
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
| 3 | Download the 4 images in advance, so the demo works without Wi-Fi | `docker pull nginx:latest mysql:8.4 adminer:latest busybox:latest` |
| 4 | Create the empty project folder | `install -d -o ubuntu -g ubuntu /home/ubuntu/compose-demo` |
| 5 | Write `~/LAB-READY.txt` with the versions | `COMPOSE LAB READY` is the sign that the setup is finished |

It uses `set -euxo pipefail` (stop on any error, print every command into the setup log) and a
`retry` helper that tries downloads and installs again (up to 5 times), because Wi-Fi can be slow.
The setup log is in `/var/log/cloud-init-output.log` inside the VM.

---

## .github/workflows/demo-test.yml

| Line | Meaning |
|---|---|
| `name: Demo test` | The name shown in the Actions tab and on the badge |
| `on: push: branches: [main]` | Run after every push to `main` |
| `on: pull_request:` | Also run for proposed changes (pull requests) |
| `on: workflow_dispatch:` | Adds a **Run workflow** button in the Actions tab |
| `permissions: contents: read` | The tests may only read the project |
| `jobs:` | The three jobs (see [05](05-git-and-github.md#github-actions-the-automatic-tests)) |
| `runs-on: ubuntu-latest` / `windows-latest` | Which kind of computer GitHub starts |
| `needs: check-files` | The demo job only starts if the file checks passed |
| `timeout-minutes: 20` | Stop the demo job if it takes longer than 20 minutes |
| `uses: actions/checkout@v5` | GitHub's official step that downloads the project onto the test computer |
| `run: ...` | A command to run |
| `shell: powershell` | Run this step with Windows PowerShell 5.1 (not the newer PowerShell 7) |

---

## .gitignore

```text
.env  .env.*     secret settings (passwords)
*.log            log files
*.swp  *~        temporary files of text editors
.DS_Store        a hidden file macOS creates
Thumbs.db        a hidden file Windows creates
*.tar            update packages of the Windows launcher
```

`*` means "any text". So `*.log` matches every file that ends with `.log`.

## .gitattributes

```text
*      text=auto eol=lf     every text file is stored with Linux line endings (LF)
*.bat  text eol=crlf        Windows batch files use Windows line endings (CRLF)
*.ps1  text eol=crlf        PowerShell files too
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

## docs/demo-runs.md

A table with one line per demo run that was saved with Git (Part 11 adds the line).
It is a real, small example of a tracked change.

---

**Next:** [07 - Commands reference](07-commands-reference.md)
