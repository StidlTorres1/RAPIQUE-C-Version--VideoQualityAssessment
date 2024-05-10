#include "FunctionLogger.h"

FunctionLogger::FunctionLogger(const std::string& output_file) : output_file_(output_file) {}

void FunctionLogger::startTimer(const std::string& video_name, const std::string& function_name) {
    std::string key = video_name + "::" + function_name;
    active_timers_[key].start();
}

void FunctionLogger::stopTimer(const std::string& video_name, const std::string& function_name) {
    std::string key = video_name + "::" + function_name;
    if (active_timers_.find(key) != active_timers_.end()) {
        //active_timers_[key].stop();
        float time_elapsed = active_timers_[key].elapsed();
        video_function_stats_[video_name][function_name].execution_count++;
        video_function_stats_[video_name][function_name].total_exec_time += time_elapsed;
        //writeXML();
    }
}

void FunctionLogger::writeXML() {
    std::ofstream file(output_file_);
    if (!file.is_open()) {
        //std::cerr << "Error opening the file for writing XML\n";
        return;
    }

    file << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" << std::endl
        << "<VideoFunctionStats>" << std::endl;

    for (const auto& video_pair : video_function_stats_) {
        file << "  <Video name=\"" << video_pair.first << "\">" << std::endl;

        for (const auto& function_pair : video_pair.second) {
            const auto& data = function_pair.second;
            // Calculate the average execution time with higher precision if needed
            double avg_exec_time = data.execution_count > 0 ? static_cast<double>(data.total_exec_time) / data.execution_count : 0.0;

            file << "   <Function name=\"" << function_pair.first << "\">" << std::endl
                << "    <ExecutionCount>" << data.execution_count << "</ExecutionCount>" << std::endl
                << "    <AverageExecTime>" << std::fixed << std::setprecision(6) << avg_exec_time << "</AverageExecTime>" << std::endl
                << "   </Function>" << std::endl;
        }

        file << "  </Video>" << std::endl;
    }

    file << "</VideoFunctionStats>" << std::endl;
    file.close();
}
