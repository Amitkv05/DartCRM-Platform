# CRM V4 Admin & Audit

## Admin user and role management
Admin can create accounts, edit account/profile information, change hierarchy level/profile, reporting manager, approval permission, department, city/territory/product-division access, and switch between profile-default or custom menu access. Account removal is implemented as deactivation so historical CRM records remain attributable.

## Approval permission
L1 remains request-only. Approval-disabled executives are skipped by the approval hierarchy. Pending approvals are reassigned upward when Admin disables/deactivates an approver and an eligible higher manager exists.

## Customer visibility
Final `VALIDATED` + `ACTIVE` customers are visible to all CRM levels. Pending/rejected customer records remain scoped to the creator/reporting hierarchy.

## Request lifecycle
Requesters can use **Requests > My Request History** to see Customer Create/Update/Delete, Contact Create, Visit Backdate, Customer Sampling, and Self-Stock requests after submission and after final approval/rejection.

## Admin Request & Approval History
Admin can filter and search all tracked requests, see requester/profile/level, current approver, last action, actor and level. Opening a request shows the existing complete approval trail and quantity history. Admin may remove completed Approved/Rejected rows from the dedicated Admin audit ledger individually or in bulk. Pending history cannot be deleted. Removing Admin history does not delete operational customer/sampling/self-stock or approval tables.
