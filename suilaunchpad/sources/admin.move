module suilaunchpad::admin {
    use suilaunchpad::suilaunchpad::{AdminCap, SuiLaunchpad, Self};

    /// The authorization witness.
    public struct Admin has drop {}

    /// Authorize the admin application in the SuiNS to get access
    /// to protected functions. Must be called in order to use the rest
    /// of the functions.
    public fun authorize(cap: &AdminCap, sui_launchpad: &mut SuiLaunchpad) {
        suilaunchpad::authorize_app<Admin>(cap, sui_launchpad)
    }
}