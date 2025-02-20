# strapi-demo

Test for running Strapi CMS locally in a Docker container. This is a development container for prototyping locally and will be used to build the initial development CI/CD pipeline. The pipeline will be built using AWS CoPilot which is an opinionated Infrastructure as Code (IaC) tool designed for containerized applications. The CI/CD development pipeline will consist of

- Github Repo
- Webhook for `git push` to trigger the AWS Pipeline build and deploy stages
- AWS ECR (container registry) to house the images
- AWS Apprunner or Fargate to deploy the containers
- Domain name: ("shift-stream.click"?)
- CDN: AWS Cloudfront or Cloudflare?
- WAF: AWS WAF or Cloudflare?

Note: Cloudflare is supposed to be better, cheaper, easier. AWS is proven, integrates better with our underlying infrastructure already build in AWS, and easier to deploy as a single Infrastructure as Code solution via AWS Copilot, AWS CDK, and AWS Cloudformation.

DATABASE: This version of Stapi uses the SQLite database, so that it can be deployed as a single container. Next steps will include:

- to use `docker compose` and the `compose.yaml` file to add a Postgres database container
- create an AWS Copilot _add-on_ to create and AWS RDS serverless Postgres database
- TBD: process from migrating and testing from development database to production database
- TBD: process for managing environmental variables to support the lifecycle of these various databases as the backend moves from development, to testing, to production environments.

STRAPI ADMIN PANEL: The Strapi Admin Panel is a separate react app that is created with the `strapi build` or `npm run build` command. To increase performance it can be hosted separately as a static app on AWS S3.

## TODO

- [x] add Todo List for project to README.md file
- [x] initial commit
- [x] Run `docker init` to create Dockerfile, compose.yaml, .dockerignore, etc.
- [x] comment out `.env` files from `.dockerignore`
- [x] Use Strapi docker docs to configure Dockerfile for Strapi
- [x] Use Bret Fisher tutorials to optimize Dockerfile for running Node apps
- [x] Build Docker image for Strapi based on Dockerfile
- [x] Run container based on new image
- [x] Test connectivity to localhost:1337 via browser
- [ ] set up VS Code as git commit editor
- [ ] create a basic template for git commit messages
- [ ] Build CI/CD pipeline using AWS CoPilot
- [ ] associate custom domain (shift-stream.click) to container
- [ ] add restart policies to container
- [ ] create suitable health checks in container
- [ ] set up AWS telemetry tools to monitor application: AWS Cloudwatch, AWS Xray.
- [ ] set up alerts to Slack via AWS SNS (simple notification service)
