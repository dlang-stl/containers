#include <optional>

struct Complex
{
    int buffer[16] = { 10 };

    Complex() {}
    ~Complex() {}
};

int fromC_val(std::optional<int>);
int fromC_ref(const std::optional<int>&);
int fromC_val(std::optional<void*>);
int fromC_ref(const std::optional<void*>&);
int fromC_val(std::optional<Complex>);
int fromC_ref(const std::optional<Complex>&);
