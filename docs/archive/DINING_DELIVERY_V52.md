# V52 – Dining & Delivery Discovery

V52 keeps the product boundary explicit: Mahlzeit recommends external options, but does not order, reserve, process payments, or manage deliveries.

## Flow

1. Choose a cuisine / category.
2. Optionally choose search radius and price level.
3. Show external discovery entry points.
4. Open the provider, map, or web search outside the app.

## Boundaries

- No cart.
- No checkout.
- No payment.
- No delivery tracking.
- No in-app reservation.
- Phone actions are supported when a trusted source provides a number.

The current MVP uses stable external search destinations rather than inventing restaurant records or phone numbers. A future provider integration may supply real restaurant cards while preserving this boundary.
