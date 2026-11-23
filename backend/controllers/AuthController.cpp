#include "AuthController.h"
#include "../utils/PasswordUtils.h"
#include "../utils/TokenUtils.h"
#include "../utils/ResponseUtils.h"
#include <drogon/HttpRequest.h>
#include <drogon/HttpResponse.h>
#include <drogon/orm/Mapper.h>
#include <drogon/orm/DbClient.h>
#include <json/json.h>

using namespace drogon;
using namespace drogon::orm;

void AuthController::login(const HttpRequestPtr &req,
                           std::function<void(const HttpResponsePtr &)> &&callback) const {
    Json::Value json;
    try {
        json = req->getJsonObject();
    } catch (...) {
        callback(ResponseUtils::error("Invalid JSON", 400, "BAD_REQUEST"));
        return;
    }
    std::string email = json.get("email", "").asString();
    std::string password = json.get("password", "").asString();
    if (email.empty() || password.empty()) {
        callback(ResponseUtils::error("Email and password required", 400, "MISSING_FIELDS"));
        return;
    }
    // Query user
    auto client = app().getDbClient();
    auto mapper = Mapper<User>(client);
    try {
        auto users = mapper.findOne(Criterion("email", CompareOperator::EQ, email));
        if (!users.id) {
            callback(ResponseUtils::error("Invalid credentials", 401, "INVALID_CREDENTIALS"));
            return;
        }
        // Verify password hash
        if (!PasswordUtils::verify(password, users.password_hash)) {
            // log attempt maybe
            callback(ResponseUtils::error("Invalid credentials", 401, "INVALID_CREDENTIALS"));
            return;
        }
        // Create JWT
        std::string token = TokenUtils::createToken(users.id, users.role);
        Json::Value data;
        data["access_token"] = token;
        data["refresh_token"] = TokenUtils::createRefreshToken(users.id); // simple for now
        data["expires_in"] = TokenUtils::accessTokenTTL();
        callback(ResponseUtils::success(data, "Login successful"));
    } catch (const std::exception &e) {
        callback(ResponseUtils::error(e.what(), 500, "SERVER_ERROR"));
    }
}

void AuthController::refresh(const HttpRequestPtr &req,
                             std::function<void(const HttpResponsePtr &)> &&callback) const {
    Json::Value json;
    try { json = req->getJsonObject(); } catch (...) {
        callback(ResponseUtils::error("Invalid JSON", 400, "BAD_REQUEST"));
        return; }
    std::string refreshToken = json.get("refresh_token", "").asString();
    if (refreshToken.empty()) {
        callback(ResponseUtils::error("Refresh token required", 400, "MISSING_TOKEN"));
        return;
    }
    // Verify and rotate (very simple – in production you would store/lookup token hashes)
    auto payload = TokenUtils::verifyRefreshToken(refreshToken);
    if (!payload.valid) {
        callback(ResponseUtils::error("Invalid refresh token", 401, "INVALID_TOKEN"));
        return;
    }
    std::string newAccess = TokenUtils::createToken(payload.userId, payload.role);
    Json::Value data;
    data["access_token"] = newAccess;
    data["expires_in"] = TokenUtils::accessTokenTTL();
    callback(ResponseUtils::success(data, "Token refreshed"));
}

void AuthController::logout(const HttpRequestPtr &req,
                            std::function<void(const HttpResponsePtr &)> &&callback) const {
    // Stateless JWT – client just discards token. Optionally you could add token to a revocation list.
    callback(ResponseUtils::success(Json::nullValue, "Logged out"));
}

void AuthController::me(const HttpRequestPtr &req,
                         std::function<void(const HttpResponsePtr &)> &&callback) const {
    // AuthMiddleware should have set user info in request attributes
    auto user = req->getAttributes()->get<std::shared_ptr<User>>("auth_user");
    if (!user) {
        callback(ResponseUtils::error("Unauthorized", 401, "UNAUTHORIZED"));
        return;
    }
    Json::Value data;
    data["id"] = static_cast<Json::Int64>(user->id);
    data["email"] = user->email;
    data["role"] = user->role;
    callback(ResponseUtils::success(data, "User info"));
}

void AuthController::changePassword(const HttpRequestPtr &req,
                                   std::function<void(const HttpResponsePtr &)> &&callback) const {
    auto user = req->getAttributes()->get<std::shared_ptr<User>>("auth_user");
    if (!user) {
        callback(ResponseUtils::error("Unauthorized", 401, "UNAUTHORIZED"));
        return;
    }
    Json::Value json;
    try { json = req->getJsonObject(); } catch (...) {
        callback(ResponseUtils::error("Invalid JSON", 400, "BAD_REQUEST"));
        return; }
    std::string current = json.get("current_password", "").asString();
    std::string newPass = json.get("new_password", "").asString();
    std::string confirm = json.get("confirm_password", "").asString();
    if (current.empty() || newPass.empty() || confirm.empty()) {
        callback(ResponseUtils::error("All fields required", 400, "MISSING_FIELDS"));
        return;
    }
    if (newPass != confirm) {
        callback(ResponseUtils::error("New passwords do not match", 400, "PASSWORD_MISMATCH"));
        return;
    }
    if (!PasswordUtils::verify(current, user->password_hash)) {
        callback(ResponseUtils::error("Current password incorrect", 401, "INVALID_CURRENT_PASSWORD"));
        return;
    }
    if (PasswordUtils::verify(newPass, user->password_hash)) {
        callback(ResponseUtils::error("New password cannot be same as current", 400, "PASSWORD_REUSE"));
        return;
    }
    // Optional strength check – simple length >=8
    if (newPass.length() < 8) {
        callback(ResponseUtils::error("Password too short (min 8 chars)", 400, "WEAK_PASSWORD"));
        return;
    }
    std::string newHash = PasswordUtils::hash(newPass);
    try {
        auto client = app().getDbClient();
        client->execSqlAsyncFuture("UPDATE users SET password_hash = ? WHERE id = ?", {newHash, user->id})
            .get();
        callback(ResponseUtils::success(Json::nullValue, "Password changed successfully"));
    } catch (const std::exception &e) {
        callback(ResponseUtils::error(e.what(), 500, "SERVER_ERROR"));
    }
}
