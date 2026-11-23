#pragma once

#include <string>

class PasswordUtils {
public:
    // Hash a plain password using Argon2id (libsodium)
    static std::string hash(const std::string &password);
    // Verify a plain password against a stored Argon2id hash
    static bool verify(const std::string &password, const std::string &hash);
};
