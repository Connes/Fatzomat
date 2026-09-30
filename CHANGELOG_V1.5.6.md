# Schmackofatz V1.5.6

## Stabilität, Security und Import-Härtung

- `file_picker` auf die aktuelle 13.x-API migriert; Einzeldateien werden mit `pickFile()` und `readAsByteStream()` gelesen.
- JSON-Import auf 1 MB, 50 Zutaten und 50 Schritte begrenzt.
- Qualitative Mengen mit `amount: null` werden beim Import sicher auf die interne Menge `1` normalisiert.
- Ungültige/zu große Rezeptdateien liefern eine verständliche Fehlermeldung statt unkontrolliertem Verhalten.
- Startup unterscheidet jetzt zwischen „Onboarding nicht abgeschlossen“ und einem Lade-/Netzwerkfehler.
- Technische Backend-/OpenAI-Fehler werden nicht mehr als rohe Providerdetails in der Nutzeroberfläche angezeigt.
- KI-Quota-Reservierungen werden nach nachgelagerten Fehlern wieder freigegeben.
- Sichtbare Restverweise auf den alten Produktnamen wurden auf Schmackofatz aktualisiert.
- Release-Signing wird für einen echten Produktionsbuild vorbereitet, statt den Debug-Key als Release-Signatur zu verwenden.
