# CI/CD Pipeline for Flask App — Terraform, Ansible & GitHub Actions on AWS

A fully automated DevOps workflow to provision infrastructure on AWS and deploy a Flask application onto an EC2 instance using **Terraform**, **Ansible**, and **GitHub Actions**.

---

<img width="1046" height="1244" alt="Project" src="https://github.com/user-attachments/assets/9b08f585-8eda-4eee-a1b3-018259106884" />


## Overview

This project implements an end-to-end CI/CD pipeline:

1. Developer pushes code to GitHub → triggers GitHub Actions.
2. GitHub Actions runs Terraform to provision AWS infrastructure (EC2, Security Group, Key Pair) and stores Terraform state in S3.
3. Terraform outputs the EC2 public IP.
4. GitHub Actions updates the Ansible inventory using the EC2 public IP.
5. Ansible configures the EC2 instance (Python, virtualenv, Gunicorn, NGINX) and deploys the Flask app.
6. The Flask application is served via Gunicorn behind NGINX and is accessible using the EC2 public IP.

---



## Setup Instructions

### 1. Prerequisites

#### Local / Repository Requirements

Your GitHub repository **must** contain the following structure:

* `terraform/` → All Terraform configuration files
* `ansible/deploy.yml` → Main Ansible playbook for deployment
* `app/` → Flask application source code
* `.github/workflows/ci-cd.yml` → GitHub Actions CI/CD workflow

---

### 2. AWS Requirements

* AWS Account
* IAM User with the following **minimum required permissions**:

  * `AmazonEC2FullAccess`
  * `AmazonS3FullAccess`
  * `IAMReadOnlyAccess`
  * `AmazonVPCReadOnlyAccess`

> These IAM user credentials will be stored securely in **GitHub Secrets**.

---

### 3. EC2 Key Pair (Manual Setup)

The EC2 key pair **must be created manually**.

Steps:

1. Go to **AWS Console → EC2 → Key Pairs**
2. Create a new key pair (example: `deva-key`)
3. Download the `.pem` file
4. Open the `.pem` file and copy its contents
5. Store the content in GitHub Secrets as `SSH_PRIVATE_KEY`

This key is required for:

* Terraform to associate the EC2 instance with the key pair
* GitHub Actions (via Ansible) to SSH into the EC2 instance

---

### 4. GitHub Secrets Configuration

Go to:

```
GitHub Repo → Settings → Secrets → Actions
```

Add the following secrets:

| Secret Name             | Description                        |
| ----------------------- | ---------------------------------- |
| `AWS_ACCESS_KEY_ID`     | IAM user access key                |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key                |
| `SSH_PRIVATE_KEY`       | Content of the EC2 `.pem` key file |

---

## Repository Structure

```
.
├── .github/workflows/
│   └── cicd.yml              # GitHub Actions CI/CD pipeline
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf          # S3 backend configuration
│
├── ansible/
│   ├── inventory             # Updated dynamically by CI
│   ├── playbook.yml          # Server setup & app deployment
│   └── keys/
│       └── id_rsa.pub        # Public SSH key
│
├── app/
│   ├── app.py
│   └── requirements.txt
│
└── README.md
```

---

## Key Components

### Terraform — AWS Infrastructure Provisioning

Terraform provisions the following AWS resources:

* EC2 instance (Ubuntu 22.04, t2.micro)
* Security Group (SSH 22, HTTP 80)
* Key Pair (using Ansible public key)
* S3 backend for Terraform state storage

#### Example S3 Backend Configuration

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

#### Example Key Pair Resource

```hcl
resource "aws_key_pair" "main_key" {
  key_name   = "main-static-key"
  public_key = file("${path.module}/../ansible/keys/id_rsa.pub")
}
```

Terraform outputs the EC2 public IP which is consumed by GitHub Actions.

---

### GitHub Actions — CI/CD Automation

Workflow path:

```
.github/workflows/cicd.yml
```

Pipeline steps:

1. Checkout repository
2. Configure AWS credentials
3. Terraform init, plan, apply
4. Capture EC2 public IP from Terraform output
5. Update Ansible inventory
6. Execute Ansible playbook

#### Example Inventory Update Step

```bash
EC2_IP=$(terraform output -raw instance_public_ip)
sed -i "s/{{EC2_PUBLIC_IP}}/${EC2_IP}/g" ansible/inventory
```

---

### Ansible — Server Configuration & Deployment

Ansible handles:

* Installing Python, pip, virtualenv
* Installing Gunicorn and NGINX
* Deploying Flask app
* Configuring systemd service for Gunicorn
* Configuring NGINX reverse proxy

#### Gunicorn systemd Service Example

```ini
[Unit]
Description=Gunicorn daemon for Flask app
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

#### NGINX Configuration Example

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

---

## Deployment Flow (Summary)

1. Code pushed to GitHub
2. GitHub Actions triggered
3. Terraform provisions infrastructure
4. EC2 public IP captured
5. Ansible inventory updated
6. Flask app deployed and started
7. App available at:

```
http://<EC2_PUBLIC_IP>/
```

---

## Security Best Practices

* ❌ Never commit private keys to GitHub
* ✅ Use GitHub Secrets for credentials
* ✅ Restrict SSH access in Security Groups
* ✅ Use encrypted S3 backend for Terraform state

---

## Author 

* **Author:** MANIKANTA3224


---

⭐ This project demonstrates a complete real-world DevOps CI/CD pipeline using AWS, Terraform, Ansible, and GitHub Actions.
