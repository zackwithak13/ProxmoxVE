#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="20" NODE_MODULE="yarn@latest,node-gyp" setup_nodejs
PG_VERSION="17" setup_postgresql

msg_info "Set up PostgreSQL"
DB_NAME="wiki"
DB_USER="wikijs_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" $DB_NAME
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "WikiJS-Credentials"
  echo "WikiJS Database User: $DB_USER"
  echo "WikiJS Database Password: $DB_PASS"
  echo "WikiJS Database Name: $DB_NAME"
} >>~/wikijs.creds
msg_ok "Set up PostgreSQL"

msg_info "Setup Wiki.js"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/Requarks/wiki/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/requarks/wiki/releases/download/v${RELEASE}/wiki-js.tar.gz" -o ""$temp_file""
mkdir /opt/wikijs
tar -xzf "$temp_file" -C /opt/wikijs
mv /opt/wikijs/config.sample.yml /opt/wikijs/config.yml
sed -i -E 's|^( *user: ).*|\1'"$DB_USER"'|' /opt/wikijs/config.yml
sed -i -E 's|^( *pass: ).*|\1'"$DB_PASS"'|' /opt/wikijs/config.yml
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Wiki.js"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wikijs.service
[Unit]
Description=Wiki.js
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/wikijs

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wikijs
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
