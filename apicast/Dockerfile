#ARG IMAGE=registry.redhat.io/3scale-amp2/apicast-gateway-rhel8:3scale2.10
ARG IMAGE=quay.io/3scale/rh-apicast:3scale-2.11-candidate

FROM ${IMAGE}

USER root
WORKDIR /opt/app-root/src/

RUN rm -rfv /opt/app-root/src/src/apicast/policy/{rate_limit,token_introspection,3scale_batcher,conditional,logging,retry,upstream_connection}/apicast-policy.json
RUN dnf install -y perl-App-cpanminus gcc git

COPY cpanfile cpanfile
RUN cpanm --notest --installdeps /opt/app-root/src/ || exit 0

COPY Roverfile .
COPY Roverfile.lock .
COPY policies policies
COPY t t
COPY config config

RUN git config --global url.https://github.com/.insteadOf git://github.com/
RUN rover install

ENV APICAST_LOADED_ENVIRONMENTS=cloud_hosted

CMD ["bin/apicast"]
