#include <gtest/gtest.h>
#include <chrono>
#include <thread>
#include "Timer.h" // Ensure this matches the correct header file name

class TimerTest : public ::testing::Test {
protected:
    TimerTest() = default;

    // Utility function to sleep for a certain number of milliseconds
    void sleepMilliseconds(int ms) {
        std::this_thread::sleep_for(std::chrono::milliseconds(ms));
    }
};

// Test Timer with immediate start
TEST_F(TimerTest, ImmediateStart) {
    Timer timer(true);
    sleepMilliseconds(100); // Sleep for 100ms
    float elapsed_time = timer.elapsed();
    EXPECT_NEAR(elapsed_time, 0.1, 0.02); // Expect roughly 100ms (+/- 20ms)
}

// Test Timer with manual start
TEST_F(TimerTest, ManualStartStop) {
    Timer timer;
    timer.start();
    sleepMilliseconds(100); // Sleep for 100ms
    timer.stop();
    float elapsed_time = timer.elapsed();
    EXPECT_NEAR(elapsed_time, 0.1, 0.02); // Expect roughly 100ms (+/- 20ms)
}

// Test Timer elapsed while running
TEST_F(TimerTest, ElapsedWhileRunning) {
    Timer timer;
    timer.start();
    sleepMilliseconds(100); // Sleep for 100ms
    float elapsed_time = timer.elapsed();
    EXPECT_NEAR(elapsed_time, 0.1, 0.02); // Expect roughly 100ms (+/- 20ms)
}

// Test Timer elapsed after stopping
TEST_F(TimerTest, ElapsedAfterStop) {
    Timer timer;
    timer.start();
    sleepMilliseconds(100); // Sleep for 100ms
    timer.stop();
    float elapsed_time_after_stop = timer.elapsed();
    // Sleep for additional 100ms to ensure timer has stopped
    sleepMilliseconds(100);
    float elapsed_time_final = timer.elapsed();
    EXPECT_NEAR(elapsed_time_after_stop, 0.1, 0.02); // Expect roughly 100ms (+/- 20ms)
    EXPECT_FLOAT_EQ(elapsed_time_final, elapsed_time_after_stop); // Timer is not running, should not increase
}

/* Main function - entry point for running all tests
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}*/
