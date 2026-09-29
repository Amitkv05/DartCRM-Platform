import test from "node:test";
import assert from "node:assert/strict";
import { sha256 } from "../src/utils/crypto.js";
import { normalizeAction, requireFields } from "../src/utils/validation.js";


test("sha256 is deterministic", () => {
  assert.equal(
    sha256("crm-service-secret"),
    "c374e8bb8986d98aae15d56844e47da360520a8720a08bd52d0803e24ba7f376"
  );
});

test("normalizeAction accepts approve/reject case-insensitively", () => {
  assert.equal(normalizeAction("approve"), "APPROVE");
  assert.equal(normalizeAction("Reject"), "REJECT");
});

test("requireFields rejects missing values", () => {
  assert.throws(() => requireFields({ a: 1 }, ["a", "b"]), /Missing required field/);
});
