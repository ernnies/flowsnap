
program c0mrad_dao.aleo {

    // =============================================
    // Constants & Types
    // =============================================

    struct WorkflowStep {
        // Simplified — real version might have more fields (target, calldata hash, etc.)
        action_type: u8,     // 0=swap, 1=add_liquidity, etc.
        // ... more params as needed
    }

    record Workflow {
        owner: address,
        name: string,
        steps: [string; 16],     // fixed max length array — adjust as needed
        steps_len: u32,          // actual number of steps used
        created_at: u64,
        last_executed: u64,
        is_active: bool,
        risk_score: u8,
        sustainability_score: u8,
        _nonce: group,           // required for records
    }

    // Public mappings (workflows are typically public data)
    mapping workflows: u64 => Workflow.public;

    mapping workflow_count: bool => u64.public;  // single key hack → total count

    mapping user_workflows: address => [u64; 32].public;  // per-user list (fixed size — production use merkle or separate program)
    mapping user_workflows_len: address => u32.public;

    // Simple proposal record (very basic — real governance needs more)
    record Proposal {
        proposer: address,
        workflow_name: string,
        description_hash: field,   // hash of description
        created_at: u64,
        approved: bool,
        _nonce: group,
    }

    mapping proposals: u64 => Proposal.public;
    mapping proposal_count: bool => u64.public;

    // =============================================
    // Helper / View-like logic (transitions that don't mutate)
    // =============================================

    transition get_workflow(id: u64) -> Workflow {
        let wf: Workflow = Mapping::get_or_default(workflows, id, Workflow {
            owner: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq5l2m3v, // 
            name: "",
            steps: [""; 16],
            steps_len: 0u32,
            created_at: 0u64,
            last_executed: 0u64,
            is_active: false,
            risk_score: 0u8,
            sustainability_score: 0u8,
            _nonce: Group::zero(),
        });

        return wf;
    }

    transition get_workflow_count() -> u64 {
        return Mapping::get_or_default(workflow_count, true, 0u64);
    }

    // =============================================
    // Propose a new workflow template (public action)
    // =============================================

    transition propose_workflow_template(
        name: string,
        steps: [string; 16],
        steps_len: u32
    ) {
        // In real system: create Proposal record → vote on it → if approved → call create_workflow
        // Here we simplify: direct creation (governance mocked)

        let caller: address = self.caller;
        let current_time: u64 = self.now;   // block timestamp equivalent

        let current_count: u64 = Mapping::get_or_default(workflow_count, true, 0u64);
        let new_id: u64 = current_count + 1u64;

        let new_workflow: Workflow = Workflow {
            owner: caller,
            name: name,
            steps: steps,
            steps_len: steps_len,
            created_at: current_time,
            last_executed: 0u64,
            is_active: true,
            risk_score: 0u8,
            sustainability_score: 0u8,
            _nonce: Group::rand(self),
        };

        Mapping::set(workflows, new_id, new_workflow);
        Mapping::set(workflow_count, true, new_id);

        // Append to user list (simplified — fixed array, production needs better structure)
        let user_len: u32 = Mapping::get_or_default(user_workflows_len, caller, 0u32);
        if (user_len < 32u32) {
            let mut list: [u64; 32] = Mapping::get_or_default(user_workflows, caller, [0u64; 32]);
            list[user_len as u64] = new_id;
            Mapping::set(user_workflows, caller, list);
            Mapping::set(user_workflows_len, caller, user_len + 1u32);
        }

        // In real DAO: emit event equivalent via output or on-chain record
    }

    // =============================================
    // Execute / touch a workflow (owner only)
    // =============================================

    transition execute_workflow(id: u64) {
        let caller: address = self.caller;
        let current_time: u64 = self.now;

        let wf_opt: Workflow = Mapping::get(workflows, id);
        assert(wf_opt.is_some(), "Workflow does not exist");

        let mut wf: Workflow = wf_opt.unwrap();

        assert(wf.is_active, "Workflow is inactive");
        assert(wf.owner == caller, "Not workflow owner");

        wf.last_executed = current_time;

        Mapping::set(workflows, id, wf);
    }

    // =============================================
    // Placeholder for governance approval (mock)
    // In production: integrate with vote.leo style logic or external DAO
    // =============================================

    transition approve_proposal(proposal_id: u64) {
        // Mock — real version would check voting result
        // You would typically have a separate voting program that outputs approval
        let prop_opt = Mapping::get(proposals, proposal_id);
        assert(prop_opt.is_some(), "Proposal does not exist");

        let mut prop: Proposal = prop_opt.unwrap();
        prop.approved = true;
        Mapping::set(proposals, proposal_id, prop);

        // Then call create_workflow or similar...
    }

    // =============================================
    // Initialization (optional — usually not needed)
    // =============================================

    transition initialize() {
        // Can be called once to set initial state if needed
        let zero: u64 = 0u64;
        Mapping::set(workflow_count, true, zero);
        Mapping::set(proposal_count, true, zero);
    }
}