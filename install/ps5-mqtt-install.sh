#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: liecno
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FunkeyFlo/ps5-mqtt/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  jq \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="playactor" setup_nodejs

msg_info "Installing PS5-MQTT"
RELEASE=$(curl -fsSL https://api.github.com/repos/FunkeyFlo/ps5-mqtt/releases/latest | jq -r '.tag_name')
curl -fsSL https://github.com/FunkeyFlo/ps5-mqtt/archive/refs/tags/${RELEASE}.tar.gz -o /tmp/${RELEASE}.tar.gz
tar zxf /tmp/${RELEASE}.tar.gz -C /opt
mv /opt/ps5-mqtt-* /opt/ps5-mqtt
cd /opt/ps5-mqtt/ps5-mqtt/
$STD npm install
$STD npm run build
echo ${RELEASE} >/opt/ps5-mqtt_version.txt
msg_ok "Installed PS5-MQTT"

msg_info "Creating Service"
mkdir -p /opt/.config/ps5-mqtt/
mkdir -p /opt/.config/ps5-mqtt/playactor
cat <<EOF >/opt/.config/ps5-mqtt/config.json
{
  "mqtt": {
      "host": "",
      "port": "",
      "user": "",
      "pass": "",
      "discovery_topic": "homeassistant"
  },

  "device_check_interval": 5000,
  "device_discovery_interval": 60000,
  "device_discovery_broadcast_address": "",

  "include_ps4_devices": false,

  "psn_accounts": [
    {
      "username": "",
      "npsso":""
    }
  ],

  "account_check_interval": 5000,

  "credentialsStoragePath": "/opt/.config/ps5-mqtt/credentials.json",
  "frontendPort": "8645"
}
EOF
cat <<EOF >/etc/systemd/system/ps5-mqtt.service
[Unit]
Description=PS5-MQTT Daemon
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/ps5-mqtt/ps5-mqtt
Environment="CONFIG_PATH=/opt/.config/ps5-mqtt/config.json"
Environment="DEBUG='@ha:ps5:*'"
Restart=always
RestartSec=5
Type=simple
ExecStart=node server/dist/index.js
KillMode=process
SyslogIdentifier=ps5-mqtt

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ps5-mqtt
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm /tmp/${RELEASE}.tar.gz
msg_ok "Cleaned"
