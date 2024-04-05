#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <Node.hpp>

namespace godot {
    class GDNScraper : public Node {
        GODOT_CLASS(GDNScraper, Node)

    public:
        int baseAddress;
        static void _register_methods();

        int open(String processName);
        int64_t scrape(int address, int size);
        int64_t scrape_abs(int address, int size);
        int getLastError();

        void _init(); // our initializer called by Godot
    };
}

bool process_setup();

#endif //GDNATIVE_LIBRARY_H
