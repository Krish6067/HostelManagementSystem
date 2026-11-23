#pragma once

#include <drogon/HttpResponse.h>
#include <json/json.h>

class ResponseUtils {
public:
    // Successful response
    static drogon::HttpResponsePtr success(const Json::Value &data, const std::string &message = "OK") {
        Json::Value root;
        root["success"] = true;
        root["message"] = message;
        root["data"] = data;
        root["error_code"] = Json::nullValue;
        auto resp = drogon::HttpResponse::newHttpJsonResponse(root);
        resp->setStatusCode(drogon::k200OK);
        return resp;
    }
    // Error response
    static drogon::HttpResponsePtr error(const std::string &message, int httpStatus = 400, const std::string &code = "ERROR") {
        Json::Value root;
        root["success"] = false;
        root["message"] = message;
        root["data"] = Json::nullValue;
        root["error_code"] = code;
        auto resp = drogon::HttpResponse::newHttpJsonResponse(root);
        resp->setStatusCode(static_cast<drogon::HttpResponseStatus>(httpStatus));
        return resp;
    }
};
