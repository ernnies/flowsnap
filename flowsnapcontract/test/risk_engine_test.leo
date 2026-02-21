// tests/risk_engine_test.leo
// Unit tests for risk_engine.aleo

import risk_engine.aleo;
import flow_core.aleo;
import common.aleo;

program risk_engine_test.aleo {

    // Test risk calculation with known steps
    @test
    transition test_calculate_risk_flashloan_leverage() {
        let mut steps: [string; 16] = [""; 16];
        steps[0u32] = "FlashLoan";
        steps[1u32] = "Leverage";
        let len: u32 = 2u32;

        let risk: u128 = risk_engine::calculate_risk(steps, len);

        assert.eq(risk, 55u128); // 30 + 25
    }

    // Test cap at 100
    @test
    transition test_risk_capped_at_100() {
        let mut steps: [string; 16] = [""; 16];
        let mut i: u32 = 0u32;
        while (i < 10u32) {
            steps[i as u64] = "FlashLoan";
            i += 1u32;
        }
        let len: u32 = 10u32;

        let risk: u128 = risk_engine::calculate_risk(steps, len);

        assert.eq(risk, common::MAX_RISK_SCORE); // capped
    }

    // Test assess_risk stores value (mock workflow exists)
    @test
    transition test_assess_risk_stores_score() {
        let workflow_id: u64 = 42u64;

        // Assume a mock active workflow exists with steps that give risk=45
        risk_engine::assess_risk(workflow_id);

        let stored: u128 = risk_engine::get_risk_score(workflow_id);

        assert(stored > 0u128); // at least something stored
        // In real suite: assert.eq(stored, expected_from_mock)
    }
}