import core.experimental.stdcpp.allocator;


extern(C++) align(64) struct AlignedStruct
{
    int x;
}

extern(C++) struct MyStruct
{
    int* a;
    double* b;
    MyStruct* c;
    MyStruct* d;
    AlignedStruct* e;
    AlignedStruct* f;
}

extern(C++) MyStruct cpp_alloc();
extern(C++) void cpp_free(ref MyStruct s);

unittest
{
    // alloc in C++, delete in D
    MyStruct s = cpp_alloc();
    allocator!int().deallocate(s.a, 42);
    allocator!double().deallocate(s.b, 42);
    allocator!MyStruct().deallocate(s.c, 42);
    allocator!MyStruct().deallocate(s.d, 2000);
    allocator!AlignedStruct().deallocate(s.e, 2);
    allocator!AlignedStruct().deallocate(s.f, 200);

    // alloc in D, delete in C++
    s.a = allocator!int().allocate(43);
    s.b = allocator!double().allocate(43);
    s.c = allocator!MyStruct().allocate(43);
    s.d = allocator!MyStruct().allocate(2000);
    s.e = allocator!AlignedStruct().allocate(2);
    s.f = allocator!AlignedStruct().allocate(200);
    cpp_free(s);
}
