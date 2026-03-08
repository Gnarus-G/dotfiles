#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel)
SCRIPT="$ROOT_DIR/.local/bin/git-wt"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "$message (expected '$expected', got '$actual')"
  fi
}

assert_file_exists() {
  local path="$1"
  local message="$2"
  [[ -e "$path" ]] || fail "$message ($path)"
}

assert_dir_missing() {
  local path="$1"
  local message="$2"
  [[ ! -d "$path" ]] || fail "$message ($path)"
}

make_fake_fzf() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat >"$bin_dir/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ " ${*:-} " == *" --multi "* && -n "${FZF_CHOICES:-}" ]]; then
  while IFS= read -r line; do
    while IFS= read -r choice; do
      if [[ "$line" == "$choice" || "$line" == "$choice"$'\t'* ]]; then
        printf '%s\n' "$line"
      fi
    done <<<"$FZF_CHOICES"
  done
  exit 0
fi
if [[ -n "${FZF_CHOICE:-}" ]]; then
  while IFS= read -r line; do
    if [[ "$line" == "$FZF_CHOICE" || "$line" == "$FZF_CHOICE"$'\t'* ]]; then
      printf '%s\n' "$line"
      exit 0
    fi
  done
  printf '%s\n' "$FZF_CHOICE"
  exit 0
fi
IFS= read -r first_line || exit 1
printf '%s\n' "$first_line"
EOF
  chmod +x "$bin_dir/fzf"
}

setup_repo() {
  local base_dir="$1"
  local repo_dir="$base_dir/sample"

  mkdir -p "$repo_dir"
  git init -b main "$repo_dir" >/dev/null
  git -C "$repo_dir" config user.name test
  git -C "$repo_dir" config user.email test@example.com

  printf 'root\n' >"$repo_dir/file.txt"
  git -C "$repo_dir" add file.txt
  git -C "$repo_dir" commit -m 'initial' >/dev/null
  git -C "$repo_dir" branch feature/base

  printf '%s\n' "$repo_dir"
}

test_create_detached_worktree() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local fake_bin="$tmpdir/bin"
  make_fake_fzf "$fake_bin"

  local repo_dir
  repo_dir=$(setup_repo "$tmpdir")

  local output
  output=$(cd "$repo_dir" && HOME="$tmpdir/home" PATH="$fake_bin:$PATH" FZF_CHOICE="main" "$SCRIPT" 2>&1)

  local created_path
  created_path=$(printf '%s\n' "$output" | grep '^Created worktree:' | sed 's/^Created worktree: //')

  assert_file_exists "$created_path/.git" 'detached worktree should be created'
  [[ "$created_path" == "$tmpdir/home/d/agentic/main_sample_"* ]] || fail 'worktree path should prefix the sanitized branch name'

  local head_ref
  head_ref=$(git -C "$created_path" symbolic-ref -q --short HEAD || true)
  assert_eq "$head_ref" "" 'worktree should be detached when -b is omitted'

  local head_commit
  head_commit=$(git -C "$created_path" rev-parse --short HEAD)
  local base_commit
  base_commit=$(git -C "$repo_dir" rev-parse --short main)
  assert_eq "$head_commit" "$base_commit" 'detached worktree should point at selected base branch'
}

test_create_attached_worktree_for_other_branch() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local fake_bin="$tmpdir/bin"
  make_fake_fzf "$fake_bin"

  local repo_dir
  repo_dir=$(setup_repo "$tmpdir")

  local output
  output=$(cd "$repo_dir" && HOME="$tmpdir/home" PATH="$fake_bin:$PATH" FZF_CHOICE="feature/base" "$SCRIPT" 2>&1)

  local created_path
  created_path=$(printf '%s\n' "$output" | grep '^Created worktree:' | sed 's/^Created worktree: //')

  local branch
  branch=$(git -C "$created_path" branch --show-current)
  assert_eq "$branch" "feature/base" 'non-current selected branch should be attached in the new worktree'
  [[ "$created_path" == "$tmpdir/home/d/agentic/feature-base_sample_"* ]] || fail 'attached worktree path should include the selected branch name'
}

