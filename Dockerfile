FROM nginx:alpine
RUN sed -i 's/user  nginx;/user  root;/' /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]