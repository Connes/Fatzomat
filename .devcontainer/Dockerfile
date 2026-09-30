FROM ubuntu:24.04

ARG FLUTTER_VERSION=3.47.2
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk \
    python3 python3-pip wget file clang cmake ninja-build pkg-config libgtk-3-dev \
    liblzma-dev && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt

RUN git config --system --add safe.directory /workspace

WORKDIR /workspace

CMD ["bash"]
