# CI/CD Pipeline for Flask Application using Terraform, Ansible & GitHub Actions

This project demonstrates a **fully automated DevOps CI/CD pipeline** to deploy a Flask application on AWS EC2 using **Terraform**, **Ansible**, and **GitHub Actions**.

The pipeline provisions infrastructure, configures the server, deploys the application, and exposes it via NGINX and Gunicorn.

---

## Project Overview

The workflow follows a GitOps-based automation approach:

1. Developer pushes code to GitHub
2. GitHub Actions pipeline is triggered
3. Terraform provisions AWS infrastructure (EC2, Security Group, Key Pair)
4. Terraform stores state securely in an S3 backend
5. GitHub Actions updates Ansible inventory using EC2 Public IP
6. Ansible configures the server and deploys the Flask application
7. Application is accessible via the EC2 Public IP

---

## Repository Structure

devops-project1/
│── .github/workflows/
│ └── cicd.yml # GitHub Actions CI/CD pipeline
│
│── ansible/
│ ├── playbook.yml # Server setup + Flask app deployment
│ ├── inventory # EC2 public IP inventory
│ └── keys/
│ ├── id_rsa # Private SSH key
│ └── id_rsa.pub # Public key (used by Terraform)
│
│── app/
│ ├── app.py # Flask application
│ └── requirements.txt # Python dependencies
│
│── terraform/
│ ├── main.tf # EC2, Security Group, Key Pair
│ ├── provider.tf # AWS provider and S3 backend
│ ├── outputs.tf # EC2 Public IP output
│ └── variables.tf # Terraform variables


---

## Technologies Used

- **AWS EC2** – Compute infrastructure
- **Terraform** – Infrastructure provisioning
- **Ansible** – Configuration management and deployment
- **GitHub Actions** – CI/CD automation
- **Flask** – Python web framework
- **Gunicorn** – WSGI application server
- **NGINX** – Reverse proxy web server

---

## Terraform Infrastructure

Terraform is responsible for provisioning AWS resources.

### Resources Created
- EC2 instance (Ubuntu 22.04)
- Security Group (HTTP & SSH access)
- Key Pair for SSH access
- S3 backend for Terraform remote state

### S3 Backend
Terraform state is stored remotely in an S3 bucket to ensure:
- State consistency
- Secure storage
- Team collaboration

---

## GitHub Actions CI/CD Pipeline

The CI/CD workflow (`cicd.yml`) performs the following steps:

1. Checks out the source code
2. Configures AWS credentials
3. Runs Terraform:
   - `terraform init`
   - `terraform plan`
   - `terraform apply -auto-approve`
4. Extracts EC2 Public IP
5. Updates Ansible inventory dynamically
6. Executes Ansible playbook to deploy the application

---

## Ansible Configuration

Ansible automates server configuration and application deployment.

### Tasks Performed
- Install Python3, pip, virtualenv
- Install NGINX and Gunicorn
- Create Python virtual environment
- Install Flask dependencies
- Deploy application files
- Configure Gunicorn systemd service
- Configure NGINX reverse proxy

### Application Flow
- NGINX listens on port **80**
- Gunicorn runs Flask app on **localhost:5000**
- NGINX forwards traffic to Gunicorn

---

## Deployment Flow

1. Code pushed to GitHub
2. GitHub Actions pipeline starts
3. Terraform provisions AWS infrastructure
4. EC2 Public IP is generated
5. Ansible connects via SSH
6. Server is configured and Flask app is deployed
7. Application becomes live

Access the application using:

http://<EC2_PUBLIC_IP>/


---

## Architecture Overview

**CI/CD Layer**
- Developer
- GitHub Repository
- GitHub Actions

**Infrastructure Layer**
- Terraform
- S3 Backend
- EC2 Instance
- Security Group
- Key Pair

**Application Layer**
- Ansible
- NGINX
- Gunicorn
- Flask Application

---

## Key Features

- Fully automated CI/CD pipeline
- Infrastructure as Code using Terraform
- Configuration management using Ansible
- Secure remote Terraform state
- GitOps-based deployment
- Scalable and reproducible architecture

---

## Conclusion

This project showcases an end-to-end DevOps pipeline that automates infrastructure provisioning, server configuration, and application deployment using modern DevOps tools. It follows best practices such as Infrastructure as Code, configuration management, and CI/CD automation.

---

## Author

**Manikanta Kurumoji**

































