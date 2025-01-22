module suins::lolo;

public struct TestingSuiNS has key, store {
    id: UID,
    count: u64
}

public fun app_add_custom_balance_testing_only<App: drop>(_: App, testSuiNS: &mut TestingSuiNS) {
    testSuiNS.count = 10;
}

// === Testing ===

#[test_only]
public fun share_for_testing_v2(self: TestingSuiNS) {
    transfer::share_object(self)
}

#[test_only]
public fun new_for_testing_v2(ctx: &mut TxContext): (TestingSuiNS) {
    (TestingSuiNS { id: object::new(ctx), count: 0 })
}