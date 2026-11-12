# Docker Compose Demo: Running Multi-Container Applications

A fully automatic, narrated demo. Press Enter once, and `demo.sh` runs every
command by itself and explains each one in simple English:

- **Parts 1–9: Docker Compose.** Start a 4-container app (website, database, Adminer,
  worker), show the containers talking by name, prove the data survives a restart
  (volume), scale the worker to 3 copies, and clean up.
- **Parts 10–11: Git + GitHub.** Save the project and its history with Git, then
  upload it to GitHub with the GitHub CLI (`gh`).

## Files

| File | What it is |
|---|---|
| `demo.sh` | The automatic demo script (runs inside Linux) |
| `docker-compose.yml` | The application: web (NGINX), db (MySQL 8.4), adminer, worker (BusyBox) |
| `html/index.html` | The page shown by the web container on port 8080 |
| `.gitignore` | Files Git must never save (logs, `.env`) |
| `Start-Demo.bat` + `Start-Demo.ps1` | One-click launcher for Windows (uses Multipass) |

## Tools

- **Multipass** on Windows: creates a small Ubuntu virtual machine (VM)
- Inside the VM (installed automatically by `cloud-init.yaml`):
  **Docker** + Compose plugin, **Git**, **GitHub CLI (`gh`)**
- A free **GitHub account**

## Run it (Windows, one click)

Put `Start-Demo.bat`, `Start-Demo.ps1`, `cloud-init.yaml` and `demo.sh` in one folder,
then double-click **Start-Demo.bat**. It creates/starts the VM, opens the browser pages
when they are ready, runs the demo, and opens the GitHub page at the end.
The first time only, it asks you to log in to GitHub (a one-time code in the browser).

## Run it (inside Linux / the VM)

```bash
cd compose-demo
./demo.sh             # automatic: press Enter once, then it runs by itself
./demo.sh --slow      # automatic, more time to read each step
./demo.sh --manual    # press Enter before every step
./demo.sh --fast      # quick practice run, no pauses
./demo.sh --setup     # one-time checks + GitHub login, then stop
./demo.sh --keep      # leave the containers running at the end
./demo.sh --no-git    # Docker part only (Parts 1-9)
./demo.sh --git-only  # Git + GitHub part only (Parts 10-11)
./demo.sh --no-push   # Git, but no upload to GitHub
```

While it runs: **Enter** skips a pause, **p** pauses, **Ctrl+C** stops.

Website: `http://<vm-ip>:8080`. Adminer: `http://<vm-ip>:8081`
(System MySQL, Server `db`, Username `root`, Password `examplepassword`).

## Git and GitHub by hand

```bash
git config --global user.name "Your Name"
git config --global user.email "ID+username@users.noreply.github.com"
git init -b main
git add .
git commit -m "Add Docker Compose multi-container demo"
gh auth login --hostname github.com --git-protocol https --web
gh repo create compose-demo --public --source=. --remote=origin --push
# later changes:
git add .
git commit -m "Describe the change"
git push
```

Clean up the containers any time with: `docker compose down --volumes`

Last demo run: 12 Nov 2026, 20:30:51
