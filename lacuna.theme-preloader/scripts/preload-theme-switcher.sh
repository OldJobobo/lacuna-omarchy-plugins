#!/usr/bin/env bash
set -uo pipefail

OMARCHY_PATH=${OMARCHY_PATH:-"$HOME/.local/share/omarchy"}
USER_THEMES_PATH=${USER_THEMES_PATH:-"$HOME/.config/omarchy/themes"}
OMARCHY_THEMES_PATH=${OMARCHY_THEMES_PATH:-"$OMARCHY_PATH/themes"}
CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
CACHE_PATH="$CACHE_HOME/omarchy/theme-selector"
PREVIEW_DIR="$CACHE_PATH/previews"
SIGNATURE_FILE="$CACHE_PATH/signature"
FAST_SIGNATURE_FILE="$CACHE_PATH/fast-signature"
STATUS_FILE="$CACHE_PATH/preloader-status.json"
LOCK_DIR="$CACHE_PATH/preloader.lock"
REASON="manual"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason)
      REASON="${2:-manual}"
      shift 2
      ;;
    --help|-h)
      printf 'Usage: %s [--reason <label>]\n' "$0"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$CACHE_PATH" "$PREVIEW_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi

# shellcheck disable=SC2329
cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

write_status() {
  local status="$1"
  local changed="$2"
  local theme_count="$3"
  local message="${4:-}"
  local now
  now=$(date -Is)
  printf '{"status":"%s","changed":%s,"themeCount":%s,"reason":"%s","message":"%s","updatedAt":"%s"}\n' \
    "$(json_escape "$status")" \
    "$changed" \
    "$theme_count" \
    "$(json_escape "$REASON")" \
    "$(json_escape "$message")" \
    "$(json_escape "$now")" >"$STATUS_FILE"
}

find_preview() {
  local theme_path="$1"
  local preview preview_name

  for preview_name in preview.png preview.jpg preview.jpeg preview.webp preview.gif preview.bmp; do
    preview=$(find -L "$theme_path" -maxdepth 1 -type f -iname "$preview_name" -print -quit 2>/dev/null)
    if [[ -n $preview ]]; then
      printf '%s\n' "$preview"
      return
    fi
  done

  if [[ -d $theme_path/backgrounds ]]; then
    find -L "$theme_path/backgrounds" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print 2>/dev/null | sort | head -n 1
  fi
}

add_theme_preview() {
  local theme_name="$1"
  local preview="$2"
  local extension

  [[ -n $preview ]] || return
  [[ -e $preview ]] || return

  extension="${preview##*.}"
  extension="${extension,,}"
  [[ -n $extension ]] || return

  if [[ -e $PREVIEW_DIR/$theme_name.$extension ]]; then
    return
  fi

  ln -s "$preview" "$PREVIEW_DIR/$theme_name.$extension"
}

fast_signature="v1"$'\n'
theme_count=0

for theme_dir in "$USER_THEMES_PATH" "$OMARCHY_THEMES_PATH"; do
  if [[ -d $theme_dir ]]; then
    fast_signature+="$theme_dir:$(stat -Lc '%Y' "$theme_dir")"$'\n'

    while IFS= read -r -d '' theme_path; do
      fast_signature+="$theme_path:$(stat -Lc '%Y' "$theme_path")"$'\n'
      theme_count=$((theme_count + 1))
    done < <(find -L "$theme_dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -print0 2>/dev/null | sort -z)
  fi
done

cache_stale=false
if [[ ! -f $FAST_SIGNATURE_FILE ]] || ! cmp -s "$FAST_SIGNATURE_FILE" <(printf '%s' "$fast_signature"); then
  cache_stale=true
fi

theme_signature=""
if [[ $cache_stale == true ]]; then
  for theme_dir in "$USER_THEMES_PATH" "$OMARCHY_THEMES_PATH"; do
    if [[ -d $theme_dir ]]; then
      theme_signature+="$theme_dir:$(stat -Lc '%Y' "$theme_dir")"$'\n'

      while IFS= read -r -d '' theme_path; do
        preview=$(find_preview "$theme_path")
        theme_signature+="$theme_path:$(stat -Lc '%Y' "$theme_path")"$'\n'

        if [[ -n $preview && -e $preview ]]; then
          theme_signature+="$preview:$(stat -Lc '%s:%Y' "$preview")"$'\n'
        fi
      done < <(find -L "$theme_dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -print0 2>/dev/null | sort -z)
    fi
  done
fi

changed=false
if [[ $cache_stale == true ]]; then
  changed=true
  rm -rf "$PREVIEW_DIR"
  mkdir -p "$PREVIEW_DIR"

  if [[ -d $USER_THEMES_PATH ]]; then
    while IFS= read -r theme_path; do
      theme_name=${theme_path##*/}
      preview=$(find_preview "$theme_path")

      if [[ -z $preview ]]; then
        preview=$(find_preview "$OMARCHY_THEMES_PATH/$theme_name")
      fi

      add_theme_preview "$theme_name" "$preview"
    done < <(find -L "$USER_THEMES_PATH" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -print 2>/dev/null | sort)
  fi

  if [[ -d $OMARCHY_THEMES_PATH ]]; then
    while IFS= read -r theme_path; do
      theme_name=${theme_path##*/}
      preview=$(find_preview "$theme_path")
      add_theme_preview "$theme_name" "$preview"
    done < <(find -L "$OMARCHY_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort)
  fi

  printf '%s' "$theme_signature" >"$SIGNATURE_FILE"
  printf '%s' "$fast_signature" >"$FAST_SIGNATURE_FILE"
fi

menu_images=(omarchy menu images)
if [[ -x "$OMARCHY_PATH/bin/omarchy" ]]; then
  menu_images=("$OMARCHY_PATH/bin/omarchy" menu images)
elif ! command -v omarchy >/dev/null 2>&1; then
  menu_images=()
fi

if ((${#menu_images[@]} > 0)); then
  if "${menu_images[@]}" --cache-only "$PREVIEW_DIR" >/dev/null 2>&1; then
    write_status "ok" "$changed" "$theme_count" "cache warm"
    exit 0
  fi

  write_status "failed" "$changed" "$theme_count" "omarchy menu images failed"
  exit 1
fi

write_status "failed" "$changed" "$theme_count" "omarchy menu images not found"
exit 1
