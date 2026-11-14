# Security policy

This page explains how this project protects your computer, your files and your GitHub account,
which choices are made only for the demo, and how to report a security problem.

**Back to:** [README](README.md) · More details: [08 - Clean up and safety](docs/08-cleanup-and-safety.md)

---

## Reporting a security problem

Please **do not** report security problems in a public issue, because everyone can read it.

1. Open the project's **Security** tab on GitHub.
2. Click **Report a vulnerability** (private vulnerability reporting).
3. Describe the problem: which file, what can happen, and how to repeat it.

Only the project owner can read the report. This is a student project, so reports are answered
as soon as possible. Fixes go into the newest version on the `main` branch, which is the only
supported version.

---

## How the project protects you

### The containers (`docker-compose.yml`, `nginx/security.conf`)

| Protection | Where | What it does |
|---|---|---|
| Fixed image versions | `nginx:1.30`, `mysql:8.4`, `adminer:6`, `busybox:1.37` | Every run uses the same, tested programs. No surprise changes from `latest` |
| Official images only | Docker Hub "official images" | The images are built and checked by Docker and the projects themselves |
| No open door for the database | `db` has no `ports:` line | MySQL can only be reached by the other containers, never from outside |
| Read-only mounts | `./html:...:ro`, `./nginx/security.conf:...:ro` | The containers can read our files, but can never change them |
| `no-new-privileges` lock | every service | A program inside a container can never give itself more rights |
| Read-only worker | `worker`: `read_only: true` | The worker's own files cannot be changed |
| Hidden server version | `server_tokens off;` | The web server does not tell visitors which NGINX version it runs |
| Security headers | `nginx/security.conf` | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Content-Security-Policy` (checked live in Part 5) |

### The scripts (`demo.sh`, `Start-Demo.ps1`, `cloud-init.yaml`)

| Protection | What it does |
|---|---|
| Removes only its own things | Docker clean up uses this project's label (`com.docker.compose.project=compose-demo`). Never `docker system prune` |
| SHA-256 file check | Every project file is fingerprinted at the start and checked again before the upload |
| Safe temporary folder | The temporary folder path is checked before it is deleted |
| Backups before updates | The Windows launcher backs up changed files before it updates the project in the VM, and never touches the Git history |
| Allowed options only | `Start-Demo.ps1` passes only known options to the VM. Anything else is refused |
| Checked addresses only | The launcher opens only the demo's own pages and checked `https://github.com/<owner>/<project>` addresses |
| Signed software sources | `cloud-init.yaml` installs Docker and the GitHub CLI only from their official package sources, checked with their signing keys |

### Git and GitHub

| Protection | What it does |
|---|---|
| Sign-in with a one-time code | Your password is never typed into the terminal. The key is shown only as `gho_****` |
| Sign-out at the end (Part 13) | The GitHub CLI key and Git's GitHub settings are removed, and this is checked |
| Never `git push --force` | Nothing on GitHub is ever overwritten. On a conflict, a new project name is used |
| Forks for other people's projects | The demo never uploads into a project that is not yours |
| `.gitignore` | `.env` files, keys and certificates are never saved or uploaded |
| Secret scanning and push protection | GitHub refuses an upload that contains a known type of secret (a key or token) |
| Branch protection | The `main` branch cannot be deleted or force-pushed |
| Dependabot | Warns about known security problems and suggests updates (see below) |

### The automatic tests (`.github/workflows/demo-test.yml`)

| Protection | What it does |
|---|---|
| `permissions: contents: read` | The tests can read the project, but never change it |
| Actions pinned to commit IDs | The outside code that runs can never change without a visible update |
| `persist-credentials: false` | The downloaded project does not keep GitHub's key |
| `timeout-minutes` | A test that hangs is stopped |
| Link check | Every link in the documentation is checked after every upload |

## Updates (Dependabot)

[`.github/dependabot.yml`](.github/dependabot.yml) asks Dependabot to check once a month for
newer versions of the GitHub Actions, the Docker images and the Codespaces features. Each update
arrives as a **pull request**, and the automatic tests run on it first.

- **Green tests:** the update works with the demo. Merge it.
- **Red tests:** the update would break something. Leave it closed and look at the test log.

MySQL stays on the 8.4 long-term support series: a new major database version is a decision for
a person, not for a robot.

---

## Demo-only choices (known and accepted)

These choices are fine for a classroom demo, but **not** for a real application:

| Choice | Why it is acceptable here | What a real project does |
|---|---|---|
| The database password `examplepassword` is written in `docker-compose.yml` | The database has no open door, holds no real data, and runs only inside your own VM or codespace for a few minutes | Keeps passwords in a `.env` file (never uploaded) or a secrets manager |
| Ports 8080 and 8081 are open on the VM | The VM is reachable only from your own computer's private network | Puts a firewall and HTTPS (TLS) in front of every open port |
| No HTTPS | The pages never leave your own computer or codespace | Always uses HTTPS |
| Adminer is running | It is the easiest way to show what is inside the database | Does not run database tools on a public server |

## Safe use on shared computers

- Do **not** use `--stay-signed-in` on a school or shared computer. Part 13 signs out by default.
- If a run was stopped before Part 13, sign out with `./demo.sh --logout`.
- Revoke old keys on GitHub: **Settings** → **Applications** → **Authorized OAuth Apps** →
  **GitHub CLI** → **Revoke access**.
- Never put real passwords or keys into the project. If it happens, change the password at once:
  removing it from a later version does not remove it from the history.
