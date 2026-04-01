FROM nginx:alpine
COPY build/web /usr/share/nginx/html
EXPOSE 8080
ENV PORT=8080
RUN sed -i 's/listen\s\+80;/listen 8080;/' /etc/nginx/conf.d/default.conf