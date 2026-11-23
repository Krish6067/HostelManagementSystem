#pragma once

#include <string>
#include <chrono>

struct TokenPayload {
    bool valid{false};
    int64_t userId{0};
    std::string role;
};

class TokenUtils {
public:
    // Create access token (short‑lived)
    static std::string createToken(int64_t userId, const std::string &role);
    // Create refresh token (long‑lived)
    static std::string createRefreshToken(int64_t userId);
    // Verify refresh token and extract payload
    static TokenPayload verifyRefreshToken(const std::string &token);
    // Validate access token and extract payload (used by AuthMiddleware)
    static TokenPayload verifyAccessToken(const std::string &token);
    // TTL values (seconds)
    static constexpr long accessTokenTTL() { return 3600; } // 1 hour
    static constexpr long refreshTokenTTL() { return 7 * 24 * 3600; } // 7 days
};
