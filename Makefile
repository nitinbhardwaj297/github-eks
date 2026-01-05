########################################
# Load config.env
########################################
ifneq (,$(wildcard config.env))
	include config.env
	export
endif

########################################
# Variables
########################################
TERRAFORM_DIR=terraform
K8S_DIR=k8s

IMAGE_NAME=thor
IMAGE_TAG=latest

########################################
# Terraform outputs
########################################
ECR_URL := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPOSITORY)


########################################
# Help
########################################
.PHONY: help
help:
	@echo "make all                 -> Full infra + build + deploy"
	@echo "make terraform-apply     -> Create AWS infra"
	@echo "make docker-build        -> Build Docker image"
	@echo "make docker-push         -> Push image to ECR"
	@echo "make k8s-deploy          -> Deploy to EKS"
	@echo "make destroy             -> Destroy everything"

########################################
# Full flow
########################################
.PHONY: all
all: terraform-init terraform-apply docker-build docker-push kubeconfig k8s-deploy

########################################
# Terraform
########################################
.PHONY: terraform-init
terraform-init:
	cd $(TERRAFORM_DIR) && terraform init

.PHONY: terraform-apply
terraform-apply:
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve


.PHONY: docker-build
docker-build:
	docker build \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

.PHONY: docker-login
docker-login:
	aws ecr get-login-password --region $(AWS_REGION) \
	| docker login --username AWS --password-stdin $(ECR_URL)

.PHONY: docker-push
docker-push: docker-login
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(ECR_URL):$(IMAGE_TAG)
	docker push $(ECR_URL):$(IMAGE_TAG)

########################################
# Kubernetes
########################################
.PHONY: kubeconfig
kubeconfig:
	aws eks update-kubeconfig \
		--region $(AWS_REGION) \
		--name $(CLUSTER_NAME)

.PHONY: k8s-deploy
k8s-deploy:
	@echo "📦 Creating namespace (idempotent)..."
	envsubst < $(K8S_DIR)/namespace.yml | kubectl apply -f -

	@echo "🚀 Deploying application to EKS..."
	envsubst < $(K8S_DIR)/deployment.yaml | \
	sed "s|IMAGE_PLACEHOLDER|$(ECR_URL):$(IMAGE_TAG)|g" | \
	kubectl apply -f -

	@echo "🌐 Applying service..."
	envsubst < $(K8S_DIR)/service.yaml | kubectl apply -f -

	@echo "⏳ Waiting for rollout..."
	kubectl rollout status deployment/thor-deployment -n $(K8S_NAMESPACE)
########################################
# Destroy
########################################
.PHONY: destroy
destroy: k8s-destroy terraform-destroy

.PHONY: k8s-destroy
k8s-destroy:
	@echo "🧹 Deleting Kubernetes resources..."
	-envsubst < $(K8S_DIR)/service.yaml | kubectl delete -f -
	-envsubst < $(K8S_DIR)/deployment.yaml | kubectl delete -f -
	-envsubst < $(K8S_DIR)/namespace.yml | kubectl delete -f -

.PHONY: terraform-destroy
terraform-destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve
