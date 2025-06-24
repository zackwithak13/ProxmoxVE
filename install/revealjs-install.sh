#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hakimel/reveal.js

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

msg_info "Setup ${APPLICATION}"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/hakimel/reveal.js/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL "https://github.com/hakimel/reveal.js/archive/refs/tags/${RELEASE}.tar.gz" -o "$temp_file"
tar zxf $temp_file
mv reveal.js-${RELEASE}/ /opt/revealjs
cd /opt/revealjs
$STD npm install
sed -i '25s/localhost/0.0.0.0/g' /opt/revealjs/gulpfile.js
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/revealjs.service
[Unit]
Description=Reveal.js Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/revealjs
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now revealjs
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
