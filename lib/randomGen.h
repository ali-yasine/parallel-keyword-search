#ifndef RANDOMGEN_H
#define RANDOMGEN_H

#include <random>

class RandomGen {
    private:
        std::mt19937 gen;
        std::uniform_int_distribution<int> dist;
    public:
        RandomGen(int min, int max) {
            std::random_device rd;
            gen = std::mt19937(rd());
            dist = std::uniform_int_distribution<int>(min, max);
        }
        int operator()() { return dist(gen); }
};

#endif