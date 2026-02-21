// flow_core.leo
// Core workflow registry & execution orchestrator for FlowSnap on Aleo
// Heavily simplified - no upgradeability, no full roles, fixed-size steps array

program flow_core.aleo {

    // =============================================
    // Constants
    // =============================================

    const MAX_STEPS: u32 = 16u32;               // Fixed max steps per workflow
    const MAX_RISK: u128 = 100u128;

    // =============================================
    // Structs & Records
    // =============================================

    // Workflow definition (public - workflows are typically visible)
    struct Workflow {
        owner: address,
        name: string,
        steps: [string; 16],        // fixed size - pad with "" if fewer steps
        steps_len: u32,             // actual number of meaningful steps
        created_at: u64,
        last_executed: u64,
        is_active: bool,
        risk_score: u128,
        sustainability_score: u128,
    }

    // Public storage
    mapping workflows: u64 => Workflow.public;

    mapping workflow_count: bool => u64.public;  // single-key total count

    mapping user_workflows: address => [u64; 32].public;  // per-user list, fixed size
    mapping user_workflows_len: address => u32.public;

    // =============================================
    // Initialization (optional - can be called once)
    // =============================================

    transition initialize() {
        // In production: restrict to deployer via caller check
        let zero: u64 = 0u64;
        Mapping::set(workflow_count, true, zero);
        // Could set other defaults here
    }

    // =============================================
    // Create a new workflow (anyone can propose/register)
    // =============================================

    transition create_workflow(
        name: string,
        steps: [string; 16],
        steps_len: u32
    ) -> u64 {
        assert(steps_len <= MAX_STEPS, "Too many steps");

        let caller: address = self.caller;
        let current_time: u64 = self.now;

        let current_count: u64 = Mapping::get_or_default(workflow_count, true, 0u64);
        let new_id: u64 = current_count + 1u64;

        // Simplified risk & sustainability calculation
        let (risk, sustain) = calculate_scores(steps, steps_len);

        let new_workflow: Workflow = Workflow {
            owner: caller,
            name: name,
            steps: steps,
            steps_len: steps_len,
            created_at: current_time,
            last_executed: 0u64,
            is_active: true,
            risk_score: risk,
            sustainability_score: sustain,
        };

        Mapping::set(workflows, new_id, new_workflow);
        Mapping::set(workflow_count, true, new_id);

        // Append to user's list (fixed size - truncate if full)
        let user_len: u32 = Mapping::get_or_default(user_workflows_len, caller, 0u32);
        if (user_len < 32u32) {
            let mut user_list: [u64; 32] = Mapping::get_or_default(user_workflows, caller, [0u64; 32]);
            user_list[user_len as u64] = new_id;
            Mapping::set(user_workflows, caller, user_list);
            Mapping::set(user_workflows_len, caller, user_len + 1u32);
        }

        return new_id;
    }

    // =============================================
    // Execute / update last_executed timestamp
    // In production: restrict via governance approval or role check
    // =============================================

    transition execute_workflow(id: u64) {
        let caller: address = self.caller;
        let current_time: u64 = self.now;

        let wf_opt = Mapping::get(workflows, id);
        assert(wf_opt.is_some(), "Workflow does not exist");

        let mut wf: Workflow = wf_opt.unwrap();

        assert(wf.is_active, "Workflow is inactive");
        // assert(has_executor_role(caller), "Not executor"); // ← add real check later

        wf.last_executed = current_time;

        Mapping::set(workflows, id, wf);
    }

    // =============================================
    // Internal: simplified score calculation
    // No keccak256(string) - use direct comparison or enum in real app
    // =============================================

    function calculate_scores(
        steps: [string; 16],
        len: u32
    ) -> (u128, u128) {

        let mut risk: u128 = 0u128;
        let mut sustainability: u128 = 100u128;

        let mut i: u32 = 0u32;
        while (i < len) {
            let step: string = steps[i as u64];

            // Very basic string matching (Leo strings support ==)
            if (step == "FlashLoan") {
                risk += 30u128;
            } else if (step == "Leverage") {
                risk += 25u128;
            }

            if (step == "HighGas") {
                sustainability -= 20u128;
            }

            i += 1u32;
        }

        if (risk > MAX_RISK) {
            risk = MAX_RISK;
        }
        if (sustainability < 0u128) {
            sustainability = 0u128;
        }

        return (risk, sustainability);
    }

    // =============================================
    // View helpers
    // =============================================

    transition get_workflow(id: u64) -> Workflow {
        return Mapping::get_or_default(workflows, id, Workflow {
            owner: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq5l2m3v, // zero-ish fallback
            name: "",
            steps: [""; 16],
            steps_len: 0u32,
            created_at: 0u64,
            last_executed: 0u64,
            is_active: false,
            risk_score: 0u128,
            sustainability_score: 0u128,
        });
    }

    transition get_workflow_count() -> u64 {
        return Mapping::get_or_default(workflow_count, true, 0u64);
    }
}