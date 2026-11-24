# Atomic all-in-one image (atomic-server + web UI + nginx), official upstream build.
# Update: bump the tag and digest together, add a CHANGELOG.md entry.
FROM ghcr.io/kenforthewin/atomic:1.45.0@sha256:b63fe3635677f90ef2e2e12f99b6a8b8b83e2853185a4d54f814abb99436dbad

# Our own start script replaces upstream's supervisord: supervisord restarts
# children forever and exits 0, so Railway never sees a crash.
RUN rm -f /etc/nginx/conf.d/atomic.conf /etc/nginx/sites-enabled/default
COPY nginx.conf.template /etc/atomic/nginx.conf.template
COPY start.sh /usr/local/bin/atomic-start
RUN chmod 755 /usr/local/bin/atomic-start && nginx -v

ENV PORT=8080 \
    ATOMIC_DATA_DIR=/data

EXPOSE 8080
HEALTHCHECK NONE
ENTRYPOINT []
CMD ["/usr/local/bin/atomic-start"]
