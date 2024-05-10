#pragma once
#include <map>
#include <string>
#include <fstream>
#include <iostream>
#include <iomanip>
#include "Timer.h"

struct FunctionData {
    int execution_count = 0;
    float total_exec_time = 0.0;
};

class FunctionLogger {
private:
    std::map<std::string, std::map<std::string, FunctionData>> video_function_stats_;
    std::map<std::string, Timer> active_timers_;
    std::string output_file_;

public:
    FunctionLogger(const std::string& output_file);
    void startTimer(const std::string& video_name, const std::string& function_name);
    void stopTimer(const std::string& video_name, const std::string& function_name);
    void writeXML();
};