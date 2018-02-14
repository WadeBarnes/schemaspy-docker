FROM openjdk:jre-alpine

# ===================================================================================================================================================================
# Install Caddy
# Referenaces:
# - https://github.com/ZZROTDesign/alpine-caddy
# - https://github.com/mholt/caddy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
RUN apk --no-cache add \
				tini \
				git \
				openssh-client && \
    apk --no-cache add --virtual \
				devs \
				tar \
				curl

# Install Caddy Server, and All Middleware
RUN curl -L "https://github.com/mholt/caddy/releases/download/v0.10.10/caddy_v0.10.10_linux_amd64.tar.gz" \
    | tar --no-same-owner -C /usr/bin/ -xz caddy

# Remove build devs
RUN apk del devs

# Add the default Caddyfile
COPY Caddyfile /etc/Caddyfile

ENTRYPOINT ["/sbin/tini"]
# ===================================================================================================================================================================

# ===================================================================================================================================================================
# Update with OpenShifty Stuff
# From https://github.com/BCDevOps/s2i-caddy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create the location where we will store our content, and fiddle the permissions so we will be able to write to it.
# Also twiddle the permissions on the Caddyfile so we will be able to overwrite it with a user-provided one if desired.
RUN mkdir -p /var/www/html && \
		chmod g+w /var/www/html && \
		chmod g+w /etc/Caddyfile

# Expose the port for the container to Caddy
EXPOSE 8080
# ===================================================================================================================================================================

# ===================================================================================================================================================================
# Install SchemaSpy
# From https://github.com/cywolf/schemaspy-docker
# Ref https://github.com/schemaspy/schemaspy
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
ENV LC_ALL=C

# Define the default output directory for SchemaSpy
# If you change this you will need to update the Caddy configuration.
ENV OUTPUT_PATH=/var/www/html

# Define the default versions for the image
ENV SCHEMA_SPY_VERSION=6.0.0-rc2
ENV POSTGRESQL_VERSION=42.2.1
ENV MYSQL_VERSION=6.0.6
ENV SQL_LITE_VERSION=3.18.0

WORKDIR /app/

# Install SchemaSpy
# Installing librsvg fixes issues with generating the SchemaSpy output; https://github.com/schemaspy/schemaspy/issues/33
RUN apk update && \
		apk add --no-cache \
				wget \
				ca-certificates \
				librsvg \
				graphviz \
				ttf-ubuntu-font-family && \
		mkdir lib && \
		wget -nv -O lib/schemaspy-$SCHEMA_SPY_VERSION.jar https://github.com/schemaspy/schemaspy/releases/download/v$SCHEMA_SPY_VERSION/schemaspy-$SCHEMA_SPY_VERSION.jar && \
		cp lib/schemaspy-$SCHEMA_SPY_VERSION.jar lib/schemaspy.jar && \
		wget -nv -O lib/postgresql-jdbc.jar http://central.maven.org/maven2/org/postgresql/postgresql/$POSTGRESQL_VERSION/postgresql-$POSTGRESQL_VERSION.jar && \
		wget -nv -O lib/mysql-connector-java.jar http://central.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_VERSION/mysql-connector-java-$MYSQL_VERSION.jar && \
		wget -nv -O lib/sqlite-jdbc.jar http://central.maven.org/maven2/org/xerial/sqlite-jdbc/$SQL_LITE_VERSION/sqlite-jdbc-$SQL_LITE_VERSION.jar && \
		apk del \
				wget \
				ca-certificates

RUN mkdir -p /app
WORKDIR /app/

COPY conf ./conf
COPY start.sh ./

RUN chown -R 1001:0 /app && \
		chmod -R ug+rwx /app

USER 1001

CMD [ "sh", "start.sh" ]
# ===================================================================================================================================================================