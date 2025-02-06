module suilaunchpad::pool_user_purchase {
    use sui::table::{Table, Self};
    use sui::vec_map::{Self, VecMap};
    use std::string::String;

    public struct PoolUserPurchase has store {
        pool_id: ID,
        usr_addr: address,
        total_buy_amount: u256,
        buy_history: Table<vector<u8>, u256>,
        /// Additional data which may be stored in a record
        data: VecMap<String, String>,
    }   
    
    // === Errors ===
    const ETxHashExisted: u64 = 1;

    public fun new(pool_id: ID, usr_addr: address, ctx: &mut TxContext): PoolUserPurchase {
        PoolUserPurchase {
            pool_id,
            usr_addr,
            total_buy_amount: 0,
            buy_history: table::new(ctx),
            data: vec_map::empty()
        }
    }

    public fun set_data(self: &mut PoolUserPurchase, data: VecMap<String, String>) {
        self.data = data;
    }

    public fun add_new_buy_tx(self: &mut PoolUserPurchase, tx_hash: vector<u8>, amount: u256) {
        assert!(!self.buy_history.contains(tx_hash), ETxHashExisted);
        self.buy_history.add(tx_hash, amount);
        self.total_buy_amount = self.total_buy_amount + amount;
    }

    public fun total_buy_txs_count(self: &PoolUserPurchase): u64 {
        self.buy_history.length()
    }

    public fun user_address(self: &PoolUserPurchase): address {
        self.usr_addr
    }

    public fun total_buy_amount(self: &PoolUserPurchase): u256 {
        self.total_buy_amount
    }

    public fun data(self: &PoolUserPurchase): &VecMap<String, String> { &self.data }

    public fun pool_id(self: &PoolUserPurchase): ID { self.pool_id }
}   