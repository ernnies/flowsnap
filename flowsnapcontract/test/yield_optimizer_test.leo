
import yield_optimizer.aleo;
import common.aleo;

program yield_optimizer_test.aleo {

    // Mock position record
    @test
    transition test_auto_rebalance_basic() {
        let owner: address = self.caller;
        let token_in: program_id = aleo1tokenprogram11111111111111111111111111111111111111111111111111; // mock
        let amount: u128 = 1000u128;

        let position: yield_optimizer::YieldPosition = yield_optimizer::YieldPosition {
            owner: owner,
            token_address: token_in,
            amount: amount,
            _nonce: Group::rand(self),
        };

        let token_out: program_id = aleo1tokentwo22222222222222222222222222222222222222222222222222; // mock
        let amount_in: u128 = 400u128;
        let min_out: u128 = 380u128; // slippage mock

        let (updated_pos, _) = yield_optimizer::auto_rebalance(position, token_out, amount_in, min_out);

        // Check updated position has reduced amount
        assert.eq(updated_pos.amount, amount - amount_in);
        assert.eq(updated_pos.owner, owner);
    }

    // Negative: insufficient balance
    @test
    transition test_rebalance_insufficient_funds_fails() {
        let position: yield_optimizer::YieldPosition = yield_optimizer::YieldPosition {
            owner: self.caller,
            token_address: aleo1mocktoken.............................................,
            amount: 100u128,
            _nonce: Group::rand(self),
        };

        yield_optimizer::auto_rebalance(position, aleo1mock.............................................., 500u128, 0u128);

        // Should panic inside transition → if reaches here, fail test
        assert(false, "Expected panic on insufficient funds");
    }
}