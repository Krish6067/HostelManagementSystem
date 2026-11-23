#include "HealthController.h"
#include <drogon/HttpResponse.h>
#include <drogon/Json.h>

void HealthController::health(const drogon::HttpRequestPtr &req,
                              std::function<void(const drogon::HttpResponsePtr &)> &&callback) const
{
    // Simple health check response
    auto resp = drogon::HttpResponse::newHttpJsonResponse({{"status", "ok"}, {"message", "Hostel Management System backend is running"}});
    resp->setStatusCode(drogon::k200OK);
    callback(resp);
}
