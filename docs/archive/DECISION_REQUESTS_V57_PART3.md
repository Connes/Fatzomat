# V57 / Teil 3 – Entscheidung abschließen

## Ziel
Eine abgeschlossene Entscheidung soll auf beiden Geräten sauber sichtbar werden. Eine Kochentscheidung wird dabei atomar zu einem gemeinsamen Heute-Plan inklusive Einkaufsliste. Bestellen und Essen gehen bleiben Discovery-only.

## Verhalten
- Rezeptentscheidung: `resolve_decision_request` erstellt Today + Shopping und schließt die Anfrage in einer kontrollierten Server-Operation ab.
- Bestellen/Essen gehen: Anfrage wird abgeschlossen und der Absender erhält eine In-App-Notification.
- Startseite des Absenders zeigt die heute abgeschlossene Entscheidung.
- Es gibt weiterhin keine Bestellung, Zahlung oder Reservierung in der App.
