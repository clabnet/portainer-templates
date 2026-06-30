# Troubleshooting: .home domains not resolving (NXDOMAIN)

Symptom: browsing to a `*.home` host configured in Nginx Proxy Manager (e.g. `proxy.home`,
`nas.home`) fails in the browser with `DNS_PROBE_FINISHED_NXDOMAIN`, even though AdGuard Home
is running and healthy.

## Cause

`.home` hostnames only resolve through AdGuard Home's DNS rewrite rules (port 53 on
`192.168.1.2`). If the client falls back to a public resolver (ISP DNS, `8.8.8.8`, Cloudflare,
etc.) for any reason, the lookup returns NXDOMAIN since public resolvers have no record of
`.home`.

Two independent causes have been observed together:

1. **Multiple active network interfaces with different DNS servers.** On Windows, if more than
   one adapter is up (e.g. a secondary Ethernet adapter alongside Wi-Fi/the primary Ethernet),
   each adapter can have its own configured DNS server. Windows may pick the adapter that
   doesn't point at AdGuard, depending on interface metric/priority.
2. **Browser "Secure DNS" / DNS-over-HTTPS (DoH).** Chrome, Edge, and Firefox can ship their own
   DoH resolver and bypass the OS DNS configuration entirely, even after the OS-level DNS is
   fixed.

## Diagnosis

Check DNS servers configured per network adapter (PowerShell):

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses.Count -gt 0} | Format-Table InterfaceAlias, ServerAddresses -AutoSize
```

Confirm AdGuard itself resolves the name when queried directly:

```bash
nslookup proxy.home 192.168.1.2
```

If that works but a plain `nslookup proxy.home` (using the OS default resolver) fails, the
OS-level DNS configuration is the problem. If both work but the browser still fails, it's DoH.

## Fix

1. **Set every active network adapter's DNS server to `192.168.1.2` (AdGuard).**

   ```powershell
   Set-DnsClientServerAddress -InterfaceAlias "Ethernet 3" -ServerAddresses 192.168.1.2
   ```

   Then flush the resolver cache: `ipconfig /flushdns`.

2. **Disable the browser's Secure DNS / DoH**, since it ignores OS DNS settings:
   - Chrome / Edge: `chrome://settings/security` (or `edge://settings/privacy`) → turn off
     "Use secure DNS".
   - Firefox: `about:preferences` → search "DNS over HTTPS" → set to Off.

   After disabling, hard-refresh the page (Ctrl+Shift+R) to bypass the browser's own DNS cache
   (Chrome: `chrome://net-internals/#dns` to clear it manually if needed).
