# Get Rid Of It
### macOS App Leftover Cleaner

> A terminal-based tool that removes leftover files, folders, LaunchAgents and LaunchDaemons from uninstalled macOS applications using Spotlight for fast, system-safe scanning.

This project was born out of the need for a **simple, safe, open-source and lightweight** tool to fully clean up stubborn applications that leave traces all over your system even after uninstalling. A notorious example is Adobe Creative Cloud, which scatters files across multiple system locations and keeps background services running long after the app itself is gone. No third-party uninstaller, no bloat, just a transparent script you can read, understand and trust.

---

## Quick Start

Open you Terminal App on macOS and enter enter following command: 
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Trayv0n/Get-Rid-Of-It/refs/heads/main/Get-Rid-Of-It.sh)
```

Requires macOS with Bash 3.2+. No dependencies, no installation needed.

---

## What It Does

When you uninstall an app on macOS, it often leaves behind preference files (`.plist`), application support folders, caches, logs, and LaunchAgents and LaunchDaemons still running in the background. **Get Rid Of It** finds all of these using `mdfind` and lets you review and delete them interactively.

---

## How It Works

1. **Warning screen** confirms you understand what the script does
2. **Enter app name** e.g. `Photoshop`, `ChatGPT`
3. **Enter publisher name** *(optional)* e.g. `Adobe`, `OpenAI` for a broader search
4. **Numbered results** every found file and folder is listed with a number
5. **Exclude entries** enter numbers you want to keep before deletion
6. **Confirm deletion** nothing is deleted without your explicit `y` confirmation
7. **LaunchAgents/Daemons** are automatically deregistered via `launchctl unload` before deletion
8. **Save log** *(optional)* exports a `.txt` report to `~/Downloads`
9. **Restart Dock** *(optional)* may clear some ghost entries from Launchpad as a side effect

---

## Safety Features

| Feature | Details |
|---|---|
| **System file protection** | Skips `/System/`, `/usr/lib/`, `/bin/`, `/sbin/`, `/usr/share/` |
| **No blind deletion** | Every file is shown before you confirm |
| **Exclude list** | Keep specific entries safe with a simple number input |
| **launchctl unload** | Deregisters background services before removing them |
| **Self-exclusion** | The script never flags its own files |

---

## Example Session

```
╔══════════════════════════════════════╗
║         Get Rid Of It – v0.1         ║
║       macOS App Leftover Cleaner     ║
╚══════════════════════════════════════╝

⚠️  WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This script will permanently delete files and folders from your system.
Only use this script if you fully understand what it does.
Deleted files cannot be recovered unless you have a backup.

For more information, please visit:
https://github.com/Trayv0n/Get-Rid-Of-It
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I understand the risks and want to continue. [y/n]: y

Enter App Name: Photoshop
Publisher Name (optional, press Enter to skip): Adobe

Searching for traces of "Photoshop"...

Found files/folders:

  [  1] /Users/you/Library/Application Support/Adobe
  [  2] /Users/you/Library/Preferences/com.adobe.Photoshop.plist
  [  3] /Library/LaunchAgents/com.adobe.AdobeCreativeCloud.plist
  ...

Do you want to exclude certain entries from deletion?
Enter numbers (e.g. 2 5 17), press Enter to skip: 2

Delete all remaining entries? [y/n]: y

  Deregistering LaunchAgents/Daemons...
   launchctl unload: /Library/LaunchAgents/com.adobe.AdobeCreativeCloud.plist

  Deleting files...

  ✓ /Users/you/Library/Application Support/Adobe
  ✓ /Library/LaunchAgents/com.adobe.AdobeCreativeCloud.plist

Finished! 2 entries deleted, 0 failed.

Save deleted entries as a text file in ~/Downloads? [y/n]: y
Log saved: ~/Downloads/get-rid-of-it_Photoshop_2026-03-29_14-00-00.txt

Restart Dock (killall Dock)? [y/n]: y

Get Rid Of It – Finished.
```

---

## Disclaimer

This script **permanently deletes files**. Always review the list carefully before confirming. The author takes no responsibility for accidental data loss. A Time Machine backup before use is recommended.

---

## Roadmap

- [ ] GUI version
- [ ] Homebrew formula
- [ ] Dry-run mode (`--dry-run` flag)
- [ ] Config file for trusted exclude patterns
- [ ] Launchpad database cleanup for stuck app entries

---

## License

MIT License. Feel free to use, modify and distribute.
