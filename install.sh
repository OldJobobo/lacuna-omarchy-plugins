#!/usr/bin/env bash
set -Eeuo pipefail

repo_url="${LACUNA_REPO_URL:-https://github.com/OldJobobo/lacuna-shell.git}"
repo_ref="${LACUNA_REPO_REF:-master}"
install_dir="${LACUNA_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/lacuna-shell}"
assume_yes=false
staging_dir=""

usage() {
  cat <<'EOF'
Usage: install.sh [--yes] [--dir PATH]

Install or refresh Lacuna Shell from the official GitHub source checkout.
Use this as an alternative to the published AUR package.

Options:
  --yes, -y    Skip the bootstrap confirmation.
  --dir PATH   Store the source checkout at PATH.
  --help, -h   Show this help.
EOF
}

fail() {
  printf 'Lacuna install: %s\n' "$*" >&2
  exit 1
}

normalize_repo_url() {
  local value="${1%/}"
  value="${value%.git}"
  case "$value" in
    git@github.com:*) value="https://github.com/${value#git@github.com:}" ;;
  esac
  printf '%s\n' "$value"
}

cleanup() {
  if [[ -n "$staging_dir" && -d "$staging_dir" ]]; then
    rm -rf -- "$staging_dir"
  fi
}
trap cleanup EXIT

while (($# > 0)); do
  case "$1" in
    --yes|-y)
      assume_yes=true
      ;;
    --dir)
      (($# >= 2)) || fail "--dir requires a path"
      install_dir="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
  shift
done

[[ ${EUID:-$(id -u)} -ne 0 ]] || fail "run this as your normal user, not root"
command -v omarchy >/dev/null 2>&1 || fail "Omarchy is required"

printf '\nLacuna source installer\n\n'
printf '  Required packages: git, Python, Qt Multimedia\n'
printf '  Feature packages:  mpv, yt-dlp, ImageMagick\n'
printf '  Source:            %s\n' "$repo_url"
printf '  Source ref:        %s\n' "$repo_ref"
printf '  Checkout:          %s\n' "$install_dir"
printf '  Profile:      full\n\n'

if [[ "$assume_yes" != true ]]; then
  [[ -r /dev/tty ]] || fail "confirmation needs a terminal; rerun with --yes"
  printf 'Continue? [y/N] '
  if ! read -r reply 2>/dev/null </dev/tty; then
    fail "could not read confirmation; rerun from a terminal or pass --yes"
  fi
  case "$reply" in
    y|Y|yes|YES|Yes) ;;
    *)
      printf 'Cancelled.\n'
      exit 0
      ;;
  esac
fi

printf '\n[1/3] Preparing dependencies\n'
omarchy pkg add git python qt6-multimedia mpv yt-dlp imagemagick
command -v git >/dev/null 2>&1 || fail "git is still unavailable after dependency setup"

printf '\n[2/3] Preparing the Lacuna source\n'
if [[ -e "$install_dir" ]]; then
  [[ "$(git -C "$install_dir" rev-parse --is-inside-work-tree 2>/dev/null || true)" == "true" ]] \
    || fail "$install_dir exists but is not a Git checkout"
  origin_url="$(git -C "$install_dir" remote get-url origin 2>/dev/null || true)"
  [[ "$(normalize_repo_url "$origin_url")" == "$(normalize_repo_url "$repo_url")" ]] \
    || fail "$install_dir points to an unexpected Git remote: ${origin_url:-none}"
  [[ -z "$(git -C "$install_dir" status --porcelain)" ]] \
    || fail "$install_dir has local changes; preserve or remove them before continuing"
  git -C "$install_dir" fetch --prune origin "$repo_ref"
  remote_ref="origin/$repo_ref"
  git -C "$install_dir" rev-parse --verify "$remote_ref" >/dev/null 2>&1 \
    || fail "could not resolve source ref: $repo_ref"
  git -C "$install_dir" merge --ff-only "$remote_ref"
  [[ "$(git -C "$install_dir" rev-parse HEAD)" == "$(git -C "$install_dir" rev-parse "$remote_ref")" ]] \
    || fail "$install_dir contains commits outside the official source ref"
else
  parent_dir="$(dirname "$install_dir")"
  mkdir -p -- "$parent_dir"
  staging_dir="${install_dir}.tmp.$$"
  git clone --depth 1 --branch "$repo_ref" --single-branch "$repo_url" "$staging_dir"
  mv -- "$staging_dir" "$install_dir"
  staging_dir=""
fi

printf '\n[3/3] Installing the full Lacuna profile\n'
"$install_dir/scripts/lacuna" install --profile full --reinstall --yes

printf '\nLacuna Shell is installed.\n'
printf 'Run this for a health report:\n  %s/scripts/lacuna status\n' "$install_dir"
