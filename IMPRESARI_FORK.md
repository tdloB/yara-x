# Impresari Security Fork

This public fork is maintained as a narrowly scoped candidate engine for
[Impresari Scan](https://github.com/tdloB/impresari-scan). It is not an
official VirusTotal project and no commit in this fork is production-admitted
merely because it exists or passes upstream tests.

The fork tracks `VirusTotal/yara-x` through a weekly pull-request workflow.
Upstream commits are never promoted directly into an Impresari production pin.
Every candidate must pass locked dependency, warning, formatting, compilation,
test, compatibility, confinement, reproducibility, provenance, and release
evidence gates defined by Impresari Scan. Exact founder approval remains
required for a production release.

Fork-only changes are limited to dependency remediation, build hardening,
reproducibility, and admission controls. Patches are removed when upstream
provides an equivalent fix. The intended end state is to return to an
unmodified upstream release that satisfies all admission gates.
