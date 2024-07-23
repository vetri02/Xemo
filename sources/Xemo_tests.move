// sources/Xemo_tests.move
#[test_only]
module my_address::XemoTests {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::coin;
    use my_address::Xemo;

    #[test]
    public fun test_mint_and_transfer() {
        let admin = account::create_account_for_test(@my_address);
        Xemo::init(&admin); // Call init instead of init_for_test

        let alice = account::create_account_for_test(@0xA);
        let bob = account::create_account_for_test(@0xB);

        // Register accounts to receive Xemo
        coin::register<Xemo::Xemo>(&admin);
        coin::register<Xemo::Xemo>(&alice);
        coin::register<Xemo::Xemo>(&bob);

        Xemo::mint(&admin, 100);
        assert!(Xemo::balance(signer::address_of(&admin)) == 100, 0);
        assert!(Xemo::total_supply() == 100, 1);

        Xemo::transfer(&admin, signer::address_of(&alice), 50);
        assert!(Xemo::balance(signer::address_of(&admin)) == 50, 2);
        assert!(Xemo::balance(signer::address_of(&alice)) == 50, 3);

        Xemo::transfer(&alice, signer::address_of(&bob), 30);
        assert!(Xemo::balance(signer::address_of(&alice)) == 20, 4);
        assert!(Xemo::balance(signer::address_of(&bob)) == 30, 5);

        Xemo::burn(&bob, 10);
        assert!(Xemo::balance(signer::address_of(&bob)) == 20, 6);
        assert!(Xemo::total_supply() == 90, 7);

        Xemo::transfer_ownership(&admin, signer::address_of(&alice));
        Xemo::mint(&alice, 50);  // Alice can now mint
        assert!(Xemo::total_supply() == 140, 8);
    }

    #[test]
    #[expected_failure(abort_code = 0x10001)] // E_EXCEEDS_SUPPLY_CAP
    public fun test_exceed_max_supply() {
        let admin = account::create_account_for_test(@my_address);
        Xemo::init_for_test(&admin);
        coin::register<Xemo::Xemo>(&admin);
        Xemo::mint(&admin, 1000000001);  // Exceeds MAX_SUPPLY
    }

    #[test]
    #[expected_failure(abort_code = 0x10002)] // E_RECIPIENT_NOT_REGISTERED
    public fun test_transfer_to_unregistered_account() {
        let admin = account::create_account_for_test(@my_address);
        Xemo::init_for_test(&admin);
        coin::register<Xemo::Xemo>(&admin);
        
        let unregistered = account::create_account_for_test(@0xC);
        
        Xemo::mint(&admin, 100);
        Xemo::transfer(&admin, signer::address_of(&unregistered), 50);  // Should fail
    }
}