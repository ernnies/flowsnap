// risk_engine.aleo
// Risk assessment engine for FlowSnap workflows on Aleo
// Simplified - uses keccak256 for step matching; in production prefer enum or off-chain precompute

import flow_core.aleo;     // to read public workflows mapping

program risk_engine.aleo {

    // =============================================
    // Constants
    // =============================================

    const MAX_RISK: u128 = 100u128;

    // Precomputed keccak256 hashes of common step names (compute off-chain once)
    // In Leo you can compute them in a transition if needed, but constants are better
    // These are placeholders — replace with actual keccak256("FlashLoan") etc.
    // Use tools like ethers.js or python keccak to get real values
    const HASH_FLASHLOAN: field  = 1234567890123456789012345678901234567890123456789012345678901234field;   // ← REPLACE
    const HASH_LEVERAGE:   field = 9876543210987654321098765432109876543210987654321098765432109876field;   // ← REPLACE
    const HASH_HIGHGAS:    field = 1122334455667788990011223344556677889900112233445566778899001122field;   // ← REPLACE

    // Public risk scores per workflow
    mapping workflow_risk_scores: u64 => u128.public;

    // =============================================
    // Assess / update risk score for a workflow
    // Restricted to admin/governance caller (placeholder check)
    // =============================================

    transition assess_risk(workflow_id: u64) {
        let caller: address = self.caller;
        // In production: assert(is_governance_or_admin(caller)) or integrate DAO approval
        // Placeholder: anyone can call for now (or restrict via governance transition)

        // Fetch workflow from flow_core public mapping
        let wf: flow_core.aleo.Workflow = Mapping::get_or_default(
            flow_core.aleo::workflows,
            workflow_id,
            flow_core.aleo::Workflow {
                owner: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq5l2m3v, // zero fallback
                name: "",
                steps: [""; 16],
                steps_len: 0u32,
                created_at: 0u64,
                last_executed: 0u64,
                is_active: false,
                risk_score: 0u128,
                sustainability_score: 0u128,
            }
        );

        assert(wf.is_active, "Workflow is inactive");

        // Calculate risk based on steps
        let risk: u128 = calculate_risk(wf.steps, wf.steps_len);

        // Store public risk score
        Mapping::set(workflow_risk_scores, workflow_id, risk);
    }

    // =============================================
    // Internal: risk calculation logic
    // Uses keccak256 hashing of step strings
    // =============================================

    function calculate_risk(
        steps: [string; 16],
        len: u32
    ) -> u128 {

        let mut risk: u128 = 0u128;

        let mut i: u32 = 0u32;
        while (i < len) {
            let step_str: string = steps[i as u64];

            // Hash the step string with keccak256
            // Note: string → bytes conversion implicit in hash.keccak256
            let step_hash: field = Keccak256::hash_to_field(step_str);

            if (step_hash == HASH_FLASHLOAN) {
                risk += 30u128;
            } else if (step_hash == HASH_LEVERAGE) {
                risk += 25u128;
            } else if (step_hash == HASH_HIGHGAS) {
                risk += 15u128;
            }

            i += 1u32;
        }

        if (risk > MAX_RISK) {
            risk = MAX_RISK;
        }

        return risk;
    }

    // =============================================
    // View: get current risk score
    // =============================================

    transition get_risk_score(workflow_id: u64) -> u128 {
        return Mapping::get_or_default(workflow_risk_scores, workflow_id, 0u128);
    }

    // =============================================
    // Optional: update core reference (if needed in future)
    // =============================================

    transition update_core(new_core_program: program_id) {
        // Restricted logic — placeholder
        // In real system: governance controlled
    }
}