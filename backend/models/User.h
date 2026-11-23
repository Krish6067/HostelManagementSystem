#pragma once
#include <drogon/orm/DbClient.h>
#include <drogon/orm/Mapper.h>
#include <string>

struct User {
    int64_t id{};
    std::string email;
    std::string password_hash;
    std::string role; // 'STUDENT','PARENT',... keep as string for simplicity
    bool is_active{true};
    // timestamps are auto-managed by DB
};

// Provide a type alias for the Drogon ORM mapper
using UserMapper = drogon::orm::Mapper<User>;
