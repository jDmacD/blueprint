---
name: cluster-sweep
description: Read-only health sweep of the k3s cluster "turing" and its Gatus endpoints. Use when asked to sweep, health-check or "look over" the cluster, check Gatus, or find what's broken or degraded right now. Runs one script, then investigates and reports only what's abnormal.
---

# Cluster sweep

A broad, read-only pass over the cluster and Gatus. It finds problems; it
doesn't fix them. Propose fixes and wait for the user to choose.

## 1. Run the sweep

```bash
@sweep@
```

It prints one section per check, each `ok` or only its problem rows:
nodes, node memory, ArgoCD apps, pods, workloads, failed jobs, Warning
events (last hour, grouped), Ceph, CNPG clusters and backups, PVCs,
certificates, ExternalSecrets, gateways and LoadBalancers, and Gatus
(failing, flapping or stale endpoints from `@gatusUrl@`).

Tunables (env vars): `SWEEP_EVENTS_SINCE` (seconds, default 3600),
`SWEEP_CERT_DAYS` (14), `SWEEP_MEM_PCT` (85).

## 2. Separate known issues from new ones

Before calling anything new, check whether it's already known:

- Read the vault's `wiki/hot.md` (the claude-obsidian vault, read-only via
  `claude-obsidian:wiki-query`). Its "Active Threads" list accepted and
  in-progress issues, e.g. Ceph `AUTH_INSECURE_*` warnings from the `aes`
  CSI keys, and tpi04's USB-attached OSD.
- The catalogue repo's `CLAUDE.md` troubleshooting section covers Ceph
  spurious reads, MDS damage, Cilium/L2 and GPU issues.

A known issue is still worth one line if it changed (new count, new OSD,
new node).

## 3. Investigate what's new

For each new finding, take it one step further with read-only commands,
then stop once the cause is clear:

- Pod restarts: `kubectl logs <pod> -c <container> --previous --tail=50`,
  `kubectl describe pod`. Restarts on several pods at the same minute
  usually point at a node or the API server; compare timestamps.
- ArgoCD Degraded/OutOfSync: `kubectl get application <app> -n argocd -o
  jsonpath='{.status.resources}'` and filter for non-Healthy resources.
- Repeating Warning events: the message usually names the cause; check the
  object it points at.
- Ceph detail beyond the CephCluster status needs the toolbox
  (`kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health
  detail`). Skip it if exec isn't allowed.
- Gatus: `curl -s @gatusUrl@/api/v1/endpoints/<key>/statuses` for one
  endpoint's history. A failing endpoint's backing app is usually in
  `~/Code/catalogue/<app>/`.

Never run a command that changes state (`delete`, `rollout restart`,
`apply`, `annotate`, Ceph repair commands, syncs) during a sweep.

## 4. Report

Lead with a one-line verdict, then findings ranked by severity:

```
<healthy | N issues (X new)>

🔴 <object> — <what's wrong> · cause: <cause or "unknown"> · next: <proposed action>
🟡 ...
Known, unchanged: <comma-separated one-liners>
```

- 🔴: user-facing breakage, data at risk, or something that will get worse
  (a crash loop, a failing backup, a filling disk, an expiring cert).
- 🟡: degraded but serving, or noise worth fixing (a repeating event).
- Don't list sections that came back `ok`.
- If the sweep itself failed (no kubeconfig, Gatus unreachable), say so
  first; a skipped check is not a clean one.
