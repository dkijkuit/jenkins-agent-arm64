FROM arm64v8/openjdk:8-jdk-stretch as agentbase

ARG version=jenkins-agent:arm64-1.5

ARG VERSION=4.6
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN apt-get update
RUN apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get install docker-ce-cli

RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d /home/${user} -u ${uid} -g ${gid} -m ${user}
LABEL Description="This is a base image, which provides the Jenkins agent executable (agent.jar)" Vendor="Jenkins project" Version="${VERSION}"

ARG AGENT_WORKDIR=/home/${user}/agent

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

RUN apt-get update && rm -rf /var/lib/apt/lists/*
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}#

# Final image
FROM agentbase as jenkins-agent-arm64

ARG version
LABEL Description="This is a base image, which allows connecting Jenkins agents via JNLP protocols" Vendor="Jenkins project" Version="$version"

ARG user=jenkins

USER root
COPY jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave
USER ${user}

ENTRYPOINT ["jenkins-agent"]
