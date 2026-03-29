#!/bin/bash

# ============================================================
#  get-rid-of-it.sh – Get Rid Of It
#  GitHub: https://github.com/Trayv0n/Get-Rid-Of-It
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

LAUNCHPAD_DB=$(find /private/var/folders -name "db" -path "*/com.apple.dock.launchpad/*" 2>/dev/null | head -1)

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║          Get Rid Of It – v0.1        ║${RESET}"
echo -e "${BOLD}║       macOS App Leftover Cleaner     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── Warning ───────────────────────────────────────────────────
echo -e "${RED}${BOLD}⚠️  WARNING${RESET}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "This script will ${BOLD}permanently delete${RESET} files and folders from your system."
echo -e "Only use this script if you ${BOLD}fully understand${RESET} what it does."
echo -e "Deleted files ${BOLD}cannot be recovered${RESET} unless you have a backup."
echo ""
echo -e "For more information, please visit:"
echo -e "${CYAN}${BOLD}https://github.com/Trayv0n/Get-Rid-Of-It${RESET}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
read -rp "$(echo -e ${YELLOW}"I understand the risks and want to continue. [y/n]: "${RESET})" WARNING_CONFIRM

if [[ "$WARNING_CONFIRM" != "y" && "$WARNING_CONFIRM" != "Y" ]]; then
  echo -e "${YELLOW}Aborted. No changes were made.${RESET}"
  exit 0
fi

echo ""

# ── Input ────────────────────────────────────────────────────
read -rp "$(echo -e ${CYAN}"Enter App Name: "${RESET})" APP_NAME
if [[ -z "$APP_NAME" ]]; then
  echo -e "${RED}No entry. Abort.${RESET}"
  exit 1
fi

read -rp "$(echo -e ${CYAN}"Publisher Name (optional, press Enter to skip): "${RESET})" VENDOR_NAME

echo ""
echo -e "${YELLOW}🔍 Searching for traces of \"${APP_NAME}\"...${RESET}"
echo ""

# ── Helper: Case-insensitive pattern ─────────────────────────
build_patterns() {
  local term="$1"
  echo "$term" | tr '[:upper:]' '[:lower:]'
}

APP_LOWER=$(build_patterns "$APP_NAME")
VENDOR_LOWER=$(build_patterns "$VENDOR_NAME")

