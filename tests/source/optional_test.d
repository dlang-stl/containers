import core.experimental.stdcpp.optional;

unittest
{
    optional!int o1;
    optional!int o2 = nullopt;
    auto o3 = optional!int(in_place, 10);
    assert(!o1 && o2.has_value == false && o3 && o3.value == 10);
    o1 = 20;
    assert(o1 && o1.value == 20);
    o1 = nullopt;
    assert(!o1);

    optional!(void*) o4;
    auto o5 = optional!(void*)(in_place, cast(void*)0x1234);
    assert(!o4 && o5 && o5.value == cast(void*)0x1234);
    o5 = null;
    assert(o5.value == null);
    o5.reset();
    assert(!o5);

    {
        optional!Complex o6;
        auto o7 = optional!Complex(in_place, Complex(20));
        assert(!o6 && o7 && o7.value.buffer[0] == 20 && o7.value.buffer[$-1] == 20);
        optional!Complex o8 = o6;
        assert(!o8);
        optional!Complex o9 = o7;
        assert(o9 && o9.value.buffer[0] == 20 && o9.value.buffer[$-1] == 20);
        o9 = o6;
        assert(!o9);
        o6 = o7;
        assert(o6 && o6.value.buffer[0] == 20 && o6.value.buffer[$-1] == 20);
        o7.reset();
        assert(!o7);
    }
    assert(opt_refCount == 0);
}

extern(C++):

__gshared opt_refCount = 0;

struct Complex
{
    bool valid = false;
    int[16] buffer;
    this(int val)
    {
        valid = true;
        buffer[] = val;
        ++opt_refCount;
    }
    this(ref inout(Complex) rhs) inout
    {
        valid = rhs.valid;
        if (rhs.valid)
        {
            buffer[] = rhs.buffer[]; ++opt_refCount;
        }
    }
    ~this()
    {
        if (valid)
            --opt_refCount;
    }
}

//int fromC_val(optional!int);
//int fromC_ref(ref const(optional!int));
//int fromC_val(optional!(void*));
//int fromC_ref(ref const(optional!(void*)));
//int fromC_val(optional!Complex);
//int fromC_ref(ref const(optional!Complex));
