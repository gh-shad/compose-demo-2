# Latest demo run

> This file is written by `demo.sh` every time the demo runs.
> It shows the **real results** of the most recent run. Older runs: [run-history.md](run-history.md).

| | |
|---|---|
| **Result** | PASSED: all 12 checks passed |
| **Date** | 15 Nov 2026, 00:39:49 IST |
| **Where it ran** | Multipass VM 'compose-lab' |
| **GitHub account** | gh-shad |
| **Mode** | fast |
| **Time until this report** | 0 min 44 s |

## Checks

| # | Check | Result |
|---|---|---|
| 1 | All 4 containers started and are running | PASSED |
| 2 | The website answered on port 8080 | PASSED |
| 3 | The worker container reached the database by its name (ping db) | PASSED |
| 4 | The web container found the database by its name (getent hosts db) | PASSED |
| 5 | MySQL started and is ready | PASSED |
| 6 | The Adminer container connected to the database | PASSED |
| 7 | Saved 2 students in the database | PASSED |
| 8 | The data survived: both students are still there after down and up | PASSED |
| 9 | Scaled the worker service to 3 running copies | PASSED |
| 10 | Clean up: no containers, networks or volumes of this project are left | PASSED |
| 11 | Safety check: all 40 project files are present and unchanged (SHA-256) | PASSED |
| 12 | Clean up: the temporary folder was deleted | PASSED |

## Key results

| What | Result |
|---|---|
| Website (web container, port 8080) | answered with the page title 'Docker Compose Demo' |
| Network test: ping db from the worker | 3 packets transmitted, 3 packets received, 0% packet loss |
| Address of 'db' on app-network | 172.18.0.3 |
| MySQL version | 8.4.13 |
| Students saved before the restart | 2 |
| Students found after down + up (volume test) | 2 |
| Worker copies after scaling | compose-demo-worker-1 compose-demo-worker-2 compose-demo-worker-3  |
| Other containers on this computer | 0 (not touched) |
| Project files checked with SHA-256 | 40, all unchanged |

## Time per part

| Part | Seconds |
|---|---|
| Part 1 - Opening | 0 |
| Part 2 - The problem | 0 |
| Part 3 - Three building blocks | 0 |
| Part 4 - The YAML file | 0 |
| Part 5 - Start the whole app | 1 |
| Part 6 - Containers talking to each other | 8 |
| Part 7 - Data survives a restart | 15 |
| Part 8 - Scaling and logs | 7 |
| Part 9 - Stop and remove the app | 11 |
| Part 10 - Clean up and safety check | 0 |

## Versions

| Tool | Version |
|---|---|
| Operating system | Ubuntu 24.04.5 LTS |
| Docker Engine | 29.9.3 |
| Docker Compose | 5.7.1 |
| Git | 2.43.0 |
| GitHub CLI | 2.103.3 |

## Run it yourself

Fork the project on GitHub, open it in GitHub Codespaces (or use `Start-Demo.bat` on Windows),
then run `./demo.sh`. Your own results will appear in this file in your fork.
See the [README](../README.md) for every step.
