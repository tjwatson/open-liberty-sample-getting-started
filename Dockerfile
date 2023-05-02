FROM icr.io/appcafe/open-liberty:beta-instanton
ARG VERSION=1.0
ARG REVISION=SNAPSHOT

COPY --chown=1001:0 src/main/liberty/config/ /config/
COPY --chown=1001:0 resources/ /output/resources/
COPY --chown=1001:0 target/*.war /config/apps/

RUN configure.sh

