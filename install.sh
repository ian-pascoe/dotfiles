#!/usr/bin/env bash

set -eEuo pipefail

DOTFILES_REPO_URL='https://github.com/ian-pascoe/dotfiles.git'
DOTFILES_DIR="$HOME/.dotfiles"
STRICT=0
DRY_RUN=0
NON_INTERACTIVE='auto'
INSTALL_YAZI_PKGS="${INSTALL_YAZI_PKGS:-0}"
BACKUP_DIR=""
STEP_TOTAL=0
STEP_OK=0
STEP_SKIPPED=0
STEP_WARN=0

log_info() {
  printf '[INFO] %s\n' "$1"
}

log_warn() {
  STEP_WARN=$((STEP_WARN + 1))
  printf '[WARN] %s\n' "$1"
}

log_error() {
  printf '[ERROR] %s\n' "$1" >&2
}

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --dry-run             Print actions without changing files.
  --strict              Exit on optional-step failures.
  --non-interactive     Never prompt or run interactive follow-up tasks.
  --interactive         Force interactive behavior.
  --install-yazi-pkgs   Run 'ya pkg install' when yazi is installed.
  -h, --help            Show this help text.
EOF
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[DRY-RUN]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    run_cmd "$@"
    return
  fi

  if command_exists sudo; then
    run_cmd sudo "$@"
    return
  fi

  return 1
}

record_step_ok() {
  STEP_TOTAL=$((STEP_TOTAL + 1))
  STEP_OK=$((STEP_OK + 1))
}

