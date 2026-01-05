# 🚀 GitHub → ECR → EKS CI/CD Pipeline (OIDC + Trivy)

> **This section explains how to set up this project from scratch** — from cloning the repo to deploying your first application on EKS using GitHub Actions.

This repository demonstrates a **production‑grade CI/CD pipeline** that builds a Node.js application, scans it for vulnerabilities, pushes the Docker image to **Amazon ECR**, and deploys it to **Amazon EKS** using **GitHub Actions with OIDC authentication** (no AWS keys).

The setup follows **DevOps / SRE / DevSecOps best practices** and is fully automated end‑to‑end.

---

## 🧩 Architecture Overview

Before setup, ensure you understand the high-level flow:

```
Developer Push → GitHub Actions
        ↓
   npm install / test
        ↓
   Docker Build
        ↓
   Trivy Security Scan (warn only)
        ↓
   Push Image to Amazon ECR
        ↓
   Update Image in EKS Deployment
        ↓
   Rolling Update (Zero Downtime)
```

---

## 📂 Repository Structure

```
.
├── Dockerfile              # Application container image
├── Makefile                # Local automation (infra + deploy)
├── config.env              # Environment configuration
├── package.json            # Node.js dependencies
├── server.js               # Application entry point
├── k8s/                     # Kubernetes manifests
│   ├── namespace.yml
│   ├── deployment.yaml
│   └── service.yaml
├── terraform/               # Infrastructure as Code (AWS)
│   ├── vpc.tf
│   ├── eks.tf
│   ├── ecr.tf
│   ├── github-iam-oidc.tf
│   ├── provider.tf
│   └── variables.tf
└── .github/workflows/
    └── eks-ci-cd.yml        # GitHub Actions pipeline
```

---

## 🔐 Authentication (OIDC – No AWS Keys)

This project uses **GitHub OpenID Connect (OIDC)** to authenticate GitHub Actions to AWS.

### Why OIDC?

* ✅ No long‑lived AWS access keys
* ✅ Short‑lived, secure credentials
* ✅ Industry best practice

GitHub assumes an IAM role:

```
arn:aws:iam::<ACCOUNT_ID>:role/github-oidc-role
```

The trust policy restricts access to:

```
repo:nitinbhardwaj297/github-eks:ref:refs/heads/main
```

---

## 🏗️ Infrastructure (Terraform)

### ✅ Prerequisites

Before starting, make sure you have:

* An **AWS account**
* An **IAM user or role** with permissions for:

  * EKS
  * ECR
  * IAM
  * VPC
* **Terraform >= 1.5**
* **AWS CLI v2**
* **kubectl**
* **Docker**
* A **GitHub repository** (fork or clone this one)

Verify tools:

```bash
aws --version
terraform --version
kubectl version --client
docker --version
```

Terraform provisions:

* **VPC** (public & private subnets)
* **Amazon EKS** (managed node group)
* **Amazon ECR** (with force_delete enabled)
* **IAM OIDC Provider** for GitHub
* **IAM Role & Policy** for CI/CD

### Create Infrastructure

```bash
make all
```

### Destroy Infrastructure

```bash
make destroy
```

> ⚠️ ECR uses `force_delete = true` so repositories are deleted even if images exist (safe for non‑prod).

---

## ⚙️ Configuration (`config.env`)

This file is used by the **Makefile** and local workflows.

```env
# =========================================================
# AWS CONFIG
# =========================================================
AWS_ACCOUNT_ID=867344428970
AWS_REGION=us-east-1
CLUSTER_NAME=thor-eks
ECR_REPOSITORY=thor

# =========================================================
# KUBERNETES CONFIG
# =========================================================
K8S_NAMESPACE=asgard
DEVELOPER_NAME=nitin
```

> ⚠️ Update values if you are using a different AWS account, region, or cluster name.

```env
AWS_ACCOUNT_ID=867344428970
AWS_REGION=us-east-1
CLUSTER_NAME=thor-eks
ECR_REPOSITORY=thor-ecr
K8S_NAMESPACE=asgard
```

These values are reused by:

* Makefile
* Terraform
* GitHub Actions

---

## 🧱 Terraform Variables (Reference)

These variables are defined in `terraform/variables.tf` and control infrastructure creation.

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "github_username" {
  default = "nitinbhardwaj297"
}

