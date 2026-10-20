# Creative Cloud signature review

Validated against the locally installed CC 6.11 x86 components. Changes apply
only to `GenP/config.ini` in this hotfix directory.

## Findings and changes

- `AccAds` and `Acc1` already match once each; retained.
- The old `Acc2` matches ten separate functions in AppsPanelBL.dll. IDA
  decompilation identifies policy, auto-update, visibility and first-launch
  checks among those matches. Replaced it with two longer patterns covering
  the three observed `ccd.fw.userEntitlement` checks. The replacement operation
  at those three sites is unchanged. This intentionally reduces coverage;
  end-to-end behavior still needs runtime validation.
- The old `Acc3` has only five literal bytes and starts inside an instruction
  in both intended matches. Its replacement form also matches an unrelated
  existing jump in ContainerBL.dll. Replaced it with separate contextual
  ContainerBL and HDPIM patterns. Both cover complete instructions and replace
  the full six-byte conditional jump with a five-byte jump plus NOP, preserving
  its original destination.

## Static validation

| Component | File version | Pattern | Match count | File offset |
| --- | --- | --- | ---: | --- |
| Adobe Desktop Service.exe | 6.11.0.483 | AccAds | 1 | 0xb1aa |
| AppsPanelBL.dll | 6.11.0.479 | Acc1 | 1 | 0x2427a9 |
| AppsPanelBL.dll | 6.11.0.479 | Acc2Entitlement | 2 | 0x12e418, 0x220d69 |
| AppsPanelBL.dll | 6.11.0.479 | Acc2EntitlementWide | 1 | 0x2208a8 |
| ContainerBL.dll | 6.11.0.483 | Acc3Container | 1 | 0x219c70 |
| HDPIM.dll | 6.11.0.478 | Acc3HDPIM | 1 | 0x1d39f1 |

Checked equal search/replacement lengths, byte-aligned matches, replacements
on in-memory copies, disappearance of original matches, and recognition of
replacement matches on a second scan. No application binaries were patched.
Other supported builds and runtime functionality remain unverified.

## Evidence

REA opened AppsPanelBL.dll as an x86 PE. Resource identity evidence:
`ev_3a97331af2ec1537253502369f53f6b635300fa84809ca97402923bb71490c41`.
REA native deep analysis was unavailable because its Ghidra provider is not
configured. Code analysis used IDA instead.

IDA AppsPanel session `b26e7b9d`: all ten old Acc2 matches were mapped to
functions and decompiled. The retained sites are at virtual addresses
`0x1012f018`, `0x102214a8`, and `0x10221969`. IDA byte searches and byte reads
also corroborated the ContainerBL and HDPIM match locations; those two databases
were opened without automatic analysis and were not decompiled.

SHA-256 identities:

```text
Adobe Desktop Service.exe 0317a31831ffaf711ce1e8fa732637c9a917cd7d31f414ae82abb10a84ef2ae6
AppsPanelBL.dll 4c1158f488ef264d37311c18c1a99ab3c006507a58e42aa616b8eec59af23178
ContainerBL.dll b37e168453386f28b144e0c5984a52f75a699f2d3d1fd8869bbfef001c0486ab
HDPIM.dll f522b6a6f43feda19351269e82c50b9ee5068198275dec663260eaaed1cc4aa8
```
