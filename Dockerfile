FROM debian:stable-slim

LABEL maintainer="jdiala@keymind.com"
LABEL description="AWS Route53 Dynamic DNS Updater"

# Install dependencies and clean up in a single layer to reduce image size
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        awscli \
        jq \
        curl \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user for security
RUN useradd -r -s /bin/false appuser

# Copy script to proper location
COPY --chmod=755 update-hosted-zone-by-hostname.sh /usr/local/bin/

# Switch to non-root user
USER appuser

ENTRYPOINT ["/bin/bash", "/usr/local/bin/update-hosted-zone-by-hostname.sh"]