record_step_skipped() {
  STEP_TOTAL=$((STEP_TOTAL + 1))
  STEP_SKIPPED=$((STEP_SKIPPED + 1))
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

canonical_path() {
  local path="$1"
  local parent=""

  if command_exists realpath; then
    realpath "$path" 2>/dev/null || printf '%s\n' "$path"
    return
  fi

  if command_exists python3; then
    python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$path" 2>/dev/null || printf '%s\n' "$path"
    return
  fi

  if [[ -d "$path" ]]; then
    (
      cd "$path" 2>/dev/null || exit 1
      pwd -P
    ) || printf '%s\n' "$path"
    return
  fi

  parent="$(dirname "$path")"
  if [[ -d "$parent" ]]; then
    (
      cd "$parent" 2>/dev/null || exit 1
      printf '%s/%s\n' "$(pwd -P)" "$(basename "$path")"
    ) || printf '%s\n' "$path"
    return
  fi

  printf '%s\n' "$path"
}

normalize_repo_url() {
  local url="$1"

  if [[ "$url" == git@github.com:* ]]; then
    url="https://github.com/${url#git@github.com:}"
  fi

  url="${url%.git}"
  url="${url%/}"
  printf '%s\n' "$url"
}

is_macos() {
  [[ "$OSTYPE" == darwin* ]]
}

init_non_interactive() {
  if [[ "$NON_INTERACTIVE" == 'auto' ]]; then
    if [[ -t 0 && -t 1 ]]; then
      NON_INTERACTIVE=0
    else
      NON_INTERACTIVE=1
    fi
  fi
}

ensure_backup_dir() {
  if [[ -n "$BACKUP_DIR" ]]; then
    return
  fi

  BACKUP_DIR="$HOME/.local/state/dotfiles-install/$(date +%Y%m%d_%H%M%S)"
  run_cmd mkdir -p "$BACKUP_DIR"
}

backup_destination() {
  local dst="$1"
  local backup_name

  ensure_backup_dir
  backup_name="${dst#$HOME/}"
  backup_name="${backup_name//\//__}"
  backup_name="${backup_name:-home-root}"
  run_cmd mv "$dst" "$BACKUP_DIR/$backup_name"
  log_info "Backed up '$dst' to '$BACKUP_DIR/$backup_name'"
}

link_with_backup() {
  local src="$1"
  local dst="$2"
  local mode="${3:-optional}"
  local current_target=""
  local expected_target=""

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    if [[ "$mode" == 'required' ]]; then
      log_error "Missing required source: $src"
      return 1
    fi
    log_warn "Source missing, skipping link: $src -> $dst"
    return 0
  fi

  if [[ -L "$dst" ]]; then
    current_target="$(canonical_path "$dst")"
    expected_target="$(canonical_path "$src")"
    if [[ "$current_target" == "$expected_target" ]]; then
      return 0
    fi
    backup_destination "$dst"
  elif [[ -e "$dst" ]]; then
    backup_destination "$dst"
  fi

  run_cmd mkdir -p "$(dirname "$dst")"
  run_cmd ln -snf "$src" "$dst"
  return 0
}

require_git() {
  if ! command_exists git; then
    log_error 'Git is not installed. Please install Git and try again.'
    exit 1
  fi
  record_step_ok
}

ensure_dotfiles_repo() {
  local origin_url=""
  local origin_normalized=""
  local expected_origin_normalized=""

  expected_origin_normalized="$(normalize_repo_url "$DOTFILES_REPO_URL")"

  if [[ ! -e "$DOTFILES_DIR" ]]; then
    log_info "Cloning dotfiles into $DOTFILES_DIR"
    run_cmd git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
    record_step_ok
    return
  fi

  if git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    origin_url="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
    origin_normalized="$(normalize_repo_url "$origin_url")"
    if [[ "$origin_normalized" == "$expected_origin_normalized" ]]; then
      log_info "Dotfiles repo already present at $DOTFILES_DIR"
      record_step_skipped
      return
    fi

    if [[ "$STRICT" -eq 1 ]]; then
      log_error "Existing repo at $DOTFILES_DIR uses different origin: $origin_url"
      exit 1
    fi

    log_warn "Existing repo at $DOTFILES_DIR uses different origin: $origin_url"
    record_step_skipped
    return
  fi

  if [[ "$STRICT" -eq 1 ]]; then
    log_error "$DOTFILES_DIR exists but is not a git repository"
    exit 1
  fi

  log_warn "$DOTFILES_DIR exists and is not a git repository. Backing up then recloning."
  backup_destination "$DOTFILES_DIR"
  run_cmd git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
  record_step_ok
}

setup_brew() {
  local brew_install_url='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'

  if ! command_exists brew; then
    if ! command_exists curl; then
      log_error 'curl is required to install Homebrew but was not found.'
      exit 1
    fi

    log_info 'Homebrew is not installed. Installing Homebrew...'
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '[DRY-RUN] /bin/bash -c "$(curl -fsSL %s)"\n' "$brew_install_url"
    else
      /bin/bash -c "$(curl -fsSL "$brew_install_url")"
    fi
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv bash)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
  fi

  if ! command_exists brew; then
    if [[ "$STRICT" -eq 1 ]]; then
      log_error 'Homebrew is unavailable after installation attempt.'
      exit 1
    fi
    log_warn 'Homebrew is unavailable; skipping Brewfile install.'
    record_step_skipped
    return
  fi

  link_with_backup "$DOTFILES_DIR/config/Brewfile" "$HOME/Brewfile" required

  log_info 'Installing Homebrew packages from Brewfile...'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[DRY-RUN] brew bundle install --file=%q\n' "$HOME/Brewfile"
    record_step_ok
    return
  fi

  if ! brew bundle install --file="$HOME/Brewfile"; then
    if [[ "$STRICT" -eq 1 ]]; then
      log_error 'brew bundle install failed in strict mode.'
      exit 1
    fi
    log_warn 'brew bundle install failed; continuing in non-strict mode.'
    record_step_skipped
    return
  fi

  log_info 'Homebrew packages installed.'
  record_step_ok
}

setup_xdg_dirs() {
  run_cmd mkdir -p "$HOME/"{.config,.cache,.local}
  run_cmd mkdir -p "$HOME/.local/"{bin,share,state}
  record_step_ok
}

