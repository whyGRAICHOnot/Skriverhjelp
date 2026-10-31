# Skrivehjelp Live

A small background helper for **Kubuntu / KDE Plasma** that fixes spelling and grammar in **any app**: select some text, press a shortcut, and the corrected text replaces it.

- **Norwegian (bokmål):** works fully offline, using the same Hunspell dictionary as LibreOffice, plus a built-in list of everyday phrases so it can pick the right word from context (for example `hvordn gor de` becomes `hvordan går det`).
- **English and Russian:** checked with LanguageTool, which runs locally on your computer.
- **Optional AI mode:** if you add your own Anthropic API key, Claude can proofread instead. This is off by default and not needed.

> **Status:** a hobby project, tested on one laptop (Kubuntu, KDE Plasma 6, Wayland). It may need tweaking on other setups. See *Known issues* below.

## Install

Open a terminal and run these three lines. The installer asks for your password once.

```bash
cd "$(mktemp -d)"         # a fresh empty folder, so no old copy gets in the way
curl -fsSL https://raw.githubusercontent.com/whyGRAICHOnot/Skriverhjelp/main/install-live.sh -o install-live.sh
less install-live.sh      # optional: read it first (press q to quit)
bash install-live.sh
```

The installer downloads `skrivehjelp-live.py` by itself. It then:

- installs the needed packages (Java, Hunspell with Norwegian and English dictionaries, clipboard tools and more),
- sets up a private Python environment in `~/.local/share/skrivehjelp`,
- adds **Skrivehjelp Live** to your app menu and starts it automatically when you log in,
- creates KDE window rules for the floating button and the pop-up messages,
- tries to bind **Ctrl+Alt+G** as a global shortcut.

Prefer to do it by hand? Download `install-live.sh` and `skrivehjelp-live.py` into the same folder and run `bash install-live.sh`.

Start it from the app menu (**Skrivehjelp Live**) or log out and back in.

## Use

1. Select some text in any app.
2. Press **Ctrl+Alt+G**, or click the green **Aa** button, or click the tray icon.
3. The text is checked and the corrected version is pasted over the selection. A short message tells you how many things were fixed.

If nothing is pasted, the corrected text has still been copied. Press **Ctrl+V** yourself (see *Wayland* below).

### Tray menu (right-click the tray icon)

| Entry | What it does |
|---|---|
| Language choices | Switch between Norwegian and English |
| Live checking while typing | Suggestions as you type (**X11 sessions only**) |
| Use Claude AI (best quality) | Optional AI proofreading (needs your own API key) |
| Set Anthropic API key… | Paste your key for the AI mode |
| Add selected word to my dictionary | Stop a name or word from being flagged |
| Show floating button | Show or hide the green **Aa** button |
| Fix selected text now | Same as the shortcut |
| Quit | Stop the helper |

### Other hotkeys (X11 sessions)

`Ctrl+Alt+1 / 2 / 3` apply a suggestion, `Ctrl+Alt+L` switches Norwegian ↔ English.

### Wayland

On Wayland, apps are not allowed to watch what you type, so **live checking is not possible**; only the "fix selected text" mode works. To let the program paste the result for you, `ydotool` must be installed and its background service running. If it isn't, you just press **Ctrl+V** yourself, which is the default behaviour.

## Teach it your own phrases (Norwegian, offline)

The offline Norwegian mode reads two plain text files. You can edit them any time, no restart needed. Create them if they don't exist.

**`~/.config/skrivehjelp/phrases.txt`** lists correct phrases, one per line. They help it choose the right word when a typo could be several words:

```
hvordan går det med deg
jeg skal på jobb i morgen
```

**`~/.config/skrivehjelp/fixes.txt`** fixes real words that are wrong in a phrase. The format is `wrong => right`. A trailing `$` means "only at the end of a sentence":

```
hva skjer de$ => hva skjer det
```

**`~/.config/skrivehjelp/my_words.txt`** is your personal dictionary (words that should never be flagged). The tray menu entry *Add selected word to my dictionary* fills it for you.

## Known issues

- **The shortcut may not register.** If **Ctrl+Alt+G** does nothing, bind it yourself: *System Settings → Keyboard → Shortcuts → Add Command*, with this command:
  ```
  ~/.local/share/skrivehjelp/venv/bin/python ~/.local/share/skrivehjelp/skrivehjelp-live.py --fix
  ```
- The offline Norwegian mode knows words and phrases, **not meaning**. It will miss real words used wrongly unless the phrase is in a list. The AI mode handles that better.
- English and Russian use LanguageTool, which downloads its data the first time they are used (a large one-time download). Java is installed by the installer.
- The installer downloads an optional Norwegian word-frequency list from another project ([FrequencyWords](https://github.com/hermitdave/FrequencyWords)) to rank suggestions. If that download fails, everything still works.

## Privacy

- **Offline mode:** your text stays on your computer.
- **AI mode (optional):** the text you select is sent to Anthropic's servers. It needs your own API key from console.anthropic.com, and API use is billed separately from any Claude.ai subscription.

## Troubleshooting

| Problem | Try this |
|---|---|
| Nothing happens when I press the shortcut | Check the helper is running: `pgrep -af skrivehjelp`. If not, start it from the app menu. Then bind the shortcut by hand (see above). |
| "No selected text found" | Select the text first, then press the shortcut. |
| Corrected text isn't pasted | Press **Ctrl+V** yourself, or install and start `ydotool`. |
| Wrong suggestion for a word | Add the phrase to `phrases.txt` or use *Add selected word to my dictionary*. |
| See what's going wrong | Run it in a terminal: `~/.local/share/skrivehjelp/venv/bin/python ~/.local/share/skrivehjelp/skrivehjelp-live.py` |

## Update

Run the install lines again (including the first `cd "$(mktemp -d)"` line). The installer downloads the newest version and restarts the helper.

## Uninstall

```bash
pkill -f skrivehjelp-live.py
rm -r ~/.local/share/skrivehjelp
rm -f ~/.local/share/applications/skrivehjelp-live.desktop \
      ~/.local/share/applications/skrivehjelp-fix.desktop \
      ~/.config/autostart/skrivehjelp-live.desktop
rm -r ~/.config/skrivehjelp        # optional: your phrases, words and API key
```

Then, in *System Settings → Window Management → Window Rules*, delete the two rules called **Skrivehjelp Button** and **Skrivehjelp Toast**, and remove any shortcut you added. The installed packages can stay.
