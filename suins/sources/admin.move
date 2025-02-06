module suins::admin;

use suins::suins::{Self, AdminCap, SuiNS};

/// The authorization witness.
public struct Admin has drop {}


#[test_only]
/// Authorize the admin application in the SuiNS to get access
/// to protected functions. Must be called in order to use the rest
/// of the functions.
public fun authorize(cap: &AdminCap, suins: &mut SuiNS) {
    suins::authorize_app<Admin>(cap, suins)
}