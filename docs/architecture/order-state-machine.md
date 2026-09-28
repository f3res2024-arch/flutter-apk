# Order State Machine v1

## Canonical states

CREATED -> PAYMENT_PENDING -> PAID -> MERCHANT_ACCEPTED -> PREPARING -> READY -> DRIVER_ASSIGNED -> PICKED_UP -> DELIVERING -> DELIVERED

## Terminal states
- CANCELLED
- REJECTED
- PAYMENT_FAILED
- REFUNDED

## Rules
- A client cannot set an arbitrary status; transitions are server-authorized.
- Each transition creates an immutable order event with actor, timestamp and metadata.
- Payment confirmation is required before a paid order can enter merchant processing unless the payment method is explicitly cash-on-delivery.
- Driver assignment does not imply pickup.
- Delivery completion requires the delivery verification policy configured for the order.
- Refunds are financial events and must not be represented by silently mutating the original payment.

## Event naming
- order.created
- order.payment_pending
- order.paid
- order.merchant_accepted
- order.preparing
- order.ready
- order.driver_assigned
- order.picked_up
- order.delivering
- order.delivered
- order.cancelled
- order.rejected
- order.payment_failed
- order.refunded

## Idempotency
Create-order, payment-intent, cancellation and refund commands require an idempotency key. Replaying the same command must return the original result rather than create a duplicate financial or fulfillment operation.
