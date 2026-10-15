# HiFi 2.3.1

HiFi v2.3.1 focuses on memory optimization, clean application lifecycle termination, storage footprint controls, and streamlined update distribution.

### 🚀 Highlights:
- **Clean Windows Exit:** Closing the window immediately stops audio playback and terminates background libmpv/JVM threads, eliminating lingering processes in Windows Task Manager.
- **Desktop Memory Footprint Reduction:** JVM memory heap tuning (`-Xms48m -Xmx128m`) combined with Skiko graphic cache limits and Coil image disk cache reduction (from 512 MB to 32 MB) reduces RAM consumption from ~600 MB down to ~120–150 MB.
- **Storage & Cache Controls:** Default song cache size is now constrained to 100 MB (previously unlimited) to prevent storage bloat on Android devices over time. Canvas video caching is capped at 25 MB.
- **GitHub Release Channel Lock:** Removed deprecated F-Droid selection from Settings; update checks now strictly and reliably connect to official HiFi GitHub Releases.
- **Refined Documentation:** Added project structure diagram and troubleshooting FAQ to README.md.
