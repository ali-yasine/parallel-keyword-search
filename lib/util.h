#ifndef UTIL_H
#define UTIL_H
#include <string>
#include <vector>
#include <unordered_map>



void getQueryVertices(const std::vector<std::string>& query,
                      const std::unordered_map<int, std::string>& node_map,
                      const int num_nodes,
                      std::vector<std::vector<int>>& query_vertices);


int getActivationLevel(float node_weight, float alpha, float avg_hops);


void identify_central(const num_nodes, int* C_identifier, const int* F_identifier, const  int* M,
                const int query_num);

void enqueue_frontier(const int num_nodes, int* F_identifier, int* frontier, int& frontier_size);

#endif