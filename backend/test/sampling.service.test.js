import test from "node:test";
import assert from "node:assert/strict";
import { createCustomerSampling } from "../src/services/sampling.service.js";

class MockExecutor {
  constructor() {
    this.sql = [];
  }

  async execute(sql, params = []) {
    assert.ok(
      params.every((value) => value !== undefined),
      `SQL bind parameters contain undefined: ${sql}\n${JSON.stringify(params)}`,
    );
    this.sql.push({ sql, params });

    if (sql.includes("FROM application_setup")) {
      return [
        [
          { key_name: "SamplingBudgetCheckApplied", key_value: "Yes" },
          { key_name: "SamplingBudgetType", key_value: "units" },
          { key_name: "SamplingBudgetFor", key_value: "overall" },
          { key_name: "SamplingEntryWithoutBudget", key_value: "Yes" },
          { key_name: "SamplingCustomerMaxQtyAllowed", key_value: "10" },
        ],
      ];
    }

    // Security patch: createCustomerSampling now verifies that the requested
    // executive is the actor or belongs to the actor's down hierarchy.
    if (sql.includes("WITH RECURSIVE down_tree")) {
      return [
        [
          {
            id: 1001,
            manager_executive_id: 1002,
            depth: 0,
          },
        ],
      ];
    }

    if (sql.includes("FROM customers") && sql.includes("customer_status")) {
      return [[{ id: 1 }]];
    }

    if (sql.includes("FROM shipment_modes")) {
      return [[{ id: 1 }]];
    }

    if (sql.includes("FROM books") && sql.includes("list_price")) {
      return [[{ id: 3, list_price: "340.00", series_id: 2 }]];
    }

    if (sql.includes("FROM sampling_types")) {
      return [[{ id: 2, name: "Personal Copy" }]];
    }

    if (sql.includes("FROM customer_contacts")) {
      return [[{ id: 1 }]];
    }

    if (sql.includes("FROM sampling_budgets")) {
      return [
        [
          {
            total_units: 1000,
            used_units: 0,
            total_value: 100000,
            used_value: 0,
          },
        ],
      ];
    }

    if (sql.includes("SELECT last_number FROM request_sequences")) {
      return [[]];
    }

    if (sql.includes("INSERT INTO request_sequences")) {
      return [{ insertId: 1 }];
    }

    if (sql.includes("INSERT INTO customer_sampling_requests")) {
      return [{ insertId: 77 }];
    }

    if (sql.includes("INSERT INTO customer_sampling_request_items")) {
      return [{ insertId: 78 }];
    }

    // Approval resubmission patch: createApproval first checks whether an
    // approval row already exists for the same module/entity.
    if (
      sql.includes("FROM approval_requests") &&
      sql.includes("module_name") &&
      sql.includes("entity_id") &&
      sql.includes("FOR UPDATE")
    ) {
      return [[]];
    }

    if (
      sql.includes("WITH RECURSIVE manager_chain") ||
      sql.includes("LEFT JOIN executives m")
    ) {
      return [
        [
          {
            id: 1002,
            executive_code: "EXE-L2",
            executive_name: "Manager",
            profile_code: "L2",
            level_rank: 2,
          },
        ],
      ];
    }

    if (sql.includes("INSERT INTO approval_requests")) {
      return [{ insertId: 88 }];
    }

    if (sql.includes("INSERT INTO approval_history")) {
      return [{ insertId: 89 }];
    }

    if (sql.includes("INSERT INTO admin_request_history")) {
      return [{ affectedRows: 1 }];
    }

    if (sql.includes("INSERT INTO notifications")) {
      return [{ insertId: 90 }];
    }

    if (sql.includes("UPDATE customer_sampling_requests SET request_status")) {
      return [{ affectedRows: 1 }];
    }

    throw new Error(`Unexpected SQL in test: ${sql}`);
  }
}

test("customer sampling accepts Flutter legacy item data without undefined SQL binds", async () => {
  const executor = new MockExecutor();

  const result = await createCustomerSampling(
    {
      customerId: 1,
      customerType: "SCHOOL",
      executiveId: 1001,
      shipmentModeId: 1,
      shippingInstructions: "",
      requestRemarks: "",
      items: [
        {
          seriesId: 2,
          bookId: 3,
          requestedQty: 2,
          samplingTypeName: "Personal Copy",
          sampleToContactId: 1,
          sampleGiven: "TO_BE_DISPATCHED",
          shipTo: "Residential Address",
          shippingAddress: "Riya Sharma, Preet Vihar, Delhi, Delhi 110092",
          unitPrice: 340,
        },
      ],
    },
    {
      userId: 1,
      executiveId: 1001,
    },
    executor,
  );

  assert.equal(result.id, 77);
  assert.equal(result.requestNumber.startsWith("CS/"), true);
  assert.equal(result.totalQty, 2);
  assert.equal(result.totalPrice, 680);
  assert.equal(result.approval.currentApprover, 1002);
});
