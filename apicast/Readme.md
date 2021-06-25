# APIcast cloud-hosted

## Why

APIcast has many policies that cannot be public for SAAS gateway, like
rate-limit, conditional, logging, upstream retry, etc.. These policies cannot be
run on the saas gateway at all. 

On the other hand, leaking information outside is not possible in any way. So we
have a custom policy that does not allow setting API-backends on internal IPS.

## How to build

The build is based on the productized version of APICast. Some dependencies for
testing need to be fetched, but overall, there is only one dependency that needs
to be in place.


```
make build
```

The makefile has a few options on the top, regarding versions, repos ,etc..

## How to deploy

TBD

## How to test:

```
make prove
make test
```
