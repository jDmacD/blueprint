# Read-only health sweep of the k3s cluster and Gatus. Prints one section per
# check: "ok" when clean, otherwise only the problem rows. Needs no more than
# the `view` ClusterRole plus CRD reads, so it also runs under claude-ops.

gatus_url="${GATUS_URL:?GATUS_URL is not set}"
events_since="${SWEEP_EVENTS_SINCE:-3600}" # seconds of Warning events to show
cert_days="${SWEEP_CERT_DAYS:-14}"
mem_pct="${SWEEP_MEM_PCT:-85}"
now=$(date +%s)

section() { printf '\n## %s\n' "$1"; }
# Prints stdin, or "ok" when it's empty.
report() {
  local out
  out=$(cat)
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo ok; fi
}
# kubectl get -A -o json, or an empty list when the CRD or RBAC is missing.
kget() {
  kubectl get "$1" -A -o json 2>/dev/null || echo '{"items":[]}'
}

echo "# cluster sweep $(date -u +%Y-%m-%dT%H:%MZ) context=$(kubectl config current-context 2>/dev/null || echo '?')"

section "nodes (not Ready, pressure, cordoned)"
kget nodes | jq -r '.items[]
  | .metadata.name as $n
  | ([.status.conditions[] | select((.type == "Ready" and .status != "True") or (.type != "Ready" and .status == "True")) | .type] | join(",")) as $bad
  | select($bad != "" or .spec.unschedulable == true)
  | "\($n) \($bad)\(if .spec.unschedulable then " cordoned" else "" end)"' | report || echo "CHECK FAILED"

section "node usage (memory >= ${mem_pct}%)"
kubectl top nodes --no-headers 2>/dev/null | awk -v t="$mem_pct" '{m=$5; sub("%","",m); if (m+0 >= t) print $1, "cpu", $3, "mem", $5}' | report || echo "CHECK FAILED"

section "argocd applications (not Synced/Healthy)"
kget applications.argoproj.io | jq -r '.items[]
  | select(.status.sync.status != "Synced" or .status.health.status != "Healthy")
  | "\(.metadata.name) sync=\(.status.sync.status) health=\(.status.health.status) op=\(.status.operationState.phase // "-")"' | report || echo "CHECK FAILED"

