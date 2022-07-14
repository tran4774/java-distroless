FROM docker.io/library/ubuntu:focal AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG resolvingdeps=https://github.com/tran4774/Resolving-Shared-Library/releases/download/v1.0.3/resolving.sh

ARG SDK_IDENTIFIER=22.1.0.r17-grl

ADD ${resolvingdeps} /home/resolvingdeps.sh

WORKDIR /home
RUN \
    bash -c "apt-get update && apt-get install -y curl zip unzip \
    && curl -s "https://get.sdkman.io" | bash"
RUN \
    bash -c " \
    source "$HOME/.sdkman/bin/sdkman-init.sh" \
    && sdk install java $SDK_IDENTIFIER"
RUN \
    /root/.sdkman/candidates/java/current/bin/java --list-modules \
    && /root/.sdkman/candidates/java/current/bin/java --list-modules | grep "java\." | sed -E "s/@.+//g" | tr "\n" "," | xargs -I {} /root/.sdkman/candidates/java/current/bin/jlink --output jre --compress=2 --no-header-files --no-man-pages --module-path ../jmods --add-modules {} \
    && chmod +x resolvingdeps.sh \
    && ./resolvingdeps.sh -p /home/jre

FROM gcr.io/distroless/static
COPY --from=builder /home/jre/ /usr/jre/
COPY --from=builder /home/deps/ /
ENV JAVA_HOME=/usr/jre/
ENV PATH=$PATH:$JAVA_HOME/bin
CMD ["java", "--version"]

# podman build -t test -v /home/${USER}/.m2:/root/.m2 .
