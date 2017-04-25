FROM quay.io/3scale/apicast:v3.0.0-rc1

WORKDIR /opt/app-root/src/

COPY server.conf sites.d/mapping-service.conf
COPY env.conf main.d/mapping-service.conf
COPY mapping_service.lua src/

WORKDIR /opt/app-root

EXPOSE 8093/tcp
