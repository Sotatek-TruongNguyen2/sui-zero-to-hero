module suins::core_config;

use std::string::String;
use sui::vec_set::{Self, VecSet};
use sui::vec_map::{VecMap};

#[error]
const EInvalidLength: vector<u8> = b"Invalid length for the label part of the domain.";

#[error]
const EInvalidTld: vector<u8> = b"Invalid TLD";

#[error]
const ESubnameNotSupported: vector<u8> = b"Subdomains are not supported for sales.";

public struct CoreConfig has store {
    /// Public key of the API server. Currently only used for direct setup.
    public_key: vector<u8>,
    /// Minimum length of the label part of the domain. This is different from
    /// the base `domain` checks. This is our minimum acceptable length (for sales).
    min_label_length: u8,
    /// Maximum length of the label part of the domain.
    max_label_length: u8,
      /// List of valid TLDs for registration / renewals.
    valid_tlds: VecSet<String>,
    /// The `PaymentIntent` version that can be used for handling sales.
    payments_version: u8,
     /// Maximum number of years available for a domain.
    max_years: u8,
    // Extra fields for future use.
    extra: VecMap<String, String>,
}

public fun new(
    public_key: vector<u8>,
    min_label_length: u8,
    max_label_length: u8,
    payments_version: u8,
    max_years: u8,
    valid_tlds: vector<String>,
    extra: VecMap<String, String>,
): CoreConfig {
    CoreConfig {
        public_key,
        min_label_length,
        max_label_length,
        payments_version,
        max_years,
        valid_tlds: vec_set::from_keys(valid_tlds),
        extra,
    }
}


public fun public_key(config: &CoreConfig): vector<u8> {
    config.public_key
}

public fun min_label_length(config: &CoreConfig): u8 {
    config.min_label_length
}

public fun max_label_length(config: &CoreConfig): u8 {
    config.max_label_length
}

public fun is_valid_tld(config: &CoreConfig, tld: &String): bool {
    config.valid_tlds.contains(tld)
}

public fun payments_version(config: &CoreConfig): u8 {
    config.payments_version
}

public fun max_years(config: &CoreConfig): u8 {
    config.max_years
}