#!/bin/bash
# ==============================================================================
# Script Name: start-aap.sh
# Description: Safely brings up micro-containerized AAP in dependency order.
# ==============================================================================

# Define colors for clean terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Starting Ansible Automation Platform Infrastructure ===${NC}"

# 1. Check SELinux Status
SELINUX_STATUS=$(getenforce)
if [ "$SELINUX_STATUS" == "Enforcing" ]; then
  echo -e "${YELLOW}Warning: SELinux is Enforcing. Temporarily switching to Permissive...${NC}"
  setenforce 0
else
  echo -e "${GREEN}✓ SELinux is in a safe state (${SELINUX_STATUS}).${NC}"
fi

# 2. Check Persistent Storage Mount
if ! mountpoint -q /ansible_platform; then
  echo -e "${RED}Error: /ansible_platform partition is not mounted! Check storage.${NC}"
  exit 1
else
  echo -e "${GREEN}✓ Persistent volume /ansible_platform is mounted.${NC}"
fi

# 3. Start Database & Cache Layers
echo -e "\n${YELLOW}[Phase 1/4] Starting Core Backend Engines & Cache...${NC}"
podman start postgresql redis-tcp redis-unix

echo -e "${YELLOW}Waiting 10 seconds for database sockets to stabilize...${NC}"
sleep 10

# 4. Start Core Application Containers (Controller, Hub, Receptor)
echo -e "${YELLOW}[Phase 2/4] Starting Automation Engine Micro-services...${NC}"
# Receptor
podman start receptor
# Controller Components
podman start automation-controller-rsyslog automation-controller-task automation-controller-web
# Hub Components
podman start automation-hub-api automation-hub-content automation-hub-web automation-hub-worker-1 automation-hub-worker-2

echo -e "${YELLOW}Waiting 10 seconds for core applications...${NC}"
sleep 10

# 5. Start Event-Driven Ansible (EDA) Components
echo -e "${YELLOW}[Phase 3/4] Starting Event-Driven Ansible (EDA) Engines...${NC}"
podman start automation-eda-api automation-eda-daphne automation-eda-web automation-eda-worker-1 automation-eda-worker-2 automation-eda-activation-worker-1 automation-eda-activation-worker-2 automation-eda-scheduler

echo -e "${YELLOW}Waiting 10 seconds for internal database schema handshakes...${NC}"
sleep 10

# 6. Start Edge Proxy Layer
echo -e "${YELLOW}[Phase 4/4] Starting Automation Gateway UI Proxies...${NC}"
podman start automation-gateway-proxy automation-gateway
sleep 5

# 7. Overall Health Verification
echo -e "\n${YELLOW}=== Verifying Infrastructure Container Status ===${NC}"
REQUIRED_CONTAINERS=(
  "postgresql" "redis-tcp" "redis-unix" "receptor"
  "automation-controller-web" "automation-controller-task" "automation-controller-rsyslog"
  "automation-hub-api" "automation-hub-content" "automation-hub-web"
  "automation-eda-web" "automation-eda-api"
  "automation-gateway-proxy" "automation-gateway"
)
FAILED_COUNT=0

for container in "${REQUIRED_CONTAINERS[@]}"; do
  STATUS=$(podman inspect --format '{{.State.Running}}' "$container" 2>/dev/null)
  if [ "$STATUS" == "true" ]; then
    echo -e "Container [${GREEN}${container}${NC}]: ${GREEN}RUNNING${NC}"
  else
    echo -e "Container [${RED}${container}${NC}]: ${RED}STOPPED/CRASHED${NC}"
    ((FAILED_COUNT++))
  fi
done

# Final Summary
echo -e "\n========================================================"
if [ "$FAILED_COUNT" -eq 0 ]; then
  echo -e "${GREEN}Success! All AAP micro-services are up and stable.${NC}"
  echo -e "Access the web console at: ${GREEN}https://192.168.29.206${NC}"
else
  echo -e "${RED}Attention: ${FAILED_COUNT} container(s) failed to start cleanly.${NC}"
  echo -e "Run 'podman ps -a' and check 'podman logs <name>' to troubleshoot."
fi
echo -e "========================================================\n"
