// tests/flow_core_test.leo
// Basic unit tests for flow_core.aleo

import flow_core.aleo;
import common.aleo;

program flow_core_test.aleo {

    // Test: create_workflow correctly increments ID, sets owner, computes scores
    @test
    transition test_create_workflow() {
        let name: string = "Arbitrage Bot";
        let mut steps: [string; 16] = [""; 16];
        steps[0u32] = "Swap";
        steps[1u32] = "FlashLoan";
        let steps_len: u32 = 2u32;

        let created_id: u64 = flow_core::create_workflow(name, steps, steps_len);

        // Check returned ID == 1 (first creation)
        assert.eq(created_id, 1u64);

        // Fetch and verify the stored workflow
        let wf: flow_core::Workflow = flow_core::get_workflow(1u64);

        assert.eq(wf.owner, self.caller);
        assert.eq(wf.name, name);
        assert.eq(wf.steps_len, steps_len);
        assert.eq(wf.steps[0u64], "Swap");
        assert.eq(wf.steps[1u64], "FlashLoan");
        assert(wf.is_active);
        assert.eq(wf.risk_score, 30u128);           // only FlashLoan hit
        assert.eq(wf.sustainability_score, 100u128); // no HighGas
    }

    // Test: execute_workflow updates timestamp (mock time via input if needed)
    @test
    transition test_execute_workflow() {
        // Assume workflow 1 already exists from previous test (in real suite: setup fixture)
        let id: u64 = 1u64;

        let before: flow_core::Workflow = flow_core::get_workflow(id);
        assert.eq(before.last_executed, 0u64);

        flow_core::execute_workflow(id);

        let after: flow_core::Workflow = flow_core::get_workflow(id);
        assert(after.last_executed > 0u64);  // timestamp updated
    }

    // Negative test: execute inactive workflow should fail
    @test
    transition test_execute_inactive_should_fail() {
        let id: u64 = 999u64; // non-existent

        // This should panic/fail — we expect failure
        flow_core::execute_workflow(id);

        // If it reaches here → test failed
        assert(false); // explicit fail if no panic occurred
    }
}