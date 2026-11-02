FROM docker.io/jenkins/inbound-agent:3383.vc8881d4b_0e76-1-jdk17

USER root

ENV VERSION=1.7.6
ENV PATH="/opt/venv/bin:/usr/local/go/bin:${PATH}"

########################################################
# APT Configuration + Base Packages
########################################################

RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' \
      /etc/apt/sources.list.d/debian.sources && \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
    mkdir -p /etc/ssl/certs && \
    chmod 755 /etc/ssl/certs && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        g++ \
        gfortran \
        make \
        patch \
        unzip \
        wget \
        curl \
        jq \
        git \
        sudo \
        rsync \
        dnsutils \
        iproute2 \
        pkg-config \
        kmod \
        gnupg2 \
        ca-certificates \
        openssh-client \
        python3 \
        python3-pip \
        python3-venv \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libgdbm-dev \
        libbz2-dev \
        libexpat1-dev \
        liblzma-dev \
        tk-dev \
        libffi-dev \
        uuid-dev \
        libcurl4-openssl-dev \
        liblapack-dev \
        libxml2-dev \
        libxslt1-dev \
        libyaml-dev \
        libopenblas-dev \
        libopenblas-openmp-dev \
        python3-openstackclient && \
    ln -sf /bin/lsmod /usr/sbin/lsmod || true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

########################################################
# Google Chrome
########################################################

RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm -f google-chrome-stable_current_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

########################################################
# IBM Cloud CLI + Plugins
########################################################

RUN wget -q https://download.clis.cloud.ibm.com/ibm-cloud-cli/2.43.1/IBM_Cloud_CLI_2.43.1_amd64.tar.gz && \
    tar -xzf IBM_Cloud_CLI_2.43.1_amd64.tar.gz && \
    ./Bluemix_CLI/install && \
    ibmcloud update -f && \
    ibmcloud plugin install cloud-object-storage -f && \
    ibmcloud plugin install container-service -f && \
    ibmcloud plugin install power-iaas -f && \
    rm -f IBM_Cloud_CLI_2.43.1_amd64.tar.gz && \
    rm -rf Bluemix_CLI

########################################################
# OpenShift Client (oc + kubectl)
########################################################

RUN wget --quiet --no-check-certificate \
    https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/latest/openshift-client-linux.tar.gz \
    -O /tmp/oc.tar.gz && \
    tar -xzf /tmp/oc.tar.gz && \
    chmod +x oc && \
    mv oc kubectl /usr/local/bin/ && \
    rm -f /tmp/oc.tar.gz

########################################################
# Python 3.11.9
########################################################

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar -xf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make -j"$(nproc)" && \
    make altinstall && \
    cd / && \
    rm -rf /tmp/Python-3.11.9* && \
    rm -rf /root/.cache

########################################################
# Python Virtual Environmen + ansible package
########################################################

RUN python3 -m venv /opt/venv && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir ansible yq

########################################################
# Kustomize
########################################################

RUN curl -sS \
    https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh \
    | bash && \
    mv kustomize /usr/local/bin/

########################################################
# Nerdctl
########################################################

RUN wget -q \
    https://github.com/containerd/nerdctl/releases/download/v${VERSION}/nerdctl-${VERSION}-linux-amd64.tar.gz && \
    tar -xzf nerdctl-${VERSION}-linux-amd64.tar.gz -C /usr/local/bin && \
    rm -f nerdctl-${VERSION}-linux-amd64.tar.gz

########################################################
# Certificates
########################################################

COPY pvm.crt /etc/ssl/certs/pvm.crt

RUN update-ca-certificates && \
    echo "check_certificate = off" >> /root/.wgetrc

########################################################
# SSH Key
########################################################

RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

########################################################
# Jenkins Agent MTU Fix
########################################################

RUN sed -i '2 a ip link set dev eth0 mtu 1420' \
    /usr/local/bin/jenkins-agent
