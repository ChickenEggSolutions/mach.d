module mach.meta.varlogical;

private:

//

public:



template canVarLogical(alias pred, T...){
    static if(T.length == 0){
        enum bool canVarLogical = true;
    }else static if(T.length == 1){
        enum bool canVarLogical = is(typeof({if(pred(T[0].init)){}}));
    }else{
        enum bool canVarLogical = (
            is(typeof({if(pred(T[0].init)){}})) &&
            canVarLogical!(pred, T[1 .. $])
        );
    }
}



/// Get whether any passed arguments evaluate true.
/// When no arguments are passed, the function returns false.
/// Short-circuits when the first true value is found.
auto varany(alias pred = (x) => (x), T...)(auto ref T args) if(
    canVarLogical!(pred, T)
){
    static if(T.length == 0){
        return false;
    }else{
        if(pred(args[0])){
            return true;
        }else{
            static if(T.length > 1) return varany!pred(args[1 .. $]);
            else return false;
        }
    }
}

/// Get whether all passed arguments evaluate true.
/// When no arguments are passed, the function returns true.
/// Short-circuits when the first false value is found.
auto varall(alias pred = (x) => (x), T...)(auto ref T args) if(
    canVarLogical!(pred, T)
){
    static if(T.length == 0){
        return true;
    }else{
        if(!pred(args[0])){
            return false;
        }else{
            static if(T.length > 1) return varall!pred(args[1 .. $]);
            else return true;
        }
    }
}

/// Get whether no passed arguments evaluate true.
/// When no arguments are passed, the function returns true.
auto varnone(alias pred = (x) => (x), T...)(auto ref T args) if(
    canVarLogical!(pred, T)
){
    return !varany!pred(args);
}



unittest{
    assert(varany(true));
    assert(varany(true, true, true));
    assert(varany(true, true, false));
    assert(!varany());
    assert(!varany(false));
    assert(!varany(null));
    assert(varany!(n => n > 0)(-1, 0, 1));
    assert(!varany!(n => n > 0)(-1, 0, -2));
}
unittest{
    assert(varall());
    assert(varall(true));
    assert(varall(true, true, true));
    assert(!varall(false));
    assert(!varall(true, true, false));
    assert(!varall(true, true, false, null));
}
unittest{
    assert(varnone());
    assert(varnone(false));
    assert(varnone(false, false, false));
    assert(!varnone(true));
    assert(!varnone(true, true));
    assert(!varnone(true, true, false));
    assert(!varnone(true, null, false));
}
