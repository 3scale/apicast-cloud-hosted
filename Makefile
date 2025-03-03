BASE_IMAGE_REPO ?= quay.io/3scale/apicast-cloud-hosted
BASE_IMAGE_TAG ?= 3scale2.15.2-1.25.0-35
BUILD_INFO ?= 001
IMAGE_NAME ?= apicast-cloud-hosted
DOCKER ?= docker
REGISTRY ?= quay.io/3scale
LOCAL_IMAGE_NAME ?= $(IMAGE_NAME):$(IMAGE_TAG)

get-new-release:
	@hack/new-release.sh $(BASE_IMAGE_TAG)-$(BUILD_INFO)