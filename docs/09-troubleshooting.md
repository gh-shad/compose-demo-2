# 09 - Troubleshooting and questions

Find your problem in the tables below. Every `[PROBLEM]` message of the script also prints a hint.

**Back to:** [README](../README.md) · **Previous:** [08 - Clean up and safety](08-cleanup-and-safety.md)

---

## Windows and Multipass

| Problem | Cause | Fix |
|---|---|---|
| `winver` says **Windows Home** | Home has no Hyper-V | Install VirtualBox, then in PowerShell (Admin): `multipass set local.driver=virtualbox`. Or use another computer with Windows Pro |
| `multipass` is not recognised | Not installed, or Windows was not restarted | Install Multipass, then restart Windows |
| Multipass will not start a VM | Wi-Fi set to **Public**, or Hyper-V is off | Set the network to **Private** ([01, step 3](01-setup-from-zero.md#step-3-set-your-wi-fi-network-to-private)), turn on Hyper-V ([step 2](01-setup-from-zero.md#step-2-turn-on-hyper-v)) |
| "Windows protected your PC" | Windows warns about every downloaded file | Click **More info** → **Run anyway** |
| The launcher window closes at once | PowerShell was blocked | Open PowerShell in the project folder and run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Demo.ps1` to see the message |
| `multipass launch` says "timed out" | The setup is still running (slow internet) | Wait, then run `multipass exec compose-lab -- cloud-init status --wait` |
| `The VM setup did not finish` | A download failed during the setup | Read the log: `multipass exec compose-lab -- tail -50 /var/log/cloud-init-output.log`. Then delete the VM (`multipass delete compose-lab`, `multipass purge`) and run `Start-Demo.bat` again |
| `cloud-init.yaml was not found` | The files are not in one folder | Keep all project files together. Do not move `Start-Demo.bat` alone |

## Docker

| Problem | Cause | Fix |
|---|---|---|
| `permission denied ... docker.sock` | The user was added to the `docker` group after the terminal was opened | Type `exit`, then `multipass shell compose-lab` again. (The script uses `sudo` automatically in the meantime) |
| `port is already allocated` (8080 or 8081) | Another program uses the port | `docker ps` to find it. If it is an old demo container: `docker compose down` |
| `MySQL did not start in 240 seconds` | Very slow computer, or a broken volume | `docker compose down --volumes`, then run the demo again |
| The browser shows nothing on port 8080 | Wrong address, or the app is not running yet | Use the address the script prints (`hostname -I`), not `localhost`. The pages only work during Parts 5 to 8 |
| Adminer login fails | MySQL is still starting | Wait 30 seconds and try again. Server: `db`, user: `root`, password: `examplepassword` |
| `Could not download the images` | No internet in the VM | Check your Wi-Fi, then `docker compose pull` |

## Git and GitHub

| Problem | Cause | Fix |
|---|---|---|
| The upload was skipped | Not logged in, or you answered No | `./demo.sh --setup` to log in, then `./demo.sh --git-only` |
| The login code is not accepted | It expired (it is valid for about 15 minutes) | Run `./demo.sh --setup` again for a new code |
| `refusing to allow an OAuth App to create or update workflow` | The `workflow` permission is missing | `gh auth refresh --hostname github.com --scopes workflow` (or `./demo.sh --setup`) |
| The project went to `compose-demo-2` | A different project already had the name, or GitHub had changes your computer did not have | Nothing was overwritten. Use the new project, or rename it on GitHub: project → **Settings** → **Repository name** |
| `Uploaded to GitHub and verified` FAILED | GitHub did not show the new commit in time | Wait a minute, then: `git rev-parse HEAD` and `gh api repos/<you>/<project>/commits/main --jq .sha` should match |
| The badge says **failing** | One automatic test failed on GitHub | Open the **Actions** tab, click the red run, then the red job, to read the message |
| The badge shows an error image | The link still says `your-username` | Run the demo with GitHub connected (Part 11 replaces it), or edit the address in `README.md` by hand |

## Signing in and out

| Problem | Cause | Fix |
|---|---|---|
| **Still signed in after signing out** | Signing out on github.com only ends the browser session. The GitHub CLI in the VM keeps its own key, and Git is set up to use it. `gh auth logout` only removes the key from that one computer | `./demo.sh --logout` (or `Start-Demo.bat --logout`), then revoke the key: <https://github.com/settings/applications> → **GitHub CLI** → **Revoke access**. Full explanation: [10](10-github-by-hand.md#signing-in-and-signing-out) |
| Still signed in after `--logout` | A `GH_TOKEN` or `GITHUB_TOKEN` variable is set | The script tells you. Remove that line from `~/.bashrc` or `~/.profile`, then open a new terminal |
| Git on Windows still pushes without asking | Git for Windows saved the password in the Credential Manager | Command Prompt: `cmdkey /delete:git:https://github.com`, or Control Panel → Credential Manager → Windows Credentials |
| Wrong GitHub account | You signed in with another account earlier | `./demo.sh --logout`, then `./demo.sh --setup` to sign in with the right one |

## GitHub Codespaces

| Problem | Cause | Fix |
|---|---|---|
| "This codespace was opened on ...'s project, not on your own copy" | The codespace belongs to the original project, not to your fork | Click **Fork** on the original project, then **Code** → **Codespaces** → **Create codespace** on **your fork** |
| The website does not open | The port is not forwarded yet, or the app is not running | Open the **Ports** tab, click the globe of port **8080**. The pages only work during Parts 5 to 8 |
| "You have used all your free Codespaces hours" | The monthly free amount is used up | Stop codespaces you do not use (<https://github.com/codespaces>), or use the Windows way |
| The codespace is slow to start | The first start builds the environment | Wait 1 to 2 minutes. Later starts are faster |

## Forks and results

| Problem | Cause | Fix |
|---|---|---|
| The tests do not run in my fork | GitHub switches off workflows in new forks | Open the **Actions** tab of your fork and click **I understand my workflows, go ahead and enable them** |
| `results/latest-run.md` says "No run yet" | The demo has not finished a run in this copy | Run `./demo.sh` (with Git, it is written in Part 11. With `--no-git`, at the end) |
| The upload went to `<you>/compose-demo-2` | Your fork or project on GitHub had changes this computer does not have | Nothing was overwritten. To combine instead: `git pull`, then `git push` ([10, step 8](10-github-by-hand.md#step-8-download-changes-pull)) |

## Script messages

| Message | Meaning |
|---|---|
| `[OK] ...` | A check passed |
| `[PROBLEM] ...` | A check failed. A hint follows |
| `NOTE: ...` | Extra information, nothing is wrong |
| `FINISHED WITH n PROBLEM(S)` | At least one recorded check failed. They are listed as `[FAILED]` |
| `$'\r': command not found` | `demo.sh` has Windows line endings. Fix: `sed -i 's/\r$//' demo.sh` (the launcher does this automatically) |

---

## Questions and answers

**Do I need to know Linux, Docker or Git before?**
No. The script explains every command before it runs it, and [02 - Concepts](02-concepts.md) explains every word.

**Does the demo change my Windows?**
No. Everything happens inside the VM. On Windows, only Multipass is installed.

**Is it safe to run the demo many times?**
Yes. Every run starts fresh (old demo containers are removed first), and every run cleans up
after itself. Each run adds one line to `docs/demo-runs.md` and one or two commits to the history.

**Why is the password `examplepassword` written in the compose file? Is that safe?**
It is only a demo database on your own VM, with no real data, and port 3306 is not opened to
the outside. In real projects, passwords go into a `.env` file, which `.gitignore` keeps out of Git.

**Why does the script keep the images?**
They are not temporary. The next run needs them, and keeping them lets the demo work without internet.

**Can my teacher (or anyone) run it without my GitHub account?**
Yes. Easiest: fork the project and open a codespace on the fork (nothing to install). Without
GitHub, the script asks if they want to upload, and "No" is the default. They can also just watch
a complete run in the **Actions** tab, without installing anything.

**What if someone downloads my project and runs it with their own GitHub account?**
The script sees that the folder came from your project and creates **their own fork**
(`gh repo fork --remote`). Your project is never changed by other people, and you can see their
forks on your project page (**Forks**).

**Which way should I choose: Codespaces or the Windows launcher?**
Codespaces for students, teachers and quick tries: nothing to install, and nothing is stored on
your computer. The Windows launcher for presenting in class without depending on Wi-Fi (after the
first setup, the images are already in the VM).

**Can I change the project name?**
Yes, for a new project: `REPO_NAME=my-name ./demo.sh`. An existing connection (`origin`) is always used as it is.

**How long does it take?**
About 15 minutes at normal speed, about 20 minutes with `--slow`, and about 2 minutes with `--fast`.
The very first start of the VM takes about 10 extra minutes.

**Can I present it myself, step by step?**
Yes: `./demo.sh --manual` waits for Enter before every step. Or press **p** at any time to pause the automatic mode.

---

**Next:** [10 - GitHub by hand](10-github-by-hand.md) · **Back to:** [README](../README.md)
