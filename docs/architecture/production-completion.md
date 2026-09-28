# Production Completion Plan

This project is being implemented incrementally. A production release is not considered complete until the following are implemented and verified end-to-end:

- Authentication and session lifecycle
- Server-authoritative roles and permissions
- RLS for every exposed table
- Real restaurant/branch/menu catalog
- Server-side order pricing and validation
- Canonical order state transitions and immutable event history
- Atomic driver dispatch and presence
- Realtime order updates
- Push notifications
- Payment provider integration with webhook verification
- Double-entry wallet ledger and payout reconciliation
- Idempotency for all financial/fulfillment commands
- Customer, merchant, driver and admin workflows
- Audit logging and support tooling
- Rate limiting, abuse/fraud controls and secrets management
- Monitoring, tracing, error reporting and alerting
- Automated unit/integration/widget/e2e tests
- Backup/restore and disaster-recovery verification
- Performance/load testing
- Release signing and reproducible CI builds

Until these checks pass, the app should be treated as an active development build rather than a production-certified service.
