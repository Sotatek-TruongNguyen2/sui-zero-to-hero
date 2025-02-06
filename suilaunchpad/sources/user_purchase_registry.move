module suilaunchpad::user_purchase_registry {
    use sui::table::{Table, Self};
    use suilaunchpad::user_purchase_record::{Self, UserPurchaseRecord};
    use suilaunchpad::suilaunchpad::{AdminCap};

    const EPoolIsAlreadyRegistered: u64 = 0;

    public struct UserPurchaseRecordMultiPools has store {
        records: Table<address, UserPurchaseRecord>, // pool -> User Purchase Record
    }

    public struct UserPurchaseRecordRegistry has store {
        registry: Table<address, UserPurchaseRecordMultiPools>, // address -> user multi pools
        pools: Table<address, bool>
    }

    public fun new(_: &AdminCap, ctx: &mut TxContext): UserPurchaseRecordRegistry {
        return UserPurchaseRecordRegistry { 
            registry: table::new(ctx), 
            pools: table::new(ctx)
        }
    }

    public fun record_user_purchase(self: &mut UserPurchaseRecordMultiPools, user_addr: address, pool_addr: address, amount: u64, digest: vector<u8>) {
        if (self.user_purchase_record_existed(pool_addr)) {
            self.records.borrow_mut(pool_addr).add_new_buy_tx(digest, amount);
            return
        };

        let user_purchase_record = user_purchase_record::new(pool_addr, user_addr);
        self.records.add(pool_addr, user_purchase_record);

        self.records.borrow_mut(pool_addr).add_new_buy_tx(digest, amount);
    }

    public(package) fun retrieve_user_purchase_record_multi_pools_mut(self: &mut UserPurchaseRecordRegistry, user_addr: address, ctx: &mut TxContext): &mut UserPurchaseRecordMultiPools {
        if (self.user_purchase_record_multi_pools_existed(user_addr)) {
            return self.registry.borrow_mut(user_addr)
        };

        self.registry.add(user_addr, UserPurchaseRecordMultiPools { 
            records: table::new(ctx) 
        });
        self.registry.borrow_mut(user_addr)
    }

    public fun retrieve_user_purchase_record_multi_pools(self: &UserPurchaseRecordRegistry, user_addr: address): &UserPurchaseRecordMultiPools {
        return self.registry.borrow(user_addr)
    }

    public fun add_pool(self: &mut UserPurchaseRecordRegistry, pool_addr: address) {
        assert!(!self.pool_existed(pool_addr), EPoolIsAlreadyRegistered);
        self.pools.add(pool_addr, true);
    }

    public fun pool_existed(self: &UserPurchaseRecordRegistry,  pool_addr: address): bool {
        self.pools.contains(pool_addr)
    }
    
    public fun user_purchase_record_multi_pools_existed(self: &UserPurchaseRecordRegistry, user_addr: address): bool {
        self.registry.contains(user_addr)
    }

     public fun user_purchase_record_existed(self: &UserPurchaseRecordMultiPools, pool_addr: address): bool {
        self.records.contains(pool_addr)
    }
}