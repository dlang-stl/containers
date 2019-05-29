// Written in the D programming language.

/**
 * Interface to C++ <typeinfo>
 *
 * Copyright: Copyright (c) 2016 D Language Foundation
 * License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(HTTP digitalmars.com, Walter Bright)
 * Source:    $(DRUNTIMESRC core/stdcpp/_typeinfo.d)
 */

module core.experimental.stdcpp.typeinfo;

import core.experimental.stdcpp.exception;


version (CppRuntime_DigitalMars)
{
    extern (C++, "std"):

    class type_info
    {
        void* pdata;

    public:
        //virtual ~this();
        void dtor() { }     // reserve slot in vtbl[]

        //bool operator==(const type_info rhs) const;
        //bool operator!=(const type_info rhs) const;
        final bool before(const type_info rhs) const;
        final const(char)* name() const;
    protected:
        //type_info();
    private:
        //this(const type_info rhs);
        //type_info operator=(const type_info rhs);
    }

    class bad_cast : exception
    {
        this() nothrow { }
        this(const bad_cast) nothrow { }
        //bad_cast operator=(const bad_cast) nothrow { return this; }
        //virtual ~this() nothrow;
        override const(char)* what() const nothrow;
    }

    class bad_typeid : exception
    {
        this() nothrow { }
        this(const bad_typeid) nothrow { }
        //bad_typeid operator=(const bad_typeid) nothrow { return this; }
        //virtual ~this() nothrow;
        override const (char)* what() const nothrow;
    }
}
else version (CppRuntime_Microsoft)
{
    import core.experimental.stdcpp.exception;

    extern (C++, "std"):

    struct __type_info_node
    {
        void* _MemPtr;
        __type_info_node* _Next;
    }

    extern __gshared __type_info_node __type_info_root_node;

    class type_info
    {
        //virtual ~this();
        void dtor() { }     // reserve slot in vtbl[]
        //bool operator==(const type_info rhs) const;
        //bool operator!=(const type_info rhs) const;
        final bool before(const type_info rhs) const;
        final const(char)* name(__type_info_node* p = &__type_info_root_node) const;

    private:
        void* pdata;
        char[1] _name;
        //type_info operator=(const type_info rhs);
    }

    class bad_cast : exception
    {
        this(const(char)* msg = "bad cast");
        //virtual ~this();
    }

    class bad_typeid : exception
    {
        this(const(char)* msg = "bad typeid");
        //virtual ~this();
    }
}
else version (CppRuntime_Gcc)
{
    extern (C++, "__cxxabiv1")
    {
        class __class_type_info;
    }

    extern (C++, "std"):

    class type_info
    {
        void dtor1();                           // consume destructor slot in vtbl[]
        void dtor2();                           // consume destructor slot in vtbl[]
        final const(char)* name()() const nothrow {
            return _name[0] == '*' ? _name + 1 : _name;
        }
        final bool before()(const type_info _arg) const {
            import core.stdc.string : strcmp;
            return (_name[0] == '*' && _arg._name[0] == '*')
                ? _name < _arg._name
                : strcmp(_name, _arg._name) < 0;
        }
        //bool operator==(const type_info) const;
        bool __is_pointer_p() const;
        bool __is_function_p() const;
        bool __do_catch(const type_info, void**, uint) const;
        bool __do_upcast(const __class_type_info, void**) const;

        const(char)* _name;
        this(const(char)*);
    }

    class bad_cast : exception
    {
        this();
        //~this();
        override const(char)* what() const;
    }

    class bad_typeid : exception
    {
        this();
        //~this();
        override const(char)* what() const;
    }
}
else version (CppRuntime_Clang)
{
    extern (C++, "std"):

    static assert(__traits(classInstanceSize, type_info)  == 16);
    static assert(__traits(classInstanceSize, bad_cast)   ==  8);
    static assert(__traits(classInstanceSize, bad_typeid) ==  8);

    class type_info
    {
        ~this() {}

    final:
        this(const ref type_info);
        // identity assignment operator overload is illegal
        ref type_info opAssign_(const ref type_info);

        version(LIBCPP_HAS_NONUNIQUE_TYPEINFO)
        {
            pragma(inline, true) extern(D)
            int __compare_nonunique_names(const ref type_info __arg) const nothrow
            {
                return __builtin_strcmp(name(), __arg.name());
            }
        }

        version (Windows)
        {
            struct {
                char*   __undecorated_name;
                char[1] __decorated_name;
            }

            int __compare(const ref type_info __rhs) const nothrow;
        }
        else version (LIBCPP_HAS_NONUNIQUE_TYPEINFO)
        {
            // A const char* with the non-unique RTTI bit possibly set.
            protected uintptr_t __type_name;
            extern(D) this(const(char*) __n) { this.__type_name = cast(uintptr_t) __n; }
        }
        else
        {
            protected const(char*) __type_name;
            extern(D) this(const(char*) __n) { this.__type_name = __n; }
        }

        version (Windows)
        {
            const(char)* name() const nothrow;

            pragma(inline, true) extern(D)
            bool before(const ref type_info __arg) const nothrow
            {
                return __compare(__arg) < 0;
            }

            size_t hash_code() const nothrow;

            bool opEquals(const ref type_info __arg) const nothrow
            { return __compare(__arg) == 0; }
        }
        else version(LIBCPP_HAS_NONUNIQUE_TYPEINFO)
        {
            pragma(inline, true) extern(D)
            const(char*) name() const nothrow
            {
                return cast(const char*)(
                    __type_name & ~_LIBCPP_NONUNIQUE_RTTI_BIT);
            }

            pragma(inline, true) extern(D)
            bool before(const ref type_info __arg) const nothrow
            {
                if (!((__type_name & __arg.__type_name) & _LIBCPP_NONUNIQUE_RTTI_BIT))
                    return __type_name < __arg.__type_name;
                return __compare_nonunique_names(__arg) < 0;
            }

            pragma(inline, true) extern(D)
            size_t hash_code() const nothrow
            {
                if (!(__type_name & _LIBCPP_NONUNIQUE_RTTI_BIT))
                    return __type_name;

                const char* ptr = name();
                size_t hash = 5381;
                for (char c = *ptr; c != '\0'; ++ptr)
                    __hash = (__hash * 33) ^ __c;
                return __hash;
            }

            pragma(inline, true) extern(D)
            bool opEquals(const ref type_info __arg) const nothrow
            {
                if (__type_name == __arg.__type_name)
                    return true;

                if (!((__type_name & __arg.__type_name) & _LIBCPP_NONUNIQUE_RTTI_BIT))
                    return false;
                return __compare_nonunique_names(__arg) == 0;
            }
        }
        else
        {
            pragma(inline, true) extern(D)
            const(char*) name() const nothrow
            { return __type_name; }

            pragma(inline, true) extern(D)
            bool before(const ref type_info __arg) const nothrow
            { return __type_name < __arg.__type_name; }

            pragma(inline, true) extern(D)
            size_t hash_code() const nothrow
            { return cast(size_t) __type_name; }

            pragma(inline, true) extern(D)
            bool opEquals(const ref type_info __arg) const nothrow
            { return __type_name == __arg.__type_name; }
        }
    }

    class bad_cast : exception
    {
    public:
        this() nothrow;
        ~this() nothrow {}
        override const(char)* what() const nothrow;
    }

    class bad_typeid : exception
    {
    public:
        this() nothrow;
        ~this() nothrow {}
        override const(char)* what() const nothrow;
    }
}
else
    static assert(0, "Missing std::type_info binding for this platform");
