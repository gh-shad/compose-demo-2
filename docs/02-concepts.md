# 02 - Concepts: every idea explained simply

You do not need to know anything before reading this page.
Each idea has a short meaning, a picture from everyday life, and where you see it in the demo.

**Back to:** [README](../README.md) · **Previous:** [01 - Setup](01-setup-from-zero.md) · **Next:** [03 - The compose file](03-docker-compose-file.md)

---

## Part 1: Docker ideas

### Program and server

A **program** is a set of instructions that a computer runs, for example a web browser.
A **server** is a program that waits for requests and answers them. A **web server** answers
requests for web pages. A **database server** stores data and answers questions about it.

### Container

A **container** is like a **small sealed box** that holds one program, plus everything that
program needs to run (its files, its libraries, its settings). The box runs the same way on
every computer. Containers on the same computer are separated from each other: one container
cannot see the files or programs of another one.

*In the demo:* `web`, `db`, `adminer` and `worker` are four containers.

### Image

An **image** is the **recipe** or **template** for a container. It is a read-only package.
From one image you can start many containers, like many cakes from one recipe.
Images are downloaded from **Docker Hub**, an online library of images.

*In the demo:* `nginx:latest`, `mysql:8.4`, `adminer:latest` and `busybox:latest`.
The part after the colon (`:8.4`, `:latest`) is the **tag**: it chooses the version.
`latest` is simply the default tag name. It does not promise the newest version.

### Container vs virtual machine (VM)

| | Container | Virtual machine (VM) |
|---|---|---|
| What it is | A sealed box for one program | A whole pretend computer |
| Operating system | Shares the host's Linux kernel | Has its own full operating system |
| Size | Small (megabytes) | Big (gigabytes) |
| Start time | Seconds | Minutes |
| Picture | A room in a shared flat | A separate house |

*In the demo:* `compose-lab` is a **VM** (made by Multipass). **Inside** it, Docker runs the **containers**.

### Docker

**Docker** is the tool that downloads images and starts, stops and removes containers.
It has two parts: the **Docker client** (the `docker` command you type) and the
**Docker engine** (a background program that does the real work).

### Docker Compose

**Docker Compose** starts a **whole application made of many containers** from **one file**,
`docker-compose.yml`, with **one command**, `docker compose up -d`.

*Picture:* a music band. Each musician is a container. Docker Compose is the band leader
with one sheet of music that says who plays, who sits together, and when to start.

Note: the modern command is `docker compose` (with a space, Compose version 2).
The old `docker-compose` (with a dash, version 1) is no longer supported since 2023.

### Service

A **service** is one entry in the compose file: one job in the application.
Docker Compose starts one container per service (or more, when you scale it).

### Network

A **network** is a **private road** between containers. Containers on the same network can
talk to each other. Docker has a built-in **DNS** (a phone book) on this network: a container
can reach another one **by its service name**, for example `db`, without knowing its IP address.

*In the demo:* `app-network`. The test `ping db` proves it works.

### IP address and port

An **IP address** is the address of a computer on a network, for example `172.25.140.12`.
A **port** is a **door number** on that computer. One computer can run many servers,
each behind its own door.

*In the demo:* `"8080:80"` means: door **8080** of the VM leads to door **80** inside the `web` container.

### Volume

A **volume** is a **safe storage locker outside the container**. Containers are temporary:
when you delete a container, everything inside it is gone. Data saved in a volume stays,
even when every container is deleted.

*In the demo:* the `db-data` volume keeps the MySQL data. Part 7 proves that the data survives.

### Bind mount

A **bind mount** connects a **folder of your computer** to a folder inside a container.

*In the demo:* `./html:/usr/share/nginx/html:ro` shows your own `html` folder inside the web
container. `:ro` means **read-only**: the container can read the files, but cannot change them.

### Environment variable

An **environment variable** is a **named setting** that a program reads when it starts.

*In the demo:* `MYSQL_ROOT_PASSWORD: examplepassword` tells MySQL which password to use.
(In a real project, passwords are kept in a separate `.env` file that is never uploaded.)

### Scaling

**Scaling** means running **more copies** of the same service to handle more work.

*In the demo:* `docker compose up -d --scale worker=3` runs three copies of `worker`.
A real website would put a **load balancer** in front of its copies to share the visitors.

### Logs

**Logs** are the messages that a program prints while it runs. Docker keeps them for every container.

*In the demo:* `docker compose logs worker --tail 6`.

### YAML

**YAML** is a simple text format for settings. The **spaces** at the start of a line matter:
a line that is pushed to the right belongs to the line above it, like items and sub-items in a list.

---

## Part 2: Tools around the demo

### Multipass

**Multipass** is a free tool from Canonical (the company behind Ubuntu) that creates
Ubuntu virtual machines with one command.

### cloud-init

**cloud-init** is a standard tool that **sets up a new Linux machine on its first start**.
It reads a file (here `cloud-init.yaml`) that says which programs to install and which commands to run.

