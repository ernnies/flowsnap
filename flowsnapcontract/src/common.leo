// common.leo
// Shared utilities, structs, constants, and helpers for FlowSnap programs on Aleo
// Import this in other .leo files: import common.leo;

program common.aleo {  // Note: even helpers live inside a dummy program declaration

    // =============================================
    // Constants (global thresholds, decimals, etc.)
    // =============================================

    const MAX_STEPS: u32 = 16u32;
    const MAX_RISK_SCORE: u128 = 100u128;
    const RISK_THRESHOLD_LOW: u8 = 30u8;     // <30 = low risk
    const RISK_THRESHOLD_MEDIUM: u8 = 60u8;  // 30-60 = medium
    const TOKEN_DECIMALS: u8 = 6u8;          // common for CMR, etc.
    const ZERO_ADDRESS: address = aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq5l2m3v;

    // Precomputed keccak256 hashes for common step names (compute once off-chain)
    // Replace with actual keccak256(utf8 bytes) values
    const HASH_FLASHLOAN: field = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdeffield; // ← REAL VALUE
    const HASH_LEVERAGE:   field = 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890field; // ← REAL VALUE
    const HASH_HIGHGAS:    field = 0x7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456field; // ← REAL VALUE

    // =============================================
    // Shared Structs
    // =============================================

    struct StepScoreWeights {
        flash_loan: u128,
        leverage: u128,
        high_gas: u128,
    }

    // Default weights (can be overridden per program if needed)
    const DEFAULT_WEIGHTS: StepScoreWeights = StepScoreWeights {
        flash_loan: 30u128,
        leverage: 25u128,
        high_gas: 15u128,
    };

    // =============================================
    // Shared Record Templates (if needed across programs)
    // =============================================

    // Generic token-like record (used in token programs, pools, positions)
    record TokenAmount {
        owner: address,
        amount: u128,
        _nonce: group,
    }

    // Optional generic position / contribution record
    record Position {
        owner: address,
        amount: u128,
        strategy_id: u8,         // 0 = default, 1 = yield A, etc.
        _nonce: group,
    }

    // =============================================
    // Helper Functions (pure, constraint-friendly)
    // =============================================

    // Clamp value between min and max
    function clamp(value: u128, min_val: u128, max_val: u128) -> u128 {
        if (value < min_val) {
            return min_val;
        } else if (value > max_val) {
            return max_val;
        } else {
            return value;
        }
    }

    // Simple risk score calculator from steps (used in flow_core + risk_engine)
    // Pass pre-hashed or use string == if steps are enums
    function calculate_risk_from_steps(
        steps: [string; 16],
        steps_len: u32,
        weights: StepScoreWeights
    ) -> u128 {

        let mut risk: u128 = 0u128;
        let mut i: u32 = 0u32;

        while (i < steps_len) {
            let step: string = steps[i as u64];
            let step_hash: field = Keccak256::hash_to_field(step);

            if (step_hash == common::HASH_FLASHLOAN) {
                risk += weights.flash_loan;
            } else if (step_hash == common::HASH_LEVERAGE) {
                risk += weights.leverage;
            } else if (step_hash == common::HASH_HIGHGAS) {
                risk += weights.high_gas;
            }

            i += 1u32;
        }

        return common::clamp(risk, 0u128, common::MAX_RISK_SCORE);
    }

    // Basic sustainability score (can be extended)
    function calculate_sustainability_from_steps(
        steps: [string; 16],
        steps_len: u32
    ) -> u128 {
        let mut score: u128 = 100u128;
        let mut i: u32 = 0u32;

        while (i < steps_len) {
            let step: string = steps[i as u64];
            if (step == "HighGas") {  // fallback string check
                score -= 20u128;
            }
            i += 1u32;
        }

        if (score < 0u128) {
            score = 0u128;
        }
        return score;
    }

    // Assert with custom error message (Leo has assert, but this can be wrapped)
    function assert_with_msg(condition: bool, msg: string) {
        assert(condition);  // Leo will fail with generic error; msg for dev readability
    }
}