setup_zsh() {
  local zsh_path=""
  local can_escalate=1

  if ! command_exists zsh; then
    record_step_skipped
    return
  fi

  log_info 'Setting up ZSH configuration...'
  zsh_path="$(command -v zsh)"

  link_with_backup "$DOTFILES_DIR/config/zsh/profile.zsh" "$HOME/.zprofile" required
  link_with_backup "$DOTFILES_DIR/config/zsh/env.zsh" "$HOME/.zshenv" required
  link_with_backup "$DOTFILES_DIR/config/zsh/rc.zsh" "$HOME/.zshrc" required

  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    log_info 'Login shell already set to zsh.'
    record_step_ok
    return
  fi

  if [[ "$NON_INTERACTIVE" -eq 1 && "${EUID:-$(id -u)}" -ne 0 ]]; then
    if command_exists sudo; then
      if ! sudo -n true >/dev/null 2>&1; then
        can_escalate=0
      fi
    else
      can_escalate=0
    fi

    if [[ "$can_escalate" -eq 0 ]]; then
      log_warn 'Skipping /etc/shells update and chsh in non-interactive mode (root access unavailable).'
      record_step_skipped
      return
    fi
  fi

  if [[ -r /etc/shells ]]; then
    if ! grep -Fxq "$zsh_path" /etc/shells; then
      log_info "Adding $zsh_path to /etc/shells"
      if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '[DRY-RUN] append %q to /etc/shells\n' "$zsh_path"
      else
        if ! printf '%s\n' "$zsh_path" | run_as_root tee -a /etc/shells >/dev/null; then
          if [[ "$STRICT" -eq 1 ]]; then
            log_error 'Failed to update /etc/shells in strict mode.'
            exit 1
          fi
          log_warn 'Could not update /etc/shells; shell change may fail.'
        fi
      fi
    fi
  else
    log_warn 'Could not read /etc/shells; skipping validation/update.'
  fi

  if ! run_as_root chsh -s "$zsh_path" "$USER"; then
    if [[ "$STRICT" -eq 1 ]]; then
      log_error 'Failed to change default shell to zsh in strict mode.'
      exit 1
    fi
    log_warn 'Unable to change default shell to zsh. You can run chsh manually later.'
    record_step_skipped
    return
  fi

  log_info 'ZSH configuration complete.'
  record_step_ok
}

setup_aerospace() {
  if ! is_macos || ! command_exists aerospace; then
    record_step_skipped
    return
  fi

  log_info 'Aerospace is installed. Setting up Aerospace configuration...'
  link_with_backup "$DOTFILES_DIR/config/aerospace" "$HOME/.aerospace" optional

  if command_exists osascript; then
    if ! osascript -e 'tell application "System Events" to (get the name of every login item) contains "Aerospace"' | grep -q 'true'; then
      run_cmd osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Aerospace.app", hidden:false}'
    fi
  fi

  log_info 'Aerospace configuration complete.'
  record_step_ok
}

setup_git_config() {
  local include_path="$HOME/.config/git/config"
  local existing_include=""
  local include_found=0

  log_info 'Setting up Git configuration...'
  link_with_backup "$DOTFILES_DIR/config/git" "$HOME/.config/git" required

  while IFS= read -r existing_include; do
    if [[ "$existing_include" == "$include_path" ]]; then
      include_found=1
      break
    fi
  done < <(git config --global --get-all include.path 2>/dev/null || true)

  if [[ "$include_found" -eq 1 ]]; then
    log_info 'Git include already configured.'
    record_step_skipped
    return
  fi

  run_cmd git config --global --add include.path "$include_path"
  log_info 'Git configuration complete.'
  record_step_ok
}

setup_optional_command_link() {
  local command_name="$1"
  local src="$2"
  local dst="$3"
  local label="$4"

  if ! command_exists "$command_name"; then
    record_step_skipped
    return
  fi

  log_info "Setting up $label configuration..."
  link_with_backup "$src" "$dst" optional
  log_info "$label configuration complete."
  record_step_ok
}

setup_optional_macos_link() {
  local command_name="$1"
  local src="$2"
  local dst="$3"
  local label="$4"

  if ! is_macos || ! command_exists "$command_name"; then
    record_step_skipped
    return
  fi

  log_info "Setting up $label configuration..."
  link_with_backup "$src" "$dst" optional
  log_info "$label configuration complete."
  record_step_ok
}

restart_brew_service_best_effort() {
  local service_name="$1"

  if ! command_exists brew; then
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[DRY-RUN] brew services restart %q\n' "$service_name"
    return
  fi

  if ! brew services restart "$service_name"; then
    log_warn "Unable to restart brew service '$service_name'."
  fi
}

