# Stage 1: Install Python + python-docx di Alpine biasa
FROM alpine:3.24 AS python-builder
RUN apk add --no-cache python3 py3-pip
RUN pip3 install python-docx --break-system-packages

# Stage 2: Copy ke n8n Hardened Image
FROM n8nio/n8n:latest
USER root

COPY --from=python-builder /usr/bin/python3 /usr/bin/python3
COPY --from=python-builder /usr/lib/libpython3.12.so.1.0 /usr/lib/libpython3.12.so.1.0
COPY --from=python-builder /usr/lib/python3.12 /usr/lib/python3.12

USER node