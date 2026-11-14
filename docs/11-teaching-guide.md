# 11 - Teaching guide

A ready-to-use guide for teachers who want to use this project in class: what students learn, how to
set up the room, a lesson plan that follows the 13 parts, questions with answers, hands-on exercises
with solutions, how students hand in their work, and a marking checklist.

**Back to:** [README](../README.md) · **Previous:** [10 - GitHub by hand](10-github-by-hand.md)

---

## Contents

1. [Learning outcomes](#1-learning-outcomes)
2. [Before the class](#2-before-the-class)
3. [Classroom setup options](#3-classroom-setup-options)
4. [Lesson plan](#4-lesson-plan)
5. [Questions for each part, with answers](#5-questions-for-each-part-with-answers)
6. [Hands-on exercises, with solutions](#6-hands-on-exercises-with-solutions)
7. [How students hand in their work](#7-how-students-hand-in-their-work)
8. [Marking checklist](#8-marking-checklist)
9. [Quick quiz](#9-quick-quiz)
10. [Tips for the class](#10-tips-for-the-class)

---

## 1. Learning outcomes

After the lesson, a student can:

| # | Outcome | Shown in |
|---|---|---|
| 1 | Explain container, image, service, network, port and volume in their own words | Parts 1 to 3 |
| 2 | Read a `docker-compose.yml` file and say what each line does | Part 4 |
| 3 | Start, list, enter, scale, read logs of and remove a multi-container application | Parts 5, 6, 8, 9 |
| 4 | Show that containers find each other by **service name** | Part 6 |
| 5 | Show that a **volume** keeps data when containers are deleted | Part 7 |
| 6 | Clean up safely: remove only what belongs to the project | Part 10 |
| 7 | Save work with Git: `init`, `status`, `add`, `commit`, `log`, `diff` | Part 11 |
| 8 | Upload work to GitHub, use a **fork**, and check that the upload really arrived | Part 12 |
| 9 | Sign out of GitHub completely, and explain why the website alone is not enough | Part 13 |
| 10 | Name three ways the demo protects the computer (fixed versions, `no-new-privileges`, read-only files, security headers) | Parts 4 and 5 |

---

## 2. Before the class

| When | What | Why |
|---|---|---|
| A week before | Ask every student to create a free GitHub account at <https://github.com> and send you their user name | Needed for forks, Codespaces and handing in |
| A few days before | Run the whole demo once yourself, the way you will run it in class | No surprises in front of the class |
| A few days before | Fork the project to your own account (or use the author's project) | Students fork **your** copy, so you see their forks |
| The day before | Open a codespace (or start the VM) once, so the images are already downloaded | The first image download takes a few minutes |
| 10 minutes before | Start the codespace or the VM, make the terminal font big (Ctrl and +) | Easy to read on the projector |

---

## 3. Classroom setup options

| Option | Who runs the demo | Needs | Good for |
|---|---|---|---|
| **A. Teacher presents, students watch** | The teacher, on the projector | One computer: a codespace, or Windows with `Start-Demo.bat` | Large classes, the first lesson |
| **B. Every student runs it** | Each student, in their own codespace | A browser and a GitHub account per student | Hands-on lessons, homework |
| **C. Lab computers** | Each student, on a lab computer | Windows 10/11 Pro + Multipass on every computer | Labs without good internet (after the first setup) |
| **D. Watch only** | Nobody (GitHub already ran it) | A browser | A quick look, revision, absent students |

For **Option D**, open the project's **Actions** tab, click the newest **Demo test** run, and show
the results report on its summary page. Each job's steps show the complete output with every explanation.

On shared lab computers, the demo **signs out of GitHub at the end** (Part 13), so the next student
cannot use the previous student's account. Do not use `--stay-signed-in` on shared computers.

---

## 4. Lesson plan

### Lesson 1: Docker Compose (about 60 minutes)

| Time | Activity | Parts | Command |
|---|---|---|---|
| 0 to 5 min | Introduction: "Real applications are many programs that work together" | — | — |
| 5 to 35 min | Run the demo with the Docker parts only. Pause with **p** to ask the questions in [section 5](#5-questions-for-each-part-with-answers) | 1 to 10 | `./demo.sh --no-git` |
| 35 to 55 min | Exercises 1 to 4 (students in pairs) | — | `./demo.sh --fast --no-git --keep`, then the exercises |
| 55 to 60 min | Quick quiz ([section 9](#9-quick-quiz)) | — | — |

### Lesson 2: Git, GitHub and signing out (about 60 minutes)

| Time | Activity | Parts | Command |
|---|---|---|---|
| 0 to 5 min | Recap of lesson 1 | — | — |
| 5 to 25 min | Run the Git and GitHub parts. Show the commits and the results report on GitHub | 10 to 13 | `./demo.sh --git-only` |
| 25 to 50 min | Students fork, open a codespace, run the whole demo, then do exercises 5 and 6 | 1 to 13 | `./demo.sh --fast` |
| 50 to 60 min | Students send their fork link. Show a few forks on the projector | — | — |

### One long session (about 90 minutes)

Run the whole demo in class with `./demo.sh` (Parts 1 to 13, with pauses for questions), then give
the students 30 to 40 minutes for the exercises, and collect the fork links at the end.

**Presenting tips:** `--manual` waits for Enter before every step, so you can talk as long as you
like. In automatic mode, press **p** to pause and **Enter** to go on. `--slow` gives more time to read.

---

## 5. Questions for each part, with answers

Ask these when you pause the demo. The answers are short, so you can check them quickly.

| Part | Question | Answer |
|---|---|---|
| 2 | Why is one compose file better than six long `docker run` commands? | Everything is in one place, it is the same every time, it is easy to share, and one command starts it all. Fewer mistakes |
| 3 | What is the difference between an **image** and a **container**? | The image is the recipe (read-only). A container is a running copy made from it. One image can make many containers |
| 3 | What is the difference between a **service** and a **container**? | A service is the description in the compose file. A container is a running copy of it. One service can have several containers (Part 8) |
| 4 | What does `"8080:80"` mean? | Port 8080 of the computer is connected to port 80 inside the container |
| 4 | Why does the `db` service have **no** `ports:` line? | Only the other containers need it, and they reach it over the private network. Not opening a port is safer |
| 4 | Why do the images have fixed versions like `nginx:1.30` instead of `latest`? | `latest` can change at any time. A fixed version makes every run use the same, tested program. Updates are still suggested by Dependabot and tested before they are used |
| 4 | What does `no-new-privileges:true` protect against? | A program inside the container cannot give itself more rights (for example with a "set user" program), even if an attacker gets in |
| 5 | What does `-d` in `docker compose up -d` do? | Runs the containers in the background (detached), so the terminal is free again |
| 5 | Why does the `Server` header say only `nginx`, without a version? | `server_tokens off;` hides the version, so an attacker cannot easily look up known problems of that exact version |
| 6 | How does the worker find the database with only the name `db`? | Compose creates the network `app-network` with a built-in name service (DNS): every service name is turned into the container's address |
| 6 | What would happen if `worker` were **not** on `app-network`? | It could not reach `db` by name. `ping db` would fail with "bad address" |
| 7 | Why are the students still there after `docker compose down` and `up`? | The data is stored in the **volume** `db-data`, not in the container. `down` deletes the containers, but keeps volumes |
| 7 | Which command **would** delete the data? | `docker compose down --volumes` (Part 9) |
| 8 | Why can we scale `worker` to 3, but not `web` in the same way? | `web` publishes the fixed port 8080. Only one container can use port 8080 on the computer, so the second copy would fail with "port is already allocated". `worker` has no port |
| 8 | Why do the three workers have different names? | Compose numbers the copies: `compose-demo-worker-1`, `-2`, `-3`. Each container also has its own host name |
| 9 | What is the difference between `down` and `down --volumes`? | `down` removes containers and the network. `down --volumes` also removes the volumes, so the data is gone |
| 10 | Why does the script not use `docker system prune` to clean up? | Prune would also delete other projects' stopped containers, unused images and other things that do not belong to this demo. The script only removes things with this project's label |
| 10 | What does the SHA-256 check prove? | That every project file is still exactly the same as at the start: even a one-letter change gives a completely different fingerprint |
| 11 | Why is there a **staging area** (`git add`) before `git commit`? | So you choose exactly what goes into the save point. Not every change has to be saved at once |
| 11 | Why do we need `.gitignore`? | To keep secrets (like `.env` files) and useless files (logs, temporary files) out of Git and out of GitHub |
| 12 | What is the difference between a **clone** and a **fork**? | A clone is a copy on your computer. A fork is a copy on GitHub, in your own account, that you are allowed to change |
| 12 | How does the script prove that the upload worked? | It compares the newest commit ID on the computer (`git rev-parse HEAD`) with the newest commit ID on GitHub (`git ls-remote`). They must be identical |
| 12 | Why does the script never use `git push --force`? | Force would overwrite the history on GitHub, and other people's work could be lost. The script uses a new project name instead |
| 13 | Why is signing out on github.com **not** enough? | The browser, the GitHub CLI and Git each keep their own sign-in. The website only ends the browser session |
| 13 | What does **revoke** on the website do that `gh auth logout` does not? | `gh auth logout` deletes the key from one computer. Revoke tells GitHub to stop accepting the key everywhere |

---

## 6. Hands-on exercises, with solutions

Start the application and leave it running:

```bash
./demo.sh --fast --no-git --keep
```

(`--keep` leaves the containers running at the end.) In a codespace, `localhost` works in the
terminal; in the browser, use the **Ports** tab. In the VM, use `curl http://localhost:8080`.

At the end of the exercises, undo your changes with Git (exercise 6) and clean up:
`docker compose down --volumes`.

### Exercise 1: Change the web page

**Task:** change the title of the website, and show the new title without restarting anything.

<details>
<summary>Solution</summary>

1. Open `html/index.html` and change the text between `<title>` and `</title>`.
2. Check it:

   ```bash
   curl -s http://localhost:8080 | grep -i "<title>"
   ```

The new title appears at once. **Why?** The compose file mounts the `html` folder into the `web`
container (`./html:/usr/share/nginx/html:ro`). NGINX reads the file from your folder, so no restart
is needed. `:ro` means the container can only **read** it.

</details>

### Exercise 2: Change the website's port

**Task:** make the website answer on port **8090** instead of 8080.

<details>
<summary>Solution</summary>

1. In `docker-compose.yml`, change `"8080:80"` to `"8090:80"`.
2. Apply the change and check:

   ```bash
   docker compose up -d
   docker compose ps web
   curl -s http://localhost:8090 | grep -i "<title>"
   ```

`docker compose up -d` sees that `web` changed and re-creates **only** that container. `ps` shows
`0.0.0.0:8090->80/tcp`. Only the left number (the computer's port) changes: NGINX inside the
container still listens on 80.

**Important:** change it back to `8080` afterwards (or use exercise 6), because the demo checks port 8080.

</details>

### Exercise 3: Scale and read the logs

**Task:** run 5 copies of the worker, then show the last 2 lines of each copy.

<details>
<summary>Solution</summary>

```bash
docker compose up -d --scale worker=5
docker compose ps worker
docker compose logs worker --tail 2
```

`ps` lists `compose-demo-worker-1` to `-5`. Every log line starts with the container's name, and
every copy prints its own host name. Scale back down with `docker compose up -d --scale worker=1`.

</details>

### Exercise 4: Prove what a volume does

**Task:** save a book in a new database, delete the containers, and show that the book survives.
Then show which command really deletes it.

<details>
<summary>Solution</summary>

```bash
docker compose exec db mysql -uroot -pexamplepassword -e "CREATE DATABASE IF NOT EXISTS library; CREATE TABLE IF NOT EXISTS library.books (title VARCHAR(80)); INSERT INTO library.books VALUES ('Docker for Beginners');"
docker compose down
docker compose up -d
```

Wait about 20 seconds (MySQL needs time to start), then:

```bash
docker compose exec db mysql -uroot -pexamplepassword -e "SELECT * FROM library.books;"
```

The book is still there, because it is stored in the volume `db-data`, and `down` keeps volumes.
Now:

```bash
docker compose down --volumes
docker compose up -d
```

Wait about 30 seconds, then `SHOW DATABASES;` (same `exec` command) no longer lists `library`:
the volume was deleted, and MySQL started with an empty one.

(The warning "Using a password on the command line interface can be insecure" is normal for this demo.)

</details>

### Exercise 5: Add a new service

**Task:** add a service called `checker` that pings the `web` service every 10 seconds, and show
its output.

<details>
<summary>Solution</summary>

Add this under `services:` in `docker-compose.yml` (same indentation as `worker:`; YAML uses
spaces, never tabs):

```yaml
  checker:
    image: busybox:1.37
    command: sh -c 'while true; do ping -c 1 web; sleep 10; done'
    networks:
      - app-network
```

Then:

```bash
docker compose config --quiet      # no output = the file has no mistakes
docker compose up -d
docker compose logs checker --tail 5
```

The logs show `64 bytes from 172.x.x.x` replies: the new container found `web` by its name, because
it is on the same network. Remove it again with exercise 6 and `docker compose up -d --remove-orphans`.

</details>

### Exercise 6: Save, compare and undo with Git

**Task:** see exactly what you changed, save one change, and undo the others.

<details>
<summary>Solution</summary>

```bash
git status                       # which files changed
git diff docker-compose.yml      # the exact lines: - old, + new
git add html/index.html          # put only the web page into the staging area
git commit -m "Change the website title"
git restore docker-compose.yml   # undo the changes in the compose file
git log --oneline -3             # the newest save points
git push                         # upload (in a codespace on your fork, no sign-in needed)
```

`git restore` brings back the last saved version of a file, so the port is 8080 again and the
`checker` service is gone. To start everything again from the saved files:
`docker compose up -d --remove-orphans`.

</details>

### Exercise 7 (extra): Find and fix a mistake

**Task:** your partner breaks the compose file (for example, removes the two spaces before
`image:` of one service). Find the mistake without starting anything.

<details>
<summary>Solution</summary>

```bash
docker compose config --quiet
```

It prints an error that names the problem (for example, an unexpected key or a wrong line).
Fix the indentation and run the command again: no output means the file is correct. This is the
same check that GitHub Actions runs after every upload.

</details>

### Exercise 8 (extra): Check the security headers

**Task:** show the security headers of the website, then find out what changes when the
security settings file is not used.

<details>
<summary>Solution</summary>

```bash
curl -sI http://localhost:8080
```

The answer shows `Server: nginx` (no version number) and the four security headers
`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` and `Content-Security-Policy`.

Now put a `#` in front of the line `- ./nginx/security.conf:...` in `docker-compose.yml`, then:

```bash
docker compose up -d
curl -sI http://localhost:8080
```

The `Server` line now shows the exact version (for example `nginx/1.30.0`), and the four security
headers are gone. Remove the `#` again (or `git restore docker-compose.yml`) and run
`docker compose up -d`: the headers are back. Lesson: one small, read-only file makes every page safer.

</details>

---

## 7. How students hand in their work

The simplest way: **one link per student**.

1. The student **forks** your project (button **Fork**).
2. They open a **codespace on their fork** and run `./demo.sh` (or `./demo.sh --fast`).
   The demo saves the results report with Git and uploads it to **their fork**.
3. They do the exercises and push them (exercise 6).
4. They send you the link to their fork: `https://github.com/<student>/compose-demo`.

What you can check in their fork:

| Where | What it proves |
|---|---|
| `results/latest-run.md` | The real results of their newest run: **Result** (PASSED), **Date**, **GitHub account**, every check, and the key results |
| `results/run-history.md` | One line for every run they saved |
| The commits list (the clock icon or the **commits** link above the files) | Their own save points, with their name and dates |
| The **Actions** tab | GitHub ran the demo on their version too (they enable workflows once) |
| `docker-compose.yml`, `html/index.html` | Their exercise changes |

To see all forks of your project: on your project page, click the **Forks** number.

---

## 8. Marking checklist

A suggested 20-point checklist. Change it to fit your course.

| # | What to check | Points |
|---|---|---|
| 1 | The fork exists and is public | 2 |
| 2 | `results/latest-run.md` shows **PASSED** and the student's GitHub account | 4 |
| 3 | The run history has at least one line from the student | 1 |
| 4 | At least one commit written by the student, with a clear message | 3 |
| 5 | An exercise change is visible (for example the new website title) | 3 |
| 6 | The student explains in their own words: service, network, volume | 3 |
| 7 | The student explains how the upload was verified | 2 |
| 8 | The student explains why signing out is needed, and what revoke does | 2 |
|  | **Total** | **20** |

Points 6 to 8 can be a short oral check in class, or a few sentences the student adds at the end
of their fork's README.

---

## 9. Quick quiz

1. Which file describes the whole application? → `docker-compose.yml`
2. Which command starts everything in the background? → `docker compose up -d`
3. How does `web` reach the database? → By the service name `db`, over `app-network`
4. Where does MySQL keep its data so that it survives `down`? → In the volume `db-data`
5. Which command deletes the data too? → `docker compose down --volumes`
6. Which command runs 3 workers? → `docker compose up -d --scale worker=3`
7. Which Git command creates a save point? → `git commit`
8. What is a fork? → Your own copy of someone else's project, on GitHub
9. How do you know the upload really worked? → The commit ID on the computer and on GitHub are the same
10. Name the three places that keep you signed in to GitHub. → The browser, the GitHub CLI's key, and Git's setting (plus GitHub itself until you revoke the key)

---

## 10. Tips for the class

| Situation | Tip |
|---|---|
| Slow internet | Use the Windows launcher (the images are stored in the VM), or Option D (Actions tab) |
| Students without a GitHub account | They can still run everything: they answer **No** to the upload question. Or they watch a classmate |
| A student's codespace says "upload skipped" | The codespace was opened on your project, not on their fork. They must fork first |
| The class needs more time to read | `./demo.sh --slow`, or `--manual` |
| Something fails | The red `[PROBLEM]` message has a hint. All fixes: [09 - Troubleshooting](09-troubleshooting.md) |
| Shared lab computers | Never use `--stay-signed-in`. Part 13 signs out at the end of every run |
| After the course | Students stop or delete their codespaces at <https://github.com/codespaces> |

---

**Back to:** [README](../README.md)
