.DEFAULT_GOAL := help

APICAST_VERSION ?= v3.8.0
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
	s2i .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME)-builder \
		--loglevel=$(LOGLEVEL) --pull-policy=$(PULL_POLICY) --local

test-image: ## Run tests (try to start the image)
	docker run -it --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy

start: .env ## Start APIcast
	docker run -it --publish 8080:8080 --env-file=.env --env APICAST_LOG_LEVEL=$(LOG_LEVEL) --rm $(LOCAL_IMAGE_NAME) bin/apicast --lazy --dev

.env:
	cp $@.example $@

#### Testing
test: ## Run all tests
	$(MAKE) --keep-going docker-busted docker-prove build test-image

# The following command deploys mapping-service into the apicast-$(APICAST_VERSION)-builder image
define DOCKER_CMD
bash -c \
		'ln -s /tmp/src/main.d/mapping-service.conf ~/main.d/mapping-service.conf && \
		 ln -s /tmp/src/sites.d/mapping-service.conf ~/sites.d/mapping-service.conf && \
		 ln -s /tmp/src/spec ~/spec && \
		 ln -s /tmp/src/t ~/t && \
		 ln -s /tmp/src/src/mapping_service.lua ~/src/mapping_service.lua && \
		 ln -sf /tmp/src/Makefile ~/Makefile &&
endef

DOCKER_SHELL_CMD := $(DOCKER_CMD) bash'
shell: ## Opens a shell to the apicast-$(APICAST_VERSION)-builder with all mapping-services code in place. Can be used to execute tests while developing
shell:
	docker run -it --rm -v $$(pwd):/tmp/src  $(BUILDER_IMAGE) $(DOCKER_SHELL_CMD)

busted: ## Run lua tests
	IMAGE_TAG=master busted

DOCKER_BUSTED_CMD := $(DOCKER_CMD) busted'
docker-busted: ## Run lua tests in the mapping-service-$(APICAST_VERSION)-builder image
	# docker run -it --rm --env-file=.env $(LOCAL_IMAGE_NAME)-builder busted
	docker run --rm -it -v $$(pwd):/tmp/src $(BUILDER_IMAGE) $(DOCKER_BUSTED_CMD)

prove: ## Run Test::Nginx
prove: /tmp/servroot
	TEST_NGINX_BINARY=openresty TEST_NGINX_CLIENT_PORT=8093 TEST_NGINX_SERVROOT=/tmp/servroot prove

DOCKER_PROVE_CMD := $(DOCKER_CMD) prove'
docker-prove: ## Run Test::Nginx in the mapping-service-$(APICAST_VERSION)-builder image
	docker run --rm -it -v $$(pwd):/tmp/src \
		-eTEST_NGINX_BINARY=openresty \
		-eTEST_NGINX_CLIENT_PORT=8093 \
		-eTEST_NGINX_SERVROOT=/tmp/servroot \
		-eJUNIT_OUTPUT_FILE=tmp/junit/prove.xml \
		-eTEST_NGINX_ERROR_LOG=tmp/prove.log \
		$(S2I_OPENRESTY_IMAGE)  make docker-exec CMD="$(DOCKER_PROVE_CMD)"

DOCKER_BUSTED_CMD := busted
docker-busted: ## Run lua tests in the $(S2I_OPENRESTY_IMAGE) image
	docker run --rm -it -u $(shell id -u)  \
		--mount type=bind,source=$$(pwd),target=/opt/app-root/src \
		$(S2I_OPENRESTY_IMAGE)  make docker-exec CMD="$(DOCKER_BUSTED_CMD)"


clean:
	rm -rf lua_modules .cache t/servroot .cpanm perl5 tmp .env

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
