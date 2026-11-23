#pragma once

#include <string>

struct Student {
    int64_t id{};
    int64_t user_id{};
    std::string student_number;
    std::string first_name;
    std::string last_name;
    std::string dob; // YYYY-MM-DD
    std::string phone;
    int64_t hostel_id{}; // nullable
    int64_t room_id{};   // nullable
    // timestamps managed by DB
};

using StudentMapper = drogon::orm::Mapper<Student>;
