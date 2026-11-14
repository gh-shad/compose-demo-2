# Screenshots

Real screens of `demo.sh`, captured in a terminal during a test run, in the order they appear in the demo.
The user name, addresses and commit IDs in your own run will be different.

**Back to:** [Documentation](../README.md) · [README](../../README.md)

| # | Screenshot | What it shows | Part |
|---|---|---|---|
| 1 | [01-getting-ready.png](01-getting-ready.png) | The checks before the demo, and the plan of all 13 parts | Getting ready |
| 2 | [02-start-the-app.png](02-start-the-app.png) | `docker compose up -d`: an explanation, the real command, its output, and what to look at | 5 |
| 3 | [12-website.png](12-website.png) | The website that the `web` container serves on port 8080 | 5 |
| 4 | [03-containers-talking.png](03-containers-talking.png) | The worker finds the database by its name (`ping db`) | 6 |
| 5 | [04-data-survives.png](04-data-survives.png) | The data is still there after the containers were deleted and started again | 7 |
| 6 | [05-scaling-and-logs.png](05-scaling-and-logs.png) | Three copies of the worker, and their logs | 8 |
| 7 | [06-cleanup-and-safety.png](06-cleanup-and-safety.png) | Only this project's things are removed, and every file is checked with SHA-256 | 10 |
| 8 | [07-git-diff-commit.png](07-git-diff-commit.png) | `git diff` shows exactly what changed, and `git commit` saves it | 11 |
| 9 | [11-github-login.png](11-github-login.png) | The GitHub sign-in with a one-time code | Getting ready |
| 10 | [08-upload-verified.png](08-upload-verified.png) | The upload is verified: the commit on GitHub matches the one on the computer | 12 |
| 11 | [09-sign-out.png](09-sign-out.png) | A complete sign-out of GitHub | 13 |
| 12 | [10-final-screen.png](10-final-screen.png) | The final confirmation screen: every check, the results and the links | End |
