# Decanter Architecture & GPTK Reference Notes

This document captures technical findings, environment variable configurations, registry override patterns, and GPTK version layout specifications preserved from the initial prototype.

---

## 1. Apple Game Porting Toolkit (GPTK) Layout Specifications

### GPTK 1.x / 2.x Layout
- Dylibs located under volume `lib/` or `Wine/lib/`:
  - `d3dmetal.dylib` -> Direct3D to Metal translation layer
  - `libMoltenVK.dylib` -> Vulkan to Metal translation layer
  - `libD3DShared.dylib` -> Shared Direct3D runtime
- Injection Method: Symlink into bottle's `drive_c/windows/system32`.

### GPTK 3.x Layout
- Libraries structured under `external/` and `wine/`:
  - `external/D3DMetal.framework` -> Copied to `~/Library/Frameworks/D3DMetal.framework`
  - `external/libd3dshared.dylib` -> Copied to system32 and `~/Library/Frameworks/`
  - `wine/x86_64-windows/*.dll` -> Copied directly to system32
  - `wine/x86_64-unix/*.so` -> Copied directly to system32

---

## 2. Wine Registry DLL Overrides

To route Direct3D & DXGI rendering pipeline calls to Apple's D3DMetal / Metal shaders, the following registry overrides must be set in `HKCU\Software\Wine\DllOverrides`:

| DLL Name | Value | Description |
| :--- | :--- | :--- |
| `d3d11` | `native,builtin` | Routes D3D11 calls to native D3DMetal dylib |
| `d3d12` | `native,builtin` | Routes D3D12 calls to native D3DMetal dylib |
| `d3d9` | `native,builtin` | Direct3D 9 translation |
| `dxgi` | `native,builtin` | DirectX Graphics Infrastructure |
| `d3dmetal` | `native,builtin` | D3DMetal engine DLL |

Command executed via Wine:
```bash
wine64 reg add "HKCU\Software\Wine\DllOverrides" /v <dll> /d "native,builtin" /f
```

---

## 3. Wine Execution Environment & Dynamic Linker Paths

### Essential Environment Variables
- `WINEPREFIX`: Absolute path to bottle directory (e.g. `~/Library/Application Support/Decanter/Bottles/<Name>`).
- `WINEARCH`: Set to `win64`.
- `WINEESYNC`: `1` (enables EventFD synchronization).
- `WINEMSYNC`: `1` (enables Mach semaphore synchronization).
- `MTL_HUD_ENABLED`: `1` when Metal HUD graph overlay is enabled.

### Linker Search Paths (macOS Hardened Runtime Compliant)
> [!NOTE]
> `DYLD_FALLBACK_LIBRARY_PATH` and `DYLD_FALLBACK_FRAMEWORK_PATH` are used instead of `DYLD_LIBRARY_PATH` so SIP (System Integrity Protection) does not strip them when spawning child processes.

Paths included in `DYLD_FALLBACK_LIBRARY_PATH`:
1. Bottle `drive_c/windows/system32`
2. `~/Library/Frameworks`
3. `~/Library/Frameworks/D3DMetal.framework/Versions/A/Resources`
4. Custom MoltenVK directory (e.g. Android SDK / Homebrew)
5. `/usr/local/lib:/usr/lib`

Paths included in `DYLD_FALLBACK_FRAMEWORK_PATH`:
1. `~/Library/Frameworks`

### MoltenVK / Vulkan Optimization Flags
- `MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE=1`
- `MVK_CONFIG_RESUME_LOST_INSTANCE=1`
- `MVK_ALLOW_METAL_FENCES=1`
