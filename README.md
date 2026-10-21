# GenP

All patches are updated by SpaceDotWho. If you paid for this, you got scammed. This is free.

Please report bugs to [SpaceDotWho/GenP](https://github.com/SpaceDotWho/GenP). Include the GenP version, application version, steps to reproduce, and the relevant log.

The maintained release is in `v4.2.2`. Older version folders are retained for reference.

The Wiki and Guides link provides older, outdated guides. Do not use it as a source for official updates to this fork. Report bugs, popup issues, and problems caused by Adobe updates to [SpaceDotWho/GenP](https://github.com/SpaceDotWho/GenP).

## Run

Download `GenP-v4.2.2.zip` from [Releases](https://github.com/SpaceDotWho/GenP/releases/latest), extract both files into a writable folder, and run `GenP-v4.2.2.exe` with `config.ini` beside it. Keep your local `patch_states.ini` when updating an existing installation. The ZIP contains only the executable and configuration; verification assets are separate downloads.

Right-click a file in the results list to copy its full path or containing folder. Multiple selected files are copied on separate lines, with duplicate folders removed. Right-click the initial information list to copy the current search folder.

Status comes from current file contents and recorded hashes. `Patched` means a recognized patched result; `Unpatched` means a recognized original. `Modified`, `Unknown`, and `Missing` describe files that cannot be confirmed as either. `Not required` identifies support files excluded by the verified rules for the installed application build. A backup file alone does not prove a patch succeeded.

## Build and verify

Run `v4.2.2/run_build.bat` as administrator, or run `v4.2.2/build.ps1` from PowerShell. The build validates configuration counts, compiles the supplied AutoIt source, checks that inputs did not change during compilation, and writes `v4.2.2/Release/build-manifest.json`.

Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_build.ps1` to verify the recorded SHA-256 hashes for the source, build script, configuration, bundled resources, and compiled GenP executable. The verifier also checks the executable's self-hash trailer and rejects changed or missing inputs. Keep the manifest with the exact source tree used for that build.

The manifest records the source/output pair produced by the build. SHA-256 hashes identify those files; they do not independently prove the origin of an arbitrary binary. Bundled third-party tools are recorded as build inputs and are not claimed to have been compiled from the GenP source.

Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\package_release.ps1` after building to verify the build and create the minimal runtime ZIP in `v4.2.2/Release`. Packaging validates both ZIP entries against their SHA-256 hashes and writes `SHA256SUMS.txt`. The release manifest includes the source commit when built from a Git checkout. The GitHub release workflow is manually triggered and builds only the maintained version; historical folders remain available as source.

Originally created by uncia. Third-party license and attribution files remain with their respective components.
