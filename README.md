# GenP — Adobe CC Universal Patcher (Open Source)

[![Latest release](https://img.shields.io/github/v/release/TheMythologist/GenP)](https://github.com/TheMythologist/GenP/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/TheMythologist/GenP/total)](https://github.com/TheMythologist/GenP/releases)

> **This repository is strictly for educational and archival purposes only.**

GenP (Generic Patcher) is an open-source Adobe patcher written in AutoIt that applies binary hex patches to Adobe Creative Cloud application files, modifying their licensing behavior. It supports Photoshop, Illustrator, Premiere Pro, After Effects, Acrobat, Lightroom, and the rest of the CC suite on Windows 10 and 11.

Copies of GenP float around on Discord, Telegram, and random file hosts — and there's no way to tell if those binaries are clean or packed with malware. That's the problem this repo fixes:

- **Source code is public.** The AutoIt source and all patch definitions (`config.ini`) are right here. Read them before you run anything.
- **Builds happen on GitHub Actions, not someone's PC.** The CI workflow ([`.github/workflows/release.yml`](.github/workflows/release.yml)) runs on GitHub-hosted runners. No one touches the binary between compilation and upload.
- **Releases ship with SHA checksums.** You can verify that what you downloaded matches what CI produced, byte for byte.

If your copy didn't come from this repo's GitHub Releases page, you can't know what's in it.

## Origins

- **Original project:** [gen.paramore.su](https://gen.paramore.su/)
- **Community continuation & guides:** [wiki.dbzer0.com/genp-guides](https://wiki.dbzer0.com/genp-guides/)

## History of GenP and Adobe

### Adobe Kills Perpetual Licenses (2013)

In 2013, Adobe dropped perpetual licenses for Creative Suite and went all-in on the Creative Cloud subscription model. A lot of people hated it. Surveys at the time put the number at 87% of users preferring the old model. For hobbyists, students, and freelancers who couldn't justify the recurring cost, piracy tools became the workaround.

### GenP Shows Up (~2019)

GenP first appeared around 2019. A developer going by **Uncia** built it as a universal Adobe CC patcher — one tool that could patch Photoshop, Illustrator, Premiere, and the rest of the suite in one shot. It worked by applying hex patches to application binaries, disabling the Adobe Genuine Service (AGS), licensing checks, and phone-home calls.

The **r/GenP** subreddit quickly became the main hub for downloads, guides, and troubleshooting.

### Version History

| Version | When | What Changed |
| ------- | ---- | ------------ |
| 2.0 | ~2019 | First multi-app patcher for Adobe CC 2019 |
| 2.4–2.5 | 2020 | Stability fixes, CC 2019–2020 compat |
| 2.7 | 2021–2022 | Partial Acrobat support |
| 3.0 | ~2023 | Hosts file bypass, full Acrobat support — Uncia's last release |
| 3.4+ | 2024 | Taken over by the CGP community |
| 3.7.x | 2025 | Latest Adobe versions, Windows 10/11 |

### Uncia Steps Down, CGP Takes Over

Uncia retired from the scene in early 2023 and dropped GenP 3.0.3 (listed on Reddit as GenP 3.0) with the full source code. The **CGP (Community GenP)** group picked it up from there, keeping it working against newer Adobe releases. The credits in current versions read: *"Original version by Uncia — CGP + GenP Community Edition."*

### How Adobe Fought Back

Adobe didn't just sit and watch. Their response came in waves:

- **Adobe Genuine Service (AGS)** — a background process that flags modified installs and nags users with "non-genuine software" warnings.
- **Anti-crack updates (2022)** — Adobe CC version 23.x shipped with detection code specifically targeting GenP patches, breaking older versions of the tool overnight.
- **DMCA takedowns (2025)** — Adobe went after hosting platforms and communities distributing GenP with formal DMCA notices.
- **Selective enforcement** — Adobe doesn't brick every patched install. They use a mix of warnings, feature degradation, and targeted lockouts. Casual users mostly get left alone (they stay in the Adobe ecosystem), while commercial use gets cracked down on harder.

### r/GenP Gets Banned, Community Scatters (April 2025)

On **April 30, 2025**, Reddit pulled the plug on r/GenP, citing copyright violations — almost certainly the result of Adobe's legal pressure. The community moved to:

- [**lemmy.dbzer0.com/c/GenP**](https://lemmy.dbzer0.com/c/GenP) — main discussion forum
- **Discord & Telegram** — real-time support channels
- **GitHub mirrors** — source code and binary archives
- [**wiki.dbzer0.com**](https://wiki.dbzer0.com/genp-guides/) — the go-to guide and troubleshooting wiki

## Binary Verification

Each version directory includes two third-party binaries. Neither is produced by this repository — they come from the upstream GenP patch developers. To ensure they haven't been tampered with, they are verified against their official sources:

| Binary | Source | Verification method |
| ------ | ------ | ------------------- |
| `upx-*-win64.zip` | [github.com/upx/upx/releases](https://github.com/upx/upx/releases) | SHA-256 compared against the matching GitHub release |
| `wintrust.dll` | Microsoft Windows (stock, unpatched) | SHA-256 looked up in [winbindex](https://winbindex.m417z.com/) to confirm it is a known Microsoft-signed binary |

The `wintrust.dll` in the repository is the **unmodified** Microsoft DLL. It gets patched at build time by `patch_wintrust.ps1` (two bytes at offsets `0x1C86`–`0x1C87`).

**Verify locally:**

```
python verify_binaries.py          # check all versions
python verify_binaries.py v4.0.0   # check a specific version
```

This check also runs automatically in CI before every release build.

## Project Structure

Each version lives in its own directory (e.g. `v3.7.2/`):

```
v3.7.2/
├── GenP/
│   ├── GenP-3.7.2.au3   # AutoIt source
│   ├── config.ini        # Patch definitions & target files
│   └── Skull.ico         # Application icon
├── WinTrust/
│   ├── patch_wintrust.ps1
│   └── wintrust.dll
├── UPX/
│   └── upx-5.0.1-win64.zip
├── build.ps1             # PowerShell build script
├── run_build.bat         # Build entry point (run as admin)
└── build_info.txt
```

## Building

Run `run_build.bat` as administrator. The build script will:

1. Download AutoIt and SciTE
2. Patch `wintrust.dll`
3. Compile the `.au3` source into an executable

The compiled `.exe` is output to a `Release/` folder.

Releases are also built automatically via GitHub Actions on push to `main`.

## Acknowledgments

GenP wouldn't exist without the people who built it, maintained it, and kept the community alive through every takedown and platform ban:

- **Uncia** — started it all. Built GenP from scratch and maintained it for years before stepping away and open-sourcing everything.
- **The CGP community** — picked up where Uncia left off and kept GenP working through Adobe's constant counter-measures.
- **MP79** — contributor behind v3.7.2 and ongoing patch work.
- **[gen.paramore.su](https://gen.paramore.su/)** — the original home of GenP.
- **[wiki.dbzer0.com](https://wiki.dbzer0.com/genp-guides/)** — took over as the community's central guide and knowledge base after the Reddit ban.
- **[ignaciocastro / a-dove-is-dumb](https://github.com/ignaciocastro/a-dove-is-dumb)** — maintains the custom domain blocklist used by GenP.
- **Everyone who wrote guides, answered questions, mirrored releases, and kept things going** — past, present, and future.

## Disclaimer

This repository is provided **as-is for educational purposes only**. The authors do not condone software piracy. Use of this tool may violate Adobe's terms of service and applicable laws in your jurisdiction. You are solely responsible for how you use this software.
