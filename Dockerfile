FROM docker.io/library/ubuntu:focal AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG SUDO_FORCE_REMOVE=yes

WORKDIR /home

RUN \
  apt-get update && \
  apt-get install curl wget sudo -y && \
  /bin/bash -c "$(curl -sL https://git.io/vokNn)" && \
  apt-fast install apt-rdepends zip unzip -y && \
  curl -s "https://get.sdkman.io" | bash && \
  # Resolving dependency lib share object with openjdk-11-jre-headless
  # After that, I'am remove penjdk-11-jre-headless folder to install specific jdk downloaded with sdkman  
  apt-rdepends -f Depends -s Depends openjdk-11-jre-headless | awk '$1 ~ /^Depends:/{print $2}' | sed 's/java8-runtime-headless//g' | sed 's/debconf-2.0/debconf/g' | sed 's/fonts-freefont/fonts-freefont-ttf/g' |xargs apt-fast download && \
  ls -1 | grep [.]deb >> all_debs.txt && \
  cat all_debs.txt | while read fn; do dpkg-deb -x $fn /jre; done && \
  rm all_debs.txt && \
  rm -r /jre/usr/lib/jvm /home/*

ARG SDK_IDENTIFIER=11.0.16-amzn

RUN \
  # Install specific jdk version
  bash -c " \
  source "$HOME/.sdkman/bin/sdkman-init.sh" \
  && sdk install java $SDK_IDENTIFIER" && \
  #Output JRE to new root
  /root/.sdkman/candidates/java/current/bin/java --list-modules \
  | sed -E "s/@.+//g" | tr "\n" "," \
  | xargs -I {} /root/.sdkman/candidates/java/current/bin/jlink \
  --output /jre/usr/lib/jvm --compress=2 --no-header-files --no-man-pages --module-path ../jmods --add-modules {} && \
  /jre/usr/lib/jvm/bin/java --version && \
  # Clean up builder image
  rm -rf $(ls -1 /root/.sdkman/candidates/java/${SDK_IDENTIFIER}/legal) /root/.sdkman && \
  apt-get purge curl wget 'sudo' apt-rdepends zip unzip -y && \
  apt-get autoremove -y && \
  apt-get clean autoclean && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/

FROM scratch 

COPY --from=builder /jre/ /

ENV JAVA_HOME=/usr/lib/jvm
ENV PATH=$PATH:$JAVA_HOME/bin \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

CMD ["java", "--version"]
