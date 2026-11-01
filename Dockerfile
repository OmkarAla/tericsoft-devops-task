# Static site served by nginx.
# nginx is configured to listen on 8081 *inside* the container, so the image
# itself serves on 8081 and the host mapping is 1:1 (8081:8081).
FROM nginx:1.27-alpine

# Replace the default server block (which listens on 80) with ours on 8081.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

# Note: the nginx:alpine base image already declares EXPOSE 80, and Docker has no
# way to remove an inherited port. Nothing listens on 80 here — our server block
# binds 8081 only, which is the port that is actually served.
EXPOSE 8081

# Docker reports healthy/unhealthy based on this; also useful under ECS.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8081/healthz || exit 1

# nginx:alpine's entrypoint is CMD ["nginx", "-g", "daemon off;"]
