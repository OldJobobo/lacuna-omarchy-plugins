#!/usr/bin/env bash
set -u

OMARCHY_PATH=${OMARCHY_PATH:-"$HOME/.local/share/omarchy"}
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
CURRENT_DIR="$CONFIG_HOME/omarchy/current"
CURRENT_THEME_PATH="$CURRENT_DIR/theme"
CURRENT_BACKGROUND_LINK="$CURRENT_DIR/background"
THEME_NAME="${1:-}"

if [[ -z $THEME_NAME && -f $CURRENT_DIR/theme.name ]]; then
  THEME_NAME=$(<"$CURRENT_DIR/theme.name")
fi

THEME_NAME=$(printf '%s' "$THEME_NAME" | tr -d '\n')
CURRENT_BACKGROUND=$(readlink -f "$CURRENT_BACKGROUND_LINK" 2>/dev/null || true)

if [[ -z $CURRENT_BACKGROUND || ! -f $CURRENT_BACKGROUND ]]; then
  exit 0
fi

BACKGROUND_NAME=${CURRENT_BACKGROUND##*/}
TARGET_BACKGROUND=""

find_source_background() {
  local candidate

  for candidate in \
    "$CONFIG_HOME/omarchy/backgrounds/$THEME_NAME/$BACKGROUND_NAME" \
    "$CONFIG_HOME/omarchy/themes/$THEME_NAME/backgrounds/$BACKGROUND_NAME" \
    "$OMARCHY_PATH/themes/$THEME_NAME/backgrounds/$BACKGROUND_NAME"; do
    if [[ -f $candidate ]]; then
      readlink -f "$candidate"
      return
    fi
  done
}

if [[ -n $THEME_NAME ]]; then
  TARGET_BACKGROUND=$(find_source_background || true)
fi

if [[ -z $TARGET_BACKGROUND ]]; then
  case "$CURRENT_BACKGROUND" in
    "$CURRENT_THEME_PATH"/backgrounds/*)
      CACHE_DIR="${XDG_CACHE_HOME:-"$HOME/.cache"}/omarchy/lacuna/background-refresh"
      mkdir -p "$CACHE_DIR"
      extension="${BACKGROUND_NAME##*.}"
      stamp=$(stat -Lc '%s-%Y' "$CURRENT_BACKGROUND" 2>/dev/null || date +%s)
      TARGET_BACKGROUND="$CACHE_DIR/${THEME_NAME:-theme}-${BACKGROUND_NAME%.*}-$stamp.$extension"
      if [[ ! -f $TARGET_BACKGROUND ]]; then
        ln "$CURRENT_BACKGROUND" "$TARGET_BACKGROUND" 2>/dev/null || cp "$CURRENT_BACKGROUND" "$TARGET_BACKGROUND"
      fi
      ;;
    *)
      TARGET_BACKGROUND="$CURRENT_BACKGROUND"
      ;;
  esac
fi

if [[ -n $TARGET_BACKGROUND && -f $TARGET_BACKGROUND ]]; then
  ln -nsf "$TARGET_BACKGROUND" "$CURRENT_BACKGROUND_LINK"
  omarchy-shell -q background set "$TARGET_BACKGROUND" >/dev/null 2>&1 || true
fi
