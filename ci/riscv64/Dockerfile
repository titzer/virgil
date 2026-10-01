FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils-riscv64-linux-gnu gcc-riscv64-linux-gnu qemu-user qemu-user-binfmt \
    && rm -rf /var/lib/apt/lists/*
