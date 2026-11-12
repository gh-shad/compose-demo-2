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
Yes. When they are not logged in, the script asks if they want to upload, and "No" is the default.
They can also just watch the run in the **Actions** tab, without installing anything.

**What if someone downloads my project and runs it with their own GitHub account?**
The script sees that the folder came from your project, keeps that link as `upstream`, and creates
**their own** copy. Your project is never changed by other people.

**Can I change the project name?**
Yes, for a new project: `REPO_NAME=my-name ./demo.sh`. An existing connection (`origin`) is always used as it is.

**How long does it take?**
About 15 minutes at normal speed, about 20 minutes with `--slow`, and about 2 minutes with `--fast`.
The very first start of the VM takes about 10 extra minutes.

**Can I present it myself, step by step?**
Yes: `./demo.sh --manual` waits for Enter before every step. Or press **p** at any time to pause the automatic mode.

---

**Back to:** [README](../README.md)
