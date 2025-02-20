# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

# Official Node image based on Debian which has several CVEs
# Node 20 highest version of Node supported by Strapi 5.9
ARG NODE=node:20.18.2-bookworm-slim@sha256:83fdfa2a4de32d7f8d79829ea259bd6a4821f8b2d123204ac467fbe3966450fc

# Use Ubuntu for OS base; better supported and no CVEs as compared to Debian
ARG BASE=ubuntu:oracular-20241120@sha256:102bc1874fdb136fc2d218473f03cf84135cb7496fefdb9c026c0f553cfe1b6d
ARG TINI_VERSION=0.19.0
ARG TINI_ARCH=arm64

FROM ${NODE} AS node
FROM ${BASE}

# From BF: set entrypoint so that you always run commands with tini
# This replaces npm in CMD with tini for better kernel signal handling
# Instead of waiting 10 secs to kill process, shutdown is instantaneous
# You may also need development tools to build native npm addons:
# apt-get install gcc g++ make

#  * * * NOTE: ARG TINI_VERSION not working for some reason, so version is hardcoded here.
# https://github.com/krallin/tini
# AMD/64 version: https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${TINI_ARCH}
# will need to use AMD/64 version on AWS

ADD --chmod=755 https://github.com/krallin/tini/releases/download/v0.19.0/tini-arm64 /tini
ENTRYPOINT ["/tini", "--"]

#"Side load" Node binaries from official NODE image
# Strategy from https://github.com/BretFisher/nodejs-rocks-in-docker/blob/main/dockerfiles/ubuntu-copy.Dockerfile
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

#fix simlinks for npx, yarn, and pnpm
RUN corepack disable && corepack enable


ARG NODE_VERSION=22.13.1

################################################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-alpine as base

# Installing libvips-dev for sharp Compatibility
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

WORKDIR /opt/
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install
ENV PATH=/opt/node_modules/.bin:$PATH

WORKDIR /opt/app
COPY . .
RUN chown -R node:node /opt/app
USER node
RUN ["npm", "run", "build"]
EXPOSE 1337
CMD ["npm", "run", "develop"]
