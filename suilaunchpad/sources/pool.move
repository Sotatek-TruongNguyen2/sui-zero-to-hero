module suilaunchpad::pool {
    use suilaunchpad::core_config::{CoreConfig};
    use suilaunchpad::suilaunchpad::{AdminCap, get_config, SuiLaunchpad};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    use std::type_name::{Self, TypeName};
    use sui::event::{Self};
    use sui::coin::{Coin, Self};
    use sui::dynamic_field as df;

    use fun df::add as UID.add;
    // use fun df::borrow as UID.borrow;
    // use fun df::borrow_mut as UID.borrow_mut;
    use fun df::exists_ as UID.exists_;
    use fun df::remove as UID.remove;
    
    public struct PreSalePool<phantom R, phantom S> has key {
        id: UID,
        // version: u64

        protocol_fee_pct: u8,

        open_time_ms: u64,
        close_time_ms: u64,

        total_sold: u64,
        total_sell: u64,
        total_raised: u64,

        raised_balance: Balance<R>,
        sell_balance: Balance<S>,

        // Check if pool is cancelled
        cancelled: bool
    }

    public struct PreSalePoolOwnerCap has key, store {
        id: UID,
        pool_id: ID
    }

    // === Errors ===
    const EInvalidOpenTime: u64 = 1;
    const EInvalidCloseTime: u64 = 2;
    const EOfferedCurrencyIsSettled: u64 = 3;
    const EPoolIsFullyFunded: u64 = 4;
    const EPoolIsNotFullyFunded: u64 = 5;
    const EFundingTimeAlreadyPassed: u64 = 6;

    // === One time Witness ===
    public struct POOL has drop {}

    // === Keys ===
    public struct OfferedCurrencyKey<phantom Currency> has copy, store, drop {}
    public struct UserPurchaseRegistryKey<phantom Currency> has copy, store, drop {}

    // === Events ===
    public struct PreSalePoolCreated has copy, drop {
        pool_id: address,
        pool_owner: address,
        protocol_fee_pct: u8,
        raise_token: TypeName,
        sold_token: TypeName,
        open_time_ms: u64,
        close_time_ms: u64,
        total_sell: u64,
        total_raised: u64,
    }

    public struct OfferedCurrencySettled has copy, drop {
        pool_id: address,
        old_offered_currency: Option<TypeName>,
        new_offered_currency: TypeName,
    }

    public struct PoolFunded has copy, drop {
        pool_id: address,
        user: address,
        funding_amount: u64,
        funded_amount: u64
    }

    public struct PoolCancelled has copy, drop {
        pool_id: address,
        released_amount: u64
    }

    // ===== Main functions =====

    fun init(otw: POOL, ctx: &mut TxContext) {
        sui::package::claim_and_keep(otw, ctx);
    }

    // TODO: Change package to module-level authorization
    public fun new<R, S>(
        _: &AdminCap,
        sui_launchpad: &SuiLaunchpad,
        owner: address,
        clock: &Clock,
        open_time_ms: u64, 
        close_time_ms: u64,
        total_sell: u64,
        total_raised: u64,
        ctx: &mut TxContext
    ): (PreSalePoolOwnerCap) {
        let current_time = clock.timestamp_ms();
        
        assert!(open_time_ms >= current_time, EInvalidOpenTime);
        assert!(close_time_ms > open_time_ms, EInvalidCloseTime);

        let config = sui_launchpad.get_config<CoreConfig>();
        let protocol_fee_pct = config.protocol_fee_pct();

        let pool = PreSalePool<R,S> {
            id: object::new(ctx),
            protocol_fee_pct,
            open_time_ms,
            close_time_ms,
            total_sold: 0,
            total_sell,
            total_raised,
            raised_balance: balance::zero<R>(),
            sell_balance: balance::zero<S>(),
            cancelled: false
        };

        let pool_cap = PreSalePoolOwnerCap {
            id: object::new(ctx),
            pool_id: object::id(&pool)
        };

        let pool_cap_for_admin = PreSalePoolOwnerCap {
            id: object::new(ctx),
            pool_id: object::id(&pool)
        };

        event::emit(PreSalePoolCreated {
            pool_id: object::id_address(&pool),
            pool_owner: object::id_address(&pool_cap),
            protocol_fee_pct,
            sold_token: type_name::get<R>(),
            raise_token: type_name::get<S>(),
            open_time_ms,
            close_time_ms,
            total_sell,
            total_raised,
        });

        transfer::transfer(pool_cap, owner);
        transfer::share_object(pool);

        (pool_cap_for_admin) 
    }

    public fun set_offered_currency<R: store, S: store>(_: &PreSalePoolOwnerCap, self: &mut PreSalePool<R,S>) {
        let mut old_offered_currency: Option<TypeName> = option::none();
        let offered_currency = type_name::get<R>();
        let settled = self.is_offered_currency_settled();

        if (settled) {
            let removed_offered_currency = self.id.remove<_, TypeName>(OfferedCurrencyKey<R> {});
            assert!(removed_offered_currency.borrow_string() != offered_currency.borrow_string(), EOfferedCurrencyIsSettled);
            old_offered_currency = option::some(removed_offered_currency);
        };

        self.id.add(OfferedCurrencyKey<R> {}, offered_currency);

        event::emit(OfferedCurrencySettled {
            old_offered_currency: if (old_offered_currency.is_some()) { old_offered_currency }  else { option::none() },
            new_offered_currency: offered_currency,
            pool_id: object::id_address(self)
        });
    }

    public fun fund_pool<R, S>(_: &PreSalePoolOwnerCap, self: &mut PreSalePool<R,S>, amount: Coin<S>, clock: &Clock, ctx: &TxContext) {
        self.assert_valid_funding_time(clock);
        self.assert_is_not_funded();

        let balance = amount.into_balance();

        event::emit(PoolFunded {
            pool_id: object::id_address(self),
            user: ctx.sender(),
            funding_amount: balance.value(),
            funded_amount: self.sell_balance.value(),
        });

        self.total_sell = self.total_sell + balance.value();
        self.sell_balance.join(balance);
    }

    public fun cancel<R,S>(_: &AdminCap, self: &mut PreSalePool<R,S>, clock: &Clock, ctx: &mut TxContext): Coin<S> {
        self.assert_valid_funding_time(clock);
        self.cancelled = true;

        let funded_amount = self.sell_balance.value();
        let balance = self.sell_balance.split(funded_amount).into_coin(ctx);

        event::emit(PoolCancelled { pool_id: object::id_address(self), released_amount: funded_amount });

        balance
    }

    public fun is_offered_currency_settled<R,S>(self: &PreSalePool<R,S>): bool {
        self.id.exists_(OfferedCurrencyKey<R> {})
    }

   public fun pool_is_eligible_to_buy<R,S>(self: &PreSalePool<R,S>, clock: &Clock): bool {
        let cancelled = self.cancelled();

        // @dev: If pool is already cancelled, return false immediately
        if (cancelled) {
            return false
        };

        let in_valid_time_to_buy = self.valid_time_to_buy(clock);

        // @dev: If this's valid time to buy, then we need to check if the pool is totally funded
        if (in_valid_time_to_buy) {
            return self.is_funded()
        };

        false
   }

    public fun is_funded<R,S>(self: &PreSalePool<R,S>): bool {
        self.sell_balance.value() == self.total_sell
    }

    public fun cancelled<R,S>(self: &PreSalePool<R,S>): bool {
        self.cancelled
    }

    public fun valid_time_to_buy<R,S>(self: &PreSalePool<R,S>, clock: &Clock): bool {
        let current_time = clock.timestamp_ms();
        self.open_time_ms <= current_time && current_time <= self.close_time_ms
    }

    public fun assert_is_not_funded<R,S>(self: &PreSalePool<R,S>) {
        assert!(!self.is_funded(), EPoolIsFullyFunded);
    }

    public fun assert_is_funded<R,S>(self: &PreSalePool<R,S>) {
        assert!(self.is_funded(), EPoolIsNotFullyFunded);
    }

    public fun assert_valid_funding_time<R,S>(self: &PreSalePool<R,S>, clock: &Clock) {
        assert!(self.open_time_ms > clock.timestamp_ms(), EFundingTimeAlreadyPassed);
    }
}