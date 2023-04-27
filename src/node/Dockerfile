FROM node:12-alpine

COPY package*.json ./
RUN npm install
COPY src/*.js .
COPY src/multer-s3-fileupload ./multer-s3-fileupload
COPY src/public ./public
COPY src/routes ./routes

ENTRYPOINT [ "npm", "start" ]