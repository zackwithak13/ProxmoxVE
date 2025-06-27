#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/zackwithak13/ProxmoxVE/refs/heads/feat/uhf-server-lxc/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: zackwithak13 (Zack)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.uhfapp.com/server

APP="UHF"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/uhf-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop uhf-server
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  bash -c "$(curl -fsSL https://link.uhfapp.com/setup.sh)"
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start uhf-server
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7568${CL}"
