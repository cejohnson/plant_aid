#!/bin/sh
HASH=$(git rev-parse --short HEAD)
docker build -t chrej/plantaid-server:latest -t chrej/plantaid-server:$HASH .
docker push chrej/plantaid-server:$HASH
docker push chrej/plantaid-server:latest
echo "Pushed image tag: $HASH"