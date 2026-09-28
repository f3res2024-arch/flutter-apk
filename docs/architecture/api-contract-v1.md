# API Contract v1 — Domain Boundaries

Base path: `/v1`

## Auth
- POST `/auth/signup`
- POST `/auth/login`
- POST `/auth/refresh`
- POST `/auth/logout`

## Customer
- GET `/me`
- GET `/restaurants`
- GET `/restaurants/:id`
- GET `/restaurants/:id/menu`
- POST `/orders`
- GET `/orders/:id`
- POST `/orders/:id/cancel`
- GET `/orders/:id/tracking`

## Merchant
- GET `/merchant/orders`
- POST `/merchant/orders/:id/accept`
- POST `/merchant/orders/:id/reject`
- POST `/merchant/orders/:id/ready`
- CRUD `/merchant/products`
- GET `/merchant/analytics`

## Driver
- GET `/driver/offers`
- POST `/driver/offers/:id/accept`
- POST `/driver/offers/:id/reject`
- POST `/driver/orders/:id/picked-up`
- POST `/driver/orders/:id/delivered`
- POST `/driver/location`
- GET `/driver/earnings`

## Admin
- GET `/admin/orders`
- GET `/admin/drivers`
- GET `/admin/merchants`
- GET `/admin/payments`
- GET `/admin/support/tickets`
- POST `/admin/orders/:id/refund`

## API rules
1. All protected endpoints require authentication.
2. Authorization is checked against the target resource and tenant/branch, not only the user role.
3. Mutating commands return a request/correlation id.
4. Financial and fulfillment commands require idempotency keys.
5. Pagination uses cursor-based pagination for high-volume collections.
6. Errors use a stable machine-readable code plus Arabic/English display messages.
7. Server timestamps are authoritative.
