# ── Stage 1: Build Flutter bundle ─────────────────────────────────────────
#
# Cross-compile on x86_64 host to produce the Flutter asset bundle
# (dart kernel snapshot + assets). The bundle is architecture-agnostic;
# only the flutter-pi runtime on the Pi is ARM.
#
FROM debian:bookworm-slim AS builder

ARG FLUTTER_VERSION=3.32.8

# System deps for Flutter + pub get
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:$PATH"

# Pre-cache Flutter artifacts for Linux
RUN flutter precache --linux

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# Build the Flutter bundle (dart snapshot + assets)
RUN flutter build bundle --release

# ── Stage 2: Runtime image for Raspberry Pi Zero 2W ──────────────────────
#
# This image runs on balenaOS (ARM32/ARM64).
# flutter-pi is installed from the official binary release.
#
FROM balenalib/raspberry-pi2-debian:bookworm-run AS runtime

# flutter-pi runtime dependencies (DRM/KMS + EGL/GLES2 + input)
RUN install_packages \
    libdrm2 libgbm1 \
    libgles2 libegl1 \
    libinput10 libudev1 \
    libxkbcommon0 \
    libfontconfig1 libfreetype6 \
    python3 python3-pip \
    && pip3 install RPi.GPIO --break-system-packages 2>/dev/null || true

# Install flutter-pi binary
# See: https://github.com/ardera/flutter-pi for the latest release
ARG FLUTTER_PI_VERSION=1.0.0
RUN curl -fsSL \
    "https://github.com/ardera/flutter-pi/releases/download/v${FLUTTER_PI_VERSION}/flutter-pi_armhf" \
    -o /usr/local/bin/flutter-pi \
    && chmod +x /usr/local/bin/flutter-pi

WORKDIR /app

# Copy Flutter bundle from builder
COPY --from=builder /app/build/flutter_assets ./bundle/flutter_assets

# Copy GPIO service
COPY gpio/ ./gpio/

# Entrypoint — flutter-pi with perfect circle clipping for 1080px display
# --clipping-radius 540  clips the framebuffer to a perfect circle
# --release              no debug overhead (important for Pi Zero 2W)
CMD ["flutter-pi", "--release", "--clipping-radius", "540", "/app/bundle"]
