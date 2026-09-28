# Zappو / Nova Delivery — Architecture

This directory is the implementation baseline for the production delivery platform.

## Principles
- Modular architecture first; extract high-load services only when justified.
- PostgreSQL is the transactional source of truth.
- Redis is for ephemeral state, cache, rate limits, locks and geospatial presence.
- Every order transition is validated and audited.
- Payment operations are idempotent.
- AI recommends and predicts; backend authorization and business rules decide.
- Customer, merchant, driver and admin surfaces share contracts and design tokens.

## Implementation sequence
1. Domain model and order state machine
2. API contracts and authorization matrix
3. Realtime tracking protocol
4. Wallet ledger and payment boundaries
5. Mobile feature modules
6. Merchant and admin surfaces
7. Observability, security and load testing
