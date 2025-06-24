#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/minio/minio

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

FEATURE_RICH_VERSION="2025-04-22T22-12-26Z"

echo
echo "MinIO recently removed many management features from the Console UI."
echo "The last feature-complete version is: $FEATURE_RICH_VERSION"
echo "Latest versions require the paid edition for full UI functionality."
echo
echo "Choose which version to install:"
echo "  [N] Feature-rich community version ($FEATURE_RICH_VERSION) [Recommended]"
echo "  [Y] Latest version (may lack UI features)"
echo
read -p "Install latest MinIO version? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  USE_LATEST=true
else
  USE_LATEST=false
fi

msg_info "Setting up MinIO"
if [[ "$USE_LATEST" == "true" ]]; then
  RELEASE=$(curl -fsSL https://api.github.com/repos/minio/minio/releases/latest | grep '"tag_name"' | awk -F '"' '{print $4}')
  DOWNLOAD_URL="https://dl.min.io/server/minio/release/linux-amd64/minio"
else
  RELEASE="$FEATURE_RICH_VERSION"
  DOWNLOAD_URL="https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.${FEATURE_RICH_VERSION}"
fi

curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/minio
chmod +x /usr/local/bin/minio
useradd -r minio-user -s /sbin/nologin
mkdir -p /home/minio-user
chown minio-user:minio-user /home/minio-user
mkdir -p /data
chown minio-user:minio-user /data

MINIO_ADMIN_USER="minioadmin"
MINIO_ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"

cat <<EOF >/etc/default/minio
MINIO_ROOT_USER=${MINIO_ADMIN_USER}
MINIO_ROOT_PASSWORD=${MINIO_ADMIN_PASSWORD}
EOF

{
  echo ""
  echo "MinIO Credentials"
  echo "MinIO Admin User: $MINIO_ADMIN_USER"
  echo "MinIO Admin Password: $MINIO_ADMIN_PASSWORD"
} >>~/minio.creds
echo "${RELEASE}" >/opt/${APPLICATION,,}_version.txt
msg_ok "Setup MinIO"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/minio.service
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target

[Service]
User=minio-user
Group=minio-user
EnvironmentFile=-/etc/default/minio
ExecStart=/usr/local/bin/minio server --console-address ":9001" /data
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now minio
msg_ok "Service created"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleanup complete"