test_create_named_branch() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local fake_bin="$tmpdir/bin"
  make_fake_fzf "$fake_bin"

  local repo_dir
  repo_dir=$(setup_repo "$tmpdir")

  local output
  output=$(cd "$repo_dir" && HOME="$tmpdir/home" PATH="$fake_bin:$PATH" FZF_CHOICE="feature/base" "$SCRIPT" -b topic/demo 2>&1)

  local created_path
  created_path=$(printf '%s\n' "$output" | grep '^Created worktree:' | sed 's/^Created worktree: //')

  local branch
  branch=$(git -C "$created_path" branch --show-current)
  assert_eq "$branch" "topic/demo" 'worktree should check out the requested branch'
  [[ "$created_path" == "$tmpdir/home/d/agentic/feature-base_sample_"* ]] || fail 'named branch worktree should prefix the sanitized base branch name'

  git -C "$repo_dir" show-ref --verify --quiet refs/heads/topic/demo || fail 'new branch should exist in source repo'
}

test_remove_selected_worktree() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local fake_bin="$tmpdir/bin"
  make_fake_fzf "$fake_bin"

  local repo_dir
  repo_dir=$(setup_repo "$tmpdir")
  git -C "$repo_dir" worktree add "$tmpdir/removable" feature/base >/dev/null

  (cd "$repo_dir" && HOME="$tmpdir/home" PATH="$fake_bin:$PATH" FZF_CHOICE="$tmpdir/removable" "$SCRIPT" rm >/dev/null 2>&1)

  assert_dir_missing "$tmpdir/removable" 'selected worktree should be removed'
  git -C "$repo_dir" show-ref --verify --quiet refs/heads/feature/base || fail 'removing a worktree should keep its branch'
}

test_remove_multiple_worktrees() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local fake_bin="$tmpdir/bin"
  make_fake_fzf "$fake_bin"

  local repo_dir
  repo_dir=$(setup_repo "$tmpdir")
  git -C "$repo_dir" worktree add "$tmpdir/removable-one" feature/base >/dev/null
  git -C "$repo_dir" worktree add --detach "$tmpdir/removable-two" main >/dev/null

  local choices
  choices=$(printf '%s\n%s\n' "$tmpdir/removable-one" "$tmpdir/removable-two")

  (
    cd "$repo_dir" &&
      HOME="$tmpdir/home" PATH="$fake_bin:$PATH" \
      FZF_CHOICES="$choices" "$SCRIPT" rm >/dev/null 2>&1
  )

  assert_dir_missing "$tmpdir/removable-one" 'first selected worktree should be removed'
  assert_dir_missing "$tmpdir/removable-two" 'second selected worktree should be removed'
}

test_zsh_wrapper_auto_cd() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  mkdir -p "$tmpdir/bin" "$tmpdir/target"

  python - <<'PY' >"$tmpdir/git-wrapper.zsh"
from pathlib import Path
import re

text = Path('/home/gnarus/d/dotfiles/.zshrc').read_text()
match = re.search(r'^git\(\) \{.*?^\}', text, re.MULTILINE | re.DOTALL)
if not match:
    raise SystemExit('git wrapper not found in .zshrc')
print(match.group(0))
PY

  cat >"$tmpdir/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -ge 1 && "$1" == wt ]]; then
  printf 'Created worktree: %s\n' "$FAKE_GIT_WT_TARGET"
  printf 'Base branch: main\n'
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$tmpdir/bin/git"

  local output
  output=$(FAKE_GIT_WT_TARGET="$tmpdir/target" HOME="$HOME" PATH="$tmpdir/bin:$PATH" zsh -fc 'source "$1"; git wt >/dev/null 2>&1; pwd' zsh "$tmpdir/git-wrapper.zsh")
  assert_eq "$output" "$tmpdir/target" 'zsh git wrapper should cd into the created worktree'
}

test_create_detached_worktree
test_create_attached_worktree_for_other_branch
test_create_named_branch
test_remove_selected_worktree
test_remove_multiple_worktrees
test_zsh_wrapper_auto_cd

printf 'ok\n'
