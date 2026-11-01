# Tericsoft DevOps Internship Task

A static web application packaged in a Docker image and deployed on AWS EC2, publicly
reachable at `http://<ec2-public-ip>:8081`.

The image serves on **port 8081** internally, so the host mapping is 1:1 (`-p 8081:8081`)
and there is only one port number to reason about.

## Repository contents

| File | Purpose |
| --- | --- |
| `index.html` | The page served to visitors |
| `nginx.conf` | nginx server block: listens on 8081, static file root, `/healthz` endpoint |
| `Dockerfile` | Builds the image from `nginx:1.27-alpine`, exposes 8081, adds a healthcheck |
| `.gitignore` | Keeps the SSH key (`*.pem`) and local files out of the repo |
| `docs/submission-checklist.md` | Pre-submission checks, including resource cleanup |

## Architecture

```
Browser
  │  http://<ec2-public-ip>:8081
  ▼
EC2 security group           inbound TCP 8081 from 0.0.0.0/0
  │                          inbound TCP 22   from <your-ip>/32
  ▼
EC2 instance (Ubuntu, Docker Engine)
  │  port mapping 8081:8081
  ▼
Container "tericsoft-web"
  │  nginx listening on 8081
  ▼
index.html
```

Traffic is allowed at two independent layers: the AWS security group (cloud firewall)
and Docker's published port (host → container). Both must line up with 8081.

`docker inspect` also lists `80/tcp`, inherited from the `nginx:alpine` base image;
Docker cannot remove an inherited `EXPOSE`. Nothing binds port 80 in this image — the
nginx server block listens on 8081 only.

## Requirements

- Docker Engine 24+ (or Docker Desktop) to build and run the image
- An AWS account with EC2 permissions

## Verified deployment environment

This image was built and deployed on:

| | |
| --- | --- |
| OS | Ubuntu Server 26.04.1 LTS, x86-64 |
| Instance | EC2 `t3.micro`, 2 vCPU, ~900 MiB RAM |
| Storage | 8 GiB gp3 |
| Region | `eu-north-1` (Stockholm) |
| Docker | Engine 29.9.2 |
| Verification | `HTTP 200` from an external network on port 8081 |

## Run locally

```bash
docker build -t tericsoft-web .
docker run -d --name tericsoft-web -p 8081:8081 tericsoft-web
```

Check it:

```bash
curl -I http://localhost:8081          # expect HTTP/1.1 200 OK
docker ps                              # container should be "Up (healthy)"
```

Open <http://localhost:8081> to see the page. Stop and remove it with:

```bash
docker rm -f tericsoft-web
```

## Deploy on EC2

### 1. Launch the instance

- **AMI:** Ubuntu Server LTS (x86-64) — tested on 26.04.1; 24.04 works identically
- **Type:** `t3.micro` (or `t2.micro`) — 2 vCPU burst, 1 GiB RAM. Enough for one nginx
  container; larger types only add cost for a static page.
- **Storage:** 8 GiB gp3
- **Key pair:** create a new `.pem` key and keep it off the repo

### 2. Security group

| Type | Port | Source | Why |
| --- | --- | --- | --- |
| SSH | 22 | your IP `/32` | administration, not the whole internet |
| Custom TCP | 8081 | `0.0.0.0/0` | the app must be publicly reachable |

### 3. Install Docker on the instance

```bash
sudo apt update && sudo apt install -y ca-certificates curl git

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run --rm hello-world      # verification step
```

### 4. Build and start the app

```bash
git clone https://github.com/<your-username>/tericsoft-devops-task.git
cd tericsoft-devops-task

sudo docker build -t tericsoft-web .

sudo docker run -d \
  --name tericsoft-web \
  --restart unless-stopped \
  -p 8081:8081 \
  tericsoft-web
```

### 5. Verify

```bash
sudo docker ps
curl -I http://localhost:8081     # HTTP/1.1 200 OK
```

Then, from your own machine (not the server), open `http://<ec2-public-ip>:8081`.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| SSH times out | Port 22 not open to your current IP, or instance still initialising | Update the security group; wait 1–2 min after launch |
| `ssh: no such file` / `Load key: invalid format` | The downloaded key is PuTTY `.ppk`, not OpenSSH `.pem` | Download the `.pem`, or convert: `puttygen task.ppk -O private-openssh -o task.pem` |
| `permission denied` running docker | User is not in the `docker` group | Use `sudo docker ...` |
| Build fails with "no such file" | Wrong directory, or `nginx.conf` / `index.html` missing | `ls` the repo root, rebuild from there |
| Local `curl` works, public URL does not | Inbound 8081 missing, or a host firewall (ufw) is active | Add the rule / `sudo ufw allow 8081/tcp` |
| `port is already allocated` | Another container or process holds 8081 | `sudo docker ps`, `sudo ss -lntp` |
| Browser shows stale content | Image was not rebuilt after editing `index.html` | Rebuild, then `docker rm -f` and run again |

## Cleanup (do this after recording)

```bash
sudo docker rm -f tericsoft-web
```

Then in the AWS console: **terminate** the EC2 instance and confirm the attached EBS volume
is deleted, and release any Elastic IP you allocated.
