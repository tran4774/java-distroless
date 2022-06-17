FROM docker.io/ubuntu:focal as builder
ARG jre_download_link=https://cdn.azul.com/zulu/bin/zulu17.34.19-ca-jre17.0.3-linux_x64.tar.gz
ARG resolvingdeps=https://github.com/tran4774/Resolving-Shared-Library/releases/download/v1.0.2/resolvingdeps
ADD ${jre_download_link} /home/jre.tar.gz
ADD ${resolvingdeps} /home/
WORKDIR /home
RUN \
    tar -xf jre.tar.gz && mv */ jre \
    && chmod +x resolvingdeps \
    && ./resolvingdeps -p /home/jre \
    && rm -rf deps/tmp

FROM gcr.io/distroless/static
COPY --from=builder /home/jre/ /usr/jre/
COPY --from=builder /home/deps/ /
COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/
ENV JAVA_HOME=/usr/jre/
ENV PATH=$PATH:$JAVA_HOME/bin
CMD ["java", "--version"]

# podman build -t test -v /home/${USER}/.m2:/root/.m2 .
