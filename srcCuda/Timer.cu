#include "Timer.h"
#include <iostream>

Timer::Timer(bool start_immediately) : is_running(false) {
    if (start_immediately) {
        start();
    }
}

void Timer::start() {
    t1 = std::chrono::high_resolution_clock::now();
    is_running = true;
}

void Timer::stop() {
    if (is_running) {
        t2 = std::chrono::high_resolution_clock::now();
        is_running = false;
    }
}

float Timer::elapsed() {
    if (is_running) {
        auto t2_temp = std::chrono::high_resolution_clock::now();
        std::chrono::duration<float> time_span = t2_temp - t1;
        return time_span.count();
    }
    else {
        std::chrono::duration<float> time_span = t2 - t1;
        return time_span.count();
    }
}