setup_yazi() {
  if ! command_exists yazi; then
    record_step_skipped
    return
  fi

  log_info 'Setting up Yazi configuration...'
  link_with_backup "$DOTFILES_DIR/config/yazi" "$HOME/.config/yazi" optional

  if [[ "$INSTALL_YAZI_PKGS" -eq 1 ]]; then
    run_cmd ya pkg install
  elif [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    log_warn "Skipping 'ya pkg install' in non-interactive mode. Use --install-yazi-pkgs to enable."
  else
    log_info "Skipping 'ya pkg install' by default. Use --install-yazi-pkgs to enable."
  fi

  log_info 'Yazi configuration complete.'
  record_step_ok
}

print_summary() {
  log_info "Install summary: total=$STEP_TOTAL success=$STEP_OK skipped=$STEP_SKIPPED warnings=$STEP_WARN"
  if [[ -n "$BACKUP_DIR" ]]; then
    log_info "Backups were saved to: $BACKUP_DIR"
  fi
}

on_error() {
  log_error "Installation failed near line ${BASH_LINENO[0]} while running: $BASH_COMMAND"
  print_summary
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --strict)
      STRICT=1
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      ;;
    --interactive)
      NON_INTERACTIVE=0
      ;;
    --install-yazi-pkgs)
      INSTALL_YAZI_PKGS=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      exit 1
      ;;
    esac
    shift
  done
}

main() {
  trap on_error ERR
  parse_args "$@"
  init_non_interactive

  require_git
  setup_xdg_dirs
  ensure_dotfiles_repo
  setup_brew
  setup_zsh

  link_with_backup "$DOTFILES_DIR/themes" "$HOME/.themes" required
  record_step_ok

  log_info 'Setting up local bin files'
  for bin_path in "$DOTFILES_DIR/bin/"*; do
    if [[ -f "$bin_path" && -x "$bin_path" ]]; then
      dst="$HOME/.local/bin/$(basename "$bin_path")"
      link_with_backup "$bin_path" "$dst" optional
    fi
  done
  record_step_ok

  setup_aerospace

  log_info 'Setting up Agents configuration...'
  link_with_backup "$DOTFILES_DIR/config/agents" "$HOME/.agents" optional
  record_step_ok

  setup_optional_command_link bat "$DOTFILES_DIR/config/bat" "$HOME/.config/bat" 'Bat'
  setup_optional_macos_link borders "$DOTFILES_DIR/config/borders" "$HOME/.config/borders" 'Borders'
  if is_macos && command_exists borders; then
    restart_brew_service_best_effort borders
  fi
  setup_optional_command_link btop "$DOTFILES_DIR/config/btop" "$HOME/.config/btop" 'Btop'
  setup_optional_command_link claude "$DOTFILES_DIR/config/claude-code" "$HOME/.claude" 'Claude Code'
  setup_optional_command_link fastfetch "$DOTFILES_DIR/config/fastfetch" "$HOME/.config/fastfetch" 'Fastfetch'
  setup_optional_command_link ghostty "$DOTFILES_DIR/config/ghostty" "$HOME/.config/ghostty" 'Ghostty'
  setup_git_config
  setup_optional_macos_link hs "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon" 'Hammerspoon'
  setup_optional_command_link k9s "$DOTFILES_DIR/config/k9s" "$HOME/.config/k9s" 'K9s'

  if is_macos; then
    log_info 'Setting up Karabiner Elements configuration...'
    link_with_backup "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner" optional
    log_info 'Karabiner Elements configuration complete.'
    record_step_ok
  else
    record_step_skipped
  fi

  setup_optional_command_link lsd "$DOTFILES_DIR/config/lsd" "$HOME/.config/lsd" 'LSD'
  setup_optional_command_link nvim "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim" 'Neovim'
  setup_optional_command_link npm "$DOTFILES_DIR/config/npmrc" "$HOME/.npmrc" 'npm'
  setup_optional_command_link opencode "$DOTFILES_DIR/config/opencode" "$HOME/.config/opencode" 'OpenCode'
  setup_optional_macos_link sketchybar "$DOTFILES_DIR/config/sketchybar" "$HOME/.config/sketchybar" 'Sketchybar'
  if is_macos && command_exists sketchybar; then
    restart_brew_service_best_effort sketchybar
  fi
  setup_optional_command_link spotify_player "$DOTFILES_DIR/config/spotify-player" "$HOME/.config/spotify-player" 'Spotify Player'
  setup_optional_command_link starship "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml" 'Starship'
  setup_optional_command_link tmux "$DOTFILES_DIR/config/tmux" "$HOME/.config/tmux" 'Tmux'
  setup_yazi
  setup_optional_command_link zellij "$DOTFILES_DIR/config/zellij" "$HOME/.config/zellij" 'Zellij'

  print_summary
}

main "$@"
