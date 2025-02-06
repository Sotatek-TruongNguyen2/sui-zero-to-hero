// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Defines the `Domain` type and helper functions.
///
/// Domains are structured similar to their web2 counterpart and the rules
/// determining what a valid domain is can be found here:
/// https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax
module suins::domain;

use std::string::{Self, String, utf8};

const EInvalidDomain: u64 = 0;

/// The maximum length of a full domain
const MAX_DOMAIN_LENGTH: u64 = 235;
/// The minimum length of an individual label in a domain.
const MIN_LABEL_LENGTH: u64 = 1;
/// The maximum length of an individual label in a domain.
const MAX_LABEL_LENGTH: u64 = 63;

/// Representation of a valid SuiNS `Domain`.
public struct Domain has copy, drop, store {
    /// Vector of labels that make up a domain.
    ///
    /// Labels are stored in reverse order such that the TLD is always in
    /// position `0`.
    /// e.g. domain "pay.name.sui" will be stored in the vector as ["sui",
    /// "name", "pay"].
    labels: vector<String>,
}

// Construct a `Domain` by parsing and validating the provided string
public fun new(domain: String): Domain {
    assert!(domain.length() <= MAX_DOMAIN_LENGTH, EInvalidDomain);

    let mut labels = split_by_dot(domain);
    validate_labels(&labels);
    labels.reverse();
    Domain {
        labels,
    }
}

/// Converts a domain into a fully-qualified string representation.
public fun to_string(self: &Domain): String {
    let dot = utf8(b".");
    let len = self.labels.length();
    let mut i = 0;
    let mut out = string::utf8(vector::empty());

    while (i < len) {
        let part = &self.labels[(len - i) - 1];
        out.append(*part);

        i = i + 1;
        if (i != len) {
            out.append(dot);
        }
    };

    out
}

/// Returns the `label` in a domain specified by `level`.
///
/// Given the domain "pay.name.sui" the individual labels have the following
/// levels:
/// - "pay" - `2`
/// - "name" - `1`
/// - "sui" - `0`
///
/// This means that the TLD will always be at level `0`.
public fun label(self: &Domain, level: u64): &String {
    &self.labels[level]
}

/// Returns the TLD (Top-Level Domain) of a `Domain`.
///
/// "name.sui" -> "sui"
public fun tld(self: &Domain): &String {
    label(self, 0)
}

/// Returns the SLD (Second-Level Domain) of a `Domain`.
///
/// "name.sui" -> "sui"
public fun sld(self: &Domain): &String {
    label(self, 1)
}

public fun number_of_levels(self: &Domain): u64 {
    self.labels.length()
}

public fun is_subdomain(domain: &Domain): bool {
    number_of_levels(domain) > 2
}

/// Derive the parent of a subdomain.
/// e.g. `subdomain.example.sui` -> `example.sui`
public fun parent(domain: &Domain): Domain {
    let mut labels = domain.labels;
    // we pop the last element and construct the parent from the remaining
    // labels.
    labels.pop_back();

    Domain {
        labels,
    }
}

/// Checks if `parent` domain is a valid parent for `child`.
public fun is_parent_of(parent: &Domain, child: &Domain): bool {
    number_of_levels(parent) < number_of_levels(child) &&
        &parent(child).labels == &parent.labels
}


fun validate_labels(labels: &vector<String>) {
    assert!(!labels.is_empty(), EInvalidDomain);

    let len = labels.length();
    let mut index = 0;

    while (index < len) {
        let label = &labels[index];
        assert!(is_valid_label(label), EInvalidDomain);
        index = index + 1;
    }
}

fun is_valid_label(label: &String): bool {
    let len = label.length();
    let label_bytes = label.as_bytes();
    let mut index = 0;

    if (!(len >= MIN_LABEL_LENGTH && len <= MAX_LABEL_LENGTH)) {
        return false
    };

    while (index < len) {
        let character = label_bytes[index];
        let is_valid_character =
            (0x61 <= character && character <= 0x7A)                   // a-z
                || (0x30 <= character && character <= 0x39)                // 0-9
                || (character == 0x2D && index != 0 && index != len - 1); // '-' not at beginning or end

        if (!is_valid_character) {
            return false
        };

        index = index + 1;
    };

    true
}


/// Splits a string `s` by the character `.` into a vector of subslices,
/// excluding the `.`
fun split_by_dot(mut s: String): vector<String> {
    let dot = utf8(b".");
    let mut parts: vector<String> = vector[];
    while (!s.is_empty()) {
        let index_of_next_dot = s.index_of(&dot);
        let part = s.substring(0, index_of_next_dot);
        parts.push_back(part);

        let len = s.length();
        let start_of_next_part = if (index_of_next_dot == len) {
            len
        } else {
            index_of_next_dot + 1
        };

        s = s.substring(start_of_next_part, len);
    };

    parts
}

// === Tests ===
