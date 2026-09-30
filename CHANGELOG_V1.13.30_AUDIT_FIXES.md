# Schmackofatz v1.13.30

## Audit Fixes

- Made Supabase migration timestamps unique while preserving the intended order.
- Enforced verified delivery metadata when the restaurant search is used in delivery mode.
- Included the delivery mode in the Edge Function cache key to prevent cross-mode cache leakage.
- Propagated `image_path` through Today, history and shared-recipe copy paths.
- Added safe fallback from private Storage image resolution to legacy `image_url`.
- Reduced recipe-image signed URL lifetime from roughly 10 years to 7 days and centralized renewal.
- Prevented deletion of a Storage object while another recipe still references its `image_path`.
- Hardened Storage and recipe write policies against arbitrary image-path references.
- Added regression coverage for migration uniqueness, delivery filtering and image-path propagation.
