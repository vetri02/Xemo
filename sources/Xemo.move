module my_address::Xemo {
    use std::signer;
    use std::string;
    use std::error;
    use aptos_framework::coin::{Self, MintCapability, BurnCapability, FreezeCapability};

    struct Xemo {}

    struct XemoCap has key {
        mint_cap: MintCapability<Xemo>,
        burn_cap: BurnCapability<Xemo>,
        freeze_cap: FreezeCapability<Xemo>,
    }

    struct XemoInfo has key {
        total_supply: u64,
        owner: address,
    }

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_NOT_OWNER: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;
    const E_EXCEEDS_SUPPLY_CAP: u64 = 5;
    const E_RECIPIENT_NOT_REGISTERED: u64 = 6;

    const MAX_SUPPLY: u64 = 1000000000; // 1 billion Xemo tokens

    fun init_module(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<XemoCap>(account_addr), error::already_exists(E_ALREADY_INITIALIZED));

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Xemo>(
            account,
            string::utf8(b"Xemo"),
            string::utf8(b"XMO"),
            6,
            false,
        );

        move_to(account, XemoCap {
            mint_cap,
            burn_cap,
            freeze_cap,
        });

        move_to(account, XemoInfo {
            total_supply: 0,
            owner: account_addr,
        });
    }

    public entry fun mint(account: &signer, amount: u64) acquires XemoCap, XemoInfo {
        let account_addr = signer::address_of(account);
        assert!(exists<XemoCap>(account_addr), error::not_found(E_NOT_INITIALIZED));
        
        let xemo_cap = borrow_global<XemoCap>(account_addr);
        let xemo_info = borrow_global_mut<XemoInfo>(account_addr);
        
        assert!(account_addr == xemo_info.owner, error::permission_denied(E_NOT_OWNER));
        assert!(xemo_info.total_supply + amount <= MAX_SUPPLY, error::invalid_argument(E_EXCEEDS_SUPPLY_CAP));

        // Ensure the account has a coin store
        if (!coin::is_account_registered<Xemo>(account_addr)) {
            coin::register<Xemo>(account);
        };

        let coins = coin::mint(amount, &xemo_cap.mint_cap);
        coin::deposit(account_addr, coins);
        xemo_info.total_supply = xemo_info.total_supply + amount;
    }

    public entry fun transfer(from: &signer, to: address, amount: u64) {
        let from_addr = signer::address_of(from);
        assert!(coin::balance<Xemo>(from_addr) >= amount, error::invalid_argument(E_INSUFFICIENT_BALANCE));

        // Ensure the recipient account has a coin store
        if (!coin::is_account_registered<Xemo>(to)) {
            abort error::invalid_argument(E_RECIPIENT_NOT_REGISTERED)
        };

        coin::transfer<Xemo>(from, to, amount);
    }

   public entry fun burn(account: &signer, amount: u64) acquires XemoCap, XemoInfo {
    assert!(exists<XemoCap>(@my_address), error::not_found(E_NOT_INITIALIZED));
    
    let xemo_cap = borrow_global<XemoCap>(@my_address);
    let xemo_info = borrow_global_mut<XemoInfo>(@my_address);
    
    let coins = coin::withdraw<Xemo>(account, amount);
    coin::burn(coins, &xemo_cap.burn_cap);
    xemo_info.total_supply = xemo_info.total_supply - amount;
}

    public fun balance(owner: address): u64 {
        coin::balance<Xemo>(owner)
    }

    public fun total_supply(): u64 acquires XemoInfo {
        borrow_global<XemoInfo>(@my_address).total_supply
    }

    public entry fun transfer_ownership(account: &signer, new_owner: address) acquires XemoInfo {
        let account_addr = signer::address_of(account);
        let xemo_info = borrow_global_mut<XemoInfo>(@my_address);
        assert!(account_addr == xemo_info.owner, error::permission_denied(E_NOT_OWNER));
        xemo_info.owner = new_owner;
    }

    #[test_only]
    public fun init_for_test(account: &signer) {
        init_module(account);
    }
}