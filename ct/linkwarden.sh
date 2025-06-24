#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkwarden.app/

APP="Linkwarden"
var_tags="${var_tags:-bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/linkwarden ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/linkwarden/linkwarden/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat /opt/linkwarden_version.txt)" ]] || [[ ! -f /opt/linkwarden_version.txt ]]; then
    NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
    msg_info "Stopping ${APP}"
    systemctl stop linkwarden
    msg_ok "Stopped ${APP}"

    RUST_CRATES="monolith" setup_rust

    msg_info "Updating ${APP} to ${RELEASE}"
    mv /opt/linkwarden/.env /opt/.env
    rm -rf /opt/linkwarden
    fetch_and_deploy_gh_release "linkwarden" "linkwarden/linkwarden"
    cd /opt/linkwarden
    $STD yarn
    $STD npx playwright install-deps
    $STD yarn playwright install
    mv /opt/.env /opt/linkwarden/.env
    $STD yarn prisma:generate
    $STD yarn web:build
    $STD yarn prisma:deploy
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start linkwarden
    msg_ok "Started ${APP}"

    msg_info "Cleaning up"
    rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache ~/.rustup
    rm -rf /root/.cache/yarn
    rm -rf /opt/linkwarden/.next/cache
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
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
