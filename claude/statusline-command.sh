#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Color codes
ORANGE='\033[38;2;255;122;61m'   # Claude orange
GRAY='\033[38;2;128;128;128m'
WHITE='\033[97m'
DIM='\033[2m'
RESET='\033[0m'

# === Line 1: context window progress bar ===
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" = "null" ]; then
    printf "${WHITE}No context yet${RESET}"
else
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    free=$((size - current))
    pct_free=$((100 - pct))
    if [ "$free" -ge 1000 ]; then free_fmt="$((free / 1000))k"; else free_fmt="$free"; fi
    bar_width=20
    filled=$((pct * bar_width / 100))
    empty=$((bar_width - filled))
    filled_bar=""
    empty_bar=""
    for ((i=0; i<filled; i++)); do filled_bar="${filled_bar}█"; done
    for ((i=0; i<empty; i++)); do empty_bar="${empty_bar}░"; done
    printf "${WHITE}Context: ${ORANGE}%d%%${WHITE} [${ORANGE}%s${GRAY}%s${WHITE}] ${DIM}|${RESET} ${WHITE}free: ${ORANGE}%s${WHITE} (%d%%)${RESET}" "$pct" "$filled_bar" "$empty_bar" "$free_fmt" "$pct_free"
fi

# === Line 2: current session model, cost, duration, rate limits ===
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
COST_FMT=$(printf '$%.2f' "$COST")
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))
printf "\n${WHITE}[%s]${RESET} 💰 ${ORANGE}%s${RESET} ${DIM}|${RESET} ⏱️  ${WHITE}%dm %ds${RESET}" "$MODEL" "$COST_FMT" "$MINS" "$SECS"

# Rate limits — only present for Pro/Max after first API call
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rate_limit_color() {
    local pct=$1
    if   [ "$(echo "$pct >= 80" | bc -l 2>/dev/null)" = "1" ]; then printf '\033[31m'   # red
    elif [ "$(echo "$pct >= 50" | bc -l 2>/dev/null)" = "1" ]; then printf '\033[33m'   # yellow
    else printf '\033[32m'; fi                                                            # green
}

resets_in() {
    local resets_at=$1
    local now; now=$(date +%s)
    local secs=$(( resets_at - now ))
    [ "$secs" -le 0 ] && { printf "now"; return; }
    local h=$(( secs / 3600 ))
    local m=$(( (secs % 3600) / 60 ))
    [ "$h" -gt 0 ] && printf "%dh %dm" "$h" "$m" || printf "%dm" "$m"
}

if [ -n "$rl_5h" ] || [ -n "$rl_7d" ]; then
    printf " ${DIM}|${RESET}"
    if [ -n "$rl_5h" ]; then
        pct_5h=$(printf '%.0f' "$rl_5h")
        CLR=$(rate_limit_color "$rl_5h")
        resets_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0')
        printf " ${DIM}5h${RESET} ${CLR}%d%%${RESET}" "$pct_5h"
        [ "$resets_5h" -gt 0 ] && printf " ${GRAY}(→%s)${RESET}" "$(resets_in "$resets_5h")"
    fi
    if [ -n "$rl_7d" ]; then
        pct_7d=$(printf '%.0f' "$rl_7d")
        CLR=$(rate_limit_color "$rl_7d")
        resets_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0')
        printf " ${DIM}7d${RESET} ${CLR}%d%%${RESET}" "$pct_7d"
        [ "$resets_7d" -gt 0 ] && printf " ${GRAY}(→%s)${RESET}" "$(resets_in "$resets_7d")"
    fi
fi

# === Line 3: today / week / month token usage and cost (cached 60s) ===
CACHE_DIR="$HOME/.cache/claude-statusline"
CACHE_FILE="$CACHE_DIR/usage.txt"
mkdir -p "$CACHE_DIR" 2>/dev/null

needs_refresh=1
if [ -f "$CACHE_FILE" ]; then
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - mtime ))
    [ "$age" -lt 60 ] && needs_refresh=0
fi
if [ "$needs_refresh" -eq 1 ] && [ -x "$HOME/.claude/usage-aggregator.py" ]; then
    python3 "$HOME/.claude/usage-aggregator.py" > "$CACHE_FILE.tmp" 2>/dev/null \
        && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
fi
if [ -s "$CACHE_FILE" ]; then
    printf "\n"
    cat "$CACHE_FILE"
fi
