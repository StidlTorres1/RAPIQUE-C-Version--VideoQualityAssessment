#pragma once
#include <chrono>

class Timer {
private:
    std::chrono::high_resolution_clock::time_point t1, t2;
    bool is_running;

public:
    Timer(bool start_immediately = false);
    void start();
    void stop();
    float elapsed(); // New method to get elapsed time
};
