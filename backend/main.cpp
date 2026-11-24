
#include <drogon/drogon.h>
#include "controllers/AuthController.h"
#include "middleware/AuthMiddleware.h"
#include <cstdlib>
#include <string>

int main()
{
    // Register authentication controller
    drogon::app().registerController(
        std::make_shared<AuthController>()
    );

    // Public authentication routes
    drogon::app().registerPreRoutingAdvice(
        [](const drogon::HttpRequestPtr &req,
           drogon::AdviceCallback &&callback,
           drogon::AdviceChainCallback &&chainCallback)
        {
            const std::string path = req->path();

            if (path == "/api/auth/login" ||
                path == "/api/auth/refresh" ||
                path == "/api/health")
            {
                chainCallback();
                return;
            }

            AuthMiddleware::instance()->doFilter(
                req,
                std::move(callback)
            );
        }
    );

    // Load database and other configuration
    drogon::app().loadConfigFile("config.json");

    // Render provides PORT at runtime
    const char *portEnv = std::getenv("PORT");
    const uint16_t port = portEnv
        ? static_cast<uint16_t>(std::stoi(portEnv))
        : 8080;

    // Listen on Render's assigned port
    drogon::app()
        .addListener("0.0.0.0", port)
        .run();

    return 0;
}
