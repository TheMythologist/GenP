"""
Verify that third-party binaries (UPX and wintrust.dll) in each version
directory match their official upstream sources.

- UPX:          compared against the GitHub release at github.com/upx/upx
- wintrust.dll: looked up by SHA-256 in winbindex (winbindex.m417z.com)

Exit code 0 = all checks passed, 1 = at least one check failed.
"""

import gzip
import hashlib
import json
import re
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

GITHUB_UPX_RELEASE_URL = (
    "https://github.com/upx/upx/releases/download/v{version}/upx-{version}-win64.zip"
)
WINBINDEX_URL = (
    "https://winbindex.m417z.com/data/by_filename_compressed/wintrust.dll.json.gz"
)

# Cache the winbindex data across multiple version directories so we only
# download it once.
_winbindex_cache: dict | None = None


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def fetch_url(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "GenP-verify/1.0"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


# -- UPX verification --------------------------------------------------------


def verify_upx(upx_dir: Path) -> bool:
    """Find the UPX zip, download the matching release, compare SHA-256."""
    zips = list(upx_dir.glob("upx-*-win64.zip"))
    if not zips:
        print(f"  [SKIP] No upx-*-win64.zip found in {upx_dir}")
        return True  # nothing to verify

    zip_path = zips[0]
    match = re.match(r"upx-(.+)-win64\.zip", zip_path.name)
    if not match:
        print(f"  [FAIL] Cannot parse version from {zip_path.name}")
        return False

    version = match.group(1)
    local_hash = sha256(zip_path)
    url = GITHUB_UPX_RELEASE_URL.format(version=version)

    print(f"  UPX {version}")
    print(f"    Local : {local_hash}")
    print(f"    Source: {url}")

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".zip") as tmp:
            tmp.write(fetch_url(url))
            tmp_path = Path(tmp.name)
        remote_hash = sha256(tmp_path)
        tmp_path.unlink(missing_ok=True)
    except urllib.error.HTTPError as e:
        print(f"    [FAIL] Download failed: HTTP {e.code}")
        return False
    except Exception as e:
        print(f"    [FAIL] Download failed: {e}")
        return False

    print(f"    Remote: {remote_hash}")

    if local_hash == remote_hash:
        print("    [PASS] SHA-256 matches official GitHub release")
        return True
    else:
        print("    [FAIL] SHA-256 does NOT match official GitHub release")
        return False


# -- wintrust.dll verification -----------------------------------------------


def load_winbindex() -> dict:
    global _winbindex_cache
    if _winbindex_cache is not None:
        return _winbindex_cache

    print("  Fetching winbindex data...")
    raw = fetch_url(WINBINDEX_URL)
    _winbindex_cache = json.loads(gzip.decompress(raw))
    return _winbindex_cache


def verify_wintrust(wintrust_dir: Path) -> bool:
    """Look up the DLL's SHA-256 in winbindex to confirm it's a known
    Microsoft-signed binary."""
    dll_path = wintrust_dir / "wintrust.dll"
    if not dll_path.exists():
        print(f"  [SKIP] wintrust.dll not found in {wintrust_dir}")
        return True

    local_hash = sha256(dll_path)
    print("  wintrust.dll")
    print(f"    Local : {local_hash}")

    try:
        index = load_winbindex()
    except Exception as e:
        print(f"    [FAIL] Failed to fetch winbindex data: {e}")
        return False

    entry = index.get(local_hash)
    if entry is None:
        print(
            "    [FAIL] SHA-256 not found in winbindex — not a known Microsoft binary"
        )
        return False

    file_info = entry.get("fileInfo", {})
    version = file_info.get("version", "unknown")
    description = file_info.get("description", "")
    signing = file_info.get("signingStatus", "unknown")

    # Identify which Windows updates shipped this DLL
    win_versions = entry.get("windowsVersions", {})
    updates = []
    for build, build_data in win_versions.items():
        for update_id, update_info in build_data.items():
            kb = update_info.get("updateKBs", [])
            if kb:
                updates.extend(kb)
            else:
                updates.append(update_id)

    print(f"    Version    : {version}")
    print(f"    Description: {description}")
    print(f"    Signing    : {signing}")
    if updates:
        print(f"    Updates    : {', '.join(updates[:5])}")
    print("    [PASS] SHA-256 matches known Microsoft binary in winbindex")
    return True


# -- Main --------------------------------------------------------------------


def verify_version_dir(version_dir: Path) -> bool:
    print(f"\n{'=' * 60}")
    print(f"Verifying {version_dir.name}")
    print("=" * 60)

    upx_ok = verify_upx(version_dir / "UPX")
    wintrust_ok = verify_wintrust(version_dir / "WinTrust")
    return upx_ok and wintrust_ok


def main():
    repo_root = Path(__file__).resolve().parent

    # Accept specific version dirs as arguments, or scan for all v* dirs
    if len(sys.argv) > 1:
        version_dirs = [repo_root / arg for arg in sys.argv[1:]]
    else:
        version_dirs = sorted(
            p for p in repo_root.iterdir() if p.is_dir() and re.match(r"^v\d+", p.name)
        )

    if not version_dirs:
        print("No version directories found.")
        sys.exit(1)

    all_ok = True
    for vdir in version_dirs:
        if not vdir.is_dir():
            print(f"Warning: {vdir} is not a directory, skipping")
            continue
        if not verify_version_dir(vdir):
            all_ok = False

    print(f"\n{'=' * 60}")
    if all_ok:
        print("All binary verification checks PASSED")
    else:
        print("Some binary verification checks FAILED")
    print("=" * 60)

    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
