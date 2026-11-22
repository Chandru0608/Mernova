# QuickDeliver feature API foundation

This branch adds authenticated backend foundations for the requested customer and delivery-partner capabilities. Existing customer, delivery and admin routes remain in place.

## Customer
- GET /api/features/orders/:id/reorder — available items from a previous order
- GET /api/features/orders/:id/eta — status/distance-based estimate
- GET /api/features/orders/:id/compensation — checks delay eligibility and issues one code
- GET /api/features/orders/:id/handover-code — retrieves the per-order handover token
- POST /api/features/orders/:id/customer-availability — availability and text instructions
- POST /api/features/orders/:id/voice-instruction — saves an HTTPS audio URL from private media storage
- POST /api/features/groups — create invitation code
- POST /api/features/groups/join — join by invitation code
- GET /api/features/groups/:id — view participant carts
- PUT /api/features/groups/:id/cart — save the caller's cart lines
- POST /api/features/groups/:id/contribution — records a pending contribution

## Delivery partner
- POST /api/features/partner/fuel — record fuel expense
- GET /api/features/partner/earnings — monthly and daily earnings/fuel summaries
- GET /api/features/partner/performance — delivery/cancellation metrics
- POST /api/features/partner/sos — persists emergency event and broadcasts support:sos
- GET /api/features/partner/weather?latitude=...&longitude=... — Open-Meteo current conditions and threshold warning
- PATCH /api/features/partner/availability — online/break state
- POST /api/features/partner/route/optimize — nearest-neighbour stop ordering for assigned jobs

## Important integration and production notes
- Checkout totals now expose product subtotal, delivery fee, platform fee, tax, discount and total. Current default fees are ₹30 delivery and ₹5 platform fee; tax/discount default to zero.
- Handover tokens are random per order and only returned to the authenticated customer through the handover-code endpoint. The assigned delivery partner submits the scanned token to verify-handover.
- Socket.IO user rooms now require a valid JWT at connection time.
- Group contribution is recorded as pending only. A payment provider and verified payment webhook are required before marking a contribution paid or converting a group into a real order.
- Voice instructions accept a private HTTPS media URL. Audio capture, upload, playback and access-controlled object storage still need client-side and storage-provider integration.
- SOS is persisted and emitted to the support event channel; an actual staffed support console, SMS/push delivery and emergency-contact notification configuration are still required.
- Weather thresholds are basic advisories, not official emergency warnings.
- Route ordering is a straight-line nearest-neighbour approximation, not a road-network optimizer.
- Performance acceptance rates and customer ratings remain unavailable until the app records those events.
- This backend foundation has not yet been built or tested against the user's local MongoDB/device. Do not use in production before tests, gateway/storage setup, secret configuration, and security review.
