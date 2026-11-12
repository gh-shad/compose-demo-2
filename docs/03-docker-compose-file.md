# 03 - The docker-compose.yml file, line by line

This one file describes the **whole application**: 4 services, 1 network and 1 volume.
Docker Compose reads it when you type `docker compose up -d`.

**Back to:** [README](../README.md) · **Previous:** [02 - Concepts](02-concepts.md) · **Next:** [04 - Demo walkthrough](04-demo-walkthrough.md)

---

## The whole file

```yaml
 1  services:
 2    web:
 3      image: nginx:latest
 4      ports:
 5        - "8080:80"
 6      volumes:
 7        - ./html:/usr/share/nginx/html:ro
 8      depends_on:
 9        - db
10      networks:
11        - app-network
12
13    db:
14      image: mysql:8.4
15      environment:
16        MYSQL_ROOT_PASSWORD: examplepassword
17      volumes:
18        - db-data:/var/lib/mysql
19      networks:
20        - app-network
21
22    adminer:
23      image: adminer:latest
24      ports:
25        - "8081:8080"
26      depends_on:
27        - db
28      networks:
29        - app-network
30
31    worker:
32      image: busybox:latest
33      command: sh -c 'while true; do echo "Worker $$(hostname) is working"; sleep 5; done'
34      networks:
35        - app-network
36
37  networks:
38    app-network:
39
40  volumes:
41    db-data:
```

(The line numbers are only for this page. They are not part of the file.)

## How to read YAML

- **Indentation (spaces at the start) shows what belongs together.** `web:` is pushed two spaces
  to the right under `services:`, so `web` is one of the services.
- `name: value` gives a setting a value, like `image: nginx:latest`.
- A line that starts with `- ` is **one item of a list**, like `- "8080:80"`.
- Always use **spaces**, never the Tab key. YAML does not allow tabs for indentation.

---

## Lines 1 to 11: the `web` service

| Line | Text | Meaning |
|---|---|---|
| 1 | `services:` | Here starts the list of all containers of the application. |
| 2 | `web:` | The first service is called `web`. This name is also its **name on the network**. |
| 3 | `image: nginx:latest` | Use the official **NGINX** web server image, tag `latest`. Docker downloads it from Docker Hub if it is not on the computer yet. |
| 4 | `ports:` | The list of doors (ports) to open from the computer into the container. |
| 5 | `- "8080:80"` | **Computer door 8080 → container door 80.** The left number is the host (the VM), the right number is inside the container. NGINX listens on door 80. The quotes stop YAML from reading `8080:80` as a strange number. |
| 6 | `volumes:` | Folders to connect into the container. |
| 7 | `- ./html:/usr/share/nginx/html:ro` | A **bind mount**: the project's `html` folder appears inside the container at `/usr/share/nginx/html`, which is where NGINX looks for web pages. So NGINX shows **our** `index.html` instead of its default page. `:ro` means **read-only**. |
| 8-9 | `depends_on:` `- db` | **Start `db` before `web`.** Note: this waits only until the db *container* has started, not until MySQL inside it is ready. That is why the script waits for MySQL separately. |
| 10-11 | `networks:` `- app-network` | Connect `web` to the private road `app-network`. |

## Lines 13 to 20: the `db` service

| Line | Text | Meaning |
|---|---|---|
| 13 | `db:` | The database service. Other containers reach it with the name `db`. |
| 14 | `image: mysql:8.4` | The official **MySQL 8.4** image. 8.4 is a long-term support (LTS) version. MySQL 5.7, used in older tutorials, reached its end of life in 2023. |
| 15-16 | `environment:` `MYSQL_ROOT_PASSWORD: examplepassword` | An **environment variable**: on its first start, MySQL sets the password of the `root` user to `examplepassword`. **Demo only!** Real projects keep passwords in a `.env` file that is never uploaded (see `.gitignore`). |
| 17-18 | `volumes:` `- db-data:/var/lib/mysql` | MySQL stores its data in `/var/lib/mysql`. This line puts that folder into the **named volume** `db-data`, outside the container. So the data survives when the container is deleted (Part 7 proves it). |
| 19-20 | `networks:` `- app-network` | Connect `db` to the private road. |

There is **no `ports:` section** here on purpose. The database is reachable only from inside
`app-network`, not from outside. This is safer.

## Lines 22 to 29: the `adminer` service

| Line | Text | Meaning |
|---|---|---|
| 22 | `adminer:` | A small web page for looking inside databases. |
| 23 | `image: adminer:latest` | The official Adminer image. |
| 24-25 | `ports:` `- "8081:8080"` | **Computer door 8081 → container door 8080.** Adminer listens on door 8080 inside its container. We use 8081 outside, because 8080 is already used by `web`. |
| 26-27 | `depends_on:` `- db` | Start `db` first. |
| 28-29 | `networks:` `- app-network` | On the same road, so Adminer can reach the server called `db`. |

## Lines 31 to 35: the `worker` service

| Line | Text | Meaning |
|---|---|---|
| 31 | `worker:` | A tiny helper service, used to show **scaling** and **logs**. |
| 32 | `image: busybox:latest` | **BusyBox**: a very small image with many basic Linux tools (including `ping`). |
| 33 | `command: sh -c '...'` | The command the container runs instead of its default one. |
| 34-35 | `networks:` `- app-network` | On the same road. |

The command on line 33, piece by piece:

| Piece | Meaning |
|---|---|
| `sh -c '...'` | Run the text in quotes with the shell `sh`. |
| `while true; do ... done` | Repeat forever. |
| `echo "Worker $$(hostname) is working"` | Print a message. `$(hostname)` is replaced by the container's name (its ID). |
| `$$` | In a compose file, `$` has a special meaning (Compose variables). `$$` means "a real `$`", so the **container** sees `$(hostname)`. |
| `sleep 5` | Wait 5 seconds before the next message. |

## Lines 37 to 41: the network and the volume

| Line | Text | Meaning |
|---|---|---|
| 37-38 | `networks:` `app-network:` | **Create** the network called `app-network`. No settings are needed. The defaults are fine. |
| 40-41 | `volumes:` `db-data:` | **Create** the named volume called `db-data`. |

## The real names on the computer

Docker Compose puts the **project name** (the folder name, here `compose-demo`) in front of
everything it creates, so different projects never mix:

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
```

---

**Next:** [04 - Demo walkthrough](04-demo-walkthrough.md)
