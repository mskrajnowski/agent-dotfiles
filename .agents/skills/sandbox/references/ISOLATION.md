# Isolation model

Summary of https://docs.docker.com/ai/sandboxes/security/ and
https://docs.docker.com/ai/sandboxes/architecture/

## Five isolation layers

1. **Hypervisor isolation** — each sandbox is a microVM with its own kernel. No shared memory
   or processes with the host.
2. **Network isolation** — all outbound TCP is proxied through the host and governed by a
   deny-by-default network policy. UDP and ICMP are blocked.
3. **Docker Engine isolation** — the sandbox has its own Docker Engine with no path to the
   host daemon. Containers built inside never touch the host.
4. **Workspace isolation** — only the declared workspace is shared with the host (and only in
   direct mode; see SETUP.md for this deployment). The rest of the host filesystem is invisible.
5. **Credential isolation** — API keys are injected into outbound HTTP headers by the host-side
   proxy. Raw credential values never enter the VM.

## What the agent can do inside

Everything: sudo, install packages, run its own Docker Engine, read/write the sandbox
filesystem and the shared workspace. Installed state persists across sandbox restarts.

## What the agent cannot do

- Read the host filesystem outside the shared workspace.
- Reach the host Docker daemon.
- Connect to the host network directly, other sandboxes, or any destination not allowed by
  network policy.
- Use UDP (unless the user explicitly enables the experimental UDP feature) or ICMP.
- Use IPv6.
- See real credential values.
