# CRM V3 Approval Workflow

## Purpose

V3 makes approvals a first-class CRM workflow instead of a module-specific feature. It adds manager eligibility, admin-managed approval rights, request detail pages, editable book quantities, final-vs-forward approval choice, and Customer Update approvals.

## Approval modules

| Module | Request source | Manager review |
|---|---|---|
| `CUSTOMER_CREATE` | Create Customer | Customer and school/contact details |
| `CUSTOMER_UPDATE` | Edit Customer | Current snapshot vs proposed changes |
| `CUSTOMER_DELETE` | Delete Customer request | Customer details before deactivation |
| `CONTACT_CREATE` | Create Contact | Customer + contact details |
| `VISIT_BACKDATE` | Visit Backdate Request | Visit date + reason |
| `CUSTOMER_SAMPLING` | Customer Sampling | Request + editable book quantities |
| `SELF_STOCK` | Self-Stock Request | Request + editable book quantities |

Normal Visit Entry does not require approval. Only a Visit Backdate Request enters the approval workflow.

## Role rules

- L1 is request-only and cannot approve.
- L2+ executives may approve only when `executives.approval_enabled = 1`.
- Admin can enable/disable approval rights for L2+ executives.
- L1 approval rights cannot be enabled even through the Admin API.
- If a manager has approval disabled, routing skips that manager and searches upward for the next active approval-enabled manager.
- Approval menus are hidden when the logged-in executive is not approval-enabled.
- The Approval Role Management menu is admin-only.

## Final vs next-level approval

The approval action accepts:

```json
{
  "action": "APPROVE",
  "remarks": "Approved",
  "sendToNextLevel": true
}
```

`sendToNextLevel: true` means:

```text
Current approver approves
        -> next active approval-enabled manager
        -> request remains PENDING
```

`sendToNextLevel: false` means:

```text
Current approver approves
        -> FINAL APPROVED
        -> no higher manager receives the request
```

The Flutter detail page exposes this as the checkbox:

> Approve and send to Next Level Approval

If no higher eligible manager exists, the approval is final even when forwarding is requested.

## Sampling / Self-Stock quantity rules

For `CUSTOMER_SAMPLING` and `SELF_STOCK`, each approver can change `approvedQty` for every item.

Example:

```text
Requested by L1: 10
L2 approves:      5 and forwards
L3 changes to:    8 and forwards
L4 changes to:    6 and final-approves
Final quantity:   6
```

An approver may increase or decrease the previous level quantity, but cannot exceed the original requested quantity. Every level is written to `approval_item_history`.

Example action:

```json
{
  "action": "APPROVE",
  "remarks": "Reduced after review",
  "sendToNextLevel": true,
  "items": [
    { "itemId": 12, "approvedQty": 5 }
  ]
}
```

## Customer Update staging

A non-admin edit no longer modifies the live customer record immediately.

```text
Junior edits customer
 -> customer_change_requests stores proposed JSON + original snapshot
 -> CUSTOMER_UPDATE approval is created
 -> manager sees Current Customer Data + Requested Changes
 -> final APPROVED applies the proposed data
 -> REJECTED leaves the original customer unchanged
```

Admin customer edits remain direct.

## Admin approval-role endpoints

Both require application token + JWT and an admin profile.

```http
GET /api/admin/executives/approval-roles
```

Returns executives, profile, manager, approval-enabled flag and pending approval count.

```http
PATCH /api/admin/executives/:id/approval-role
Content-Type: application/json

{
  "approvalEnabled": false
}
```

When disabling a manager with pending approvals, the backend reassigns them to the next eligible manager. If there is no higher eligible manager, disabling is blocked with HTTP 409 to avoid orphaning requests.

## Generic manager approval APIs

```http
GET /api/approvals?module=CUSTOMER_CREATE
GET /api/approvals?module=CUSTOMER_UPDATE
GET /api/approvals?module=CUSTOMER_DELETE
GET /api/approvals?module=CONTACT_CREATE
GET /api/approvals?module=VISIT_BACKDATE
GET /api/approvals?module=CUSTOMER_SAMPLING
GET /api/approvals?module=SELF_STOCK
```

```http
GET /api/approvals/:approvalId
```

Returns generic approval information, module-specific request data, approval history, item history and capabilities such as `canAct`, `supportsEditableQuantities`, `canSendToNextLevel` and `nextEligibleApprover`.

```http
POST /api/approvals/:approvalId/action
```

Reject example:

```json
{
  "action": "REJECT",
  "remarks": "Incorrect request details",
  "sendToNextLevel": false
}
```

## Flutter menus

Request-only features remain available according to profile/menu mapping. Approval features are server-driven.

Expected default seed behavior:

- L1: request screens only; no approval menus.
- L2/L3/L4/L5: approval menus while `approval_enabled = 1`.
- Approval-disabled L2+: request menus remain, approval menus disappear, and approval routing skips them.
- HDA/Admin: approval menus plus `Admin -> Approval Role Management`.

The approval menus are:

- Customer Create Approval
- Customer Update Approval
- Customer Delete Approval
- Contact Approval
- Visit Backdate Approval
- Customer Sampling Approval
- Self-Stock Approval

## Notifications

Approval notifications now include the related generic `approvalId` when available. Flutter can open the corresponding Approval Request Detail page directly from the notification.

## Database upgrade

For an existing V2.3 database, back it up and run exactly once:

```text
database/migrations/003_approval_workflow_v3.sql
```

Do not rerun `schema.sql` or `seed.sql` on an existing database.
