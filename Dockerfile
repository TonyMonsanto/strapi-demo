# syntax=docker/dockerfile:1  

# The line above is from docker init command.  It has to be the first line in the Dockerfile in order to take effect. "Declaring a syntax version lets you automatically use the latest Dockerfile version without having to upgrade BuildKit or Docker Engine, or even use a custom Dockerfile implementation." (https://docs.docker.com/go/dockerfile-reference/) 


# ************** SOURCES ****************

# This Dockerfile is compiled from the following "best practices":

# - DOCKER INIT command (DI).  For more info see: https://docs.docker.com/reference/cli/docker/init/
# - STRAPI DOCKER docs (SD): https://docs.strapi.io/dev-docs/installation/docker
# - BRET FISHER Docker/Node repo (BF): https://github.com/BretFisher/nodejs-rocks-in-docker/blob/main/README.md


# ************** BASE IMAGE (Follows BF Best Practices) ****************

# CHAINGUARD IMAGES: From BF repo and YouTube video(https://www.youtube.com/watch?v=GEPW008G250): 
# Chainguard base image is most secure and very small.  For more on Chaingaurd image details see: https://edu.chainguard.dev/chainguard/chainguard-images/reference/node-lts/tags_history/

# Chainguard images do not include the ibvips-dev libraries needed by Strapi for image processing.  Also,the current chainguard Node image is not supported by Strapi.  We may chose to revisit chaingaurd images for production, but not for development.

# BF SIDE LOAD STRATEGY: (1) Use a secure, widely supported image for Base OS (Ubuntu); and (2) copy the official Node binaries directly into the base image.  Results in a small, secure, well-supported image (https://github.com/BretFisher/nodejs-rocks-in-docker/blob/main/dockerfiles/ubuntu-copy.Dockerfile).

#Latest version of Node supported by Strapi
ARG NODE=node:22.14-bullseye-slim@sha256:7ed5bbd6c552d2a8f83c24620c68e88f4299980214d89bc1f39c46bfa80b1ec7

#Latest version of Ubuntu with zero CVEs
ARG BASE=ubuntu:oracular-20241120@sha256:102bc1874fdb136fc2d218473f03cf84135cb7496fefdb9c026c0f553cfe1b6d

FROM ${NODE} AS node
FROM ${BASE}


# ************** BASE IMAGE (Follows BF Best Practices) ****************

# From BF: set entrypoint so that you always run commands with tini
# This replaces npm in CMD with tini for better kernel signal handling
# Instead of waiting 10 secs to kill process, shutdown is instantaneous
# You may also need development tools to build native npm addons:
# apt-get install gcc g++ make
# From BF: replace NPM in CMD with tini v0.19.0 for better kernel signal handling

#  * * * NOTE: ARG TINI_VERSION not working for some reason, so version is hardcoded here.
# https://github.com/krallin/tini
# AMD/64 version: https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${TINI_ARCH}
# will need to use AMD/64 version on AWS

ARG TINI_VERSION=v0.19.0
ARG TINI_ARCH=arm64

ADD --chmod=755 https://github.com/krallin/tini/releases/download/v0.19.0/tini-arm64 /tini
ENTRYPOINT ["/tini", "--"]

#Copy Node binaries from official Node image
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

#fix simlinks for npx, yarn, and pnpm
RUN corepack disable && corepack enable

# ************** Build Strapi (Follows SD and BF Best Practices) ****************

ARG NODE_VERSION=22.13.1

# Installing libvips-dev for sharp Compatibility
RUN apt update && apt install build-essential gcc autoconf automake zlib1g-dev libpng-dev nasm bash  libvips-dev git -y

ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

# NOTE: This Dockerfile uses NPM. Strapi v5.10 officially supports PNPM but the container crashes when we attempt to run this image.  The errors say it cannot find the Sharp Compatibility library.  For this reason, we are sticking to NPM.

WORKDIR /opt/
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install
# RUN npm config set fetch-retry-maxtimeout 600000 -g && npm ci --omit=dev
ENV PATH=/opt/node_modules/.bin:$PATH

# create node user and group.  This user is part of the official node package, but because we are side-loading Node we have to create it.
RUN groupadd --gid 1001 node \
    && useradd --uid 1001 --gid node --shell /bin/bash --create-home node

WORKDIR /opt/app
COPY . .
RUN chown -R node:node /opt/app
USER node
RUN ["npm", "run", "build"]
EXPOSE 1337
CMD ["npm", "run", "develop"]
