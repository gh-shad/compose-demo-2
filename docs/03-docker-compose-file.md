# 03 - The docker-compose.yml file, line by line

This one file describes the **whole application**: 4 services, 1 network and 1 volume.
Docker Compose reads it when you type `docker compose up -d`.

**Back to:** [README](../README.md) · **Previous:** [02 - Concepts](02-concepts.md) · **Next:** [04 - Demo walkthrough](04-demo-walkthrough.md)

---

## The whole file

```yaml
 1  name: compose-demo
 2
 3  services:
 4    web:
 5      image: nginx:1.30
 6      ports:
 7        - "8080:80"
 8      volumes:
 9        - ./html:/usr/share/nginx/html:ro
10        - ./nginx/security.conf:/etc/nginx/conf.d/security.conf:ro
11      depends_on:
12        - db
13      networks:
14        - app-network
15      security_opt:
16        - no-new-privileges:true
17
18    db:
19      image: mysql:8.4
20      environment:
21        MYSQL_ROOT_PASSWORD: examplepassword
22      volumes:
23        - db-data:/var/lib/mysql
24      networks:
25        - app-network
26      security_opt:
27        - no-new-privileges:true
28
29    adminer:
30      image: adminer:6
31      ports:
32        - "8081:8080"
33      depends_on:
34        - db
35      networks:
36        - app-network
37      security_opt:
38        - no-new-privileges:true
39
40    worker:
41      image: busybox:1.37
42      command: sh -c 'while true; do echo "Worker $$(hostname) is working"; sleep 5; done'
43      read_only: true
44      networks:
45        - app-network
46      security_opt:
47        - no-new-privileges:true
48
49  networks:
50    app-network:
51
52  volumes:
53    db-data:
```

(The line numbers are only for this page. They are not part of the file.)

## How to read YAML

- **Indentation (spaces at the start) shows what belongs together.** `web:` is pushed two spaces
  to the right under `services:`, so `web` is one of the services.
- `name: value` gives a setting a value, like `image: nginx:1.30`.
- A line that starts with `- ` is **one item of a list**, like `- "8080:80"`.
- Always use **spaces**, never the Tab key. YAML does not allow tabs for indentation.

---

## Line 1: the project name

