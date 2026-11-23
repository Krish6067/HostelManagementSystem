#pragma once

#include <drogon/HttpController.h>

class HealthController : public drogon::HttpController<HealthController>
{
public:
    // Define the routes for this controller
    METHOD_LIST_BEGIN
    // GET /api/health returns a simple JSON indicating the service is alive
    ADD_METHOD_TO(HealthController::health, "/api/health", drogon::Get);
    METHOD_LIST_END

    // Handler function
    void health(const drogon::HttpRequestPtr &req,
                std::function<void(const drogon::HttpResponsePtr &)> &&callback) const;
};
