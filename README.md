# FortiClient VPN MSI for BreezeRMM

Original, unmodified Fortinet-signed FortiClient VPN 7.4.3.6002 MSI, extracted from the supplied official online installer on 2026-11-18. This repository provides a fixed download URL and deployment validation. It is not the FortiClient source code or an official Fortinet repository.

- Architecture: x64, for Intel/AMD Windows PCs (not ARM64).
- Windows Installer product code: `{15C7B361-A0B2-4E79-93E0-868B5000BA3F}`.
- All cabinet files are embedded. The MSI is standalone.
- Fortinet digital signature is preserved and validated.
- VPN profiles, gateways and user credentials are configured separately.
- Reboots are suppressed during deployment. Code 3010 means a reboot is required afterward.

## BreezeRMM

Use the versioned MSI asset from Releases. If Breeze supplies `msiexec /i` automatically, use these arguments:

```text
/qn /norestart REBOOT=ReallySuppress DONT_PROMPT_REBOOT=1
```

Full installation command:

```text
msiexec.exe /i "FortiClientVPN-7.4.3.6002-x64.msi" /qn /norestart REBOOT=ReallySuppress DONT_PROMPT_REBOOT=1
```

Uninstall:

```text
msiexec.exe /x {15C7B361-A0B2-4E79-93E0-868B5000BA3F} /qn /norestart REBOOT=ReallySuppress DONT_PROMPT_REBOOT=1
```

Accept codes 0 and 3010 as successful deployment. Test on one supported Windows endpoint before rollout, especially if another FortiClient version is installed. A VPN connection, profile migration, actual tunnel traffic, and behavior after reboot require a pilot in the target network.

## Provenance

The supplied online downloader and extracted MSI both carry a valid Fortinet signature. See `package.json` and `SHA256SUMS.txt` for hashes.

Fortinet documents this extraction procedure: https://community.fortinet.com/fortigate-3/technical-tip-extraction-of-msi-file-from-exe-file-forticlient-vpn-only-setup-214366

The workflow tests the exact release candidate as SYSTEM on a disposable Windows runner, verifies installation, product version, service and driver registration, then tests uninstallation. The Actions result is deployment evidence for that environment; it does not establish vendor support for Windows Server or successful VPN connections.