### Terminal, shell and script

A **terminal** is a window where you type commands. A **shell** (here **bash**) is the program
that reads and runs those commands. A **script** is a text file full of commands that run one
after the other, like `demo.sh`.

### SHA-256 fingerprint (checksum)

**SHA-256** turns the content of a file into a long number, called a **hash** or **fingerprint**.
The same content always gives the same fingerprint. If **even one letter** changes, the
fingerprint is completely different. That is why it is used to prove that files are unchanged.

*In the demo:* `sha256sum` makes fingerprints at the start, and Part 10 checks them again.

---

## Part 3: Git and GitHub ideas

### Git and version control

**Git** is a **version control** tool: it remembers every saved version of your project.
You can see what changed, when, and by whom, and you can go back to any older version.

### Repository (repo)

A **repository** is a project folder that Git tracks. Git keeps the whole history in a hidden
folder inside it, called `.git`.

### Commit

A **commit** is a **save point**, like in a video game. It stores a snapshot of the files,
a short message, the author's name and email, and a unique ID (for example `1a2b3c4`).

### Staging area

The **staging area** is a **box** where you put the changes that should go into the next commit.
`git add` puts files into the box. `git commit` saves the box as a commit.

### Branch

A **branch** is a line of work. The main line is called `main`.

### .gitignore

A file with a list of files that Git must **never** save, for example passwords (`.env`) and log files.

### GitHub

**GitHub** is a website that keeps Git repositories online, so other people can see, download and use them.

### Remote, origin and upstream

A **remote** is a link from your folder to a repository on GitHub.
`origin` is the usual name of **your own** online repository.
`upstream` is the usual name of **someone else's** repository that you copied from.

### Push, pull and clone

| Word | Direction | Meaning |
|---|---|---|
| **push** | your computer → GitHub | upload your new commits |
| **pull** | GitHub → your computer | download new commits |
| **clone** | GitHub → your computer | download a whole repository for the first time |

Easy way to remember: you **push** a box **away** from you, and you **pull** a rope **towards** you.

### GitHub CLI (gh)

**gh** is GitHub's official command-line tool. It logs in to GitHub and creates and changes
repositories from the terminal, for example `gh repo create`.

### Login token and scopes

When `gh` logs in, GitHub gives it a secret **token** (a long password just for this tool).
**Scopes** are the permissions of the token. `repo` lets it work with repositories.
`workflow` lets it upload the automatic test files in `.github/workflows/`.

### GitHub Actions (CI)

**GitHub Actions** runs tasks on GitHub's own computers, for example after every push.
This is called **CI (continuous integration)**: every change is tested automatically.
*In this project:* `.github/workflows/demo-test.yml` runs the whole Docker demo on GitHub.

---

## Glossary (A to Z)

| Word | Short meaning |
|---|---|
| Adminer | A small web page for looking inside a database |
| bash | The program that runs commands in a Linux terminal |
| Bind mount | A folder of the computer shown inside a container |
| BusyBox | A tiny Linux toolbox in one small image |
| CI | Continuous integration: automatic tests after every change |
| Clone | Download a whole repository from GitHub |
| cloud-init | Sets up a new Linux machine on its first start |
| Commit | A save point in Git |
| Container | A sealed box that runs one program |
| Daemon / engine | A program that runs in the background (the Docker engine) |
| DNS | The "phone book" that turns names into IP addresses |
| Docker | The tool that runs containers |
| Docker Compose | Starts many containers from one file |
| Docker Hub | The online library of images |
| Environment variable | A named setting a program reads when it starts |
| gh | The GitHub command-line tool |
| Git | The version control tool |
| GitHub | The website for Git repositories |
| Hash / SHA-256 | A fingerprint of a file's content |
| Hyper-V | The virtual machine feature of Windows Pro |
| Image | The template for a container |
| IP address | The address of a computer on a network |
| Load balancer | Shares visitors between many copies of a website |
| Logs | Messages a program prints while it runs |
| Multipass | Creates Ubuntu virtual machines |
| MySQL | A popular database server |
| Network | A private road between containers |
| NGINX | A popular web server |
| origin | The usual name of your own online repository |
| Port | A door number on a computer |
| Pull | Download new commits from GitHub |
| Push | Upload new commits to GitHub |
| Repository | A project folder tracked by Git |
| Scaling | Running more copies of a service |
| Scope | A permission of a login token |
| Service | One job (one entry) in the compose file |
| Staging area | The box of changes for the next commit |
| Tag | The version part of an image name, after the colon |
| upstream | The usual name of someone else's original repository |
| VM (virtual machine) | A whole pretend computer inside your computer |
| Volume | A safe storage locker outside the container |
| YAML | A simple text format for settings |

---

**Next:** [03 - The docker-compose.yml file, line by line](03-docker-compose-file.md)
