FROM frolvlad/alpine-oraclejdk8:slim
ENV LC_ALL C
WORKDIR /app/
COPY start.sh conf ./
RUN apk update && \
	apk add --no-cache wget ca-certificates graphviz ttf-ubuntu-font-family java-postgresql-jdbc && \
	mkdir lib && \
	mkdir output && \
	wget -nv -O lib/schemaspy.jar https://github.com/schemaspy/schemaspy/releases/download/v6.0.0-rc1/schemaspy-6.0.0-rc1.jar && \
	wget -nv -O lib/mysql-connector-java.jar http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.42/mysql-connector-java-5.1.42.jar && \
	wget -nv -O lib/sqlite-jdbc.jar http://central.maven.org/maven2/org/xerial/sqlite-jdbc/3.18.0/sqlite-jdbc-3.18.0.jar && \
	apk del wget ca-certificates

RUN chown -R 1001:0 /app && chmod -R ug+rwx /app
RUN chown -R 1001:0 /usr/sbin && chmod -R ug+rwx /usr/sbin
RUN chown -R 1001:0 /bin/busybox && chmod -R ug+rwx /bin/busybox
VOLUME /app/output
USER 1001

CMD [ "sh", "start.sh" ]
