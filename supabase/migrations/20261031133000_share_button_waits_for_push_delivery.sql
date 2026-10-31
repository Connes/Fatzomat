-- Track when FCM has accepted the push for a shared daily decision.
-- The sender's Share button stays enabled until this timestamp is set.
alter table public.decision_shares
  add column if not exists push_delivered_at timestamptz;

comment on column public.decision_shares.push_delivered_at is
  'Timestamp when FCM accepted at least one push for this decision share.';
