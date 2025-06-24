#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: finkerle
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/raydak-labs/configarr

APP="Configarr"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/configarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/raydak-labs/configarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.configarr 2>/dev/null || cat /opt/configarr_version.txt 2>/dev/null)" ]]; then
    msg_info "Stopping $APP"
    systemctl stop configarr-task.timer
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to v${RELEASE}"
    mkdir -p /opt/backup/
    mv /opt/configarr/{config.yml,secrets.yml,.env} "/opt/backup/"
    rm -rf /opt/configarr
    fetch_and_deploy_gh_release "configarr" "raydak-labs/configarr"
    mv /opt/backup/* /opt/configarr/
    cd /opt/configarr
    $STD pnpm install
    $STD pnpm run build
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start configarr-task.timer
    msg_ok "Started configarr"

    rm -rf /opt/backup
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL (no web-ui):${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8989${CL}"