section "pods (not Running/Succeeded, not ready, or restarted in the last 24h)"
kget pods | jq -r --argjson now "$now" '.items[]
  | (.metadata.namespace + "/" + .metadata.name) as $p
  | .status.phase as $ph
  | [(.status.containerStatuses // [])[]
      | select(
          (.state.waiting.reason // "") != ""
          or ((.lastState.terminated.finishedAt // "") != ""
              and ($now - (.lastState.terminated.finishedAt | fromdateiso8601)) < 86400)
          or (.ready == false and $ph == "Running"))
      | "\(.name):\(.state.waiting.reason // (if .ready then "ready" else "notready" end)) restarts=\(.restartCount) last=\(.lastState.terminated.reason // "-")@\(.lastState.terminated.finishedAt // "-")"] as $bad
  | select(($ph != "Running" and $ph != "Succeeded") or ($bad | length) > 0)
  | "\($p) \($ph) \(.spec.nodeName // "-") \($bad | join(" "))"' | report || echo "CHECK FAILED"

section "workloads (ready < desired)"
{
  kget deployments | jq -r '.items[] | select((.status.readyReplicas // 0) < (.spec.replicas // 0)) | "deploy \(.metadata.namespace)/\(.metadata.name) \(.status.readyReplicas // 0)/\(.spec.replicas)"'
  kget statefulsets | jq -r '.items[] | select((.status.readyReplicas // 0) < (.spec.replicas // 0)) | "sts \(.metadata.namespace)/\(.metadata.name) \(.status.readyReplicas // 0)/\(.spec.replicas)"'
  kget daemonsets | jq -r '.items[] | select(.status.numberReady < .status.desiredNumberScheduled) | "ds \(.metadata.namespace)/\(.metadata.name) \(.status.numberReady)/\(.status.desiredNumberScheduled)"'
} | report || echo "CHECK FAILED"

section "failed jobs (last 24h)"
kget jobs | jq -r --argjson now "$now" '.items[]
  | select((.status.failed // 0) > 0 and ((.status.conditions // []) | any(.type == "Failed" and .status == "True")))
  | select(($now - ((.status.startTime // "1970-01-01T00:00:00Z") | fromdateiso8601)) < 86400)
  | "\(.metadata.namespace)/\(.metadata.name) failed=\(.status.failed)"' | report || echo "CHECK FAILED"

section "warning events (last $((events_since / 60))m, grouped)"
kget events | jq -r --argjson now "$now" --argjson since "$events_since" '[.items[]
  | select(.type == "Warning")
  | select(($now - ((.lastTimestamp // .eventTime // .metadata.creationTimestamp) | sub("\\.[0-9]+"; "") | fromdateiso8601)) < $since)
  | {k: "\(.involvedObject.namespace // "-")/\(.involvedObject.kind)/\(.involvedObject.name) \(.reason)", m: (.message | gsub("\\s+"; " ") | .[0:140]), c: (.count // 1)}]
  | group_by(.k) | map({k: .[0].k, m: .[-1].m, c: (map(.c) | add)})
  | sort_by(-.c) | .[:20][] | "\(.c)x \(.k): \(.m)"' | report || echo "CHECK FAILED"

section "ceph"
kget cephclusters.ceph.rook.io | jq -r '.items[]
  | "\(.metadata.name) \(.status.ceph.health // "unknown")",
    ((.status.ceph.details // {}) | to_entries[] | "  \(.key): \(.value.message)")' || echo "CHECK FAILED"

section "cnpg clusters (not healthy) and backups (latest not completed)"
{
  kget clusters.postgresql.cnpg.io | jq -r '.items[] | select(.status.phase != "Cluster in healthy state") | "cluster \(.metadata.namespace)/\(.metadata.name) \(.status.phase) ready=\(.status.readyInstances // 0)/\(.spec.instances)"'
  kget backups.postgresql.cnpg.io | jq -r 'reduce .items[] as $b ({}; .["\($b.metadata.namespace)/\($b.spec.cluster.name)"] |= (if . == null or .metadata.creationTimestamp < $b.metadata.creationTimestamp then $b else . end))
    | to_entries[] | select(.value.status.phase != "completed") | "backup \(.key) latest=\(.value.metadata.name) \(.value.status.phase // "none") \(.value.status.error // "")"'
} | report || echo "CHECK FAILED"

section "pvcs (not Bound)"
kget persistentvolumeclaims | jq -r '.items[] | select(.status.phase != "Bound") | "\(.metadata.namespace)/\(.metadata.name) \(.status.phase)"' | report || echo "CHECK FAILED"

section "certificates (not Ready or expiring within ${cert_days}d)"
kget certificates.cert-manager.io | jq -r --argjson now "$now" --argjson d "$cert_days" '.items[]
  | ((.status.conditions // []) | map(select(.type == "Ready")) | .[0].status // "Unknown") as $r
  | ((.status.notAfter // null) | if . then ((fromdateiso8601 - $now) / 86400 | floor) else null end) as $left
  | select($r != "True" or ($left != null and $left < $d))
  | "\(.metadata.namespace)/\(.metadata.name) ready=\($r) days_left=\($left // "-")"' | report || echo "CHECK FAILED"

section "externalsecrets (not Ready)"
kget externalsecrets.external-secrets.io | jq -r '.items[]
  | ((.status.conditions // []) | map(select(.type == "Ready")) | .[0]) as $c
  | select(($c.status // "Unknown") != "True")
  | "\(.metadata.namespace)/\(.metadata.name) \($c.reason // "-"): \(($c.message // "") | .[0:120])"' | report || echo "CHECK FAILED"

section "gateways (not Programmed) and LoadBalancers (no IP)"
{
  kget gateways.gateway.networking.k8s.io | jq -r '.items[] | select(((.status.conditions // []) | any(.type == "Programmed" and .status == "True")) | not) | "gateway \(.metadata.namespace)/\(.metadata.name) not programmed"'
  kget services | jq -r '.items[] | select(.spec.type == "LoadBalancer" and ((.status.loadBalancer.ingress // []) | length) == 0) | "svc \(.metadata.namespace)/\(.metadata.name) no LB IP"'
} | report || echo "CHECK FAILED"

section "gatus ($gatus_url): failing now, or failures among recent results"
if ! statuses=$(curl -fsS --max-time 20 "$gatus_url/api/v1/endpoints/statuses?pageSize=20"); then
  echo "UNREACHABLE: could not fetch $gatus_url/api/v1/endpoints/statuses"
else
  printf '%s' "$statuses" | jq -r --argjson now "$now" '
    "endpoints=\(length) failing_now=\(map(select((.results[-1].success // true) | not)) | length)",
    (.[] | (.results // []) as $r
      | select(($r | length) > 0)
      | ($r | map(select(.success | not)) | length) as $fails
      | select($fails > 0)
      | ($r[-1]) as $last
      | (($r | map(.timestamp | sub("\\.[0-9]+"; "") | fromdateiso8601) | max)) as $ts
      | "\(if $last.success then "flapping" else "FAILING" end) \(.key) \($fails)/\($r | length) failed, last \((($now - $ts) / 60) | floor)m ago: \(($last.errors // []) | join("; ") | .[0:100]) \([$last.conditionResults[]? | select(.success | not) | .condition] | join(", "))"),
    (map(select((.results // []) | length > 0))
      | map(select(($now - (.results[-1].timestamp | sub("\\.[0-9]+"; "") | fromdateiso8601)) > 900))
      | .[] | "STALE \(.key): no result for over 15m")'
fi
