# V57 / Teil 4 – Benachrichtigungen

## Ziel
Der Übergang bei „Entscheide du heute“ wird auf beiden Geräten sichtbar, ohne externe Push-Infrastruktur vorauszusetzen.

## Neu
- Realtime-Inbox für `app_notifications`.
- Benachrichtigungsseite unter Profil.
- Ungelesen-Badge und „Alle gelesen“.
- Neue Entscheidungsanfrage erzeugt eine Benachrichtigung beim Empfänger.
- Annahme der Anfrage erzeugt eine Benachrichtigung beim Absender.
- Benachrichtigungen mit offener Entscheidungsanfrage öffnen direkt „Du bist dran“.
- Bestehende Rezept-/Nicht-Rezept-Auflösung aus Teil 3 bleibt erhalten.

## Release-Grenze
Echte OS-Push-Benachrichtigungen (FCM/APNs) sind noch nicht aktiviert. Dafür werden Android/iOS-Push-Konfiguration und ein sicherer Versandweg benötigt. Die Realtime-Inbox funktioniert bereits ohne diese Provider.
