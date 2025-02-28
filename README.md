# APIcast Cloud Hosted

APIcast Cloud Hosted is the modified [APIcast](https://github.com/3scale/apicast) that is used as the [3scale SaaS](3scale.net) gateway. It also has an extra component, the *mapping-service*, a microservice used to fetch configuration from the API and serve them to the gateway. This extra microservice is required to lazy-load confgurations on use, due to the high number of tenants and services that exist in the 3scale SaaS.

## APIcast gateway

### Features

* IP Blacklist: Blacklist access to internal IP addresses to avoid users from accessing internal services.

* Disabled policies: Some policies are disabled in SaaS due to security or performance. The list of removed policies is:
  * rate_limit
  * token_introspection
  * 3scale_batcher
  * conditional
  * logging
  * retry
  * upstream_connection
  * liquid_context_debug
  * request_unbuffered

### Gateway Configuration

The SaaS APIcast gateway is configured like any installaton of APIcast, using [available configuration options](https://github.com/3scale/APIcast/blob/master/doc/parameters.md). The only special configuration is that `THREESCALE_PORTAL_ENDPOINT` needs to be pointed to the `mapping-service` microservice instead of the usual 3scale Portal API.

### Gateway exposed ports

The usual APIcast ports: 8080 for the gateway, 8090 for management and 9421 for metrics.

## Mapping Service

Mapping Service is a microservice that fetches configuration from the 3scale Portal API and serves it to the APIcast gateway.

### Mapping Service Configuration

| Varible                       | Default               | Purpose                                                                              |
|-------------------------------|-----------------------|--------------------------------------------------------------------------------------|
| API_HOST                      | N/A                   | The 3scale Portal endpoint. Defaults to `multitenant-admin.3scale.net`.              |
| MASTER_ACCESS_TOKEN           | N/A                   | Master token used to fetch APIcast configurations from 3scale Portal API.            |

As the Mapping Service is built on top of an APIcast, the APIcast config options for logging level, etc, are available.

### Mapping Service exposed ports

The Mapping Service exposes the service port on 8093 and the metrics port on 9421.

## Development

### Local test execution with docker

Within each directory (apicast/mappong-service) there is a Makefile with targets to execute tests locally inside a docker container to avoid having to install test dependencies on the local host

* Unit tests: `make busted`
* Integration tests: `make prove`

### Change the base APIcast image

Both apicast and mapping-service docker images are built on top of the productized apicast image (quay.io/3scale/rh-apicast). In the top Makefile of this project, the variable `BASE_IMAGE_TAG` holds the tag to be used from the apicast productized image repository.

There are two options to rebuild apicast-cloud-hosted images:

* Change the tag of the base image changing `BASE_IMAGE_TAG`. This is tipically done when we want to upgrade, for example from 3scale 2.12 to 3scale 2.13 images.
* Increase the build number by changing the Makefile variable `BUILD_INFO`. This is used to force a rebuild of the image within the same apicast version. This only makes sense when using a floating tag from the productized apicast docker repo.

## Pipelines

Pipelines are configured in GitHub Actions. There are two workflows.

* With every PR to the master branch, the test workflow will run.
* With each push to master, the release workflow will run. It will create new apicast-cloud-hosted images and a new release in the repo if a release with the same name does not yet exist. The releases are named as `<apicast_productized_tag>-<build_info>`.

Images are tagged as follows:

* APIcast gateway: `quay.io/3scale/apicast-cloud-hosted:apicast-<apicast_productized_tag>-<build_info>`
* Mapping Service: `quay.io/3scale/apicast-cloud-hosted:mapping-service-<apicast_productized_tag>-<build_info>`

## Images

The apicast-cloud-hosted images are pushed to [quay.io/3scale/apicast-cloud-hosted](https://quay.io/repository/3scale/apicast-cloud-hosted?tab=tags). The images are built on top of the [APIcast productized image](https://quay.io/repository/3scale/rh-apicast?tab=tags&tag=latest).
