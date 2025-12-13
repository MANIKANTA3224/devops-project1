# CI/CD Pipeline for Flask App — Terraform, Ansible & GitHub Actions on AWS

A fully automated DevOps workflow to provision infrastructure on AWS and deploy a Flask application onto an EC2 instance using Terraform, Ansible and GitHub Actions.

---

## Overview

This project implements an end-to-end pipeline:

1. Developer pushes code to GitHub → triggers GitHub Actions.
2. GitHub Actions runs Terraform to provision AWS infra (EC2, Security Group, Key Pair) and persists state in S3.
3. Terraform outputs the EC2 public IP.
4. GitHub Actions updates the Ansible inventory with the EC2 public IP.
5. Ansible configures the server (Python, virtualenv, Gunicorn, NGINX) and deploys the Flask app.
6. The app is served via Gunicorn behind NGINX and is accessible using the EC2 public IP.

Architecture Diagram
- (Add your diagram image file to the repo and reference it here)
- Example: `docs/architecture.png`

---

## Repository Structure (example)

- .github/workflows/cicd.yml          # GitHub Actions workflow
- terraform/
  - main.tf
  - variables.tf
  - outputs.tf
  - backend.tf                        # S3 backend config
- ansible/
  - inventory                         # Template inventory updated by CI
  - playbook.yml
  - roles/
    - app/
      - tasks/
      - templates/
  - keys/
    - id_rsa.pub
    - id_rsa
- app/
  - requirements.txt
  - app.py
  - wsgi.py
- docs/
  - architecture.png

(Adjust the structure to match your repo.)

---

## Key Components

### Terraform (AWS Provisioning)

- Provisions:
  - Security Group (allows HTTP 80 and SSH 22)
  - EC2 instance (Ubuntu 22.04, t2.micro, key pair)
  - Key Pair (reads public key from `ansible/keys/id_rsa.pub`)
- S3 backend stores encrypted terraform state.

Example backend configuration (terraform/backend.tf)
```hcl
terraform {
  backend "s3" {
    bucket  = "devops-tfstate-bucket-manikanta"
    key     = "ec2-project/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
```

Example key-pair resource
```hcl
resource "aws_key_pair" "main_key" {
  key_name   = "main-static-key"
  public_key = file("${path.module}/../ansible/keys/id_rsa.pub")
}
```

EC2 instance notes:
- AMI: Ubuntu 22.04 (use appropriate AMI id per region)
- Instance type: t2.micro
- SSH key: `main-static-key`
- Security group: allows inbound 22 and 80, outbound all

Terraform should output the instance public IP (e.g., `instance_public_ip`) to be consumed by CI.

---

### GitHub Actions (CI/CD)

Workflow path: `.github/workflows/cicd.yml`

Typical job steps:
1. Checkout repository
2. Configure AWS credentials (via `aws-actions/configure-aws-credentials`)
3. terraform init/plan/apply (use auto-approve or manual approval as you prefer)
4. Capture Terraform output for EC2 Public IP
5. Update Ansible inventory (replace placeholder host with the public IP)
6. Run Ansible playbook to configure & deploy app

Example snippet to capture terraform output and update inventory (bash):
```bash
# Run in the GitHub Actions runner after terraform apply
EC2_IP=$(terraform output -raw instance_public_ip)
# Replace placeholder in ansible/inventory (inventory template should have e.g. [web] x.x.x.x)
sed -i "s/{{EC2_PUBLIC_IP}}/${EC2_IP}/g" ansible/inventory
```

Make sure to store AWS credentials and any secrets as GitHub Actions secrets.

---

### Ansible (Server Setup & Deployment)

Main responsibilities:
- Install Python3, pip, virtualenv, Gunicorn, NGINX.
- Create a venv, e.g. `/home/ubuntu/venv`.
- Copy application to `/home/ubuntu/app/`.
- Install app dependencies: `pip install -r requirements.txt` inside the venv.
- Configure Gunicorn systemd service.
- Configure NGINX as a reverse proxy (port 80 → Gunicorn port, typically 5000).
- Ensure service is started and enabled.

Example Gunicorn systemd unit (template):
```ini
[Unit]
Description=gunicorn daemon for Flask app
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/app
Environment="PATH=/home/ubuntu/venv/bin"
ExecStart=/home/ubuntu/venv/bin/gunicorn -w 3 -b 127.0.0.1:5000 app:app

[Install]
WantedBy=multi-user.target
```

Example NGINX server block (template)
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Typical Ansible playbook tasks:
- apt update & install packages
- python3 -m venv /home/ubuntu/venv
- copy app files to `/home/ubuntu/app/`
- pip install -r /home/ubuntu/app/requirements.txt
- install and enable gunicorn systemd unit
- configure NGINX, remove default site, restart services

---

## Deployment Flow (summary)

1. Push code to repository → GitHub Actions triggered.
2. Terraform provisions/updates resources and writes state to S3.
3. Terraform outputs EC2 public IP.
4. CI updates Ansible inventory with that public IP.
5. CI runs Ansible playbook to configure server & deploy the Flask app.
6. Application is available at `http://<EC2_PUBLIC_IP>/`.

---

## How to Use (local / CI guidelines)

Prerequisites:
- AWS account & IAM credentials with permissions for EC2, S3, IAM (if needed), VPC.
- Terraform v1.x
- Ansible 2.9+ (or latest)
- Python 3.8+
- Add your SSH key pair public key to `ansible/keys/id_rsa.pub` (and keep private key secure)

Local test flow (high level):
1. Put your public key at `ansible/keys/id_rsa.pub`.
2. terraform init && terraform apply -auto-approve
3. Grab the public IP: `terraform output -raw instance_public_ip`
4. Update `ansible/inventory` with the IP, or run:
   `ansible-playbook -i ansible/inventory ansible/playbook.yml --private-key ansible/keys/id_rsa`
5. Visit `http://<EC2_PUBLIC_IP>/`

CI flow:
- Configure GitHub repository secrets for AWS access and any other credentials.
- Ensure the Actions workflow runs terraform and then Ansible with the private key (or use SSH agent and secrets).

Security note:
- Do not commit private keys to the repo. Use GitHub Secrets and/or a secure secrets manager.
- Limit security group (SSH) to trusted IPs if necessary.

---

## Files to Customize

- `.github/workflows/cicd.yml` — Customize steps, region, and permissions.
- `terraform/variables.tf` — set region, instance type, AMI id (per region), bucket name.
- `ansible/inventory` — template to be filled by CI with EC2 public IP.
- `ansible/playbook.yml` and roles — edit for your app specifics (entrypoint, port).
- `ansible/keys/id_rsa.pub` — public key used by Terraform to create key-pair.

---

## Tips & Troubleshooting

- AMI selection: use official Ubuntu 22.04 AMI ID for your AWS region.
- If Terraform cannot read the public key path, ensure relative path is correct (`path.module` usage).
- Verify S3 backend bucket exists and proper IAM permissions are configured.
- Use `terraform output -json` for structured output parsing in CI.
- Use `ssh -i ansible/keys/id_rsa ubuntu@<EC2_IP>` to debug server configuration manually.

---

## Example Variables (terraform/variables.tf)
```hcl
variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type    = string
  default = "main-static-key"
}
```

---

## License & Author

- Author: MANIKANTA3224
- License: (add your preferred license here, e.g., MIT)

---

If you want, I can:
- Generate a ready-to-use `.github/workflows/cicd.yml` example for this pipeline.
- Provide a complete Terraform module and Ansible playbook skeleton to drop into the repo.
- Add a sample architecture diagram file and embed it in the README.
