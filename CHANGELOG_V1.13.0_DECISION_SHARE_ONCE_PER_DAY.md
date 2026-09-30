# Schmackofatz v1.13.0 – Decision Share Once Per Day

- Eine persönliche Tagesentscheidung kann pro Tag nur einmal geteilt werden.
- Die Sperre liegt serverseitig im `send_decision_message`-RPC und wird zusätzlich durch einen Unique Index erzwungen.
- Die geteilte Entscheidung speichert die Quell-Tagesplan-ID.
- Nach dem Teilen wird der Teilen-Button deaktiviert.
- Nach Annahme wird weiterhin nur die Löschaktion angeboten. Die übernommene Entscheidung des Empfängers bleibt unabhängig bestehen.
- Ein neuer persönlicher Tagesplan an einem späteren Tag kann wieder einmal geteilt werden.