| Line | Text | Meaning |
|---|---|---|
| 1 | `name: compose-demo` | The **project name**. Docker puts it in front of everything it creates (see [the real names](#the-real-names-on-the-computer) below). Without this line, Compose would use the folder name, which is different on every computer (for example `compose-demo-main` after a ZIP download). With a fixed name, the clean up in Part 10 always finds exactly this project's things. |

## Lines 3 to 16: the `web` service

| Line | Text | Meaning |
|---|---|---|
| 3 | `services:` | Here starts the list of all containers of the application. |
| 4 | `web:` | The first service is called `web`. This name is also its **name on the network**. |
| 5 | `image: nginx:1.30` | Use the official **NGINX** web server image, version **1.30** (the "stable" series). Docker downloads it from Docker Hub if it is not on the computer yet. A fixed version means the demo works the same way every time (see [fixed versions](#fixed-versions-instead-of-latest)). |
| 6 | `ports:` | The list of doors (ports) to open from the computer into the container. |
| 7 | `- "8080:80"` | **Computer door 8080 → container door 80.** The left number is the host (the VM), the right number is inside the container. NGINX listens on door 80. The quotes stop YAML from reading `8080:80` as a strange number. |
| 8 | `volumes:` | Files and folders to connect into the container. |
| 9 | `- ./html:/usr/share/nginx/html:ro` | A **bind mount**: the project's `html` folder appears inside the container at `/usr/share/nginx/html`, which is where NGINX looks for web pages. So NGINX shows **our** `index.html` instead of its default page. `:ro` means **read-only**. |
| 10 | `- ./nginx/security.conf:/etc/nginx/conf.d/security.conf:ro` | Our **security settings** for NGINX, also read-only. NGINX loads every `.conf` file in `/etc/nginx/conf.d/` when it starts. The file hides the NGINX version and adds security headers to every page (see [the security settings](#the-security-settings)). |
| 11-12 | `depends_on:` `- db` | **Start `db` before `web`.** Note: this waits only until the db *container* has started, not until MySQL inside it is ready. That is why the script waits for MySQL separately. |
| 13-14 | `networks:` `- app-network` | Connect `web` to the private road `app-network`. |
| 15-16 | `security_opt:` `- no-new-privileges:true` | A **safety lock**: no program inside the container can ever get more rights than it started with (for example through a special "set user" program). Every service has this lock. |

## Lines 18 to 27: the `db` service

| Line | Text | Meaning |
|---|---|---|
| 18 | `db:` | The database service. Other containers reach it with the name `db`. |
| 19 | `image: mysql:8.4` | The official **MySQL 8.4** image. 8.4 is a long-term support (LTS) version. MySQL 5.7, used in older tutorials, reached its end of life in 2023. |
| 20-21 | `environment:` `MYSQL_ROOT_PASSWORD: examplepassword` | An **environment variable**: on its first start, MySQL sets the password of the `root` user to `examplepassword`. **Demo only!** It is safe here because the database has no open door (see below) and holds no real data. Real projects keep passwords in a `.env` file that is never uploaded (see `.gitignore` and [SECURITY.md](../SECURITY.md)). |
| 22-23 | `volumes:` `- db-data:/var/lib/mysql` | MySQL stores its data in `/var/lib/mysql`. This line puts that folder into the **named volume** `db-data`, outside the container. So the data survives when the container is deleted (Part 7 proves it). |
| 24-25 | `networks:` `- app-network` | Connect `db` to the private road. |
| 26-27 | `security_opt:` `- no-new-privileges:true` | The safety lock (see line 15). |

There is **no `ports:` section** here on purpose. The database is reachable only from inside
`app-network`, not from outside. This is safer.

## Lines 29 to 38: the `adminer` service

| Line | Text | Meaning |
|---|---|---|
| 29 | `adminer:` | A small web page for looking inside databases. |
| 30 | `image: adminer:6` | The official Adminer image, version 6. |
| 31-32 | `ports:` `- "8081:8080"` | **Computer door 8081 → container door 8080.** Adminer listens on door 8080 inside its container. We use 8081 outside, because 8080 is already used by `web`. |
| 33-34 | `depends_on:` `- db` | Start `db` first. |
| 35-36 | `networks:` `- app-network` | On the same road, so Adminer can reach the server called `db`. |
| 37-38 | `security_opt:` `- no-new-privileges:true` | The safety lock (see line 15). |

## Lines 40 to 47: the `worker` service

| Line | Text | Meaning |
|---|---|---|
| 40 | `worker:` | A tiny helper service, used to show **scaling** and **logs**. |
| 41 | `image: busybox:1.37` | **BusyBox** 1.37 (the "stable" series): a very small image with many basic Linux tools (including `ping`). |
| 42 | `command: sh -c '...'` | The command the container runs instead of its default one. |
| 43 | `read_only: true` | The container's own files are **read-only**. The worker never needs to save anything, so nobody (not even an attacker inside it) can change its programs. |
| 44-45 | `networks:` `- app-network` | On the same road. |
| 46-47 | `security_opt:` `- no-new-privileges:true` | The safety lock (see line 15). |

The command on line 42, piece by piece:

| Piece | Meaning |
|---|---|
| `sh -c '...'` | Run the text in quotes with the shell `sh`. |
| `while true; do ... done` | Repeat forever. |
| `echo "Worker $$(hostname) is working"` | Print a message. `$(hostname)` is replaced by the container's name (its ID). |
| `$$` | In a compose file, `$` has a special meaning (Compose variables). `$$` means "a real `$`", so the **container** sees `$(hostname)`. |
| `sleep 5` | Wait 5 seconds before the next message. |

## Lines 49 to 53: the network and the volume

| Line | Text | Meaning |
|---|---|---|
| 49-50 | `networks:` `app-network:` | **Create** the network called `app-network`. No settings are needed. The defaults are fine. |
| 52-53 | `volumes:` `db-data:` | **Create** the named volume called `db-data`. |

## The security settings

The file `nginx/security.conf` (mounted on line 10) contains five settings. You can see their
effect with `curl -sI http://localhost:8080`, and Part 5 of the demo checks them.

| Setting | What it does |
|---|---|
| `server_tokens off;` | The `Server` header says only `nginx`, without the version number. Attackers learn less. |
| `X-Content-Type-Options: nosniff` | The browser must not guess what kind of file it received. |
| `X-Frame-Options: DENY` | No other website may show this page inside a frame (protects against "clickjacking"). |
| `Referrer-Policy: no-referrer` | Links on this page do not tell other websites where the visitor came from. |
| `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; ...` | The page may use only its own built-in styles: no scripts, no files from other websites, no forms. Our page needs nothing more. |

## Fixed versions instead of `latest`

Older tutorials use tags like `nginx:latest`. `latest` can point to a new version at any time,
so the same file could start different programs next month. This project uses **fixed versions**
(`nginx:1.30`, `mysql:8.4`, `adminer:6`, `busybox:1.37`), so every run uses the same, tested
programs. Within these versions, Docker Hub still delivers the security fixes (for example
1.30.0, 1.30.1, ...). Newer versions are suggested by **Dependabot** as pull requests, which the
automatic tests check first (see [SECURITY.md](../SECURITY.md)).

## The real names on the computer

Docker Compose puts the **project name** (line 1: `compose-demo`) in front of everything it
creates, so different projects never mix:

| In the file | Real name on the computer |
|---|---|
| network `app-network` | `compose-demo_app-network` |
| volume `db-data` | `compose-demo_db-data` |
| service `web` | container `compose-demo-web-1` |
| service `worker`, scaled to 3 | `compose-demo-worker-1`, `-2`, `-3` |

Compose also puts a **label** on all of them: `com.docker.compose.project=compose-demo`.
Part 10 uses this label to find, and clean up, **only** this project's things.

## What about `version: '3.8'`?

Older tutorials start the file with `version: '3.8'`. Modern Docker Compose ignores this line,
so it is not needed any more.

## Try it yourself

```bash
docker compose config            # shows the file as Docker Compose understands it
docker compose config --quiet    # only checks it: no output means no mistakes
docker compose config --services # lists the services: web, db, adminer, worker
docker compose config --images   # lists the images and their versions
curl -sI http://localhost:8080   # shows the security headers (while the app is running)
```

---

**Next:** [04 - Demo walkthrough](04-demo-walkthrough.md)
