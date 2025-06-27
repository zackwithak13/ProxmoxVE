#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

APP="Docmost"
var_tags="${var_tags:-documents}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/docmost ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! command -v node >/dev/null || [[ "$(/usr/bin/env node -v | grep -oP '^v\K[0-9]+')" != "22" ]]; then
    msg_info "Installing Node.js 22"
    $STD apt-get purge -y nodejs
    rm -f /etc/apt/sources.list.d/nodesource.list
    rm -f /etc/apt/keyrings/nodesource.gpg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
    $STD apt-get update
    $STD apt-get install -y nodejs
    $STD npm install -g pnpm@10.4.0
    msg_ok "Node.js 22 installed"
  fi
  export NODE_OPTIONS="--max_old_space_size=4096"
  RELEASE=$(curl -fsSL https://api.github.com/repos/docmost/docmost/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop docmost
    msg_ok "${APP} Stopped"

    msg_info "Updating ${APP} to v${RELEASE}"
    cp /opt/docmost/.env /opt/
    cp -r /opt/docmost/data /opt/
    rm -rf /opt/docmost
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/docmost/docmost/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    tar -xzf "$temp_file"
    mv docmost-${RELEASE} /opt/docmost
    cd /opt/docmost
    mv /opt/.env /opt/docmost/.env
    mv /opt/data /opt/docmost/data
    $STD pnpm install --force
    $STD pnpm build
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start docmost
    msg_ok "Started ${APP}"

    msg_info "Cleaning Up"
    rm -f ${temp_file}
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
