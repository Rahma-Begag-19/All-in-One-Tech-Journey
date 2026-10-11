# 🚨 Alertmanager — From Firing Rules to Your Inbox

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd) (`monitoring/alertmanager/`)

---

## 1. The alerting chain

```
Prometheus (alert rules fire)
        │  "MonitoringTargetDown is firing on instance X"
        ▼
Alertmanager (deduplicate, group, route)
        │
        ▼
Receiver: email via Gmail SMTP → 📧 rahmabegag19@gmail.com
```

Prometheus decides **when** something is wrong; Alertmanager decides **who gets told and how**. Splitting these jobs is what lets one alert storm become a single grouped email instead of 50.

---

## 2. The configuration (`monitoring/alertmanager/alertmanager.yml`)

```yaml
global:
  smtp_smarthost: "smtp.gmail.com:587"
  smtp_from: "cyberguru1903@gmail.com"
  smtp_auth_username: "cyberguru1903@gmail.com"
  smtp_auth_password_file: "/etc/alertmanager/secrets/smtp_password"   # not inline!
  smtp_require_tls: true

route:
  receiver: "email-alerts"
  group_by: ["alertname"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
  - name: "email-alerts"
    email_configs:
      - to: "rahmabegag19@gmail.com"
        send_resolved: true
        headers:
          Subject: '[DevOps Monitoring] {{ .Status | toUpper }}: {{ .CommonLabels.alertname }}'
```

### Line by line

**`global` — SMTP settings**
- Uses Gmail's SMTP on port 587 with TLS.
- ⚠️ **Never put the password in this file.** It's read from a mounted secret file: `monitoring/alertmanager/secrets/smtp_password` (mounted read-only in compose). The file just contains the password as plain text — protect the directory, gitignore it.

**`route` — how alerts flow**

| Setting | Effect |
|---|---|
| `receiver: "email-alerts"` | Default destination for all alerts |
| `group_by: ["alertname"]` | One email per alert *name*, not one per instance — an outage on 3 targets = 1 email |
| `group_wait: 30s` | Wait 30s to batch related alerts before sending |
| `group_interval: 5m` | While an alert keeps firing, re-notify at most every 5 min |
| `repeat_interval: 4h` | For still-firing alerts, repeat the notification every 4h (reminder, not spam) |

**`receivers` — where alerts go**
- One email receiver with `send_resolved: true`, so you also get an "**RESOLVED**" email when things recover — knowing a problem ended is as valuable as knowing it started.
- Subject line is templated: `{{ .Status | toUpper }}` → FIRING / RESOLVED, `{{ .CommonLabels.alertname }}` → the alert name.

---

## 3. The Gmail app password step (the part everyone gets stuck on)

Gmail rejects normal account passwords from scripts. You need an **App Password**:

1. Google Account → **Security → 2-Step Verification** (must be on).
2. Search "App passwords" → create one for "Mail".
3. Copy the 16-character password into `monitoring/alertmanager/secrets/smtp_password` on the server.
4. Ensure the file exists *before* starting the stack — Alertmanager fails to start otherwise.

---

## 4. The compose service

```yaml
  alertmanager:
    image: prom/alertmanager:latest
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"
      - "--storage.path=/alertmanager"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-data:/alertmanager
      - ./alertmanager/secrets/smtp_password:/etc/alertmanager/secrets/smtp_password:ro
    ports:
      - "127.0.0.1:9093:9093"
```

UI at http://localhost:9093 — see active alerts, silences, and the routing tree.

---

## 5. End-to-end test

The rules live in Prometheus (`monitoring/prometheus/alerts/monitoring-alerts.yml` — see the Prometheus tutorial). Test the whole chain:

```bash
# 1. Make a monitored target go down
docker stop monitoring-node-exporter

# 2. Wait ~1 minute (the rule has `for: 1m`) + 30s group_wait

# 3. Check Prometheus: http://localhost:9090/alerts  → MonitoringTargetDown FIRING

# 4. Check Alertmanager: http://localhost:9093  → alert visible

# 5. 📧 Email arrives: "[DevOps Monitoring] FIRING: MonitoringTargetDown"

# 6. Restore and get the RESOLVED email
docker start monitoring-node-exporter
```

---

## 6. Extending: routes by severity

Current setup: everything → one email. The natural next step is routing by the `severity` label our rules already set:

```yaml
route:
  receiver: "email-alerts"
  routes:
    - match:
        severity: critical
      receiver: "email-alerts"          # later: add pagerduty/slack/webhook here
    - match:
        severity: warning
      receiver: "email-alerts"
```

The structure is ready — swap receivers as you grow (Slack webhooks, Discord, PagerDuty...).

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| Alert FIRING in Prometheus, nothing in Alertmanager | Check the `alerting` block in `prometheus.yml` targets `alertmanager:9093` |
| Alert in Alertmanager, no email | Wrong app password / 2FA off; test SMTP manually. Also check `docker logs monitoring-alertmanager` |
| Works locally, fails on server | `secrets/smtp_password` file missing on the deployment machine |
| One email per target (spam) | Add/verify `group_by: ["alertname"]` |
| No "RESOLVED" email | Set `send_resolved: true` in the receiver |
| Config change ignored | Alertmanager doesn't hot-reload this mount automatically — restart: `docker compose restart alertmanager` |

---

## 8. What I learned

- **Prometheus evaluates; Alertmanager notifies.** Keeping them separate keeps rules simple and notification logic in one place.
- Grouping settings are the difference between useful alerts and alert fatigue.
- Secrets belong in mounted files, never in YAML — even private YAML.
- Always test the full chain by breaking something on purpose (I stop `node-exporter`).
