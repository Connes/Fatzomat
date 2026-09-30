# V45 · Visual Redesign

The app now uses the visual language from the `together` design kit while keeping the product name `Mahlzeit` and the existing Supabase workflows.

## Visual system
- Inter Regular / Medium / SemiBold / Bold bundled locally.
- Warm cream app background: `#FFF8F2`.
- Sage green primary: `#4CAF7F` / dark `#2E8B63`.
- Peach accent: `#FF8A65`.
- Lilac surprise accent: `#D9B4E8`.
- Soft surfaces, subtle dividers, no default Material elevation.
- Rounded cards around 22–26 px and rounded primary actions around 24 px.

## Navigation
The bottom navigation now follows the redesigned information architecture:
1. Start
2. Sammlung
3. Heute
4. Einkauf
5. Profil

Lebensmittel, Verbindung and Benachrichtigungen are grouped under Profil. Existing workflows remain available.

## Screens refreshed
- Start page with branded header, large cooking hero card, two secondary choices and surprise card.
- Sammlung with cleaner search, shared-today banner and compact recipe cards.
- Profil with connection/notification status and settings tiles.
- Einkauf as a dedicated top-level destination.
- Global Material 3 theme, typography, buttons, cards, inputs, chips, navigation and snackbars.

## Intentionally unchanged
- Anonymous Supabase authentication.
- Supabase RLS / collaboration model.
- Realtime collaboration and in-app notifications.
- Recipe generation and validation behavior.
- No OS push notifications.
- No pantry feature.
- No additional AI context optimization.
- Account hardening remains deferred.
