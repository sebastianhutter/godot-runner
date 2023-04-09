# simple godot image for exporting and running tests
# inspired by: https://github.com/abarichello/godot-ci/blob/master/Dockerfile
# and https://mikeschulze.github.io/gdUnit4/faq/ci/

FROM ubuntu:22.04

# setup requirements for godot headless
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install -y ca-certificates curl unzip xvfb gosu \
  && apt-get install -y cmake pkg-config mesa-utils libglu1-mesa-dev freeglut3-dev mesa-common-dev libglew-dev libglfw3-dev libglm-dev libao-dev libmpg123-dev libxcursor-dev libxkbcommon-dev libxinerama-dev \
  && apt-get install -y libdbus-1-3 libasound2 libpulse-dev libspeechd-dev alsa-base alsa-utils \
  && rm -rf /var/lib/apt/lists/*

# install godot, godot_bin env var is required by gdunit script
ARG GODOT_VERSION="4.0.2"
ENV GODOT_BIN="/usr/local/bin/godot"
RUN mkdir /tmp/godot \
    && cd /tmp/godot \
    && curl -L "https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip \
    && unzip godot.zip \
    && mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" "${GODOT_BIN}" \
    && chmod +x "${GODOT_BIN}" \
    && cd \ 
    && rm -rf /tmp/godot

# setup ci user with godot templates and gdunit4
RUN useradd -ms /bin/bash runner
USER runner
RUN mkdir -p "${HOME}/.config/godot" "${HOME}/.local/share/godot/export_templates" "${HOME}/.local/share/godot/addons"

RUN mkdir /tmp/godot \
    && cd /tmp/godot \
    && curl -L "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o templates.tpz \
    && unzip templates.tpz \
    && mv templates "${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
    && cd \
    && rm -rf /tmp/godot

ARG GDUNIT_VERSION="4.1.0"
ENV GDUNIT_BIN="/home/runner/.local/share/godot/addons/gdUnit4/runtest.sh"
RUN mkdir /tmp/godot \
    && cd /tmp/godot \
    && curl -L "https://github.com/MikeSchulze/gdUnit4/archive/refs/tags/v${GDUNIT_VERSION}.zip" -o gdunit.zip \
    && unzip gdunit.zip \
    && mv "gdUnit4-${GDUNIT_VERSION}/addons/gdUnit4" "${HOME}/.local/share/godot/addons/gdUnit4" \
    && chmod +x "${GDUNIT_BIN}" \
    && cd \
    && rm -rf /tmp/godot

# setup entrypoint which sets up virtual display and then passes the 
# execution to the runner suer
USER root
ENV DISPLAY=":99"
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]