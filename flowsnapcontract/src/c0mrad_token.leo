import credits.aleo;  

program c0mrad_token.aleo {

    // =============================================
    // Constants
    // =============================================

    const TOTAL_INITIAL_SUPPLY: u128 = 1000000u128;  // 1,000,000 CMR
    const DECIMALS: u8 = 6u8;                        // like 10**6 in Solidity

    
    const ADMIN: address = aleo1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;  // 

    // =============================================
    // Storage
    // =============================================

    // Public balances (transparent, like ERC20 public view)
    mapping public_balances: address => u128.public;

    // Total supply (public)
    mapping total_supply: bool => u128.public;  // single-key mapping hack

    // Voting power (simple - tracks balance for voting weight, updated on transfer)
    // In real DAO: this could be snapshotted or delegated via separate program
    mapping voting_power: address => u128.public;

    // Private shielded token record (Aleo-native private balance)
    record C0mrad {
        owner: address,
        amount: u128,
        _nonce: group,          // required for privacy
    }

    // =============================================
    // Initialization (run once after deploy)
    // =============================================

    transition initialize() {
        let caller: address = self.caller;
        assert(caller == ADMIN, "Only admin can initialize");

        // Mint initial supply to deployer (public)
        let initial_amount: u128 = TOTAL_INITIAL_SUPPLY * 10u128.pow(DECIMALS as u32);

        Mapping::set(public_balances, caller, initial_amount);
        Mapping::set(total_supply, true, initial_amount);
        Mapping::set(voting_power, caller, initial_amount);
    }

    // =============================================
    // Public Transfer (like ERC20 transfer)
    // =============================================

    transition transfer_public(
        recipient: address,
        amount: u128
    ) {
        let sender: address = self.caller;

        let sender_balance: u128 = Mapping::get_or_default(public_balances, sender, 0u128);
        assert(sender_balance >= amount, "Insufficient public balance");

        let recipient_balance: u128 = Mapping::get_or_default(public_balances, recipient, 0u128);

        Mapping::set(public_balances, sender, sender_balance - amount);
        Mapping::set(public_balances, recipient, recipient_balance + amount);

        // Update voting power (simple mirror of balance)
        Mapping::set(voting_power, sender, sender_balance - amount);
        Mapping::set(voting_power, recipient, recipient_balance + amount);
    }

    // =============================================
    // Private Transfer (shielded)
    // =============================================

    async transition transfer_private(
        private sender_token: C0mrad,
        private recipient: address,
        private amount: u128
    ) -> (C0mrad, C0mrad) {

        assert(sender_token.owner == self.caller, "Not token owner");
        assert(sender_token.amount >= amount, "Insufficient private amount");

        let sender_new_amount: u128 = sender_token.amount - amount;

        let sender_updated: C0mrad = C0mrad {
            owner: sender_token.owner,
            amount: sender_new_amount,
            _nonce: Group::rand(self),
        };

        let recipient_new: C0mrad = C0mrad {
            owner: recipient,
            amount: amount,
            _nonce: Group::rand(self),
        };

        (sender_updated, recipient_new)
    }

    // =============================================
    // Mint (admin only, public for simplicity)
    // =============================================

    transition mint_public(
        recipient: address,
        amount: u128
    ) {
        let caller: address = self.caller;
        assert(caller == ADMIN, "Only admin can mint");

        let current_total: u128 = Mapping::get_or_default(total_supply, true, 0u128);
        let recipient_balance: u128 = Mapping::get_or_default(public_balances, recipient, 0u128);

        Mapping::set(public_balances, recipient, recipient_balance + amount);
        Mapping::set(total_supply, true, current_total + amount);
        Mapping::set(voting_power, recipient, recipient_balance + amount + amount);  // update voting power
    }

    // =============================================
    // View functions (transitions that just return data)
    // =============================================

    transition get_balance_public(owner: address) -> u128 {
        return Mapping::get_or_default(public_balances, owner, 0u128);
    }

    transition get_voting_power(owner: address) -> u128 {
        return Mapping::get_or_default(voting_power, owner, 0u128);
    }

    transition get_total_supply() -> u128 {
        return Mapping::get_or_default(total_supply, true, 0u128);
    }
}