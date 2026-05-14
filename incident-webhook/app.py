from flask import Flask, request, jsonify
from datetime import datetime, timezone
import json
import os
import uuid

app = Flask(__name__)

DATA_DIR = "/data"
INCIDENTS_FILE = os.path.join(DATA_DIR, "incidents.json")


def ensure_storage():
    os.makedirs(DATA_DIR, exist_ok=True)
    if not os.path.exists(INCIDENTS_FILE):
        with open(INCIDENTS_FILE, "w", encoding="utf-8") as file:
            json.dump([], file)


def load_incidents():
    ensure_storage()
    with open(INCIDENTS_FILE, "r", encoding="utf-8") as file:
        return json.load(file)


def save_incidents(incidents):
    ensure_storage()
    with open(INCIDENTS_FILE, "w", encoding="utf-8") as file:
        json.dump(incidents, file, indent=2, ensure_ascii=False)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/incidents", methods=["GET"])
def list_incidents():
    incidents = load_incidents()
    return jsonify(incidents), 200


@app.route("/incidents/<incident_id>", methods=["GET"])
def get_incident(incident_id):
    incidents = load_incidents()

    for incident in incidents:
        if incident.get("id") == incident_id:
            return jsonify(incident), 200

    return jsonify({"error": "incident not found"}), 404


@app.route("/incidents/<incident_id>/resolve", methods=["POST"])
def resolve_incident(incident_id):
    incidents = load_incidents()

    for incident in incidents:
        if incident.get("id") == incident_id:
            incident["status"] = "resolved"
            incident["resolved_at"] = datetime.now(timezone.utc).isoformat()
            save_incidents(incidents)
            return jsonify(incident), 200

    return jsonify({"error": "incident not found"}), 404




@app.route("/alert", methods=["POST"])
@app.route("/webhook", methods=["POST"])
def receive_alert():
    payload = request.get_json(silent=True) or {}
    alerts = payload.get("alerts", [])

    incidents = load_incidents()
    processed_incidents = []

    if not alerts:
        incident = {
            "id": str(uuid.uuid4()),
            "status": "open",
            "severity": "unknown",
            "alertname": "manual_alert",
            "summary": "Alerte reçue sans format Alertmanager",
            "description": payload,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        incidents.append(incident)
        processed_incidents.append(incident)
        save_incidents(incidents)

        return jsonify({
            "status": "received",
            "processed": len(processed_incidents),
            "incidents": processed_incidents
        }), 201

    for alert in alerts:
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})

        alert_status = alert.get("status", payload.get("status", "firing"))
        alertname = labels.get("alertname", "unknown")
        instance = labels.get("instance", "unknown")
        job = labels.get("job", "unknown")
        fingerprint = alert.get("fingerprint", f"{alertname}:{instance}:{job}")

        if alert_status == "resolved":
            for incident in incidents:
                same_incident = (
                    incident.get("fingerprint") == fingerprint
                    or (
                        incident.get("alertname") == alertname
                        and incident.get("instance") == instance
                        and incident.get("job") == job
                    )
                )

                if same_incident and incident.get("status") == "open":
                    incident["status"] = "resolved"
                    incident["resolved_at"] = datetime.now(timezone.utc).isoformat()
                    processed_incidents.append(incident)
                    break

            save_incidents(incidents)

            return jsonify({
                "status": "resolved",
                "processed": len(processed_incidents),
                "incidents": processed_incidents
            }), 200

        existing_incident = None

        for incident in incidents:
            same_incident = (
                incident.get("fingerprint") == fingerprint
                or (
                    incident.get("alertname") == alertname
                    and incident.get("instance") == instance
                    and incident.get("job") == job
                )
            )

            if same_incident and incident.get("status") == "open":
                existing_incident = incident
                break

        if existing_incident:
            existing_incident["last_seen_at"] = datetime.now(timezone.utc).isoformat()
            processed_incidents.append(existing_incident)
            continue

        incident = {
            "id": str(uuid.uuid4()),
            "fingerprint": fingerprint,
            "status": "open",
            "severity": labels.get("severity", "unknown"),
            "alertname": alertname,
            "instance": instance,
            "job": job,
            "summary": annotations.get("summary", "Aucune description courte"),
            "description": annotations.get("description", "Aucune description détaillée"),
            "starts_at": alert.get("startsAt"),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        incidents.append(incident)
        processed_incidents.append(incident)

    save_incidents(incidents)

    return jsonify({
        "status": "received",
        "processed": len(processed_incidents),
        "incidents": processed_incidents
    }), 200


if __name__ == "__main__":
    ensure_storage()
    app.run(host="0.0.0.0", port=5000)
