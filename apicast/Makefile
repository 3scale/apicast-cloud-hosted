.DEFAULT_GOAL := help

APICAST_VERSION ?= v3.0.0
RUNTIME_IMAGE ?= quay.io/3scale/apicast:$(APICAST_VERSION)
BUILDER_IMAGE ?= $(RUNTIME_IMAGE)-builder
IMAGE_TAG ?= $(APICAST_VERSION)
IMAGE_NAME ?= apicast-cloud-hosted
REGISTRY ?= quay.io/3scale
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
REMOTE_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
LOG_LEVEL ?= notice

build: ## Build the image
	s2i build .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME) --environment-file=.env --assemble-user=root --runtime-image=$(RUNTIME_IMAGE)

test: ## Run tests (try to start the image)
	docker run -it --rm $(LOCAL_IMAGE_NAME) bin/apicast -d

start: ## Start APIcast
	docker run -it --publish 8080:8080 --env-file=.env --env APICAST_LOG_LEVEL=$(LOG_LEVEL) --rm $(LOCAL_IMAGE_NAME) bin/apicast

push: ## Push image to the registry
	docker tag $(LOCAL_IMAGE_NAME) $(REGISTRY)/$(REMOTE_IMAGE_NAME)
	docker push $(REGISTRY)/$(REMOTE_IMAGE_NAME)


# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
