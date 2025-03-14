ARG IMAGE
FROM ${IMAGE}

USER root
WORKDIR /opt/app-root/src/

RUN dnf install -y perl-App-cpanminus gcc git
# RUN dnf install -y gcc git

COPY cpanfile cpanfile
RUN cpanm --notest --installdeps /opt/app-root/src/ || exit 0

COPY Roverfile .
COPY Roverfile.lock .
COPY t t
COPY main.d main.d
COPY sites.d sites.d
COPY src src

CMD ["bin/apicast"]
