# Schmackofatz v1.13.0 – Restaurant Discovery Session Fix 23

## Ursache

Die produktive Edge Function `restaurant-discovery` lief mit `verify_jwt=false`, während die Funktion selbst die neue `withSupabase({ auth: 'user' })`-Abstraktion verwendete. In der betroffenen Laufzeit kam `ctx.userClaims` trotz eines vom Flutter-Client explizit gesetzten Bearer-Tokens leer an. Dadurch wurde die Restaurantsuche mit HTTP 401 und „Die persönliche Sitzung ist nicht gültig“ abgewiesen.

## Fix

Die Funktion authentifiziert den Bearer-Token jetzt explizit über Supabase Auth (`auth.getUser(token)`) und akzeptiert dafür den serverseitig vorhandenen Supabase-Key. Der Client-JWT bleibt der tatsächliche Benutzerkontext. Die Funktion bleibt ohne Gateway-JWT-Prüfung, weil die Benutzerprüfung innerhalb der Funktion erfolgt.

Die Flutter-Seite übergibt weiterhin den frisch erneuerten Access-Token explizit als `Authorization: Bearer ...`.
