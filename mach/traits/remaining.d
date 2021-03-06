module mach.traits.remaining;

private:

import mach.traits.primitives : isNumeric;
import mach.traits.property : hasProperty, PropertyType;

public:



template hasRemaining(T...) if(T.length == 1){
    enum bool hasRemaining = hasProperty!(T, `remaining`);
}

template RemainingType(T...) if(T.length == 1 && hasRemaining!T){
    alias RemainingType = PropertyType!(T, `remaining`);
}

template hasNumericRemaining(T...) if(T.length == 1){
    static if(hasRemaining!T){
        enum bool hasNumericRemaining = isNumeric!(RemainingType!T);
    }else{
        enum bool hasNumericRemaining = false;
    }
}



version(unittest){
    private:
    struct RemainingFieldTest{
        size_t remaining;
    }
    struct RemainingPropertyTest{
        double rem;
        @property auto remaining(){
            return this.rem;
        }
    }
    struct NoRemainingTest{
        double rem;
    }
}

unittest{
    // hasRemaining
    static assert(hasRemaining!RemainingFieldTest);
    static assert(hasRemaining!RemainingPropertyTest);
    static assert(!hasRemaining!NoRemainingTest);
    // RemainingType
    static assert(is(RemainingType!RemainingFieldTest == size_t));
    static assert(is(RemainingType!RemainingPropertyTest == double));
}
