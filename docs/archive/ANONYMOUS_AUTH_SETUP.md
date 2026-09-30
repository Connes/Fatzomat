# Anmeldung ohne sichtbaren Login

Die Food-App verwendet für die private Nutzung von zwei Geräten keine E-Mail-/Passwort-Anmeldung. Stattdessen erzeugt Supabase beim ersten Start eine anonyme Auth-Identität. Dadurch bleiben die bestehenden RLS- und persönliche Appsregeln erhalten, ohne dass Nutzer ein Konto anlegen müssen.

## Einmalig im Supabase-Dashboard

1. Öffne dein Supabase-Projekt.
2. Gehe zu **Authentication → Configuration**.
3. Aktiviere **Anonymous Sign-Ins**.
4. Speichern.

## Verhalten

- Gerät 1 startet die App und bekommt automatisch eine anonyme Identität.
- Gerät 1 erstellt den persönliche App und erhält einen Einladungscode.
- Gerät 2 startet die App und bekommt eine eigene anonyme Identität.
- Gerät 2 tritt mit dem Einladungscode dem gleichen persönliche App bei.
- Es gibt keinen Login-Bildschirm.
- Es gibt keinen Logout-Button.

## Wichtig

Die anonyme Identität ist gerätegebunden. Wenn die App gelöscht und neu installiert wird, entsteht eine neue Identität. Das Gerät muss dann dem persönliche App erneut beitreten.

Für diese private Zwei-Personen-App ist das zunächst die einfachste Lösung. Eine spätere optionale Kontoverknüpfung kann ergänzt werden, falls eine Wiederherstellung über mehrere Geräte benötigt wird.
