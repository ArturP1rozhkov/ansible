#!/bin/bash
set -euo pipefail

ZONE="ru-central1-a"
SUBNET="default-ru-central1-a"
IMAGE_FOLDER="standard-images"
IMAGE_FAMILY="almalinux-9"
CLOUD_INIT_FILE="cloud-init.yaml"

echo "Create clickhouse-01"
yc compute instance create \
  --name clickhouse-01 \
  --hostname clickhouse-01 \
  --zone "$ZONE" \
  --network-interface subnet-name="$SUBNET",nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id="$IMAGE_FOLDER",image-family="$IMAGE_FAMILY",size=20 \
  --memory 4 \
  --cores 2 \
  --metadata-from-file user-data="$CLOUD_INIT_FILE"

echo "Create vector-01"
yc compute instance create \
  --name vector-01 \
  --hostname vector-01 \
  --zone "$ZONE" \
  --network-interface subnet-name="$SUBNET",nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id="$IMAGE_FOLDER",image-family="$IMAGE_FAMILY",size=20 \
  --memory 4 \
  --cores 2 \
  --metadata-from-file user-data="$CLOUD_INIT_FILE"

echo "Create lighthouse-01"
yc compute instance create \
  --name lighthouse-01 \
  --hostname lighthouse-01 \
  --zone "$ZONE" \
  --network-interface subnet-name="$SUBNET",nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id="$IMAGE_FOLDER",image-family="$IMAGE_FAMILY",size=20 \
  --memory 2 \
  --cores 2 \
  --metadata-from-file user-data="$CLOUD_INIT_FILE"

echo
echo "Instances list:"
yc compute instance list