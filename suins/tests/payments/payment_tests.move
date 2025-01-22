
#[test_only]
module suins::payment_tests;    

use sui::test_utils::{destroy};
use suins::suins::{Self, SuiNS};
use std::debug;

public struct PaymentsApp() has drop;

public fun setup_suins(ctx: &mut TxContext): SuiNS {
    let (mut suins, cap) = suins::new_for_testing(ctx);

    // authorize a "payments" app that is responsible for handling payments and
    // issuing receipts.
    cap.authorize_app<PaymentsApp>(&mut suins);
    
    destroy(cap);
    suins
}