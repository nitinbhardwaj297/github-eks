
# StackGen DevOps Assignment – Hello World on EKS

This repository contains an end‑to‑end solution using **AWS + Terraform + EKS + ECR + GitHub Actions**.  

Once configured, any engineer can fork/clone this repo, adjust a single config file, and run `make all` to provision infra, build, push, and deploy.

---

## 1. Prerequisites

- AWS account with permissions to create:
  - ECR repository
  - EKS cluster + node group
  - IAM roles (including OIDC for GitHub Actions)
  - VPC, subnets, and related networking
- Local tools:
  - `aws` CLI v2
  - `terraform` (v1.5+ recommended)
  - `kubectl`
  - `docker`
  - `make`
- GitHub:
  - Personal GitHub account
  - Ability to create a new repository

---

## 2. Get this code into your own GitHub repo

1. **Clone this repo locally**:

    ```bash
    git clone https://github.com/aadirai02/hello-world.git
    cd hello-world
    ```

2. **Create a new empty repo** under your own GitHub account (for example `your-user/hello-world`).

3. **Point the local clone to your new remote**:

    ```bash
    git remote remove origin
    git remote add origin https://github.com/<YOUR_GITHUB_OWNER>/<YOUR_REPO>.git
    git push -u origin main
    ```


---

## 3. Configure AWS & GitHub variables

### 3.1. Fill in `config.env`

Edit `config.env`:

```bash
=== AWS base ===
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1

=== ECR / image ===
ECR_REPO=hello-world

=== EKS / Kubernetes ===
K8S_CLUSTER_NAME=stackgen-eks
K8S_NAMESPACE=stackgen

=== GitHub info (for IAM trust) ===
GITHUB_OWNER=your-github-username-or-org
GITHUB_REPO=hello-world

DEVELOPER_USER_NAME=your-iam-user-name

```


### 3.2. Set GitHub Actions repository variables

In your new GitHub repo:

1. Go to **Settings → Secrets and variables → Actions → Variables**.
2. Add these **repository variables**, using values matching `config.env`:

    | Name             | Example value      |
    |------------------|-------------------|
    | `AWS_ACCOUNT_ID` | `123456789012`    |
    | `AWS_REGION`     | `us-east-1`       |
    | `ECR_REPO`       | `hello-world`     |
    | `K8S_CLUSTER_NAME` | `stackgen-eks`  |
    | `K8S_NAMESPACE`  | `stackgen`        |

GitHub Actions uses these in `.github/workflows/ci-cd.yml`.

---

## 4. Terraform IAM + OIDC (high level)

The Terraform in `terraform/` will:

- Create a **VPC** and subnets.
- Create an **EKS cluster** and managed node group.
- Create an **ECR repository**.
- Create a **GitHub OIDC provider** and an **IAM role `github-actions-eks`** that GitHub Actions assumes via OIDC.

You do not need to hand‑edit `terraform.tfvars`; the Makefile generates it from `config.env`.

---

## 5. One‑command setup: `make all`

From the repo root:

```bash
make all
```


This runs:

1. **`sync-tfvars`**  
   - Reads `config.env`.
   - Generates `terraform/terraform.tfvars` so Terraform and the Makefile share the same values.

2. **`infra`**  
   - `terraform init` and `terraform apply -auto-approve`.
   - Creates VPC, EKS, node group, ECR, IAM roles, OIDC provider.
   - Updates kubeconfig to point to the new EKS cluster.

3. **`build-push`**  
   - Logs in to ECR.
   - Builds the Node.js app Docker image.
   - Tags and pushes `<account>.dkr.ecr.<region>.amazonaws.com/<ECR_REPO>:latest`.

4. **`deploy`**  
   - Updates kubeconfig.
   - Ensures the namespace exists.
   - Uses `envsubst` to render all `k8s/*.yaml` with `AWS_ACCOUNT_ID`, `AWS_REGION`, `ECR_REPO`, `K8S_NAMESPACE`.
   - Applies namespace, StorageClass, PVC, Deployment, and Service.
   - Waits for deployment rollout.
   - Prints the LoadBalancer hostname.

Example final output:
```bash
deployment "hello-world" successfully rolled out
a6041e4abaa254911bffba8b3cfc0aba-a24f40341b311ab3.elb.us-east-1.amazonaws.com
```

That hostname is the public URL of the app.

---

## 6. CI/CD pipeline behavior

The workflow `.github/workflows/ci-cd.yml` implements CI/CD:

- Trigger: `push` to `main`.
- **Lint job**
  - `npm ci`
  - `npm run lint`
- **Build / scan / push job**
  - Assumes the IAM role `github-actions-eks` via OIDC.
  - Logs into ECR.
  - Builds and tags Docker image (`run_number` and `latest`).
  - Runs Trivy:
    - Fails job on **CRITICAL** vulnerabilities.
    - Prints a markdown table and warns on **HIGH** vulnerabilities.
  - Pushes the image to ECR.
- **Deploy job**
  - Assumes the same IAM role.
  - Updates kubeconfig for the EKS cluster.
  - Injects the new image tag into the deployment manifest.
  - Runs `envsubst` on each `k8s/*.yaml` and applies them.
  - Waits for rollout and prints the LoadBalancer hostname.

Once config is set, a push to `main` automatically runs lint → build/scan/push → deploy.

---

## 7. How others can reuse this template

To reuse this setup in another AWS account and GitHub repo:

1. Create a new repo from this one (template or clone + push).
2. Clone locally,  edit values in `config.env`.
3. Set repo **Actions variables** (`AWS_ACCOUNT_ID`, `AWS_REGION`, `ECR_REPO`, `K8S_CLUSTER_NAME`, `K8S_NAMESPACE`).
4. Run `make all` locally to provision infra and deploy once.
5. Push to `main`; GitHub Actions will build, scan, push, and deploy to that account’s EKS cluster.




