
# Multistage Angular build, taken from:
# https://medium.com/@avatsaev/create-efficient-angular-docker-images-with-multi-stage-builds-907e2be3008d

### STAGE 1: Build ###

# We label our stage as ‘builder’
FROM node:8.1.4-alpine as validator-front-end-builder

# Optional --build-arg location=<path> to run the app from a different path on the server
ARG location=iati-feedback/

COPY package.json package-lock.json ./

## Storing node modules on a separate layer will prevent unnecessary npm installs at each build
RUN npm i && mkdir /ng-app && cp -R ./node_modules ./ng-app

WORKDIR /ng-app

COPY . .

## Build the angular app in production mode and store the artifacts in dist folder
RUN $(npm bin)/ng build --prod --base-href=/$location

### STAGE 2: Setup ###

FROM nginx:alpine

# Optional --build-arg location=<path> to run the app from a different path on the server
ARG location=iati-feedback/

COPY nginx.conf /tmp
RUN envsubst '$location' < /tmp/nginx.conf > /etc/nginx/conf.d/default.conf && rm /tmp/nginx.conf

## From ‘builder’ stage copy over the artifacts in dist folder to default nginx public folder
COPY --from=validator-front-end-builder /ng-app/dist /usr/share/nginx/html/$location

CMD ["nginx", "-g", "daemon off;"]