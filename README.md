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

* Unit tests: `make docker-busted`
* Integration tests: `make docker-prove`

### Change the base APIcast imager

To change the base APIcast image used to build both APIcast Cloud Hosted images, just change the APICAST_VERSION variable in each Makefile.

## Release process

The release process is managed with a [CircleCI pipeline](https://app.circleci.com/pipelines/github/3scale/apicast-cloud-hosted). This pipeline can be triggered in two different ways:

* With every push of code to the repo, the test job of the pipeline will be executed
* When an annotated git tag is pushed to the repo that matches the pattern "r.*", the pipeline will execute the test and release steps. The release step will push new images to quay.io/3scale/apicast-cloud-hosted, tagged with the git tag. The recommended way to create a new git annotated tag is to create a new GitHub release in this repository, with all the release information.

Images are tagged as follows:

* APIcast gateway: `quay.io/3scale/apicast-cloud-hosted:apicast-<apicast_version>-<rX>`
* Mapping Service: `quay.io/3scale/apicast-cloud-hosted:mapping-service-<apicast_version>-<rX>`

## Images

The apicast-cloud-hosted images are published to [quay.io/3scale/apicast-cloud-hosted](https://quay.io/repository/3scale/apicast-cloud-hosted?tab=tags). The images are built on top of the [APIcast upstream image](https://quay.io/repository/3scale/apicast?tab=tags) using the [s2i](https://github.com/openshift/source-to-image) tool (source to image).
