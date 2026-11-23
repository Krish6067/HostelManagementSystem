#include "PasswordUtils.h"
#include <sodium.h>
#include <stdexcept>

std::string PasswordUtils::hash(const std::string &password) {
    // Ensure libsodium is initialized
    if (sodium_init() < 0) {
        throw std::runtime_error("libsodium initialization failed");
    }
    const size_t HASH_LEN = crypto_pwhash_STRLEN;
    char hash[HASH_LEN];
    if (crypto_pwhash_str(
            hash,
            password.c_str(),
            password.size(),
            crypto_pwhash_OPSLIMIT_MODERATE,
            crypto_pwhash_MEMLIMIT_MODERATE) != 0) {
        throw std::runtime_error("Password hashing failed (out of memory)");
    }
    return std::string(hash);
}

bool PasswordUtils::verify(const std::string &password, const std::string &hash) {
    if (sodium_init() < 0) {
        throw std::runtime_error("libsodium initialization failed");
    }
    return crypto_pwhash_str_verify(hash.c_str(), password.c_str(), password.size()) == 0;
}
