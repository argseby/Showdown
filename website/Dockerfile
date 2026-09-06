FROM nginx:stable-alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY default.conf /etc/nginx/conf.d/default.conf

# Copy the whole site so new pages and assets deploy automatically.
# Exclusions belong in .dockerignore.
COPY . /usr/share/nginx/html/

# default.conf is needed above, but must never be served from the web root.
RUN rm -f /usr/share/nginx/html/default.conf

EXPOSE 2244

CMD ["nginx", "-g", "daemon off;"]
