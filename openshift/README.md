# APIcast Cloud Hosted on OpenShift

1. Download `3scale+openshift` robot account credentials from quay.io as kubernetes object (`secret.yml`)
1. `oc project NAME`
1. `oc create -f secret.yml`
1. `oc secrets add serviceaccount/default secrets/3scale-openshift-pull-secret --for=pull`
1. `oc secret new-basicauth master-access-token-secret --password=MASTER_ACCESS_TOKEN`
1. `make imagestream` to deploy the imageStreams (Apicast Cloud Hosted and Apicast Builder)
1. `make buildconfig` to create the BuildConfig
1. `make deploy RELEASE_REF=release_number ENVIRONMENT=staging CACHE_TTL=30` - (with `ENVIRONMENT=production CACHE_TTL=300` for production or  `ENVIRONMENT=staging CACHE_TTL=30` for staging)
1. `make route ENVIRONMENT=staging WILDCARD_DOMAIN=cluster.wildcard.domain.com` -  Wildcard Domain Concatenation: `apicast.${ENVIRONMENT}.${WILDCARD_DOMAIN}`

# Example of canary deploy

* In this example it will be deployed apicast version `v3.5.0-beta1` on both apicast-staging and apicast-production environments (currently deployed apicast version `v3.4.0`).

## Initial checks

* Check if there is any extra policy that may need to be disabled on BuildConfig `apicast-cloud-hosted-policy-disabler`.
* Check on quay.io that there are the following available Docker images:
    * quay.io/3scale/apicast:v3.5.0-beta1
    * quay.io/3scale/apicast:v3.5.0-beta1-builder

## Apicast-staging canary preparation

* Go to `apicast-staging` Openshift project.
* Edit ImageStream `apicast` and add a new block pointing to new builder version:
    * Tag: `v3.5.0-beta1-builder`
    * DockerImage: `quay.io/3scale/apicast:v3.5.0-beta1-builder`
* Edit Buildconfig `apicast-cloud-hosted`, and update:
    * Build From ImageStream Tag `apicast-staging/apicast:v3.5.0-beta1-builder`
    * Push To ImageStream Tag `apicast-staging/apicast-cloud-hosted:v3-5-0-beta1-builder` (replacing bullet points by hyphens)
    * Save
    * Start Build
* Edit Buildconfig `apicast-cloud-hosted-policy-disabler`, and update:
    * Build From ImageStream Tag `apicast-staging/apicast-cloud-hosted:v3-5-0-beta1-builder` (created by previous BuildConfig)
    * Push To ImageStream Tag `apicast-staging/apicast-cloud-hosted:saas-v3-5-0-beta1` (adding `saas` preffix and removing `builder` suffix)
    * Save
    * Start Build
* Do deploy of canary environment, leaving a single pod by the moment (it will create parallel DeploymentConfig/Services with new version `v3-5-0-beta1`):

```bash
    $ oc project apicast-staging
    $ make deploy RELEASE_REF=v3-5-0-beta1 ENVIRONMENT=staging CACHE_TTL=30
```

* Manually update the `apicast-mapping-service` DeploymentConfig image to use the dot notation `quay.io/3scale/apicast-cloud-hosted:mapping-service-v3.5.0-beta1` as the image is generated in the CI and fetched directly from `quay.io`.

* Update both Routes pointing to new services version `v3-5-0-beta1` with weight 0 by the moment (leaving old but productive version `v3-4-0` with weight 100).

## Apicast-production canary preparation

* Go to `apicast-production` Openshift project.
* Edit ImageStream `apicast` and add a new block pointing to new builder version:
    * Tag: `v3.5.0-beta1-builder`
    * DockerImage: `quay.io/3scale/apicast:v3.5.0-beta1-builder`
* Edit Buildconfig `apicast-cloud-hosted`, and update:
    * Build From ImageStream Tag `apicast-production/apicast:v3.5.0-beta1-builder`
    * Push To ImageStream Tag `apicast-production/apicast-cloud-hosted:v3-5-0-beta1-builder` (replacing bullet points by hyphens)
    * Save
    * Start Build
* Edit Buildconfig `apicast-cloud-hosted-policy-disabler`, and update:
    * Build From ImageStream Tag: `apicast-production/apicast-cloud-hosted:v3-5-0-beta1-builder` (created by previous BuildConfig)
    * Push To ImageStream Tag: `apicast-production/apicast-cloud-hosted:saas-v3-5-0-beta1` (adding `saas` preffix and removing `builder` suffix)
    * Save
    * Start Build
* Do deploy of canary environment, leaving a single pod by the moment (it will create parallel DeploymentConfig/Services with new version `v3-5-0-beta1`):

```bash
    $ oc project apicast-production
    $ make deploy RELEASE_REF=v3-5-0-beta1 ENVIRONMENT=production CACHE_TTL=300
```

* Manually update the `apicast-mapping-service` DeploymentConfig image to use the dot notation `quay.io/3scale/apicast-cloud-hosted:mapping-service-v3.5.0-beta1` as the image is generated in the CI and fetched directly from `quay.io`.

* Update both Routes pointing to new services version `v3-5-0-beta1` with weight 0 by the moment (leaving old but productive version `v3-4-0` with weight 100).

At this point, both canary environments are 100% prepared to receive real traffic.

## Apicast-staging canary deploy

Once apicast-staging new DeploymentConfigs/Services are ready to receive real traffic:

* Update new version `v3-5-0-beta1` DeploymentConfigs number of replicas with the same quantity as old version `v3-4-0` DeploymentConfigs.
* Edit both Routes, and send traffic to new services version `v3-5-0-beta1`:
    * Old `v3-4-0` weight 75%
    * New `v3-5-0-beta1` weight 25%
    * Check that everything is OK by checking pod logs, prometheus monitoring...
* Once you verify everything is OK, repeat the procedure but now sending more traffic to new version `v3-5-0-beta1` (50%/50%).
* Update both Routes weight by sending 100% traffic to new version `v3-5-0-beta1` and 0% to old version `v3-4-0`.
* Update old version `v3-4-0` DeploymentConfigs to 0 replicas (in case of a needed possible rollback, you just need to add pods to these DeploymentConfigs, and update Routes weights).

At this point apicast-staging new version `v3-5-0-beta1` is receiving ALL TRAFFIC, and old version `v3-4-0` have 0 pods (but it is prepared for a possible rollback).

## Apicast-production canary deploy

Once apicast-staging vew version `v3-5-0-beta1` is 100% tested, repeat the same procedure with apicast-production:

* Update new version `v3-5-0-beta1` DeploymentConfigs number of replicas with the same quantity as old version `v3-4-0` DeploymentConfigs.
* Edit both Routes, and send traffic to new services version `v3-5-0-beta1`:
    * Old `v3-4-0` weight 50%
    * New `v3-5-0-beta1` weight 50%
    * Check that everything is OK by checking pod logs, prometheus monitoring...
* Once you verify everything is OK, update both Routes weight by sending 100% traffic to new version `v3-5-0-beta1` and 0% to old version `v3-4-0`.
* Update old version `v3-4-0` DeploymentConfigs to 0 replicas (in case of a needed possible rollback, you just need to add pods to these DeploymentConfigs, and update Routes weights).

At this point apicast-production new version `v3-5-0-beta1` is receiving ALL TRAFFIC, and old version `v3-4-0` have 0 pods (but it is prepared for a possible rollback).
