from flask import Flask, request, jsonify
from datetime import datetime
import json
import os

app = Flask(__name__)

INCIDENT_FILE = "/data/incidents.json"

@app.route("/alert", methods=["POST"])
def receive_alert():
    payload = request.json

    incident = {
        "timestamp": datetime.utcnow().isoformat(),
        "status": payload.get("status"),
        "alerts": payload.get("alerts", []),
        "source": "alertmanager",
        "tool": "cyna-incident-webhook"
    }

    os.makedirs(os.path.dirname(INCIDENT_FILE), exist_ok=True)

    incidents = []
    if os.path.exists(INCIDENT_FILE):
        with open(INCIDENT_FILE, "r") as f:
            try:
                incidents = json.load(f)
            except json.JSONDecodeError:
                incidents = []

    incidents.append(incident)

    with open(INCIDENT_FILE, "w") as f:
        json.dump(incidents, f, indent=2)

    return jsonify({"message": "Incident received", "incident": incident}), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/incidents", methods=["GET"])
def get_incidents():
    if not os.path.exists(INCIDENT_FILE):
        return jsonify([])

    with open(INCIDENT_FILE, "r") as f:
        return jsonify(json.load(f))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
