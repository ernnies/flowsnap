// insurance_pool.aleo
// Simplified insurance / contribution pool for FlowSnap on Aleo
// Uses private position records + public total pool tracking
// Assumes token transfers via token_registry.aleo (ARC-20 style hub)

import token_registry.aleo;   // Standard token registry (recommended)
// OR import your_custom_token.aleo if using standalone ARC-20

program insurance_pool.aleo {

    // =============================================
    // Constants & Types
    // =============================================

    // Token program ID (the premiumToken equivalent)
    // In production: set via initialize or governance
    constant PREMIUM_TOKEN_PROGRAM: program_id = token_registry.aleo;

    // Private user contribution position (shielded)
    record Contribution {
        owner: address,
        amount: u128,
        _nonce: group,
    }

    // Public aggregate (total pool size - visible TVL)
    mapping total_pool: bool => u128.public;

    // Optional: public user contribution view (for transparency, zero-knowledge optional)
    mapping public_contributions: address => u128.public;

    // =============================================
    // Initialization (optional - set token if needed)
    // =============================================

    transition initialize() {
        // Can restrict to deployer/governance
        let zero: u128 = 0u128;
        Mapping::set(total_pool, true, zero);
    }

    // =============================================
    // Add contribution to the pool (deposit)
    // =============================================

    async transition add_contribution(
        private input_token: token_registry.aleo/TokenRecord,   // from registry or ARC-20
        public amount: u128
    ) -> (Contribution, Future) {

        let caller: address = self.caller;
        assert(amount > 0u128, "Amount must be greater than 0");

        // =============================================
        // Off-chain: assume token transfer happened via registry call
        // In real code: call token_registry.transfer(...) first in bundle
        // Here we just check ownership & amount
        // =============================================
        assert(input_token.owner == caller, "Not token owner");
        assert(input_token.amount >= amount, "Insufficient token amount");

        // Create private contribution record
        let contribution: Contribution = Contribution {
            owner: caller,
            amount: amount,
            _nonce: Group::rand(self),
        };

        // Return updated token record (reduced) + future for finalize
        let updated_token: token_registry.aleo/TokenRecord = token_registry.aleo/TokenRecord {
            owner: input_token.owner,
            amount: input_token.amount - amount,
            _nonce: Group::rand(self),  // new nonce
        };

        (contribution, future)
    }

    finalize add_contribution(
        public contributor: address,
        public amount: u128
    ) {
        // Update public total pool
        let current_total: u128 = Mapping::get_or_default(total_pool, true, 0u128);
        Mapping::set(total_pool, true, current_total + amount);

        // Optional: update public contribution view
        let current_user: u128 = Mapping::get_or_default(public_contributions, contributor, 0u128);
        Mapping::set(public_contributions, contributor, current_user + amount);
    }

    // =============================================
    // Process / claim from the pool
    // =============================================

    async transition process_claim(
        private contribution: Contribution,
        public amount: u128
    ) -> (Contribution, token_registry.aleo/TokenRecord) {

        let caller: address = self.caller;
        assert(contribution.owner == caller, "Not contributor");
        assert(contribution.amount >= amount, "Insufficient contribution");

        // Check pool has enough funds (public constraint)
        let current_total: u128 = Mapping::get_or_default(total_pool, true, 0u128);
        assert(current_total >= amount, "Insufficient pool funds");

        // Update contribution record
        let updated_contribution: Contribution = Contribution {
            owner: contribution.owner,
            amount: contribution.amount - amount,
            _nonce: Group::rand(self),
        };

        // Create output token record for claimant (via registry pattern)
        let output_token: token_registry.aleo/TokenRecord = token_registry.aleo/TokenRecord {
            owner: caller,
            amount: amount,
            _nonce: Group::rand(self),
        };

        (updated_contribution, output_token)
    }

    finalize process_claim(
        public claimant: address,
        public amount: u128
    ) {
        // Reduce public total pool
        let current_total: u128 = Mapping::get_or_default(total_pool, true, 0u128);
        Mapping::set(total_pool, true, current_total - amount);

        // Optional: reduce public contribution view
        let current_user: u128 = Mapping::get_or_default(public_contributions, claimant, 0u128);
        if (current_user >= amount) {
            Mapping::set(public_contributions, claimant, current_user - amount);
        }
    }

    // =============================================
    // View helpers
    // =============================================

    transition get_total_pool() -> u128 {
        return Mapping::get_or_default(total_pool, true, 0u128);
    }

    transition get_user_contribution_public(user: address) -> u128 {
        return Mapping::get_or_default(public_contributions, user, 0u128);
    }
}