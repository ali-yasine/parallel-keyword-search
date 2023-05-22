#ifndef UTIL_H
#define UTIL_H
#include <string>
#include <vector>
#include <random>
#include <unordered_map>
#include <unordered_set>
#include "graph.h"

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

void getQueryVertices(const std::vector<std::string>& query,
                      const std::unordered_map<int, std::string>& node_map,
                      const int num_nodes,
                      std::vector<std::unordered_set<int>>& query_vertices);


void identify_central(const int num_nodes, bool* C_identifier, 
                      const bool* F_identifier, const  int* M, const int query_num);

void enqueue_frontier(const int num_nodes, bool* F_identifier, bool* frontier, int& frontier_size);

bool is_keyword(int node, const std::vector<std::unordered_set<int>>& keyword_nodes);

void getMinActivations(const float* node_weights, const int num_nodes, 
                       const float alpha, const float avg_hops, int* min_activations);
                       
float score(const CooGraph* graph, const int central_node, const float* node_weights, const int* M, const int query_num, const float lambda=0.2f);

void dequeue_frontier(bool* frontier, int& frontier_size, const int num_nodes);

bool check_terminate(const bool* C_identifier, const int num_nodes, const int k);

#endif