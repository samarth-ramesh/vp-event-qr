FROM nginx:alpine
COPY . /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf
RUN rm -f /usr/share/nginx/html/default.conf \
          /usr/share/nginx/html/Dockerfile \
          /usr/share/nginx/html/README.md
EXPOSE 80
