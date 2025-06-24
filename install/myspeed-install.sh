#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gnmyt/myspeed

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing MySpeed"
RELEASE=$(curl -fsSL https://github.com/gnmyt/myspeed/releases/latest | grep "title>Release" | cut -d " " -f 5)
cd /opt
curl -fsSL "https://github.com/gnmyt/myspeed/releases/download/v$RELEASE/MySpeed-$RELEASE.zip" -o "MySpeed-$RELEASE.zip"
$STD unzip MySpeed-$RELEASE.zip -d myspeed
cd myspeed
$STD npm install
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed MySpeed"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/myspeed.service
[Unit]
Description=MySpeed
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/myspeed 

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myspeed
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
rm -rf /opt/MySpeed-$RELEASE.zip
$STD apt-get -y autoclean
msg_ok "Cleaned"
