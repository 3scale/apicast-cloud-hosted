.DEFAULT_GOAL := help

APICAST_VERSION ?= 3scale2.10
IMAGE_TAG ?= apicast-$(APICAST_VERSION)
IMAGE_NAME ?= apicast-cloud-hosted
BASE_IMAGE ?= registry.redhat.io/3scale-amp2/apicast-gateway-rhel8:$(APICAST_VERSION)
DOCKER = docker
REGISTRY ?= quay.io/3scale
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)

build: ## build the image
	$(DOCKER) build --build-arg IMAGE=$(BASE_IMAGE) -t $(LOCAL_IMAGE_NAME) .

test:
	$(DOCKER) run --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy

prove:
	$(DOCKER) run --rm -e TEST_NGINX_BINARY=openresty -e TEST_NGINX_SERVROOT=/tmp/servroot $(LOCAL_IMAGE_NAME) prove

tag: ## Tag image
	$(DOCKER) tag $(LOCAL_IMAGE_NAME) $(REGISTRY)/$(LOCAL_IMAGE_NAME)

push: ## Push image to container registry
push: tag
	$(DOCKER) push $(REGISTRY)/$(LOCAL_IMAGE_NAME)

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf lua_modules .cache t/servroot .cpanm perl5 tmp
