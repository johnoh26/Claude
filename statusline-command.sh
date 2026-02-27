#!/usr/bin/env bash
# Claude Code status line: token usage %, model, git branch, directory, 5h block

input=$(cat)

# Parse JSON using node (no jq dependency)
cwd=$(node -e "const d=JSON.parse(process.argv[1]); process.stdout.write(d.cwd||d.workspace?.current_dir||'')" "$input" 2>/dev/null)
model=$(node -e "const d=JSON.parse(process.argv[1]); process.stdout.write(d.model?.display_name||'')" "$input" 2>/dev/null)
used_pct=$(node -e "const d=JSON.parse(process.argv[1]); process.stdout.write(String(d.context_window?.used_percentage??''))" "$input" 2>/dev/null)
input_tokens=$(node -e "const d=JSON.parse(process.argv[1]); const t=d.context_window?.current_usage?.input_tokens; process.stdout.write(t!=null?String(t):'')" "$input" 2>/dev/null)
ctx_size=$(node -e "const d=JSON.parse(process.argv[1]); const s=d.context_window?.context_window_size; process.stdout.write(s!=null?String(s):'')" "$input" 2>/dev/null)

home_dir="$HOME"
short_cwd="${cwd/#$home_dir/~}"

# Git branch
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Round token usage percentage
used_pct_display=""
if [ -n "$used_pct" ]; then
  used_pct_display=$(printf '%.0f' "$used_pct" 2>/dev/null)
fi

# Format token counts as K (thousands)
format_k() {
  local n="$1"
  if [ -z "$n" ]; then echo ""; return; fi
  node -e "process.stdout.write((Number(process.argv[1])/1000).toFixed(1)+'k')" "$n" 2>/dev/null
}

input_tokens_k=$(format_k "$input_tokens")
ctx_size_k=$(format_k "$ctx_size")

# 5-hour block info from ccusage
# Strip context_window field (ccusage rejects unknown keys) then pipe to ccusage
ccusage_input=$(printf '%s' "$input" | node -e "const c=[]; process.stdin.on('data',d=>c.push(d)); process.stdin.on('end',()=>{const d=JSON.parse(c.join('')); delete d.context_window; process.stdout.write(JSON.stringify(d));})" 2>/dev/null)
block_info=$(printf '%s' "$ccusage_input" | /home/johnoh26/.nvm/versions/node/v24.12.0/bin/npx ccusage statusline 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -oP '\$[0-9.]+ block \([^)]+\)' || true)

# Cyan: directory
printf '\033[01;36m%s\033[00m' "$short_cwd"

# Yellow: git branch
if [ -n "$git_branch" ]; then
  printf ' \033[01;33m(%s)\033[00m' "$git_branch"
fi

# Blue: model
if [ -n "$model" ]; then
  printf ' \033[01;34m%s\033[00m' "$model"
fi

# Magenta: token usage — show "used_tokens/ctx_size (pct%)" when counts available, else just pct
if [ -n "$used_pct_display" ]; then
  if [ -n "$input_tokens_k" ] && [ -n "$ctx_size_k" ]; then
    printf ' \033[01;35mctx:%s/%s(%s%%)\033[00m' "$input_tokens_k" "$ctx_size_k" "$used_pct_display"
  else
    printf ' \033[01;35mctx:%s%%\033[00m' "$used_pct_display"
  fi
fi

# Green: 5-hour block cost and time remaining
if [ -n "$block_info" ]; then
  printf ' \033[01;32m%s\033[00m' "$block_info"
fi
