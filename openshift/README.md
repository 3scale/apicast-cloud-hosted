# APIcast Cloud Hosted on OpenShift

1. Download `3scale+openshift` robot account credentials from quay.io as kubernetes object (`secret.yml`)
1. `oc project NAME`
1. `oc create -f secret.yml`
1. `oc secrets add serviceaccount/default secrets/3scale-openshift-pull-secret --for=pull`
1. `oc secret new-basicauth master-access-token-secret --password=MASTER_ACCESS_TOKEN`
1. `oc new-app -f openshift/template.yml` (with `-p ENVIRONMENT=production -p CACHE_TTL=300` for production or  `-p ENVIRONMENT=staging -p CACHE_TTL=0` for staging)
