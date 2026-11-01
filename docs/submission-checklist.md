# Submission checklist

Work through this top to bottom. The last section is the one that costs money if skipped.

## Before recording

- [ ] Repo is **public** and contains `index.html`, `nginx.conf`, `Dockerfile`, `README.md`
- [ ] No `.pem` file or AWS credentials committed (`git ls-files | grep pem` returns nothing)
- [ ] Local `docker build` and `curl -I http://localhost:8081` both succeed
- [ ] Security group: SSH 22 from *your* IP only, TCP 8081 from `0.0.0.0/0`
- [ ] Page loads at `http://<public-ip>:8081` from your laptop, not just from the server

## Must be visible on the Loom recording (one take, face + screen)

- [ ] Instance specs: instance type, vCPU, RAM, disk — and why that size
- [ ] Security group inbound rules, on screen
- [ ] GitHub repo in a browser: files, `Dockerfile`, `README.md`
- [ ] `docker ps` with the container `Up (healthy)`
- [ ] Browser hit on `http://<public-ip>:8081` from your own machine
- [ ] (Only if attempted) ECS console with a running service

Do not show the private key, AWS credentials, or the account email.

## Before replying to the recruiter

- [ ] Loom link is set to "anyone with the link can view"
- [ ] Repo link opens in an incognito window
- [ ] Written note is 5–6 lines, and every problem in it actually happened

## Cleanup — do not skip

- [ ] `sudo docker rm -f tericsoft-web` (optional, the instance is going away anyway)
- [ ] EC2 instance **terminated** (not merely stopped)
- [ ] Attached EBS volume deleted with the instance
- [ ] Elastic IP released, if one was allocated
- [ ] If ECS was attempted: service, cluster, task definition, ALB, and ECR repo deleted
- [ ] Billing → Free tier page shows no lingering usage tomorrow
