# Schmackofatz v1.13.0

## Rezept teilen

- Rezepte können aus „Meine Rezepte“ mit der verbundenen Person geteilt werden.
- Vor dem Teilen wird eine Bestätigung angezeigt.
- Geteilte Rezepte erzeugen eine dauerhafte In-App-Notification.
- Die Notification öffnet direkt eine vollständige Rezept-Vorschau.
- Empfänger können ein Rezept annehmen oder ablehnen.
- Beim Annehmen wird eine unabhängige persönliche Rezeptkopie erzeugt.
- Die Kopie enthält Rezeptdaten, Bild und Zutaten und gehört danach vollständig dem Empfänger.
- Änderungen oder Löschung des Originalrezepts beeinflussen die übernommene Kopie nicht.
- Nur der Eigentümer eines Rezepts kann es teilen.
- Die bestehende Connection- und RPC-Sicherheitsarchitektur wird weiterverwendet.
- „Entscheide Du“ und Personal Today bleiben fachlich unverändert.
## Benachrichtigungen: V85-Schema-Kompatibilität
- Die Benachrichtigungsabfrage fällt bei einer noch nicht angewendeten `decision_share_id`-Migration auf die bisherigen Spalten zurück.
- Dadurch wird ein fehlendes V85-Datenbankfeld nicht mehr als allgemeiner Verbindungsfehler auf der Benachrichtigungsseite angezeigt.
- Alte `decision_message`-Benachrichtigungen ohne Share-ID öffnen ersatzweise die Heute-Seite.


## Rezeptbenachrichtigung nach Ablehnung
- Bereits abgelehnte Rezeptvorschläge können aus der Benachrichtigungszentrale erneut geöffnet werden.
- In diesem Fall wird keine erneute Rezeptfreigabe vorausgesetzt und stattdessen ein eindeutiger Hinweis „Rezept bereits abgelehnt“ angezeigt.
- Das verhindert, dass der erneute Klick auf die alte Benachrichtigung durch die bewusst entfallende Rezeptzugriffsberechtigung in einen allgemeinen Fehlerbildschirm läuft.

- Decision Share: Tagesentscheidung pro Tag nur einmal teilbar; nach Teilen/Annahme bleibt nur die Löschaktion verfügbar.
