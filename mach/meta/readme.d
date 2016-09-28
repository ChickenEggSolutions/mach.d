module mach.meta.readme;

private:

import mach.meta;

/++ md

# mach.meta

This package primarily contains templates useful for doing operations at
compile time.

## mach.meta.adjoin

Adjoin can be used to generate a function from several different functions,
where the returned value is a tuple containing each value returned from the
adjoined functions.

+/

unittest{
    alias fn = Adjoin!(e => e - 1, e => e + 1);
    auto result = fn(0);
    assert(result[0] == -1);
    assert(result[1] == 1);
}

/++ md

A function generated using Adjoin will return a tuple unconditionally, even
when adjoining only one function.

To return a single untampered-with value when adjoining only a single function,
use AdjoinFlat instead. In the case that a single function is passed to it,
it will alias itself to that function. In all other cases, it evaluates the
same as Adjoin.

+/

unittest{
    alias astuple = Adjoin!(e => e);
    assert(astuple(0)[0] == 0);
    alias flat = AdjoinFlat!(e => e);
    assert(flat(0) == 0);
}

/++ md

## mach.meta.aliases

Provides templates that can be used to generate an alias referring to some
value or sequence of values.

There is Alias for generating an alias to a single specific value, even values
that cannot be aliased using `alias x = y;` syntax.

+/

unittest{
    alias intalias = Alias!int;
    static assert(is(intalias == int));
    alias zero = Alias!0;
    static assert(zero == 0);
}

/++ md

And there is Aliases for generating an alias to a sequence of values.

+/

unittest{
    alias ints = Aliases!(int, int, int);
    static assert(ints.length == 3);
    auto fn0(int, int, int){}
    static assert(is(typeof({fn0(ints.init);})));
    auto fn1(ints){}
    static assert(is(typeof({fn1(ints.init);})));
}

/++ md

## mach.meta.contains

Given at least one argument, determines whether the first argument is
equivalent to any of the subsequent arguments.

+/

unittest{
    static assert(Contains!(int, byte, short, int));
    static assert(!Contains!(int, void, void, void));
}

/++ md

This can be more intuitively expressed as:

+/

unittest{
    alias nums = Aliases!(byte, short, int);
    alias voids = Aliases!(void, void, void);
    static assert(Contains!(int, nums));
    static assert(!Contains!(int, voids));
}

/++ md

## mach.meta.filter

Given a sequence of values, generate a new sequence containing only those
values which meet a predicate.

+/

unittest{
    enum bool NotVoid(T) = !is(T == void);
    static assert(is(Filter!(NotVoid, void, void, int, void, long) == Aliases!(int, long)));
}

/++ md

## mach.meta.indexof

+/

unittest{
    // TODO: Document
}

/++ md

## mach.meta.logical

+/

unittest{
    // TODO: Document
}

/++ md

## mach.meta.map

+/

unittest{
    // TODO: Document
}

/++ md

## mach.meta.partial

+/

unittest{
    // TODO: Document
}

/++ md

## mach.meta.repeat

Given a value or sequence of values, generate a new sequence which is the
original sequence repeated and concatenated some number of times.

+/

unittest{
    static assert(is(Repeat!(3, int) == Aliases!(int, int, int)));
    static assert(is(Repeat!(2, int, void) == Aliases!(int, void, int, void)));
}

/++ md

## mach.meta.retro

Given a sequence of values, generate a new sequence which is the same as the
original but in reverse order.

+/

unittest{
    static assert(is(Retro!(byte, short, int) == Aliases!(int, short, byte)));
}

/++ md

## mach.meta.varfilter

Given a sequence of variadic arguments, return a tuple containing only those
arguments whose types meet a template predicate.

+/

unittest{
    enum NotInt(T) = !is(T == int);
    auto values = varfilter!NotInt(byte(1), short(2), int(3), "hi");
    static assert(values.length == 3);
    assert(values[0] == 1);
    assert(values[1] == 2);
    assert(values[2] == "hi");
}

/++ md

## mach.meta.varmap

Given a sequence of variadic arguments, return a tuple containing the result of
each argument being transformed by a passed function.

+/

unittest{
    auto mapped = varmap!(e => e * e)(0, 1, 2, 3);
    static assert(mapped.length == 4);
    assert(mapped[0] == 0);
    assert(mapped[$-1] == 9);
    auto fn(int, int, int, int){}
    static assert(is(typeof({fn(mapped.expand);})));
}

/++ md

## mach.meta.varreduce

Provides an implementation of the reduce HOF, operating upon a sequence of
variadic arguments.

The reduction operation can be given a seed by prepending the seed as an
additional argument.

+/

unittest{
    alias sum = (a, b) => (a + b);
    assert(varreduce!sum(1, 2, 3) == 6);
}

/++ md

This module provides several common abstractions built on top of varreduce,
including varmin, varmax, varany, varall, and varsum.

+/

unittest{
    assert(varmin(1, 2, 3) == 1);
    assert(varmax(1, 2, 3) == 3);
    assert(varsum(1, 2, 3) == 6);
    assert(varany(true, false));
    assert(varall(true, true));
    assert(varnone(false, false));
}
