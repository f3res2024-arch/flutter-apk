# Implementation Backlog — v1

## P0 — Production foundation
- [x] Architecture baseline
- [x] Canonical order state machine
- [x] API domain boundaries
- [ ] Harden role authorization using server-controlled claims/permissions
- [ ] Normalize order statuses to the canonical state machine
- [ ] Add immutable order_events table
- [ ] Add idempotency_keys table and command middleware
- [ ] Add wallet ledger tables
- [ ] Add payment intents/transactions/refunds
- [ ] Add merchant staff and branch permissions
- [ ] Add driver availability/presence model
- [ ] Add tracking event protocol
- [ ] Add production RLS policy matrix

## P1 — Customer experience
- [ ] Real restaurant/branch discovery
- [ ] Catalog search and filtering
- [ ] Real cart and server-side pricing
- [ ] Checkout and payment provider integration
- [ ] Live order tracking
- [ ] Push notifications
- [ ] Favorites and loyalty

## P1 — Merchant
- [ ] Live order board
- [ ] Product/menu management
- [ ] Inventory availability
- [ ] Branch management
- [ ] Merchant analytics

## P1 — Driver
- [ ] Offer feed
- [ ] Atomic order claiming
- [ ] Background location strategy
- [ ] Earnings ledger
- [ ] Delivery verification

## P1 — Admin
- [ ] Operations dashboard
- [ ] Merchant/driver management
- [ ] Payment/refund controls
- [ ] Support/dispute workflow
- [ ] Audit log

## P2 — Intelligence
- [ ] Recommendation engine
- [ ] ETA model
- [ ] Dispatch scoring
- [ ] Demand forecasting
- [ ] Fraud signals
- [ ] AI assistant with confirmation gates

## P2 — Super App
- [ ] Group ordering
- [ ] Scheduled orders
- [ ] Grocery/retail verticals
- [ ] Subscription/membership
- [ ] Advanced promotions
