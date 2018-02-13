#FROM openjdk:8u111-jre-alpine
FROM openjdk:jre-alpine

# ===================================================================================================================================================================
# Install Caddy
# Referenaces:
# - https://github.com/ZZROTDesign/alpine-caddy
# - https://github.com/mholt/caddy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
RUN apk --no-cache add tar tini git openssh-client \
    && apk --no-cache add --virtual devs tar curl

# Install Caddy Server, and All Middleware
RUN curl -JLO "https://github.com/mholt/caddy/releases/download/v0.10.10/caddy_v0.10.10_linux_amd64.tar.gz" \
    | tar --no-same-owner -C /usr/bin/ -xz caddy

# Remove build devs
RUN apk del devs

# Copy over the default Caddyfile
# COPY ./Caddyfile /etc/Caddyfile

ENTRYPOINT ["/sbin/tini"]

# CMD ["caddy", "-quic", "--conf", "/etc/Caddyfile"]
# ===================================================================================================================================================================

# ===================================================================================================================================================================
# Update with OpenShifty Stuff
# From https://github.com/BCDevOps/s2i-caddy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
ADD Caddyfile /etc/Caddyfile

# Create the location where we will store our content, and fiddle the permissions so we will be able to write to it.
# Also twiddle the permissions on the Caddyfile so we will be able to overwrite it with a user-provided one if desired.
RUN mkdir -p /var/www/html && chmod g+w /var/www/html && chmod g+w /etc/Caddyfile

# Expose the port for the container to Caddy's default
#EXPOSE 2015
EXPOSE 8080

USER 1001

# ENTRYPOINT ["/sbin/tini"]

# CMD ["sh","/tmp/scripts/usage"]
# ===================================================================================================================================================================

# ===================================================================================================================================================================
# Install SchemaSpy
# From https://github.com/cywolf/schemaspy-docker
# Ref https://github.com/schemaspy/schemaspy
#
# ToDo: Update to use Caddy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
ENV OUTPUT_PATH=/var/www/html

ENV LC_ALL C
WORKDIR /app/
COPY start.sh conf ./

RUN apk update && \
	apk add --no-cache wget ca-certificates graphviz ttf-ubuntu-font-family java-postgresql-jdbc && \
	mkdir lib && \
	mkdir output && \
	wget -nv -O lib/schemaspy.jar https://github.com/schemaspy/schemaspy/releases/download/v6.0.0-rc2/schemaspy-6.0.0-rc2.jar && \
	wget -nv -O lib/postgresql-jdbc.jar http://central.maven.org/maven2/org/postgresql/postgresql/42.2.1/postgresql-42.2.1.jar && \
	wget -nv -O lib/mysql-connector-java.jar http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.42/mysql-connector-java-5.1.42.jar && \
	wget -nv -O lib/sqlite-jdbc.jar http://central.maven.org/maven2/org/xerial/sqlite-jdbc/3.18.0/sqlite-jdbc-3.18.0.jar && \
	apk del wget ca-certificates

RUN chown -R 1001:0 /app && chmod -R ug+rwx /app
# RUN chown -R 1001:0 /usr/sbin && chmod -R ug+rwx /usr/sbin
# RUN chown -R 1001:0 /bin/busybox && chmod -R ug+rwx /bin/busybox
# VOLUME /app/output
# USER 1001

CMD [ "sh", "start.sh" ]
# ===================================================================================================================================================================