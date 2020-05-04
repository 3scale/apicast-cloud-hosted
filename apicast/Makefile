.DEFAULT_GOAL := help

APICAST_VERSION ?= v3.8.0
RUNTIME_IMAGE ?= quay.io/3scale/apicast:$(APICAST_VERSION)
BUILDER_IMAGE ?= $(RUNTIME_IMAGE)-builder
IMAGE_TAG ?= apicast-$(APICAST_VERSION)
IMAGE_NAME ?= apicast-cloud-hosted
REGISTRY ?= quay.io/3scale
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):apicast-$(IMAGE_TAG)
REMOTE_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
LOG_LEVEL ?= notice
LOGLEVEL ?= 2
PULL_POLICY ?= always
S2I_OPENRESTY_IMAGE ?= quay.io/3scale/s2i-openresty-centos7:1.17.4.1-0-centos8

build: ## Build the image
	s2i build .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME) \
		--runtime-image=$(RUNTIME_IMAGE) --loglevel=$(LOGLEVEL) \
		--pull-policy=$(PULL_POLICY) --runtime-pull-policy=$(PULL_POLICY)

builder: ## Build the builder image
	s2i build .  $(BUILDER_IMAGE) $(LOCAL_IMAGE_NAME) \
		--loglevel=$(LOGLEVEL) --pull-policy=$(PULL_POLICY)

test-image: ## Run tests (try to start the image)
test-image: build
	docker run -it --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy



start: ## Start APIcast
start: build
	docker run -it --publish 8080:8080 --env-file=.env --env APICAST_LOG_LEVEL=$(LOG_LEVEL) --rm $(LOCAL_IMAGE_NAME) bin/apicast --lazy --dev

#### Testing
test: ## Run all tests
	$(MAKE) --keep-going docker-busted docker-prove build test-image

/tmp/servroot:
	mkdir -p $@
prove: ## Run Test::Nginx
prove: /tmp/servroot
	TEST_NGINX_BINARY=openresty TEST_NGINX_CLIENT_PORT=8093 TEST_NGINX_SERVROOT=/tmp/servroot prove


#### Execute tests inside docker
DOCKER_PROVE_CMD ?= mkdir -p /tmp/junit && /usr/libexec/s2i/entrypoint sh -c 'rover exec prove --harness=TAP::Harness::JUnit'
docker-prove: ## Run Test::Nginx in the $(S2I_OPENRESTY_IMAGE) image
	docker run --rm -it -u $(shell id -u)  \
		--mount type=bind,source=$$(pwd),target=/opt/app-root/src \
		-eTEST_NGINX_BINARY=openresty \
		-eLUA_BIN_PATH=/opt/app-root/bin \
		-eTEST_NGINX_SERVROOT=/tmp/servroot \
		-eJUNIT_OUTPUT_FILE=/tmp/junit/prove.xml \
		-eTEST_NGINX_ERROR_LOG=/tmp/prove.log \
		$(S2I_OPENRESTY_IMAGE)  make docker-exec CMD="$(DOCKER_PROVE_CMD)"

docker-exec: ## target to execute commands inside the $(S2I_OPENRESTY_IMAGE), mainly to execute tests both locally and in the CI
	rover install
	/usr/libexec/s2i/entrypoint cpanm --notest --installdeps .
	$(CMD)


help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf lua_modules .cache t/servroot .cpanm perl5 tmp
