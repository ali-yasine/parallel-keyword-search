#include <vector>
#include <cstdio>
#include <unordered_map>
int main() {
    std::unordered_map<unsigned int, std::vector<unsigned int>> vertex_types {};
    vertex_types[0] = {1, 2, 3};
    for (auto i : vertex_types[0])
        printf("%d\t", i);
    return 0;
}