#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.meilisearch.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup ${APPLICATION}"
tmp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/meilisearch/meilisearch/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL https://github.com/meilisearch/meilisearch/releases/latest/download/meilisearch.deb -o $tmp_file
$STD dpkg -i $tmp_file
curl -fsSL https://raw.githubusercontent.com/meilisearch/meilisearch/latest/config.toml -o /etc/meilisearch.toml
MASTER_KEY=$(openssl rand -base64 12)
LOCAL_IP="$(hostname -I | awk '{print $1}')"
sed -i \
  -e 's|^env =.*|env = "production"|' \
  -e "s|^# master_key =.*|master_key = \"$MASTER_KEY\"|" \
  -e 's|^db_path =.*|db_path = "/var/lib/meilisearch/data"|' \
  -e 's|^dump_dir =.*|dump_dir = "/var/lib/meilisearch/dumps"|' \
  -e 's|^snapshot_dir =.*|snapshot_dir = "/var/lib/meilisearch/snapshots"|' \
  -e 's|^# no_analytics = true|no_analytics = true|' \
  -e 's|^http_addr =.*|http_addr = "0.0.0.0:7700"|' \
  /etc/meilisearch.toml
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

read -r -p "${TAB3}Do you want add meilisearch-ui? [y/n]: " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs

  msg_info "Setup ${APPLICATION}-ui"
  tmp_file=$(mktemp)
  tmp_dir=$(mktemp -d)
  mkdir -p /opt/meilisearch-ui
  RELEASE_UI=$(curl -s https://api.github.com/repos/riccox/meilisearch-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  curl -fsSL "https://github.com/riccox/meilisearch-ui/archive/refs/tags/${RELEASE_UI}.zip" -o "$tmp_file"
  $STD unzip "$tmp_file" -d "$tmp_dir"
  mv "$tmp_dir"/*/* /opt/meilisearch-ui/
  cd /opt/meilisearch-ui
  sed -i 's|const hash = execSync("git rev-parse HEAD").toString().trim();|const hash = "unknown";|' /opt/meilisearch-ui/vite.config.ts
  $STD pnpm install
  cat <<EOF >/opt/meilisearch-ui/.env.local
VITE_SINGLETON_MODE=true
VITE_SINGLETON_HOST=http://${LOCAL_IP}:7700
VITE_SINGLETON_API_KEY=${MASTER_KEY}
EOF
  echo "${RELEASE_UI}" >/opt/${APPLICATION}-ui_version.txt
  msg_ok "Setup ${APPLICATION}-ui"
fi

msg_info "Setting up Services"
cat <<EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=Meilisearch
After=network.target

[Service]
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now meilisearch

if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  cat <<EOF >/etc/systemd/system/meilisearch-ui.service
[Unit]
Description=Meilisearch UI Service
After=network.target meilisearch.service
Requires=meilisearch.service

[Service]
User=root
WorkingDirectory=/opt/meilisearch-ui
ExecStart=/usr/bin/pnpm start
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=meilisearch-ui

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now meilisearch-ui
fi

msg_ok "Set up Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
