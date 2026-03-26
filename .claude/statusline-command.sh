#!/usr/bin/env bash
# Claude Code statusLine command
# Shows: dir, git branch, 5h rate limit, 7d rate limit, reset countdown, model + ctx tokens
# Uses cache to persist rate limit data between invocations (stdin doesn't always include it)

input=$(cat)

# ── Cache setup ─────────────────────────────────────────────────────────────
CACHE_DIR="$HOME/.cache/claude-statusline"
CACHE_FILE="$CACHE_DIR/last_data.json"
CACHE_MAX_AGE=120  # seconds
mkdir -p "$CACHE_DIR" 2>/dev/null

# ── Parse stdin JSON ──────────────────────────────────────────────────────────
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(printf '%s' "$input" | jq -r '.model.display_name // ""')

# Rate limits (may be absent on some invocations)
fh_pct=$(printf '%s' "$input"  | jq -r '.rate_limits.five_hour.used_percentage  // empty')
fh_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at        // empty')
sd_pct=$(printf '%s' "$input"  | jq -r '.rate_limits.seven_day.used_percentage  // empty')
sd_reset=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at       // empty')

# Context window
ctx_total=$(printf '%s' "$input" | jq -r '.context_window.context_window_size   // empty')
ctx_used=$(printf '%s' "$input"  | jq -r '.context_window.total_input_tokens    // empty')

# ── Cache write/read ────────────────────────────────────────────────────────
from_cache=0

if [ -n "$fh_pct" ]; then
  # Fresh rate limit data -- cache it (atomic write)
  now_epoch=$(date +%s)
  printf '%s' "$input" | jq --arg ct "$now_epoch" '. + {_cache_time: ($ct | tonumber)}' \
    > "${CACHE_FILE}.tmp" 2>/dev/null && mv "${CACHE_FILE}.tmp" "$CACHE_FILE" 2>/dev/null
else
  # No rate limits in stdin -- try cache fallback
  if [ -f "$CACHE_FILE" ]; then
    now_epoch=$(date +%s)
    cache_time=$(jq -r '._cache_time // 0' "$CACHE_FILE" 2>/dev/null)
    cache_age=$(( now_epoch - cache_time ))
    if [ "$cache_age" -le "$CACHE_MAX_AGE" ]; then
      fh_pct=$(jq -r '.rate_limits.five_hour.used_percentage  // empty' "$CACHE_FILE" 2>/dev/null)
      fh_reset=$(jq -r '.rate_limits.five_hour.resets_at        // empty' "$CACHE_FILE" 2>/dev/null)
      sd_pct=$(jq -r '.rate_limits.seven_day.used_percentage  // empty' "$CACHE_FILE" 2>/dev/null)
      sd_reset=$(jq -r '.rate_limits.seven_day.resets_at       // empty' "$CACHE_FILE" 2>/dev/null)
      from_cache=1
    fi
  fi
fi

# Context window fallback: avoid showing 0.0k when ctx_used is missing/zero
if [ -z "$ctx_used" ] || [ "$ctx_used" = "0" ] || [ "$ctx_used" = "null" ]; then
  if [ -f "$CACHE_FILE" ]; then
    cached_ctx=$(jq -r '.context_window.total_input_tokens // empty' "$CACHE_FILE" 2>/dev/null)
    cached_ctx_total=$(jq -r '.context_window.context_window_size // empty' "$CACHE_FILE" 2>/dev/null)
    if [ -n "$cached_ctx" ] && [ "$cached_ctx" != "0" ]; then
      ctx_used="$cached_ctx"
      [ -z "$ctx_total" ] && ctx_total="$cached_ctx_total"
    fi
  fi
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

# Format a token count as "13.4k" or "1.0M"
fmt_tokens() {
  local n=$1
  awk -v n="$n" 'BEGIN {
    if (n >= 1000000)      printf "%.1fM", n/1000000
    else if (n >= 1000)    printf "%.1fk", n/1000
    else                   printf "%d", n
  }'
}

# Build a 10-char block progress bar
build_bar() {
  local pct=$1
  local fill empty_blocks i
  fill=$(awk -v p="$pct" 'BEGIN { v=int(p/10+0.5); if(v>10)v=10; if(v<0)v=0; print v }')
  empty_blocks=$((10 - fill))
  local bar=""
  for ((i=0; i<fill; i++));        do bar="${bar}█"; done
  for ((i=0; i<empty_blocks; i++)); do bar="${bar}░"; done
  printf '%s' "$bar"
}

