
program rwa_factory.aleo {

    // =============================================
    // Constants & Types
    // =============================================

    // Collection name & symbol (for reference / metadata)
    const COLLECTION_NAME: string = "C0mrad RWA";
    const COLLECTION_SYMBOL: string = "CRWA";

    // Private NFT record (owner can be hidden)
    record RwaNft {
        owner: address,
        token_id: u64,
        metadata_uri: string,          // off-chain JSON URI (IPFS/Arweave/etc.)
        asset_type: string,            // e.g. "RealEstate", "Invoice", "Commodity"
        _nonce: group,
    }

    // Public view / index for minted tokens (optional transparency)
    mapping token_metadata: u64 => string.public;   // token_id → metadata_uri
    mapping token_asset_type: u64 => string.public; // token_id → asset_type
    mapping token_owner_public: u64 => address.public; // optional public owner view

    // Global token ID counter (public)
    mapping next_token_id: bool => u64.public;

    // =============================================
    // Initialization (optional - set counter to 0)
    // =============================================

    transition initialize() {
        Mapping::set(next_token_id, true, 0u64);
    }

    // =============================================
    // Tokenize / mint a new RWA NFT
    // Anyone can call (or restrict via governance in production)
    // =============================================

    async transition tokenize_asset(
        to: address,
        metadata_uri: string,
        asset_type: string
    ) -> (RwaNft, Future) {

        let current_id: u64 = Mapping::get_or_default(next_token_id, true, 0u64);
        let new_id: u64 = current_id + 1u64;

        // Create private NFT record (owner = 'to')
        let nft: RwaNft = RwaNft {
            owner: to,
            token_id: new_id,
            metadata_uri: metadata_uri,
            asset_type: asset_type,
            _nonce: Group::rand(self),
        };

        // Return the private record + future for on-chain updates
        (nft, future)
    }

    finalize tokenize_asset(
        public to: address,
        public metadata_uri: string,
        public asset_type: string,
        public token_id: u64
    ) {
        // Update public indexes (optional - for explorer / marketplace visibility)
        Mapping::set(token_metadata, token_id, metadata_uri);
        Mapping::set(token_asset_type, token_id, asset_type);
        Mapping::set(token_owner_public, token_id, to); // public owner view

        // Increment global counter
        Mapping::set(next_token_id, true, token_id + 1u64);
    }

    // =============================================
    // View helpers
    // =============================================

    transition get_next_token_id() -> u64 {
        return Mapping::get_or_default(next_token_id, true, 0u64);
    }

    transition get_metadata(token_id: u64) -> string {
        return Mapping::get_or_default(token_metadata, token_id, "");
    }

    transition get_asset_type(token_id: u64) -> string {
        return Mapping::get_or_default(token_asset_type, token_id, "");
    }

    transition get_public_owner(token_id: u64) -> address {
        return Mapping::get_or_default(token_owner_public, token_id, aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq5l2m3v);
    }
}