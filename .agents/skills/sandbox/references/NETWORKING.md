# Networking

Summary of https://docs.docker.com/ai/sandboxes/architecture/ (Networking) and
https://docs.docker.com/ai/sandboxes/security/

## How outbound traffic works

- All outbound traffic from the sandbox routes through a proxy on the host:
  - HTTP/HTTPS go through a forward proxy.
  - Other TCP traffic is forwarded transparently.
- The proxy enforces **network policy** — the rules deciding which destinations a sandbox may
  reach.
- ICMP does not cross the boundary. UDP is blocked unless the user enables the experimental
  UDP feature (and allows it through network policy). IPv6 is blocked in this deployment.

## Credential injection

The forward proxy also handles credentials: the agent sees a sentinel value, and the proxy
swaps in the real credential after the request leaves the VM. See ISOLATION.md.

## This deployment's policy

The user's setup script creates an allow-all policy and then denies:

- private networks (RFC 1918, CGNAT, link-local) and the host's loopback ranges — this is why
  host services and LAN devices are unreachable. The sandbox's own `localhost`/`127.0.0.1` is
  unaffected: services running inside the sandbox are reachable normally.
- IPv6 and 6to4 relay;
- multicast/broadcast and reserved/TEST-NET ranges.

The allowed loopback exception exists specifically for **shared host services**, published
under hostnames such as `forge.local` (the Git forge). Use hostnames; hardcoded IPs break and
are bad practice anyway.

## Troubleshooting request failures

If a connection fails (timeout, connection refused/unreachable):

1. It is most likely the network policy, not the destination.
2. Check whether the destination is a host/local service — those are denied by default; only
   explicitly shared services (like the forge hostname) are reachable. Services the agent
   starts inside the sandbox on localhost are unaffected.
3. Retry over HTTPS rather than other protocols; only TCP-based traffic can leave.
4. If the destination is a legitimate external service, ask the user to inspect and adjust
   policy on the host: `sbx policy ls`, then `sbx policy allow network <ip-range|hostname>`.
   The agent cannot run `sbx` itself.
5. Remember DNS: only resolvable, policy-allowed destinations will connect. IPv6-only hosts
   are unreachable.
