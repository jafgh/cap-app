# Use official Python base image with Buildozer dependencies
FROM ubuntu:22.04

# Install required system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    build-essential \
    openjdk-11-jdk \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    libffi-dev \
    libssl-dev \
    autoconf \
    libtool \
    pkg-config \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libsqlite3-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Buildozer and Cython
RUN pip3 install --upgrade pip
RUN pip3 install buildozer==1.4.2 cython

# Set working directory
WORKDIR /app

# Copy source
COPY . /app

# Ensure assets folder exists
RUN mkdir -p /app/assets
# Copy ONNX model into assets (assumes model placed in repo under assets/)
# (If hosted elsewhere, adjust accordingly)

# Run Buildozer to compile APK (debug)
# This will generate bin/MyApp-0.1-debug.apk
RUN buildozer android debug

# Default command
CMD ["buildozer", "android", "debug", "--verbose"]
