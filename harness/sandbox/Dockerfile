FROM python:3.12-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/pulp-sandbox-requirements.txt
RUN python -m pip install --upgrade pip \
  && python -m pip install --no-compile -r /tmp/pulp-sandbox-requirements.txt

COPY entrypoint.sh /usr/local/bin/pulp-sandbox-entrypoint
RUN chmod +x /usr/local/bin/pulp-sandbox-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/pulp-sandbox-entrypoint"]
CMD ["bash"]

