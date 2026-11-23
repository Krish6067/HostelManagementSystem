#pragma once

#include <drogon/HttpController.h>
#include <drogon/HttpResponse.h>

class AuthController : public drogon::HttpController<AuthController>
{
public:
    // Register routes
    METHOD_LIST_BEGIN
    ADD_METHOD_TO(AuthController::login, "/api/auth/login", drogon::Post);
    ADD_METHOD_TO(AuthController::refresh, "/api/auth/refresh", drogon::Post);
    ADD_METHOD_TO(AuthController::logout, "/api/auth/logout", drogon::Post);
    ADD_METHOD_TO(AuthController::me, "/api/auth/me", drogon::Get);
    ADD_METHOD_TO(AuthController::changePassword, "/api/auth/change-password", drogon::Post);
    METHOD_LIST_END

    void login(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
    void refresh(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
    void logout(const drogon::HttpRequestPtr &req,
                std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
    void me(const drogon::HttpRequestPtr &req,
            std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
    void changePassword(const drogon::HttpRequestPtr &req,
                        std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
};
