module suilaunchpad::suilaunchpad {
    use sui::dynamic_field as df;

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use fun df::add as UID.add;
    use fun df::borrow as UID.borrow;
    use fun df::borrow_mut as UID.borrow_mut;
    use fun df::exists_ as UID.exists_;
    use fun df::remove as UID.remove;

    public struct SuiLaunchpad has key {
        id: UID,
        total_pools: u256,
        balance: Balance<SUI>,

    }
    
    /// An admin capability. The admin has full control over the application.
    /// This object must be issued only once during module initialization.
    public struct AdminCap has key, store { id: UID }

    public struct SUILAUNCHPAD has drop {}

    // === Errors ===

    /// Trying to withdraw from an empty balance.
    const ENoProfits: u64 = 0;
    /// An application is not authorized to access the feature.
    const EAppNotAuthorized: u64 = 1;
    const ENoProfitsInCoinType: u64 = 2;

    // === Keys ===
    public struct ConfigKey<phantom Config> has copy, drop, store {}
    public struct BalanceKey<phantom T> has copy, drop, store {}
    public struct RegistryKey<phantom Config> has copy, drop, store {}

    // === App Auth ===

    /// An authorization Key kept in the Sui Launchpad - allows applications access
    /// protected features of the Sui Launch pad (such as total_pools, etc.)
    /// The `App` type parameter is a witness which should be defined in the
    /// original module (Controller, Registry, Registrar - whatever).
    public struct AppKey<phantom App: drop> has copy, drop, store {}

    fun init(otw: SUILAUNCHPAD, ctx: &mut TxContext) {
        sui::package::claim_and_keep(otw, ctx);

        transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());

        let launchpad = SuiLaunchpad {
            id: object::new(ctx),
            total_pools: 0,
            balance: balance::zero()
        };

        transfer::share_object(launchpad);
    }

    // === Admin actions ===

    /// Withdraw from the SuiNS balance directly and access the Coins within the
    /// same
    /// transaction. This is useful for the admin to withdraw funds from the SuiNS
    /// and then send them somewhere specific or keep at the address.
    public fun withdraw(_: &AdminCap, self: &mut SuiLaunchpad, ctx: &mut TxContext): Coin<SUI> {
        let amount = self.balance.value();
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    /// Withdraw from the SuiNS balance of a custom coin type.
    public fun withdraw_custom<T>(self: &mut SuiLaunchpad, _: &AdminCap, ctx: &mut TxContext): Coin<T> {
        let balance_key = BalanceKey<T> {};
        assert!(self.id.exists_(balance_key), ENoProfitsInCoinType);

        self.id.borrow_mut<_, Balance<T>>(balance_key).withdraw_all().into_coin(ctx)
    }

    public fun authorize_app<App: drop>(_: &AdminCap, self: &mut SuiLaunchpad) {
        self.id.add(AppKey<App> {}, true);
    }

    public fun deauthorize_app<App: drop>(_: &AdminCap, self: &mut SuiLaunchpad): bool {
        self.id.remove(AppKey<App> {})
    }

    public fun is_app_authorized<App: drop>(self: &SuiLaunchpad): bool {
        self.id.exists_(AppKey<App> {})
    }

    public fun app_add_balance<App: drop>(_: App, self: &mut SuiLaunchpad, balance: Balance<SUI>) {
        self.assert_app_is_authorized<App>();
        self.balance.join(balance);
    }

    /// Adds a balance of type `T` to the SuiLaunchpad protocol as an authorized app.
    public fun app_add_custom_balance<App: drop, T>(self: &mut SuiLaunchpad, _: App, balance: Balance<T>) {
        self.assert_app_is_authorized<App>();
        let key = BalanceKey<T> {};
        if (self.id.exists_(key)) {
            let balances: &mut Balance<T> = self.id.borrow_mut(key);
            balances.join(balance);
        } else {
            self.id.add(key, balance);
        }
    }

    /// Assert that an application is authorized to access protected features of
    /// the SuiLaunchpad. Aborts with `EAppNotAuthorized` if not.
    public fun assert_app_is_authorized<App: drop>(self: &SuiLaunchpad) {
        assert!(self.is_app_authorized<App>(), EAppNotAuthorized);
    }

    // === Config management ===

    /// Attach dynamic configuration object to the application.
    public fun add_config<Config: store + drop>(_: &AdminCap, self: &mut SuiLaunchpad, config: Config) {
        self.id.add(ConfigKey<Config> {}, config);
    }

    /// Borrow configuration object. Read-only mode for applications.
    public fun get_config<Config: store + drop>(self: &SuiLaunchpad): &Config {
        self.id.borrow(ConfigKey<Config> {})
    }

    /// Get the configuration object for editing. The admin should put it back
    /// after editing (no extra check performed). Can be used to swap
    /// configuration since the `T` has `drop`. Eg nothing is stopping the admin
    /// from removing the configuration object and adding a new one.
    ///
    /// Fully taking the config also allows for edits within a transaction.
    public fun remove_config<Config: store + drop>(_: &AdminCap, self: &mut SuiLaunchpad): Config {
        self.id.remove(ConfigKey<Config> {})
    }


    /// Get a mutable access to the `Registry` object. Can only be performed by
    /// authorized
    /// applications.
    public fun app_registry_mut<App: drop, R: store>(_: App, self: &mut SuiLaunchpad): &mut R {
        self.assert_app_is_authorized<App>();
        self.pkg_registry_mut<R>()
    }

    // === Registry ===

    /// Get a read-only access to the `Registry` object.
    public fun registry<R: store>(self: &SuiLaunchpad): &R {
        self.id.borrow(RegistryKey<R> {})
    }

    /// Add a registry to the SuiNS. Can only be performed by the admin.
    public fun add_registry<R: store>(_: &AdminCap, self: &mut SuiLaunchpad, registry: R) {
        self.id.add(RegistryKey<R> {}, registry);
    }

    /// Get a mutable access to the `Registry` object. Can only be called
    /// internally by SuiNS.
    public(package) fun pkg_registry_mut<R: store>(self: &mut SuiLaunchpad): &mut R {
        self.id.borrow_mut(RegistryKey<R> {})
    }
}