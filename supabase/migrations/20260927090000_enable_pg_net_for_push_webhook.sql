-- Push delivery requires pg_net for the database -> Edge Function webhook.
-- Keep this explicit so a fresh database cannot silently create notifications
-- without ever dispatching the asynchronous push request.
create extension if not exists pg_net;
