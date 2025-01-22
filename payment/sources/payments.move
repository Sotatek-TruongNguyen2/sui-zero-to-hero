/*
/// Module: payment
module payment::payment;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module payments::payments;

use suins::suins::{SuiNS};
use sui::balance::{Self, Balance};

public struct PAYMENT has drop {}

public struct PaymentsApp() has drop;

// public fun add_up_balance(suins: &mut SuiNS, testing_suins: &mut TestingSuiNS) {
//     suins::suins::app_add_custom_balance_testing_only(PaymentsApp(), suins, testing_suins);
//     // suins::suins::app_add_custom_balance(PaymentsApp(), suins, balance);
// }