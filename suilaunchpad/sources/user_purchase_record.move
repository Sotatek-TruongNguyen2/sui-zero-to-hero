module suilaunchpad::user_purchase_record {
    // use sui::table::{Table, Self};
    use sui::vec_map::{Self, VecMap};
    use std::string::String;

    public struct UserPurchaseRecord has store {
        pool_addr: address,
        usr_addr: address,
        total_desired_sell_tokens: u64,
        // buy_history: Table<vector<u8>, bool>,
        /// Additional data which may be stored in a record
        data: VecMap<String, String>,
    }   
    
    // === Errors ===
    // const ETxHashExisted: u64 = 1;

    public fun new(pool_addr: address, usr_addr: address): UserPurchaseRecord {
        UserPurchaseRecord {
            pool_addr,
            usr_addr,
            total_desired_sell_tokens: 0,
            // buy_history: table::new(ctx),
            data: vec_map::empty()
        }
    }

    public fun set_data(self: &mut UserPurchaseRecord, data: VecMap<String, String>) {
        self.data = data;
    }

    public fun add_new_buy_tx(self: &mut UserPurchaseRecord, tx_hash: vector<u8>, amount: u64) {
        // assert!(!self.buy_history.contains(tx_hash), ETxHashExisted);
        // self.buy_history.add(tx_hash, true);
        self.total_desired_sell_tokens = self.total_desired_sell_tokens + amount;
    }

    // public fun total_buy_txs_count(self: &UserPurchaseRecord): u64 {
    //     self.buy_history.length()
    // }

    public fun user_address(self: &UserPurchaseRecord): address {
        self.usr_addr
    }

    public fun total_desired_sell_tokens(self: &UserPurchaseRecord): u64 {
        self.total_desired_sell_tokens
    }

    public fun data(self: &UserPurchaseRecord): &VecMap<String, String> { &self.data }

    public fun pool_addr(self: &UserPurchaseRecord): address { self.pool_addr }
}   