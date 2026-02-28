# Stage 1: Build dependencies
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app

# Install system build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies to a local folder
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt


# Stage 2: Final Runtime (The "Padded Cell")
FROM python:3.11-slim-bookworm

# 1. Create a non-privileged user (UID 10001)
# This prevents "Root Escape" to your host machine.
RUN groupadd -g 10001 openclaw && \
    useradd -u 10001 -g openclaw -m -s /bin/bash openclaw

WORKDIR /home/openclaw/app

# 2. Copy only the necessary files from the builder
COPY --from=builder /root/.local /home/openclaw/.local
COPY . .

# 3. Set ownership to the non-root user
RUN chown -R openclaw:openclaw /home/openclaw/app

# 4. Environment hardening
ENV PATH=/home/openclaw/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# 5. Drop all capabilities except what is strictly needed
# (This is reinforced at the 'docker run' or 'compose' level)
USER openclaw

# OpenClaw Gateway port
EXPOSE 18789

CMD ["python", "main.py"]