.DEFAULT_GOAL := help

APICAST_VERSION ?= v3.2.0-alpha2
RUNTIME_IMAGE ?= quay.io/3scale/apicast:$(APICAST_VERSION)
BUILDER_IMAGE ?= $(RUNTIME_IMAGE)-builder
IMAGE_TAG ?= $(APICAST_VERSION)
IMAGE_NAME ?= apicast-cloud-hosted
REGISTRY ?= quay.io/3scale
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
REMOTE_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
LOG_LEVEL ?= notice
LOGLEVEL ?= 2
PULL_POLICY ?= always

build: ## Build the image
	s2i build .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME) \
		--runtime-image=$(RUNTIME_IMAGE) --loglevel=$(LOGLEVEL) \
		--pull-policy=$(PULL_POLICY) --runtime-pull-policy=$(PULL_POLICY)

builder: ## Build the builder image
	s2i build .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME) \
		--loglevel=$(LOGLEVEL) --pull-policy=$(PULL_POLICY)

test: ## Run tests (try to start the image)
	docker run -it --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy

start: ## Start APIcast
	docker run -it --publish 8080:8080 --env-file=.env --env APICAST_LOG_LEVEL=$(LOG_LEVEL) --rm $(LOCAL_IMAGE_NAME) bin/apicast --lazy --dev

push: ## Push image to the registry
	docker tag $(LOCAL_IMAGE_NAME) $(REGISTRY)/$(REMOTE_IMAGE_NAME)
	docker push $(REGISTRY)/$(REMOTE_IMAGE_NAME)


# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf lua_modules
