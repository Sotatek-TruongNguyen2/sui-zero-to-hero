#[test_only]
module payments::payments_tests;

use payments::payments::{PaymentsApp};

use suins::suins::{Self, SuiNS, AdminCap};
// use suins::lolo::{TestingSuiNS, new_for_testing_v2};
use suins::payment_tests::setup_suins;

use sui::balance::Balance;
use sui::coin::{Self, CoinMetadata};
use sui::test_scenario::{Self as ts, ctx};
use sui::test_utils::destroy;
use std::debug;

use payments::testns::TESTNS;
use payments::testusdc::TESTUSDC;

const SUINS_ADDRESS: address = @0xA001;
const TEST_ADDRESS: address = @0xA002;


public fun setup(ctx: &mut TxContext): (SuiNS, AdminCap) {
     let mut suins = setup_suins(ctx);
     let admin_cap = suins::create_admin_cap_for_testing(ctx);
     admin_cap.authorize_app<PaymentsApp>(&mut suins);

     payments::testns::test_init(ctx);
     payments::testusdc::test_init(ctx);

     (suins, admin_cap)
}

#[test]
fun test_e2e() {
     let mut scenario = ts::begin(SUINS_ADDRESS);
     let (mut suins, _admin_cap) = setup(scenario.ctx());

     scenario.next_tx(SUINS_ADDRESS);

     let usdc_metadata = scenario.take_from_sender<CoinMetadata<TESTUSDC>>();
//      let usdc_type_data = new_coin_type_data<TESTUSDC>(
//         &usdc_metadata,
//         0,
//         vector[],
//     );
//     let mut setups = vector[];
//     setups.push_back(usdc_type_data);

     // let testing_suins = new_for_testing_v2(scenario.ctx());
     // share_for_testing_facade(testing_suins);
     
     // {
     //      scenario.next_tx(SUINS_ADDRESS);
     //      let testing_suins = scenario.take_shared<TestingSuiNS>();
     //      // // // add_up_balance<TESTUSDC>(&mut suins, coin::mint_for_testing<TESTUSDC>(10, test.ctx()).into_balance());
     //      // add_up_balance(&mut suins, &mut testing_suins);
     //      debug::print(&testing_suins);
     //      destroy(testing_suins);

     // };

     destroy(usdc_metadata);
     destroy(_admin_cap);
     destroy(suins);

     scenario.end();
}