/**
 * D header file for interaction with C++ std::vector.
 *
 * Copyright: Copyright (c) 2018 D Language Foundation
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/vector.d)
 */

module core.experimental.stdcpp.vector;

///////////////////////////////////////////////////////////////////////////////
// std::vector declaration.
//
// Current caveats :
// - missing noexcept
// - nothrow @trusted @nogc for most functions depend on knowledge
//   of T's construction/destruction/assignment semantics
///////////////////////////////////////////////////////////////////////////////

import core.experimental.stdcpp.allocator;

enum DefaultConstruct { value }

/// Constructor argument for default construction
enum Default = DefaultConstruct();

extern(C++, "std"):

extern(C++, class) struct vector(T, Alloc = allocator!T)
{
    import core.lifetime;

    static assert(!is(T == bool), "vector!bool not supported!");
extern(D):

    ///
    alias size_type = size_t;
    ///
    alias difference_type = ptrdiff_t;
    ///
    alias value_type = T;
    ///
    alias allocator_type = Alloc;
    ///
    alias pointer = T*;
    ///
    alias const_pointer = const(T)*;

    ///
    alias as_array this;

    /// MSVC allocates on default initialisation in debug, which can't be modelled by D `struct`
    @disable this();

    ///
    alias length = size;
    ///
    alias opDollar = length;

    ///
    ref inout(T) front() inout pure nothrow @safe @nogc                     { return this[0]; }
    ///
    ref inout(T) back() inout pure nothrow @safe @nogc                      { return this[$-1]; }


    // WIP...

//    this(size_type count);
//    this(size_type count, ref const(value_type) val);
//    this(size_type count, ref const(value_type) val, ref const(allocator_type) al);
//    this(ref const(vector) x);
//    this(iterator first, iterator last);
//    this(iterator first, iterator last, ref const(allocator_type) al = defaultAlloc);
//    this(const_iterator first, const_iterator last);
//    this(const_iterator first, const_iterator last, ref const(allocator_type) al = defaultAlloc);
//    this(T[] arr)                                                     { this(arr.ptr, arr.ptr + arr.length); }
//    this(T[] arr, ref const(allocator_type) al = defaultAlloc)        { this(arr.ptr, arr.ptr + arr.length); }
//    this(const(T)[] arr)                                              { this(arr.ptr, arr.ptr + arr.length); }
//    this(const(T)[] arr, ref const(allocator_type) al = defaultAlloc) { this(arr.ptr, arr.ptr + arr.length); }

//    ref vector opAssign(ref const(vector) s);

//    ///
//    ref basic_string opOpAssign(string op : "~")(const(T)[] str)            { return append(str); }
    ///
    ref vector opOpAssign(string op : "~")(auto ref T item)           { push_back(forward!item); return this; }

    // Modifiers
    ///
    void push_back(U)(auto ref U element)
    {
        emplace_back(forward!element);
    }

    version (CppRuntime_Microsoft)
    {
        //----------------------------------------------------------------------------------
        // Microsoft runtime
        //----------------------------------------------------------------------------------

        ///
        this(DefaultConstruct) @nogc                                        { _Alloc_proxy(); }
        ///
        this(size_t count)                                                  { T def; this(count, def); }
        ///
        this(size_t count, ref T val)
        {
            _Alloc_proxy();
            _Buy(count);
            scope(failure) _Tidy();
            for (size_t i = 0; i < count; ++i)
                emplace(&_Get_data()._Myfirst[i], val);
            _Get_data()._Mylast = _Get_data()._Myfirst + count;
        }
        ///
        this(T[] array)
        {
            _Alloc_proxy();
            _Buy(array.length);
            scope(failure) _Tidy();
            for (size_t i = 0; i < array.length; ++i)
                emplace(&_Get_data()._Myfirst[i], array[i]);
            _Get_data()._Mylast = _Get_data()._Myfirst + array.length;
        }
//        ///
//        this(Range)(Range r)
////            if (isInputRange!Range && !isInfinite!Range && (hasLength!Range || isForwardRange!Range)) // wtf phobos?!
//        {
//            _Alloc_proxy();
//            static if (false) // hasLength...
//            {
//                // reserve and copy elements
//            }
//            else
//            {
//                // use a push_back loop
//            }
//        }

        ///
        this(this)
        {
            _Alloc_proxy();
            size_t len = size(); // the alloc len should probably keep a few in excess? (check the MS implementation)
            T* src = _Get_data()._Myfirst;
            _Buy(len);
            scope(failure) _Tidy();
            for (size_t i = 0; i < len; ++i)
                emplace(&_Get_data()._Myfirst[i], src[i]);
            _Get_data()._Mylast = _Get_data()._Myfirst + len;
        }

        ///
        ~this()                                                             { _Tidy(); }

        ///
        ref inout(Alloc) get_allocator() inout pure nothrow @safe @nogc     { return _Getal(); }

        ///
        size_type max_size() const pure nothrow @safe @nogc                 { return ((size_t.max / T.sizeof) - 1) / 2; } // HACK: clone the windows version precisely?

        ///
        size_type size() const pure nothrow @safe @nogc                     { return _Get_data()._Mylast - _Get_data()._Myfirst; }
        ///
        size_type capacity() const pure nothrow @safe @nogc                 { return _Get_data()._Myend - _Get_data()._Myfirst; }
        ///
        bool empty() const pure nothrow @safe @nogc                         { return _Get_data()._Myfirst == _Get_data()._Mylast; }
        ///
        inout(T)* data() inout pure nothrow @safe @nogc                     { return _Get_data()._Myfirst; }
        ///
        inout(T)[] as_array() inout pure nothrow @trusted @nogc             { return _Get_data()._Myfirst[0 .. size()]; }
        ///
        ref inout(T) at(size_type i) inout pure nothrow @trusted @nogc      { return _Get_data()._Myfirst[0 .. size()][i]; }

        ///
        ref T emplace_back(Args...)(auto ref Args args)
        {
            if (_Has_unused_capacity())
            {
                emplace(_Get_data()._Mylast, forward!args);
                static if (_ITERATOR_DEBUG_LEVEL == 2)
                    _Orphan_range(_Get_data()._Mylast, _Get_data()._Mylast);
                return *_Get_data()._Mylast++;
            }
            return *_Emplace_reallocate(_Get_data()._Mylast, forward!args);
        }

        ///
        void reserve(const size_type newCapacity)
        {
            if (newCapacity > capacity())
            {
//                if (newCapacity > max_size())
//                    _Xlength();
                _Reallocate_exactly(newCapacity);
            }
        }

        ///
        void shrink_to_fit()
        {
            if (_Has_unused_capacity())
            {
                if (empty())
                    _Tidy();
                else
                    _Reallocate_exactly(size());
            }
        }

        ///
        void pop_back()
        {
            static if (_ITERATOR_DEBUG_LEVEL == 2)
            {
                assert(!empty(), "vector empty before pop");
                _Orphan_range(_Get_data()._Mylast - 1, _Get_data()._Mylast);
            }
            destroy!false(_Get_data()._Mylast[-1]);
            --_Get_data()._Mylast;
        }

    private:
        import core.experimental.stdcpp.xutility : MSVCLinkDirectives;

        // Make sure the object files wont link against mismatching objects
        mixin MSVCLinkDirectives!true;

        pragma(inline, true)
        {
            ref inout(_Base.Alloc) _Getal() inout pure nothrow @safe @nogc       { return _Base._Mypair._Myval1; }
            ref inout(_Base.ValTy) _Get_data() inout pure nothrow @safe @nogc    { return _Base._Mypair._Myval2; }
        }

        void _Alloc_proxy() @nogc
        {
            static if (_ITERATOR_DEBUG_LEVEL > 0)
                _Base._Alloc_proxy();
        }

        void _AssignAllocator(ref const(allocator_type) al) nothrow @nogc
        {
            static if (_Base._Mypair._HasFirst)
                _Getal() = al;
        }

        bool _Buy(size_type _Newcapacity) @trusted @nogc
        {
            _Get_data()._Myfirst = null;
            _Get_data()._Mylast = null;
            _Get_data()._Myend = null;

            if (_Newcapacity == 0)
                return false;

            // TODO: how to handle this in D? kinda like a range exception...
//            if (_Newcapacity > max_size())
//                _Xlength();

            _Get_data()._Myfirst = _Getal().allocate(_Newcapacity);
            _Get_data()._Mylast = _Get_data()._Myfirst;
            _Get_data()._Myend = _Get_data()._Myfirst + _Newcapacity;

            return true;
        }

        static void _Destroy(pointer _First, pointer _Last)
        {
            for (; _First != _Last; ++_First)
                destroy!false(*_First);
        }

        void _Tidy()
        {
            _Base._Orphan_all();
            if (_Get_data()._Myfirst)
            {
                _Destroy(_Get_data()._Myfirst, _Get_data()._Mylast);
                _Getal().deallocate(_Get_data()._Myfirst, capacity());
                _Get_data()._Myfirst = null;
                _Get_data()._Mylast = null;
                _Get_data()._Myend = null;
            }
        }

        size_type _Unused_capacity() const pure nothrow @safe @nogc
        {
            return _Get_data()._Myend - _Get_data()._Mylast;
        }

        bool _Has_unused_capacity() const pure nothrow @safe @nogc
        {
            return _Get_data()._Myend != _Get_data()._Mylast;
        }

        pointer _Emplace_reallocate(_Valty...)(pointer _Whereptr, auto ref _Valty _Val)
        {
            const size_type _Whereoff = _Whereptr - _Get_data()._Myfirst;
            const size_type _Oldsize = size();

            // TODO: what should we do in D? kinda like a range overflow?
//            if (_Oldsize == max_size())
//                _Xlength();

            const size_type _Newsize = _Oldsize + 1;
            const size_type _Newcapacity = _Calculate_growth(_Newsize);

            pointer _Newvec = _Getal().allocate(_Newcapacity);
            pointer _Constructed_last = _Newvec + _Whereoff + 1;
            pointer _Constructed_first = _Constructed_last;

            try
            {
                emplace(_Newvec + _Whereoff, forward!_Val);
                _Constructed_first = _Newvec + _Whereoff;
                if (_Whereptr == _Get_data()._Mylast)
                    _Utransfer!(true, true)(_Get_data()._Myfirst, _Get_data()._Mylast, _Newvec);
                else
                {
                    _Utransfer!true(_Get_data()._Myfirst, _Whereptr, _Newvec);
                    _Constructed_first = _Newvec;
                    _Utransfer!true(_Whereptr, _Get_data()._Mylast, _Newvec + _Whereoff + 1);
                }
            }
            catch (Throwable e)
            {
                _Destroy(_Constructed_first, _Constructed_last);
                _Getal().deallocate(_Newvec, _Newcapacity);
                throw e;
            }

            _Change_array(_Newvec, _Newsize, _Newcapacity);
            return _Get_data()._Myfirst + _Whereoff;
        }

        void _Resize(_Lambda)(const size_type _Newsize, _Lambda _Udefault_or_fill)
        {
            const size_type _Oldsize = size();
            const size_type _Oldcapacity = capacity();

            if (_Newsize > _Oldcapacity)
            {
//                if (_Newsize > max_size())
//                    _Xlength();

                const size_type _Newcapacity = _Calculate_growth(_Newsize);

                pointer _Newvec = _Getal().allocate(_Newcapacity);
                pointer _Appended_first = _Newvec + _Oldsize;
                pointer _Appended_last = _Appended_first;

                try
                {
                    _Appended_last = _Udefault_or_fill(_Appended_first, _Newsize - _Oldsize);
                    _Utransfer!(true, true)(_Get_data()._Myfirst, _Get_data()._Mylast, _Newvec);
                }
                catch (Throwable e)
                {
                    _Destroy(_Appended_first, _Appended_last);
                    _Getal().deallocate(_Newvec, _Newcapacity);
                    throw e;
                }
                _Change_array(_Newvec, _Newsize, _Newcapacity);
            }
            else if (_Newsize > _Oldsize)
            {
                pointer _Oldlast = _Get_data()._Mylast;
                _Get_data()._Mylast = _Udefault_or_fill(_Oldlast, _Newsize - _Oldsize);
                _Orphan_range(_Oldlast, _Oldlast);
            }
            else if (_Newsize == _Oldsize)
            {
                // nothing to do, avoid invalidating iterators
            }
            else
            {
                pointer _Newlast = _Get_data()._Myfirst + _Newsize;
                _Orphan_range(_Newlast, _Get_data()._Mylast);
                _Destroy(_Newlast, _Get_data()._Mylast);
                _Get_data()._Mylast = _Newlast;
            }
        }

        void _Reallocate_exactly(const size_type _Newcapacity)
        {
            const size_type _Size = size();
            pointer _Newvec = _Getal().allocate(_Newcapacity);

            try
            {
                for (size_t i = _Size; i > 0; )
                {
                    --i;
                    _Get_data()._Myfirst[i].moveEmplace(_Newvec[i]);
                }
            }
            catch (Throwable e)
            {
                _Getal().deallocate(_Newvec, _Newcapacity);
                throw e;
            }

            _Change_array(_Newvec, _Size, _Newcapacity);
        }

        void _Change_array(pointer _Newvec, const size_type _Newsize, const size_type _Newcapacity) @nogc
        {
            _Base._Orphan_all();

            if (_Get_data()._Myfirst != null)
            {
                _Destroy(_Get_data()._Myfirst, _Get_data()._Mylast);
                _Getal().deallocate(_Get_data()._Myfirst, capacity());
            }

            _Get_data()._Myfirst = _Newvec;
            _Get_data()._Mylast = _Newvec + _Newsize;
            _Get_data()._Myend = _Newvec + _Newcapacity;
        }

        size_type _Calculate_growth(const size_type _Newsize) const pure nothrow @nogc @safe
        {
            const size_type _Oldcapacity = capacity();
            if (_Oldcapacity > max_size() - _Oldcapacity/2)
                return _Newsize;
            const size_type _Geometric = _Oldcapacity + _Oldcapacity/2;
            if (_Geometric < _Newsize)
                return _Newsize;
            return _Geometric;
        }

        struct _Uninitialized_backout
        {
            this() @disable;
            this(pointer _Dest)
            {
                _First = _Dest;
                _Last = _Dest;
            }
            ~this()
            {
                _Destroy(_First, _Last);
            }
            void _Emplace_back(Args...)(auto ref Args args)
            {
                emplace(_Last, forward!args);
                ++_Last;
            }
            pointer _Release()
            {
                _First = _Last;
                return _Last;
            }
        private:
            pointer _First;
            pointer _Last;
        }
        pointer _Utransfer(bool _move, bool _ifNothrow = false)(pointer _First, pointer _Last, pointer _Dest)
        {
            // TODO: if copy/move are trivial, then we can memcpy/memmove
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; _First != _Last; ++_First)
            {
                static if (_move && (!_ifNothrow || true)) // isNothrow!T (move in D is always nothrow! ...until opPostMove)
                    _Backout._Emplace_back(move(*_First));
                else
                    _Backout._Emplace_back(*_First);
            }
            return _Backout._Release();
        }
        pointer _Ufill()(pointer _Dest, size_t _Count, auto ref T val)
        {
            // TODO: if T.sizeof == 1 and no elaborate constructor, fast-path to memset
            // TODO: if copy ctor/postblit are nothrow, just range assign
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; 0 < _Count; --_Count)
                _Backout._Emplace_back(val);
            return _Backout._Release();
        }
        pointer _Udefault(pointer _Dest, size_t _Count)
        {
            // TODO: if zero init, then fast-path to zeromem
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; 0 < _Count; --_Count)
                _Backout._Emplace_back();
            return _Backout._Release();
        }

        static if (_ITERATOR_DEBUG_LEVEL == 2)
        {
            void _Orphan_range(pointer _First, pointer _Last) const @nogc
            {
                import core.experimental.stdcpp.xutility : _Lockit, _LOCK_DEBUG;

                alias const_iterator = _Base.const_iterator;
                auto _Lock = _Lockit(_LOCK_DEBUG);

                const_iterator** _Pnext = cast(const_iterator**)_Get_data()._Base._Getpfirst();
                if (!_Pnext)
                    return;

                while (*_Pnext)
                {
                    if ((*_Pnext)._Ptr < _First || _Last < (*_Pnext)._Ptr)
                    {
                        _Pnext = cast(const_iterator**)(*_Pnext)._Base._Getpnext();
                    }
                    else
                    {
                        (*_Pnext)._Base._Clrcont();
                        *_Pnext = *cast(const_iterator**)(*_Pnext)._Base._Getpnext();
                    }
                }
            }
        }

        _Vector_alloc!(_Vec_base_types!(T, Alloc)) _Base;
    }
    else version (None)
    {
        size_type size() const pure nothrow @safe @nogc                     { return 0; }
        size_type capacity() const pure nothrow @safe @nogc                 { return 0; }
        bool empty() const pure nothrow @safe @nogc                         { return true; }

        inout(T)* data() inout pure nothrow @safe @nogc                     { return null; }
        inout(T)[] as_array() inout pure nothrow @trusted @nogc             { return null; }
        ref inout(T) at(size_type i) inout pure nothrow @trusted @nogc      { data()[0]; }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }

