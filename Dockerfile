FROM bids/base_validator

# Update system
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MATLAB MCR
ENV MATLAB_VERSION R2022b
RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget --quiet -P /opt/mcr_install https://ssd.mathworks.com/supportfiles/downloads/R2022b/Release/3/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2022b_Update_3_glnxa64.zip && \
    unzip -q /opt/mcr_install/*.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/*

# Configure environment
ENV MCR_VERSION v913
ENV MCR_RELEASE R2022b
ENV LD_LIBRARY_PATH /opt/mcr/${MCR_RELEASE}/runtime/glnxa64:/opt/mcr/${MCR_RELEASE}/bin/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/os/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/opengl/lib/glnxa64
ENV MCR_INHIBIT_CTF_LOCK 1
ENV MCR_HOME /opt/mcr/${MCR_RELEASE}
