-- The shopping-list page subscribes to decision_shares alongside the other collaboration tables.
-- Every table in a Postgres Changes channel must be part of the Realtime publication.
ALTER PUBLICATION supabase_realtime ADD TABLE public.decision_shares;
