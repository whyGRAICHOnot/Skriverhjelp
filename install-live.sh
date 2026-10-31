#!/usr/bin/env bash
set -e
DIR="$HOME/.local/share/skrivehjelp"
SRC="$(cd "$(dirname "$0")" && pwd)"

sudo apt update
sudo apt install -y default-jre python3-venv python3-pip xclip wl-clipboard libxcb-cursor0 \
    hunspell hunspell-no hunspell-en-us curl

mkdir -p "$DIR"
cp "$SRC/skrivehjelp-live.py" "$DIR/"

# Norwegian word-frequency list: makes spelling suggestions pick common words first (optional)
if [ ! -s "$DIR/no_50k.txt" ]; then
  curl -fsSL -o "$DIR/no_50k.txt" \
    https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/no/no_50k.txt \
    || echo "Could not download the word list (optional) - continuing."
fi
[ -x "$DIR/venv/bin/python" ] || python3 -m venv "$DIR/venv"
"$DIR/venv/bin/pip" install --upgrade pip
"$DIR/venv/bin/pip" install PyQt6 language_tool_python pynput

ENTRY="[Desktop Entry]
Type=Application
Name=Skrivehjelp Live
Comment=System-wide grammar and spell helper (EN / NO / RU)
Exec=$DIR/venv/bin/python $DIR/skrivehjelp-live.py
Icon=accessories-text-editor
Categories=Utility;
Terminal=false"

mkdir -p "$HOME/.local/share/applications" "$HOME/.config/autostart"
echo "$ENTRY" > "$HOME/.local/share/applications/skrivehjelp-live.desktop"
echo "$ENTRY" > "$HOME/.config/autostart/skrivehjelp-live.desktop"

# ---- KDE window rules: keep the button/toast on top, borderless, never take focus ----
KW=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
KR=$(command -v kreadconfig6 || command -v kreadconfig5 || true)
if [ -n "$KW" ] && [ -n "$KR" ]; then
  # Work out the screen size (logical pixels) to place the button bottom-right.
  GEOM=$(kscreen-doctor -j 2>/dev/null | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    o=[x for x in d["outputs"] if x.get("enabled")][0]
    s=o.get("scale",1) or 1
    print(int(o["size"]["width"]/s), int(o["size"]["height"]/s))
except Exception:
    pass' || true)
  W=${GEOM% *}; H=${GEOM#* }

  rules=$("$KR" --file kwinrulesrc --group General --key rules || true)
  case ",$rules," in
    *,skrivehjelp-button,*) ;;
    *) rules="${rules:+$rules,}skrivehjelp-button"; ;;
  esac
  case ",$rules," in
    *,skrivehjelp-toast,*) ;;
    *) rules="$rules,skrivehjelp-toast" ;;
  esac
  count=$(echo "$rules" | tr ',' '\n' | grep -c .)
  "$KW" --file kwinrulesrc --group General --key rules "$rules"
  "$KW" --file kwinrulesrc --group General --key count "$count"

  setrule() { # group key value rulecode
    "$KW" --file kwinrulesrc --group "$1" --key "$2" "$3"
    "$KW" --file kwinrulesrc --group "$1" --key "$2"rule "$4"
  }
  for G in skrivehjelp-button skrivehjelp-toast; do
    if [ "$G" = skrivehjelp-button ]; then T="Skrivehjelp Button"; else T="Skrivehjelp Toast"; fi
    "$KW" --file kwinrulesrc --group $G --key Description "$T"
    "$KW" --file kwinrulesrc --group $G --key title "$T"
    "$KW" --file kwinrulesrc --group $G --key titlematch 1
    setrule $G above true 2
    setrule $G acceptfocus false 2
    setrule $G noborder true 2
    setrule $G skiptaskbar true 2
    setrule $G skipswitcher true 2
    setrule $G skippager true 2
  done
  # 4 = remember (you can drag it with Alt+left-drag), 3 = apply initially
  if [ -n "$GEOM" ]; then
    setrule skrivehjelp-button position "$((W - 90)),$((H - 150))" 4
    setrule skrivehjelp-toast position "$((W / 2 - 200)),$((H - 170))" 3
  else
    setrule skrivehjelp-button position "" 4
  fi
  dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
  echo "KDE window rules installed."
else
  echo "kwriteconfig not found - skipping KDE window rules (see the manual steps)."
fi

# ---- KDE global shortcut for fixing selection (Ctrl+Alt+G) ----
FIX_ENTRY="[Desktop Entry]
Type=Application
Name=Skrivehjelp Fix Selection
Comment=Check and fix selected text with Skrivehjelp
Exec=$DIR/venv/bin/python $DIR/skrivehjelp-live.py --fix
Icon=accessories-text-editor
Categories=Utility;
Terminal=false
StartupNotify=false
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true"

echo "$FIX_ENTRY" > "$HOME/.local/share/applications/skrivehjelp-fix.desktop"

if [ -n "$KW" ]; then
  "$KW" --file kglobalshortcutsrc --group "skrivehjelp-fix.desktop" --key "_k_friendly_name" "Skrivehjelp Fix Selection"
  "$KW" --file kglobalshortcutsrc --group "skrivehjelp-fix.desktop" --key "_launch" "Ctrl+Alt+G,none,Skrivehjelp Fix Selection"
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental || true
fi

python3 -c '
try:
    import dbus
    bus = dbus.SessionBus()
    kg = bus.get_object("org.kde.kglobalaccel", "/kglobalaccel")
    iface = dbus.Interface(kg, "org.kde.KGlobalAccel")
    action_id = ["skrivehjelp-fix.desktop", "_launch", "Skrivehjelp Fix Selection", "Skrivehjelp Fix Selection"]
    iface.doRegister(action_id)
    iface.setForeignShortcut(action_id, dbus.Array([201326663], signature="i"))
    print("Registered global shortcut Ctrl+Alt+G.")
except Exception as e:
    print(f"Notice: could not dynamically bind DBus shortcut: {e}")
' || true

# Restart the daemon if running
if pgrep -f "$DIR/skrivehjelp-live.py" >/dev/null 2>&1; then
  echo "Restarting Skrivehjelp Live..."
  pkill -f "$DIR/skrivehjelp-live.py" || true
  sleep 1
  nohup "$DIR/venv/bin/python" "$DIR/skrivehjelp-live.py" >/dev/null 2>&1 &
fi

echo
echo "Done. Session type: ${XDG_SESSION_TYPE:-unknown}"
echo "Shortcut: highlight any text and press Ctrl+Alt+G (or click the green 'Aa' button)."
echo "Start it from the app menu ('Skrivehjelp Live') or it will autostart on login."
