CI/CD Pipeline for Flask App using Terraform, Ansible & GitHub Actions in AWS
This project implements a fully automated DevOps workflow to deploy a Flask application on AWS EC2 using Terraform, Ansible, and GitHub Actions.
Architecture Diagram
<img width="627" height="716" alt="image" src="https://github.com/user-attachments/assets/bddfaff5-a1d4-4cb7-b4be-e2a813705575" />

 

The pipeline automates infrastructure provisioning, server configuration, and application deployment:
1.	Developer pushes code to GitHub → triggers GitHub Actions.
2.	Terraform provisions AWS infrastructure (EC2, Security Group, Key Pair) and stores state in S3.
3.	GitHub Actions passes EC2 Public IP to Ansible inventory.
4.	Ansible configures the server: Python, virtualenv, Gunicorn, NGINX
5.	Flask app is deployed and served through NGINX + Gunicorn.
6.	Application is accessible via the EC2 Public IP.
Repository Structure:
<img width="288" height="456" alt="image" src="https://github.com/user-attachments/assets/eb139388-d7d9-4db2-a2c1-749f99b10c03" />

3. Terraform (AWS Provisioning)
   
3.1 Security Group
    •	Allows HTTP (80) and SSH (22).
    •	Outbound traffic: all allowed.

3.2 Key Pair
    resource "aws_key_pair" "main_key" {
         key_name   = "main-static-key"
         public_key = file("${path.module}/../ansible/keys/id_rsa.pub")
      }
3.3 EC2 Instance
    •	AMI: Ubuntu 22.04
    •	Type: t2.micro
    •	Key Pair: main-static-key
    •	Security Group: web-sg

3.4 S3 Backend
       backend "s3" {
  	       bucket  = "devops-tfstate-bucket-manikanta"
  	       key     = "ec2-project/terraform.tfstate"
  	       region  = "ap-southeast-1"
  	       encrypt = true
         }

4. GitHub Actions CI/CD
Workflow: .github/workflows/cicd.yml
1.	Checkout repo
2.	Configure AWS credentials
3.	Terraform commands
<img width="161" height="77" alt="image" src="https://github.com/user-attachments/assets/3d432e6f-bce4-4fae-a448-69eb24065525" />



4.	Update Ansible inventory with EC2 Public IP:
	<img width="426" height="54" alt="image" src="https://github.com/user-attachments/assets/813a52db-a7c3-469e-bce7-ce44e4e5760f" />


5.	Run Ansible Playbook
   <img width="294" height="33" alt="image" src="https://github.com/user-attachments/assets/54be61df-ea12-470a-b63f-60f42bf4e08c" />



5. Ansible (Server Setup & Deployment)
Tasks performed:
1	Install Python3, pip, virtualenv, Gunicorn, NGINX.
2	Create virtual environment:
   (python3 -m venv /home/ubuntu/venv)
3	Install Flask dependencies:
   (pip install -r requirements.txt)
4	Deploy app to /home/ubuntu/app/.
5	Configure Gunicorn systemd service:
   (ExecStart={{ venv_dir }}/bin/gunicorn -w 3 -b 127.0.0.1:{{ flask_port }} app:app)
6	Configure NGINX as reverse proxy (port 80 → Gunicorn port 5000).

6. Deployment Flow
•	Developer pushes code → GitHub Actions triggers.
•	Terraform provisions EC2, SG, Key Pair.
•	Terraform outputs Public IP.
•	GitHub Actions updates Ansible inventory.
•	Ansible configures server & deploys app.
•	Application is live at:

http://<EC2_PUBLIC_IP>/

7. Architecture Diagram
Components:
•	Source & CI/CD: Developer → GitHub → GitHub Actions
•	Infrastructure: Terraform → S3 (state) → EC2 + SG + Key Pair
•	Configuration & App Layer: Ansible → NGINX + Gunicorn → Flask app
•	Client: Browser → EC2 Public IP

8. Summary
•	Automated CI/CD pipeline: Terraform + Ansible + GitHub Actions.
•	Terraform provisions AWS infra and uses S3 backend.
•	Ansible handles server setup & app deployment.
•	Flask app is served via NGINX + Gunicorn and publicly accessible.
•	Workflow follows a GitOps approach for end-to-end automation.



     




