
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    zip \
    unzip \
    tar \
    pkg-config \
    libssl-dev \
    libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Install vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg \
    && /opt/vcpkg/bootstrap-vcpkg.sh -disableMetrics

WORKDIR /app

# Copy backend source
COPY backend/ ./backend/

# Install C++ dependencies
RUN /opt/vcpkg/vcpkg install \
    drogon \
    libsodium \
    jwt-cpp \
    --triplet x64-linux

# Build backend
RUN cmake -S backend -B build \
    -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_TARGET_TRIPLET=x64-linux \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j2

WORKDIR /app/backend

EXPOSE 10000

CMD ["/bin/sh", "-c", "exec /app/build/HostelManagementSystem"]
