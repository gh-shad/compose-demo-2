# Changelog

All notable changes to this project, newest first.
The project uses simple version numbers: a new number for every finished stage.

## [2.0] - November 2026: complete public project

### Added
- **Part 13: Sign out of GitHub.** After the upload, the demo signs out completely: it removes the
  GitHub CLI key and Git's GitHub settings, checks the result, and explains how to revoke the key
  on github.com. A complete run is now one safe GitHub session: sign in, upload, verify, sign out.
- `--stay-signed-in` option, to skip Part 13 on your own private computer.
- The final screen shows the sign-in status: `[OK] This computer is signed out of GitHub.`
- Real screenshots of every important step in `docs/images/`, shown in the README.
- A complete new README: overview, objectives, features, technologies, how it works, install,
  run, every feature, results, uploading to GitHub, sharing with a teacher, the development
  process, structure, safety, troubleshooting, and Q&A.
- `docs/11-teaching-guide.md`: learning outcomes, classroom setup, lesson plan, questions with
  answers, hands-on exercises with solutions, how students hand in work, and a marking checklist.
- A documentation index (`docs/README.md`) with a learning path, and a screenshot index.
- This changelog.

### Changed
- `--logout-after` is now the default behaviour (it still works as an older name).
- The sign-in question and the documentation explain that every run that uploads asks for a new
  one-time code, because the previous run signed out.
- The Windows launcher still opens your project page at the end, after Part 13 signed out.
- When nothing was uploaded, Part 13 says so, and still makes sure the computer is signed out.
- `--push` now also signs in when it is used together with `--fast`.
- The hints after a skipped upload point to one command: `./demo.sh --git-only --push`
  (sign in, save, upload, sign out).

## [1.5] - November 2026: for everyone

### Added
- **Forks:** when the folder came from someone else's project, the demo creates your own fork
  (`gh repo fork --remote`) and uploads there. Nothing is ever uploaded into someone else's project.
- **GitHub Codespaces** (`.devcontainer/devcontainer.json`): run the demo in the browser with
  nothing to install, already signed in.
- **Results report:** `results/latest-run.md` (every check, key results, time per part, versions)
  and `results/run-history.md` (one line per run), saved with Git and uploaded.
- **Upload verification:** the newest commit on the computer is compared with the one on GitHub.
- The final screen shows the **execution results** and the links to the project and the report.
- `--logout`: signs out of GitHub completely (GitHub CLI, Git settings, `~/.git-credentials`).
- `docs/10-github-by-hand.md`: fork, clone, change, run Compose again, push, pull, sync, sign out.
- GitHub Actions shows the results report on each run's summary page and saves it as an artifact.

### Changed
- The upload never overwrites anything: on any conflict, a free name is used
  (`compose-demo-2`, ...), never `git push --force`.

## [1.0] - November 2026: public project

### Added
- **Part 10: Clean up and safety check** before anything is uploaded: removes only this project's
  containers, network, volume and temporary files, and checks every project file with SHA-256.
- Every important result is recorded as a check, and the **final confirmation screen** shows them all.
  The exit code is `0` only when every check passed.
- **Automatic tests** with GitHub Actions: ShellCheck, the compose file check, the whole Docker demo
  with the real images, and the Windows launcher check.
- Self-repair: missing project files are re-created. The Windows launcher backs up unsaved changes
  before it updates the project in the VM, and never touches the Git history.
- Documentation in `docs/01` to `docs/09`, the MIT license, `.gitignore` and `.gitattributes`.

## [0.3] - November 2026: one Enter press

### Added
- Fully automatic mode: press Enter once, every command runs and is explained by itself.
- **Windows launcher** (`Start-Demo.bat` and `Start-Demo.ps1`): creates the VM, copies the project,
  opens the website and Adminer in the browser, runs the demo, and opens the GitHub page.
- Speeds: `--slow`, `--manual`, `--fast`.

### Changed
- All explanations rewritten in simple English.

## [0.2] - November 2026: Git and GitHub

### Added
- **Part 11: Git** (`init`, `status`, `add`, `commit`, `log`, `diff`) and **Part 12: GitHub**
  with the GitHub CLI (`gh auth login` with a one-time code, `gh repo create`, `git push`).
- `cloud-init.yaml` installs Git and the GitHub CLI in the VM.

## [0.1] - November 2026: the demo is recreated

### Added
- `demo.sh`: the narrated demo of the class presentation "Running Multi-Container Applications
  with Docker Compose" (Parts 1 to 9).
- `docker-compose.yml`: `web` (NGINX), `db` (MySQL 8.4), `adminer`, `worker` (BusyBox),
  the network `app-network` and the volume `db-data`.
- `cloud-init.yaml`: the Multipass VM `compose-lab` with Docker and the images ready in advance.
- `html/index.html`: the web page.

### Changed (compared with the presentation)
- `docker-compose` (v1) → `docker compose` (v2), no `version:` line, MySQL 5.7 (end of life) → 8.4.
