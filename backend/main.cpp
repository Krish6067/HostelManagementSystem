#include "AuthController.h"
#include "../middleware/AuthMiddleware.h"
#include "../middleware/RoleMiddleware.h"

int main()
{
    // Register controllers
    drogon::app().registerController(std::make_shared<AuthController>());

    // Register global authentication middleware (skip login/refresh routes)
    drogon::app().registerPreHandler([](const drogon::HttpRequestPtr &req,
                                      std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
        // paths that do not require auth
        std::string path = req->path();
        if (path == "/api/auth/login" || path == "/api/auth/refresh") {
            callback(drogon::HttpResponse::newHttpResponse());
            return;
        }
        // invoke AuthMiddleware
        AuthMiddleware::instance()->doFilter(req, std::move(callback));
    });

    // Load configuration from config.json (placed in the working directory)
    // Drogon will automatically read config.json if present.
    // Register health controller (route already defined in the controller class)
    drogon::app()
        .loadConfigFile("config.json")
        .addListener("0.0.0.0", 8080) // default port, can be changed in config.json
        .run();
    return 0;
}