private:
    // HACK: because no rvalue->ref
    __gshared static immutable allocator_type defaultAlloc;
}


// platform detail
private:
version (CppRuntime_Microsoft)
{
    import core.experimental.stdcpp.xutility : _ITERATOR_DEBUG_LEVEL;

    extern (C++, struct) struct _Vec_base_types(_Ty, _Alloc0)
    {
        alias Ty = _Ty;
        alias Alloc = _Alloc0;
    }

    extern (C++, class) struct _Vector_alloc(_Alloc_types)
    {
        import core.experimental.stdcpp.xutility : _Compressed_pair;
    extern(D):
    @nogc:

        alias Ty = _Alloc_types.Ty;
        alias Alloc = _Alloc_types.Alloc;
        alias ValTy = _Vector_val!Ty;

        void _Orphan_all() nothrow @safe
        {
            static if (is(typeof(ValTy._Base)))
                _Mypair._Myval2._Base._Orphan_all();
        }

        static if (_ITERATOR_DEBUG_LEVEL != 0)
        {
            import core.experimental.stdcpp.xutility : _Container_proxy;

            alias const_iterator = _Vector_const_iterator!(ValTy);

            ~this()
            {
                _Free_proxy();
            }

            void _Alloc_proxy() @trusted
            {
                import core.lifetime : emplace;

                alias _Alproxy = Alloc.rebind!_Container_proxy;
                _Alproxy _Proxy_allocator = _Alproxy(_Mypair._Myval1);
                _Mypair._Myval2._Base._Myproxy = _Proxy_allocator.allocate(1);
                emplace(_Mypair._Myval2._Base._Myproxy);
                _Mypair._Myval2._Base._Myproxy._Mycont = &_Mypair._Myval2._Base;
            }
            void _Free_proxy()
            {
                alias _Alproxy = Alloc.rebind!_Container_proxy;
                _Alproxy _Proxy_allocator = _Alproxy(_Mypair._Myval1);
                _Orphan_all();
                destroy!false(_Mypair._Myval2._Base._Myproxy);
                _Proxy_allocator.deallocate(_Mypair._Myval2._Base._Myproxy, 1);
                _Mypair._Myval2._Base._Myproxy = null;
            }
        }

        _Compressed_pair!(Alloc, ValTy) _Mypair;
    }

    extern (C++, class) struct _Vector_val(T)
    {
        import core.experimental.stdcpp.xutility : _Container_base;
        import core.experimental.stdcpp.type_traits : is_empty;

        alias pointer = T*;

        static if (!is_empty!_Container_base.value)
            _Container_base _Base;

        pointer _Myfirst;   // pointer to beginning of array
        pointer _Mylast;    // pointer to current end of sequence
        pointer _Myend;     // pointer to end of array
    }

    static if (_ITERATOR_DEBUG_LEVEL > 0)
    {
        extern (C++, class) struct _Vector_const_iterator(_Myvec)
        {
            import core.experimental.stdcpp.xutility : _Iterator_base;
            import core.experimental.stdcpp.type_traits : is_empty;

            static if (!is_empty!_Iterator_base.value)
                _Iterator_base _Base;
            _Myvec.pointer _Ptr;
        }
    }
}
