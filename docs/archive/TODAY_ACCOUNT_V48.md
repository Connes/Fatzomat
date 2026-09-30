# V48 – Heute + Account-Lifecycle

## Umgesetzt

- Heute verwendet jetzt ein typed `TodayPlan` statt roher Maps.
- Einkauf verwendet typed `ShoppingItem` inklusive Lebensmittelkategorie.
- Einkauf wird nach Lebensmittelkategorie gruppiert.
- Optimistisches Abhaken bleibt erhalten und rollt bei Fehlern zurück.
- Heute → Einkauf → Gekocht bleibt ein linearer Ablauf.
- Datenbank schützt zusätzlich gegen zwei aktive Heute-Pläne derselben Verbindung am selben Tag.
- Profil enthält „Konto sichern“.
- Anonyme Konten können mit E-Mail + Passwort in ein wiederherstellbares Konto umgewandelt werden.
- Gesicherte Konten können sich auf einem anderen Gerät mit E-Mail + Passwort anmelden.
- Die Sicherung ist bewusst optional und wird nicht beim ersten Start erzwungen.

## Release-Gate

Nach dem Auspacken mit Flutter prüfen:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk
```

Zusätzlich gegen Supabase testen:

1. User A wählt ein Rezept für Heute.
2. User B sieht denselben Plan.
3. Beide sehen dieselbe Einkaufsliste.
4. User A hakt einen Artikel ab, User B erhält die Änderung per Realtime.
5. User A setzt „Gekocht“.
6. Ein zweiter aktiver Heute-Plan für dieselbe Verbindung und dasselbe Datum wird von der Datenbank verhindert.
7. Anonymer User sichert sein Konto.
8. Auf einem zweiten Gerät Anmeldung mit denselben Zugangsdaten.
9. Sammlung und Präferenzen sind wieder vorhanden.
