.PHONY: all imagestream buildconfig deploy route help 
.DEFAULT_GOAL := help

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))

all: imagestream buildconfig deploy route  

imagestream: ## Create the Imagestreams (APIcast and Builder APICast).
	oc create -f $(THISDIR_PATH)/01-apicast-cloud-hosted-imagestream.yml
	oc create -f $(THISDIR_PATH)/02-apicast-builder-imagestream.yml

buildconfig: ## Create the BuildConfig.
	oc create -f $(THISDIR_PATH)/03-build-config.yml

deploy: ## Create the BuildConfig. Parameters: RELEASE_REF, ENVIRONMENT, CACHE_TTL.   
	oc new-app -f $(THISDIR_PATH)/04-deployment-template.yml \
		-p RELEASE_REF=${RELEASE_REF} \
		-p ENVIRONMENT=${ENVIRONMENT} \
		-p CACHE_TTL=${CACHE_TTL} 

route: ## Create the Routes.Parameters: WILDCARD_DOMAIN, ENVIRONMENT.
	oc new-app -f $(THISDIR_PATH)/05-routes.yml \
		-p ENVIRONMENT=${ENVIRONMENT} \
		-p WILDCARD_DOMAIN=${WILDCARD_DOMAIN}

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)