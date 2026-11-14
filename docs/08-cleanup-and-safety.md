# 08 - Clean up and safety

The demo creates containers, a network, a volume and some temporary files. This page lists
**everything** it creates, **when** each thing is removed, and the **safety rules** that protect
your own files and data.

**Back to:** [README](../README.md) · **Previous:** [07 - Commands reference](07-commands-reference.md) · **Next:** [09 - Troubleshooting](09-troubleshooting.md)

---

## The one rule

> **The script only removes what this demo created. It never removes anything else.**

---

## Everything the demo creates

| What | Where | Created in | Removed in | Why it is removed / kept |
|---|---|---|---|---|
| 4 containers (`web`, `db`, `adminer`, `worker`) + 2 extra workers | Docker, inside the VM | Parts 5, 7, 8 | Part 9 (and checked in Part 10) | Not needed after the demo |
| Network `compose-demo_app-network` | Docker | Part 5 | Part 9 / 10 | Not needed after the demo |
| Volume `compose-demo_db-data` (the demo database) | Docker | Part 5 | Part 9 / 10 | Only demo data (two names) |
| Temporary folder `/tmp/compose-demo-run.XXXXXX` with `fingerprint.sha256` and `page.html` | VM | Getting ready | Part 10 | Only needed while the demo runs |
| `compose-demo-update.tar` | Windows `TEMP` folder | Launcher | Launcher, right after copying | Only a transport package |
| `/tmp/compose-demo-update.tar` and `/tmp/compose-demo-import.XXXXXX` | VM | Launcher | `--import-update` right away (Part 10 removes any old leftovers) | Only a transport package |
| `results/latest-run.md` (the report) and one new line in `results/run-history.md` | Project | Part 11 (or the end, without Git) | **Kept** | They are your results |
| Git commits | `.git` in the project | Part 11 | **Kept** | That is the whole point of Git |
| Your project on GitHub | github.com | Part 12 | **Kept** | That is the goal |
| `~/.compose-demo-github-url` (one line: your project's address) | VM | Part 12 | Replaced at the next run | The launcher reads it to open your GitHub page |
| The 4 images | Docker | `cloud-init.yaml` | **Kept** | Needed for the next run, even without internet |
| Backups `~/compose-demo-backups/<date-time>/` | VM | `--import-update`, only if needed | **Kept** | They protect your unsaved changes |
| GitHub sign-in: gh's key in `~/.config/gh/hosts.yml`, Git's setting in `~/.gitconfig` | VM / Linux | The sign-in in "Getting ready" | **Part 13** (after the upload), then checked | Nobody who uses the computer next can use your account. Kept only with `--stay-signed-in` |

---

## How each safety rule works

### 1. Docker: only things with this project's label

Docker Compose puts a **label** on everything it creates:
`com.docker.compose.project=compose-demo`. The clean up uses only commands that work on
**this project**:

```bash
docker compose down --volumes --remove-orphans
docker ps -a       --filter label=com.docker.compose.project=compose-demo
docker network ls  --filter label=com.docker.compose.project=compose-demo
docker volume ls   --filter label=com.docker.compose.project=compose-demo
```

The script **never** uses commands that clean up the **whole** computer, like
`docker system prune`, `docker volume prune` or `docker rm -f $(docker ps -aq)`.
Your other containers, images, volumes and projects are never touched. Part 10 even shows
how many other containers exist, and that they were left alone.

### 2. Temporary files: one private folder, checked before deleting

- The script creates its temporary folder with `mktemp -d /tmp/compose-demo-run.XXXXXX`.
  `mktemp` makes a **new** folder with a random name that nobody else uses.
- Before `rm -rf`, the function `remove_tmp_dir` checks **three** things:
  1. the path really looks like `/tmp/compose-demo-run.` followed by exactly 6 characters,
  2. it really is a folder,
  3. it belongs to the current user.
- If any check fails, **nothing is deleted**.
- Old launcher packages are only removed if they are in `/tmp`, belong to the current user, and
  have the exact names `compose-demo-update*.tar` or `compose-demo-import.XXXXXX`.

### 3. Project files: SHA-256 fingerprints

- In "Getting ready", the script makes a **SHA-256 fingerprint** of **every** project file
  (everything except the `.git` folder).
- In Part 10, **before** anything is uploaded, it checks all files again:
  `sha256sum --check --quiet fingerprint.sha256`.
- If a file is missing or changed, the check is **FAILED** and you see which file.
- The project files are **never deleted** by the clean up. They are only checked.

### 4. Your Git history

- The clean up never touches the `.git` folder.
- The Windows launcher's copy step (`--import-update`) skips `.git` completely.
- If a file in the VM has changes that are **not saved in Git**, it is backed up to
  `~/compose-demo-backups/<date-time>/` **before** it is replaced.

### 5. GitHub: never overwrite, never delete

- The script uses a normal `git push`. It **never** uses `git push --force`.
- If GitHub has changes that your computer does not have, GitHub refuses the push. The script
  then uploads to a **new** name (`compose-demo-2`, ...) instead of overwriting anything.
- If a different project already has the name, the script also uses a new name.
- If the folder was downloaded from someone else's project, it creates **your own fork** (`gh repo fork`).
  In Codespaces, it only uploads into a codespace of your own project or fork.
- The script never deletes a repository.

---

### 6. Your GitHub sign-in

Signing in stores a key on the computer. The script never shows it in full (`gh auth status`
prints `gho_****`), never writes it into the project, and never uploads it. `.gitignore` also keeps
`.env` files out of Git. **Part 13** removes the key and Git's GitHub settings after the upload, and
then **checks** that you are signed out (`./demo.sh --logout` does the same at any time). Why signing out on the website is not enough:
[10 - Signing in and signing out](10-github-by-hand.md#signing-in-and-signing-out).

### 7. Hardened containers

The containers themselves are locked down as far as the demo allows (details in
[03 - The compose file](03-docker-compose-file.md#the-security-settings)):

| Setting | Effect |
|---|---|
| Fixed image versions (`nginx:1.30`, `mysql:8.4`, `adminer:6`, `busybox:1.37`) | Every run uses the same, tested programs |
| `security_opt: no-new-privileges:true` on every service | No program inside a container can give itself more rights |
| `read_only: true` on the worker | Its files cannot be changed |
| `:ro` on both bind mounts | The containers cannot change the project's files |
| No `ports:` for `db` | The database cannot be reached from outside |
| `nginx/security.conf` | The NGINX version is hidden and four security headers are sent. Part 5 checks this live with `curl -sI` |

### 8. The Windows launcher accepts only known options

`Start-Demo.ps1` passes your options to `demo.sh` inside the VM. Before it does, it compares each
option with the list of known options. Anything else (for example a typing mistake, or text that
tries to run another command) stops the launcher with a message. Nothing is sent to the VM.

### 9. The GitHub project

| Protection | Effect |
|---|---|
| Secret scanning with push protection | GitHub refuses an upload that contains a known type of key or token |
| Branch rule for `main` | `main` cannot be deleted and cannot be force-pushed, so its history is safe |
| Dependabot alerts and updates | Warnings about known problems in the actions and images, and monthly update suggestions |
| Private vulnerability reporting | Anyone can report a security problem privately (Security tab → **Report a vulnerability**) |
| Pinned actions, read-only permissions | The automatic tests cannot change the project, and their code cannot change unnoticed |

Everything in one place, plus the choices that are made only for the demo: [SECURITY.md](../SECURITY.md).

---

## Cleaning up more, by hand

These commands remove more than the demo does. Use them only if you really want to.

| Goal | Command | Where |
|---|---|---|
| Remove this project's containers, network and volume | `docker compose down --volumes --remove-orphans` | VM, in `~/compose-demo` |
| Remove the 4 images (they must be downloaded again next time) | `docker image rm nginx:1.30 mysql:8.4 adminer:6 busybox:1.37` | VM |
| Remove the backups made by the launcher | `rm -rf ~/compose-demo-backups` (look inside first!) | VM |
| Sign out of GitHub on this VM, completely (if you used `--stay-signed-in`, or stopped before Part 13) | `./demo.sh --logout` (or `Start-Demo.bat --logout` on Windows) | VM |
| Cancel the GitHub CLI key on GitHub itself (all devices) | <https://github.com/settings/applications> → **GitHub CLI** → **Revoke access** | Browser |
| Delete the whole VM | `multipass delete compose-lab` then `multipass purge` | Windows / macOS / Linux |
| Delete your project on GitHub | On github.com: your project → **Settings** → bottom of the page → **Delete this repository**. This cannot be undone | Browser |

Deleting the VM does **not** delete your project on GitHub, and deleting your project on GitHub
does **not** delete the VM.

---

**Next:** [09 - Troubleshooting](09-troubleshooting.md)