variable "github_repo_name" {
  default = "github-eks"
}

variable "k8s_cluster_name" {
  default = "thor-eks"
}

variable "k8s_namespace" {
  default = "asgard"
}

variable "ECR_REPO" {
  default = "thor"
}

variable "AWS_ACCOUNT_ID" {
  default = "867344428970"
}

variable "DEVELOPER_NAME" {
  default = "nitin"
}
```

These defaults match `config.env` for consistency.

---

## 🚀 Step-by-Step Setup Guide

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/nitinbhardwaj297/github-eks.git
cd github-eks
```

---

### 2️⃣ Configure AWS CLI

Login to AWS on your local machine or EC2 instance:

```bash
aws configure
```

Verify:

```bash
aws sts get-caller-identity
```

---

### 3️⃣ Create Infrastructure (VPC, EKS, ECR, IAM)

Run:

```bash
make all
```

This will:

* Create VPC & subnets
* Create EKS cluster + node group
* Create ECR repository
* Create GitHub OIDC provider & IAM role

⏱️ This step can take **15–20 minutes**.

---

### 4️⃣ Configure GitHub Repository Variables

In **GitHub → Settings → Secrets and variables → Actions → Variables**, add:

| Variable Name    | Value        |
| ---------------- | ------------ |
| AWS_ACCOUNT_ID   | 867344428970 |
| AWS_REGION       | us-east-1    |
| ECR_REPOSITORY   | thor         |
| EKS_CLUSTER_NAME | thor-eks     |
| K8S_NAMESPACE    | asgard       |

No AWS secrets are required (OIDC is used).

---

### 5️⃣ Push Code to Trigger CI/CD

```bash
git push origin main
```

This triggers:

* npm install
* Docker build
* Trivy scan (warn only)
* Push image to ECR
* Deploy to EKS

---

### 6️⃣ Verify Deployment

```bash
kubectl get pods -n asgard
kubectl get svc -n asgard
```

---

### 7️⃣ Destroy Everything (Cost Cleanup)

```bash
make destroy
```

This removes:

* Kubernetes resources
* EKS cluster
* VPC
* ECR repository

⚠️ Use with caution.

---

## 🔄 CI/CD Pipeline (GitHub Actions)

Pipeline file:

```
.github/workflows/eks-ci-cd.yml
```

### Pipeline Stages

1. **Checkout code**
2. **Setup Node.js**
3. **Install dependencies (`npm ci`)**
4. **Run tests (if present)**
5. **Authenticate to AWS (OIDC)**
6. **Build Docker image**
7. **Trivy vulnerability scan (warn only)**
8. **Push image to ECR**
9. **Update kubeconfig**
10. **Rolling update on EKS**

Each image is tagged with:

```
IMAGE_TAG = github.sha
```

This guarantees **immutable deployments** and easy rollback.

---

## 🔐 Security Scanning (Trivy)

Trivy scans the Docker image for:

* OS vulnerabilities
* Application library vulnerabilities

Current behavior:

* 🔍 Detects HIGH & CRITICAL issues
* ⚠️ Logs warnings
* ✅ Does NOT fail the pipeline

This is ideal for **development / learning environments**.

---

## ☸️ Kubernetes Deployment

The deployment updates only the image:

```bash
kubectl set image deployment/thor-deployment thor=<IMAGE>
```

Features:

* Rolling updates
* Zero downtime
* Rollout status verification

---

## 🧪 Local Development

Build and push manually:

```bash
make docker-build docker-push
```

Deploy to EKS:

```bash
make kubeconfig k8s-deploy
```

---

## 🟢 Key Highlights

* ✅ Fully automated CI/CD
* ✅ Secure AWS authentication (OIDC)
* ✅ Infrastructure as Code (Terraform)
* ✅ DevSecOps with Trivy
* ✅ Zero‑downtime Kubernetes deployments

---

## 🚀 Future Improvements

* Blue/Green or Canary deployments
* Environment‑based Trivy policies
* Slack notifications
* Prometheus & Grafana monitoring
* Automatic rollback on failed rollout

---

## 👨‍💻 Author

**Nitin Bhardwaj**
DevOps / SRE / Cloud Engineer

---

⭐ If this repo helped you learn real‑world DevOps, give it a star!