# Pick ANSI color based on percent (green/yellow/red matching reference project)
pct_color() {
  local pct=$1
  local int_pct
  int_pct=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  if   [ "$int_pct" -ge 70 ]; then printf '\033[00;31m'  # red
  elif [ "$int_pct" -ge 30 ]; then printf '\033[00;33m'  # yellow
  else                              printf '\033[00;32m'  # green
  fi
}

# Dimmed color for cached values
dim_color() {
  printf '\033[02;37m'  # dim white
}

# Format a reset countdown as "(1h21m)" or "" if not in the future
fmt_countdown() {
  local reset_at=$1
  local now_epoch
  now_epoch=$(date +%s)
  if [ -n "$reset_at" ] && [ "$reset_at" -gt "$now_epoch" ] 2>/dev/null; then
    local diff_s=$(( reset_at - now_epoch ))
    local diff_h=$(( diff_s / 3600 ))
    local diff_m=$(( (diff_s % 3600) / 60 ))
    printf ' (%dh%02dm)' "$diff_h" "$diff_m"
  fi
}

RESET='\033[00m'
BOLD_BLUE='\033[01;34m'
CYAN='\033[00;36m'
DIM='\033[02m'
SEP=' | '

# ── Directory (abbreviate parents, full current dir name) ────────────────────
home="$HOME"
short_cwd="${cwd/#$home/\~}"
# Abbreviate all parent segments to first char, keep last segment full
# e.g. ~/tools/llm-project/vllm-server -> ~/t/l/vllm-server
abbrev_cwd=$(echo "$short_cwd" | awk -F'/' '{
  if (NF <= 1) { print $0; next }
  out = ""
  for (i = 1; i < NF; i++) {
    seg = $i
    if (seg == "~") { out = out seg }
    else if (seg != "") { out = out "/" substr(seg, 1, 1) }
    else { out = out "/" }
  }
  out = out "/" $NF
  print out
}')
output=$(printf "${BOLD_BLUE}%s${RESET}" "$abbrev_cwd")

# ── Git branch ────────────────────────────────────────────────────────────────
git_branch=""
if git -C "$cwd" rev-parse --git-dir --no-optional-locks >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
               || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi
if [ -n "$git_branch" ]; then
  output="${output} $(printf "${CYAN}\xef\x9c\xa5 %s${RESET}" "$git_branch")"
fi

# ── 5-hour rate limit with countdown ─────────────────────────────────────────
if [ -n "$fh_pct" ]; then
  if [ "$from_cache" -eq 1 ]; then
    color=$(dim_color)
  else
    color=$(pct_color "$fh_pct")
  fi
  pct_int=$(printf '%.0f' "$fh_pct")
  cd_5h=$(fmt_countdown "$fh_reset")
  cache_mark=""
  [ "$from_cache" -eq 1 ] && cache_mark="$(printf "${DIM}~${RESET}")"
  output="${output}${SEP}$(printf "${color}5h %s%%${RESET}${color}%s${RESET}" "$pct_int" "$cd_5h")${cache_mark}"
fi

# ── 7-day rate limit with countdown ─────────────────────────────────────────
if [ -n "$sd_pct" ]; then
  if [ "$from_cache" -eq 1 ]; then
    color=$(dim_color)
  else
    color=$(pct_color "$sd_pct")
  fi
  pct_int=$(printf '%.0f' "$sd_pct")
  cd_7d=$(fmt_countdown "$sd_reset")
  cache_mark=""
  [ "$from_cache" -eq 1 ] && cache_mark="$(printf "${DIM}~${RESET}")"
  output="${output}${SEP}$(printf "${color}7d %s%%${RESET}${color}%s${RESET}" "$pct_int" "$cd_7d")${cache_mark}"
fi

# ── Model (short name) + context tokens ───────────────────────────────────────
if [ -n "$model" ]; then
  # Take first word only (e.g. "Opus 4.6 (1M context)" -> "Opus")
  short_model=$(echo "$model" | awk '{print $1}')
  if [ -n "$ctx_used" ] && [ -n "$ctx_total" ] && [ "$ctx_used" != "0" ]; then
    used_fmt=$(fmt_tokens "$ctx_used")
    total_fmt=$(fmt_tokens "$ctx_total")
    # Context color based on used/total ratio
    ctx_pct=$(awk -v u="$ctx_used" -v t="$ctx_total" 'BEGIN { if(t>0) printf "%.1f", u/t*100; else print 0 }')
    color=$(pct_color "$ctx_pct")
    model_seg=$(printf "${color}%s(%s/%s)${RESET}" "$short_model" "$used_fmt" "$total_fmt")
  else
    color='\033[00;32m'
    model_seg=$(printf "${color}%s${RESET}" "$short_model")
  fi
  output="${output}${SEP}${model_seg}"
fi

printf '%s' "$output"
