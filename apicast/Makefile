.DEFAULT_GOAL := help

RUNTIME_IMAGE ?= quay.io/3scale/apicast:master
BUILDER_IMAGE ?= $(RUNTIME_IMAGE)-builder
IMAGE_NAME ?= cloud-hosted-apicast
REGISTRY ?= quay.io/3scale

build: ## Build the image
	s2i build .  $(BUILDER_IMAGE) $(IMAGE_NAME) --environment-file=.env --assemble-user=root --runtime-image=$(RUNTIME_IMAGE)

test: ## Run tests (try to start the image)
	docker run -it --rm cloud-hosted-apicast bin/apicast -d


push: ## Push image to the registry
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME)
	docker push $(REGISTRY)/$(IMAGE_NAME)


# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
