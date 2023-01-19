FROM ubuntu:22.04

# Update system
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MATLAB MCR
ENV MATLAB_VERSION R2017b
RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget --quiet -P /opt/mcr_install https://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip && \
    unzip -q /opt/mcr_install/*.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/*

# MCR does not provide libfontconfig and the bundled libfreetype is
# incompatbile to the system version. This is a common issue and the easiest
# fix is to hide/delete the bundle libfreetype and implicitly use the system
# version.
RUN rm -f /opt/mcr/*/bin/glnxa64/libfreetype.so*

# Configure environment
ENV MCR_VERSION v93
ENV MCR_RELEASE v93
ENV LD_LIBRARY_PATH /opt/mcr/${MCR_RELEASE}/runtime/glnxa64:/opt/mcr/${MCR_RELEASE}/bin/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/os/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/opengl/lib/glnxa64
ENV MCR_INHIBIT_CTF_LOCK 1
ENV MCR_HOME /opt/mcr/${MCR_RELEASE}
