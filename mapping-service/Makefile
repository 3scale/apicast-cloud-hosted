.DEFAULT_GOAL := help

ifndef IMAGE_TAG
$(error IMAGE_TAG is not set)
endif

IMAGE_NAME ?= mapping-service
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)
REGISTRY ?= quay.io/3scale
REMOTE_IMAGE_NAME ?= $(REGISTRY)/apicast-cloud-hosted:$(IMAGE_NAME)-$(IMAGE_TAG)
LOG_LEVEL ?= info



Gemfile.lock: Gemfile
	bundle check || bundle install

t/servroot:
	mkdir -p $@

nginx: ## Start nginx in foreground
nginx: export LUA_PATH=$(PWD)/src/?.lua;$(PWD)/?.lua;;
nginx: t/servroot .env Gemfile.lock
	dotenv openresty -p t/servroot -c $(PWD)/nginx.conf -g 'daemon off; error_log /dev/stderr $(LOG_LEVEL);'

.env:
	cp $@.example $@

busted: ## Run busted tests
busted: .env
	bundle exec dotenv bin/busted

prove: ## Run Test::Nginx
prove: Gemfile.lock .env
	TEST_NGINX_BINARY=openresty bundle exec dotenv prove

build: ## Build docker image
	docker build -t $(LOCAL_IMAGE_NAME) .

target: ## Install deps
	cd apicast && make dependencies

push:
	docker tag $(LOCAL_IMAGE_NAME) $(REMOTE_IMAGE_NAME)
	docker push $(REMOTE_IMAGE_NAME)

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