# ── System file filter ────────────────────────────────────────
is_system_file() {
  local path="$1"
  [[ "$path" == /System/* ]] && return 0
  [[ "$path" == /usr/lib/* ]] && return 0
  [[ "$path" == /usr/share/* ]] && return 0
  [[ "$path" == /bin/* ]] && return 0
  [[ "$path" == /sbin/* ]] && return 0
  return 1
}

# ── Search ────────────────────────────────────────────────────
declare -a RESULTS

collect_mdfind() {
  local term="$1"
  while IFS= read -r line; do
    is_system_file "$line" && continue
    [[ "$line" == *"get-rid-of-it"* ]] && continue
    # Deduplicate
    for existing in "${RESULTS[@]}"; do
      [[ "$existing" == "$line" ]] && continue 2
    done
    RESULTS+=("$line")
  done < <(mdfind -name "$term" 2>/dev/null)
}

collect_mdfind "$APP_NAME"
[[ -n "$VENDOR_NAME" ]] && collect_mdfind "$VENDOR_NAME"

# Search for alias files
while IFS= read -r line; do
  is_system_file "$line" && continue
  line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
  if [[ "$line_lower" == *"$APP_LOWER"* ]] || { [[ -n "$VENDOR_LOWER" ]] && [[ "$line_lower" == *"$VENDOR_LOWER"* ]]; }; then
    for existing in "${RESULTS[@]}"; do
      [[ "$existing" == "$line" ]] && continue 2
    done
    RESULTS+=("$line")
  fi
done < <(mdfind "kMDItemKind == 'Alias'" 2>/dev/null)

# ── LaunchAgents / LaunchDaemons ──────────────────────────────
declare -a LAUNCH_FILES

check_launch_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return
  while IFS= read -r f; do
    local fname
    fname=$(basename "$f")
    fname_lower=$(echo "$fname" | tr '[:upper:]' '[:lower:]')
    if [[ "$fname_lower" == *"$APP_LOWER"* ]] || { [[ -n "$VENDOR_LOWER" ]] && [[ "$fname_lower" == *"$VENDOR_LOWER"* ]]; }; then
      LAUNCH_FILES+=("$f")
      # Deduplicate with RESULTS
      for existing in "${RESULTS[@]}"; do
        [[ "$existing" == "$f" ]] && continue 2
      done
      RESULTS+=("$f")
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name "*.plist" 2>/dev/null)
}

check_launch_dir ~/Library/LaunchAgents
check_launch_dir /Library/LaunchAgents
check_launch_dir /Library/LaunchDaemons

# ── Show results ──────────────────────────────────────────────
if [[ ${#RESULTS[@]} -eq 0 ]]; then
  echo -e "${GREEN}✅ No traces from \"${APP_NAME}\" were found.${RESET}"
  exit 0
fi

echo -e "${BOLD}Found files/folders:${RESET}"
echo ""

for i in "${!RESULTS[@]}"; do
  printf "  ${CYAN}[%3d]${RESET} %s\n" $((i+1)) "${RESULTS[$i]}"
done

echo ""
echo -e "${YELLOW}Do you want to ${BOLD}exclude${RESET}${YELLOW} certain entries from deletion?${RESET}"
read -rp "Enter numbers (e.g. 2 5 17), press Enter to skip: " EXCLUDE_INPUT

declare -a EXCLUDE_INDICES
if [[ -n "$EXCLUDE_INPUT" ]]; then
  read -ra EXCLUDE_INDICES <<< "$EXCLUDE_INPUT"
fi

is_excluded() {
  local num=$((${1}+1))
  for excl in "${EXCLUDE_INDICES[@]}"; do
    [[ "$excl" -eq "$num" ]] && return 0
  done
  return 1
}

# ── Confirm deletion ──────────────────────────────────────────
echo ""
read -rp "$(echo -e ${RED}"Delete all remaining entries? [y/n]: "${RESET})" CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${YELLOW}Abort. Nothing was deleted.${RESET}"
  exit 0
fi

# ── Deregister LaunchAgents/Daemons ──────────────────────────
if [[ ${#LAUNCH_FILES[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}⏏  Deregistering LaunchAgents/Daemons...${RESET}"
  for lf in "${LAUNCH_FILES[@]}"; do
    echo "   launchctl unload: $lf"
    launchctl unload "$lf" 2>/dev/null || sudo launchctl unload "$lf" 2>/dev/null
  done
fi

# ── Delete ────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}🗑  Deleting files...${RESET}"
echo ""

declare -a DELETED
declare -a FAILED

for i in "${!RESULTS[@]}"; do
  is_excluded "$i" && continue
  path="${RESULTS[$i]}"
  if rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} $path"
    DELETED+=("$path")
  else
    echo -e "  ${RED}✗ Error:${RESET} $path"
    FAILED+=("$path")
  fi
done

echo ""
echo -e "${GREEN}${BOLD}✅ Finished! ${#DELETED[@]} entries deleted, ${#FAILED[@]} failed.${RESET}"

# ── Save log ──────────────────────────────────────────────────
echo ""
read -rp "$(echo -e ${CYAN}"Save deleted entries as a text file in ~/Downloads? [y/n]: "${RESET})" SAVE_LOG

if [[ "$SAVE_LOG" == "y" || "$SAVE_LOG" == "Y" ]]; then
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  LOG_FILE=~/Downloads/get-rid-of-it_${APP_NAME// /_}_${TIMESTAMP}.txt
  {
    echo "Get Rid Of It – Log"
    echo "App: $APP_NAME"
    [[ -n "$VENDOR_NAME" ]] && echo "Publisher: $VENDOR_NAME"
    echo "Date: $(date)"
    echo ""
    echo "=== Deleted ==="
    for d in "${DELETED[@]}"; do echo "$d"; done
    if [[ ${#FAILED[@]} -gt 0 ]]; then
      echo ""
      echo "=== Failed ==="
      for f in "${FAILED[@]}"; do echo "$f"; done
    fi
  } > "$LOG_FILE"
  echo -e "${GREEN}📄 Log saved: $LOG_FILE${RESET}"
fi

# ── Restart Dock ──────────────────────────────────────────────
echo ""
read -rp "$(echo -e ${CYAN}"Restart Dock (killall Dock)? [y/n]: "${RESET})" RESTART_DOCK

if [[ "$RESTART_DOCK" == "y" || "$RESTART_DOCK" == "Y" ]]; then
  killall Dock
  echo -e "${GREEN}🔄 Restarting Dock...${RESET}"
fi

echo ""
echo -e "${BOLD}Get Rid Of It – Finished.${RESET}"
echo ""