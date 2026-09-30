# Anonymous Auth und RLS – V1.4

## Entscheidung

together verwendet weiterhin Supabase Anonymous Auth. Anonyme Benutzer erhalten eine echte Supabase-User-ID und laufen bei PostgREST unter der `authenticated`-Rolle. Deshalb erscheinen die fachlichen RLS-Policies für `authenticated` im Supabase-Linter als für anonyme Zugriffe relevant.

Diese Policies werden **nicht** auf `public` geöffnet. Tabellen mit personenbezogenen oder kollaborativen Daten bleiben ausschließlich über `authenticated` erreichbar und prüfen `auth.uid()` bzw. die Verbindungmitgliedschaft.

## Sicherheitsregeln

- Kein Client erhält `service_role`-Zugriff.
- `SECURITY DEFINER`-Funktionen setzen `search_path = public`.
- Direkter `EXECUTE`-Zugriff durch `anon` und `public` ist für die RPC-Funktionen entzogen.
- `ai_generation_events` ist für Client-Rollen nicht lesbar oder beschreibbar.
- Anonymous Auth darf nur auf fachliche Daten zugreifen, die eine normale App-Sitzung auch verwenden darf.
- Authorization basiert nie auf lokalen Caches.

## Bewusste Restwarnung

Der Supabase Advisor kann weiterhin auf Policies für `authenticated` hinweisen, weil Anonymous Auth diese Rolle verwendet. Das ist kein Grund, die Policies auf `anon` umzustellen oder `authenticated` pauschal zu entfernen, da die App sonst ihren Authentifizierungsmodus verliert.

Eine spätere Migration von Anonymous Auth zu dauerhaft registrierten Konten würde die Policy- und Account-Lebenszyklusregeln erneut prüfen müssen.
