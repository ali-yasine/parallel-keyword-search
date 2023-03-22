#ifndef __BFS_H__
#define __BFS_H__
#include "graph.h"
#include <unordered_set>

using std::unordered_set;

struct Bfs_instance {

    unordered_set<int> visited;  
    unordered_set<int> frontier;
    
    void init() {
        visited = unordered_set<int>();
        frontier = unordered_set<int>();
    }

    void add(int node) {
        frontier.insert(node);
    }

    void remove(int node) {
        frontier.erase(node);
        visited.insert(node);
    }

    int frontier_size() {
        return frontier.size();
    }

    int visited_size() {
        return visited.size();
    }

    bool is_visited(int node) {
        return visited.find(node) != visited.end();
    }

    bool is_frontier(int node) {
        return frontier.find(node) != frontier.end();
    }
};

#endif