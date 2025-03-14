.DEFAULT_GOAL := help

include ../Makefile

IMAGE_TAG ?= mapping-service-$(BASE_IMAGE_TAG)-$(BUILD_INFO)

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## build the image
	$(DOCKER) build --build-arg IMAGE=$(BASE_IMAGE_REPO):$(BASE_IMAGE_TAG) -t $(LOCAL_IMAGE_NAME) .

test: build ## Run the image
	docker run --rm $(LOCAL_IMAGE_NAME) bin/apicast --test --lazy

prove: build ## Run mapping-service tests
	$(DOCKER) run --rm \
		-e TEST_NGINX_BINARY=openresty \
		-e TEST_NGINX_SERVROOT=/tmp/servroot \
		-e TEST_NGINX_CLIENT_PORT=8093 \
		$(LOCAL_IMAGE_NAME) prove

busted: ## Run lua tests in the $(S2I_OPENRESTY_IMAGE) image
	docker run --rm -u $(shell id -u)  \
		-v ./spec:/opt/app-root/src/spec \
		-v ./.busted:/opt/app-root/src/.busted \
		-v ./bin:/opt/app-root/src/bin/ \
		$(LOCAL_IMAGE_NAME) \
		sh -c \
			"git config --global url.https://github.com/.insteadOf git://github.com/ && \
			rover install && \
			rover exec /opt/app-root/src/bin/busted"


push: build ## Push image to container registry
	$(DOCKER) tag $(LOCAL_IMAGE_NAME) $(REGISTRY)/$(LOCAL_IMAGE_NAME)
	$(DOCKER) push $(REGISTRY)/$(LOCAL_IMAGE_NAME)

.env:
	cp $@.example $@


LOG_LEVEL = notice
start: .env ## Start APIcast
start: build
	docker run --publish 8093:8093 --env-file=.env --env APICAST_LOG_LEVEL=$(LOG_LEVEL) --rm $(LOCAL_IMAGE_NAME) bin/apicast --lazy --dev
	# How to test: curl "http://127.0.0.1:8093/config/staging.json?host=api-2445583083201.staging.gw.apicast.io" -H "host: mapping-service-staging"

clean:
	rm -rf lua_modules .cache t/servroot .cpanm perl5 tmp .env
