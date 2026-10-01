#!/bin/bash
# build.sh — template, complete it according to the README

VERSION=${VERSION:-dev}

# Stage 1: Build
docker run --rm -v $(pwd):/app -w /app node:18 npm run build

# Stage 2: Test
docker run --rm -v $(pwd):/app -w /app node:18 npm test

# Stage 3: Package
docker build -t myapp:$VERSION .

# Stage 4: Push
docker push myapp:$VERSION
