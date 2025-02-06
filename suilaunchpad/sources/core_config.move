module suilaunchpad::core_config {

    public struct CoreConfig has copy, drop, store {
        protocol_fee_pct: u8
    }

    public fun new(
        protocol_fee_pct: u8,
    ): CoreConfig {
        CoreConfig {
            protocol_fee_pct
        }
    }

    public fun protocol_fee_pct(config: &CoreConfig): u8 {
        config.protocol_fee_pct
    }
}