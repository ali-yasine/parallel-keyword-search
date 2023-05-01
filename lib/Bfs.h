#ifndef __BFS_H__
#define __BFS_H__
#include "graph.h"

struct Bfs_instance {
    int num_nodes;
    int* visited;
    
    void init(int num_nodes) {
        this->num_nodes = num_nodes;
        visited = (int*) calloc(num_nodes, sizeof(int));
    }

    void add(int node) {
        visited[node] = 1;
    }

    int size() {
        int count = 0;
        for (int i = 0; i < this->num_nodes; ++i) {
            if (visited[i] == 1) {
                count++;
            }
        }
        return count;
    }

    bool is_visited(int node) {
        return visited[node] == 1;
    }

    void destroy() {
        free(visited);
    }

};

#endif