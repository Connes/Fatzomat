# ADR-001: Release- und Backend-Grenzen

## Status

Accepted for the private two-person product mode.

## Context

Schmackofatz is used by two trusted people and is not distributed through an
app store. The app needs Supabase for authentication, authorization, shared
data and realtime synchronization, but does not need a paid server-side AI
provider for recipe creation.

## Decision

- Flutter contains only the public Supabase client configuration supplied at
  build time through `--dart-define`.
- No OpenAI API key is included in Flutter, Supabase Edge Functions, or the
  current recipe workflow.
- Recipe creation uses the external ChatGPT app. The stable boundary between
  ChatGPT and Schmackofatz is the versioned `together_recipe` JSON format.
- Supabase remains the backend for authenticated personal and shared data.
- RLS and `auth.uid()` remain the authorization boundary.
- Local Android release signing is optional because the app is privately
  installed on trusted devices. A private keystore can still be configured.
- Store-specific infrastructure is not a product requirement.

## Consequences

Positive:

- No OpenAI API cost for recipe creation.
- Fewer backend components and fewer secrets.
- The AI integration is replaceable because the app only consumes the stable
  JSON contract.
- The deployment process is simple enough for two users.

Negative:

- The user must switch to ChatGPT and import the resulting file.
- The external ChatGPT app cannot be controlled by Schmackofatz.
- The `generate-recipes` function and historical AI quota migrations remain in
  the repository history for traceability, but the client no longer calls them.
