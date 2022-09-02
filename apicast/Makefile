.DEFAULT_GOAL := help

include ../Makefile

IMAGE_TAG ?= apicast-$(BASE_IMAGE_TAG)-$(BUILD_INFO)

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## build the image
	$(DOCKER) build --build-arg IMAGE=$(BASE_IMAGE_REPO):$(BASE_IMAGE_TAG) -t $(LOCAL_IMAGE_NAME) .

test: build ## Run the image
	$(DOCKER) run --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy

prove: build ## Run blacklist tests
	$(DOCKER) run --rm -e TEST_NGINX_BINARY=openresty -e TEST_NGINX_SERVROOT=/tmp/servroot $(LOCAL_IMAGE_NAME) prove

push: build ## Push image to container registry
	$(DOCKER) tag $(LOCAL_IMAGE_NAME) $(REGISTRY)/$(LOCAL_IMAGE_NAME)
	$(DOCKER) push $(REGISTRY)/$(LOCAL_IMAGE_NAME)

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf lua_modules .cache t/servroot .cpanm perl5 tmp
