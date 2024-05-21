#ifndef TIMER_H
#define TIMER_H

#include <chrono>

class Timer {
public:
    Timer(bool start_immediately = false);
    void start();
    void stop();
    float elapsed();

private:
    bool is_running;
    std::chrono::high_resolution_clock::time_point t1, t2;
};

#endif // TIMER_H