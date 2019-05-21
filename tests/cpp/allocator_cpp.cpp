#include <memory>

#if defined(_MSC_VER)
__declspec(align(64))
#endif
struct AlignedStruct
{
    int x;
}
#if !defined(_MSC_VER)
__attribute__((aligned(64)))
#endif
;

struct MyStruct
{
    int *a;
    double *b;
    MyStruct *c;
    MyStruct *d;
    AlignedStruct *e;
    AlignedStruct *f;
};

MyStruct cpp_alloc()
{
    MyStruct r;
    r.a = std::allocator<int>().allocate(42);
    r.b = std::allocator<double>().allocate(42);
    r.c = std::allocator<MyStruct>().allocate(42);
    r.d = std::allocator<MyStruct>().allocate(2000);
    r.e = std::allocator<AlignedStruct>().allocate(2);
    r.f = std::allocator<AlignedStruct>().allocate(200);
    return r;
}

void cpp_free(MyStruct& s)
{
    std::allocator<int>().deallocate(s.a, 43);
    std::allocator<double>().deallocate(s.b, 43);
    std::allocator<MyStruct>().deallocate(s.c, 43);
    std::allocator<MyStruct>().deallocate(s.d, 2000);
    std::allocator<AlignedStruct>().deallocate(s.e, 2);
    std::allocator<AlignedStruct>().deallocate(s.f, 200);
}
