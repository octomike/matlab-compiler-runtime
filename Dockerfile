FROM ubuntu:22.04

# Update system
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MATLAB MCR
ENV MATLAB_VERSION R2020b
RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget --quiet -P /opt/mcr_install https://ssd.mathworks.com/supportfiles/downloads/R2020b/Release/8/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020b_Update_8_glnxa64.zip && \
    unzip -q /opt/mcr_install/*${MATLAB_VERSION}*.zip -d /opt/mcr_install && \
    cd /opt/mcr_install && mkdir save && \
    for f in $(grep -E '(xml|enc)$' productdata/1000.txt) ; do  cp --parents archives/$f save/ ; done && \
    for f in $(grep -E '(xml|enc)$' productdata/35000.txt) ; do  cp --parents archives/$f save/ ; done && \
    for f in $(grep -E '(xml|enc)$' productdata/35010.txt) ; do  cp --parents archives/$f save/ ; done && \
    rm -rf archives && mv save/archives . && rmdir save && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/* && \
    rm -rf /opt/mcr/*/cefclient && \
    rm -rf /opt/mcr/*/mcr/toolbox/matlab/maps && \
    rm -rf /opt/mcr/*/toolbox/matlab/system/editor && \
    rm -rf /opt/mcr/*/toolbox/matlab/codetools && \
    rm -rf /opt/mcr/*/toolbox/matlab/datatools && \
    rm -rf /opt/mcr/*/toolbox/matlab/codeanalysis && \
    rm -rf /opt/mcr/*/toolbox/shared/dastudio && \
    rm -rf /opt/mcr/*/toolbox/shared/mlreportgen && \
    rm -rf /opt/mcr/*/sys/java/jre/glnxa64/jre/lib/ext/jfxrt.jar && \
    rm -rf /opt/mcr/*/sys/java/jre/glnxa64/jre/lib/amd64/libjfxwebkit.so && \
    rm -rf /opt/mcr/*/bin/glnxa64/libQt* && \
    rm -rf /opt/mcr/*/bin/glnxa64/qtwebengine && \
    rm -rf /opt/mcr/*/bin/glnxa64/cef_resources

# MCR does not provide libfontconfig and the bundled libfreetype is
# incompatbile to the system version. This is a common issue and the easiest
# fix is to hide/delete the bundle libfreetype and implicitly use the system
# version.
RUN rm -f /opt/mcr/*/bin/glnxa64/libfreetype.so*

# Configure environment
ENV MCR_VERSION v99
ENV MCR_RELEASE v99
ENV LD_LIBRARY_PATH /opt/mcr/${MCR_RELEASE}/runtime/glnxa64:/opt/mcr/${MCR_RELEASE}/bin/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/os/glnxa64:/opt/mcr/${MCR_RELEASE}/sys/opengl/lib/glnxa64
ENV MCR_INHIBIT_CTF_LOCK 1
ENV MCR_HOME /opt/mcr/${MCR_RELEASE}
