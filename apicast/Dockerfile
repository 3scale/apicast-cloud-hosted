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

ENV LUA_PATH="/usr/lib64/lua/5.1/?.lua;/usr/local/share/lua/5.1/?.lua"
RUN mkdir -p /usr/share/lua/5.1/luarocks/ && \
    cp /usr/lib64/lua/5.1/luarocks/site_config.lua /usr/share/lua/5.1/luarocks/site_config.lua && \
    yum install -y luarocks && \
    luarocks install --server=http://luarocks.org/dev lua-rover && \
    rover install

ENV LUA_PATH="/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/opt/app-root/src/lua_modules/share/lua/5.1/?.lua;/opt/app-root/src/src/apicast/policy/?/init.lua;/opt/app-root/src/src/apicast/policy/?/init.lua"
ENV APICAST_LOADED_ENVIRONMENTS=cloud_hosted

CMD ["bin/apicast"]
