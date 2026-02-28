#include <iostream>
#include <chrono>
#include <thread>
#include <csignal>
#include <atomic>
#include <fmt/core.h>
#include <ctime>

std::atomic<bool> running(true);

void signal_handler(int) {
    running = false;
}

std::string now() {
    std::time_t t = std::time(nullptr);
    char buf[64];
    std::strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", std::localtime(&t));
    return std::string(buf);
}

int main() {
    std::signal(SIGTERM, signal_handler);
    std::signal(SIGINT, signal_handler);

    fmt::print("[{}] App started\n", now());

    while (running) {
        fmt::print("[{}] Alive\n", now());
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    fmt::print("[{}] App stopped\n", now());
    return 0;
}
