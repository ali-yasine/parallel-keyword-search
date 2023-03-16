#ifndef __BFS_H__
#define __BFS_H__
#include "graph.h"
#include <unordered_set>

using std::unordered_set;

struct Bfs_instance {
    unordered_set<int> visited;  

    void init() {
    }

    void add(int node) {
        visited.insert(node);
    }
    bool contains(int node) {
        return visited.find(node) != visited.end();
    }
    
};

#endif