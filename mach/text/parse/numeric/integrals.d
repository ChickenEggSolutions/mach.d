module mach.text.parse.numeric.integrals;

private:

import std.math : abs;
import mach.traits : Unqual, isNumeric, isIntegral, isSigned, Unsigned;
import mach.traits : isString, hasNumericLength;
import mach.math : divceil, clog, clog2, ispow2;
import mach.text.parse.numeric.exceptions;

public:



/// Generic function for parsing an integer value.
/// Throws a NumberParseException when fed invalid input.
/// For unsigned T, the input string may not begin with a sign. For signed T,
/// the string beginning with '+' or no sign implies positive whereas beginning
/// with '-' implies a negative value.
/// The allowsign flag is used to allow or disallow signs at the beginning of 
/// the input when T is signed.
/// The padding flag is used to indicate whether there are any special padding
/// symbols that may optionally be located at the rear of the input string.
/// The ispadding function must accept a character element of the input string
/// and return a value valid as a condition, e.g. a boolean.
/// The ispos and isneg functions must accept a character element and return a
/// value valid as a condition.
/// The valueof function must accept a character element of the input string and
/// return a number.
auto ParseBaseGeneric(
    T, size_t base, bool allowsign,
    bool padding, alias ispadding,
    alias ispos, alias isneg,
    alias valueof, S
)(auto ref S str) if(
    isNumeric!T && isString!S && is(typeof({
        auto x = valueof('0');
        auto y = cast(Unqual!T) x;
        static if(padding){if(ispadding('0')){}}
        static if(allowsign){
            if(ispos('0')){}
            if(isneg('0')){}
        }
    }))
){
    enum bool signed = isSigned!T && allowsign;
    Unqual!T value = 0;
    bool anydigits = false;
    static if(signed){
        bool foundsign = false;
        bool negative = false;
    }
    static if(padding){
        bool pad = false;
    }
    foreach(ch; str){
        static if(signed){
            if(ispos(ch)){
                NumberParseException.enforceinvalid(!anydigits && !foundsign);
                foundsign = true;
                continue;
            }else if(isneg(ch)){
                NumberParseException.enforceinvalid(!anydigits && !foundsign);
                foundsign = true; negative = true;
                continue;
            }
        }
        static if(padding){
            if(ispadding(ch)){
                pad = true;
                value *= base;
                continue;
            }else{
                NumberParseException.enforcepadding(!pad);
            }
        }
        value = cast(typeof(value))((value * base) + valueof(ch));
        anydigits = true;
    }
    NumberParseException.enforcedigits(anydigits);
    static if(signed){
        return cast(T)(negative ? -value : value);
    }else{
        return cast(T) value;
    }
}

/// Same as the prior method by the same name, but provides default inputs for
/// some template arguments.
auto ParseBaseGeneric(
    T, size_t base, alias valueof, S
)(auto ref S str) if(
    isNumeric!T && isString!S && is(typeof({
        auto x = valueof('0');
        auto y = cast(Unqual!T) x;
    }))
){
    return ParseBaseGeneric!(
        T, base, true, false, (){},
        (ch){return ch == '+';},
        (ch){return ch == '-';},
        valueof, S
    )(str);
}



/// Generic function for writing an integer value.
/// The output begins with a negation sign if the input is a negative number.
/// The digit function must accept an integral and return an element for the
/// returned string, of the same type as the negation and zero symbol inputs.
/// You probably want it to return a char of some sort, but whatever floats
/// your boat.
auto WriteBaseGeneric(size_t base, alias neg, alias zero, alias digit, T)(T number) if(
    isIntegral!T && is(typeof({
        auto ch = digit(0);
        typeof(ch) x = neg;
        typeof(ch) y = zero;
    }))
){
    alias Digit = typeof(zero);
    alias Digits = immutable(Digit)[];
    if(number == 0){
        return cast(Digits)[zero];
    }else{
        Digits str;
        Unqual!T n = cast(Unqual!T) number;
        static if(isSigned!T){
            bool negative = number < 0;
            if(number > 0){
                while(n > 0){
                    str = digit(n % base) ~ str; n /= base;
                }
            }else{
                enum sbase = cast(typeof(n)) base;
                while(n < 0){
                    str = digit(-(n % sbase)) ~ str;
                    n /= sbase;
                }
            }
            return negative ? neg ~ str : str;
        }else{
            while(n > 0){
                str = digit(n % base) ~ str; n /= base;
            }
            return str;
        }
    }
}

/// Same as the prior method by the same name, but provides default inputs for
/// some template arguments.
auto WriteBaseGeneric(size_t base, alias digit, T)(T number) if(
    isIntegral!T && is(typeof({auto ch = digit(0);}))
){
    return WriteBaseGeneric!(base, '-', '0', digit, T)(number);
}



/// Parse a string as a unary integer. The returned value will be the length of
/// the input.
template ParseBase(size_t base) if(base == 1){
    auto ParseBase(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
        static if(isSigned!T){
            enum Sign{Positive, Negative, None, Unknown}
            auto sign = Sign.Unknown;
            Unqual!T value = 0;
            foreach(ch; str){
                if(sign is Sign.Unknown){
                    if(ch == '+') sign = Sign.Positive;
                    else if(ch == '-') sign = Sign.Negative;
                    else sign = Sign.None;
                    static if(hasNumericLength!S){
                        if(sign is Sign.Negative) return -(cast(T) str.length) + 1;
                        else if(sign is Sign.Positive) return (cast(T) str.length) - 1;
                        else return cast(T) str.length;
                    }
                }else if(sign is Sign.Negative){
                    value--;
                }else{
                    value++;
                }
            }
            return cast(T) value;
        }else{
            static if(hasNumericLength!S){
                return cast(T) str.length;
            }else{
                Unqual!T value;
                foreach(ch; str) value++;
                return cast(T) value;
            }
        }
    }
}

/// Write a number as a string in unary. Concatenates a number of symbols
/// equivalent to the input number. By default the symbol is the character '1'.
template WriteBase(size_t base, alias digit = '1') if(base == 1){
    auto WriteBase(T)(T n) if(isIntegral!T){
        immutable(typeof(digit))[] str;
        static if(isSigned!T) auto len = abs(n);
        else alias len = n;
        str.reserve(cast(size_t) len);
        foreach(i; 0 .. len) str ~= digit;
        static if(isSigned!T) return n < 0 ? '-' ~ str : str;
        else return str;
    }
}



/// Parse a string as a binary number with the digits '0' and '1' by default.
template ParseBase(size_t base, alias zero = '0', alias one = '1') if(
    base == 2 && is(typeof({
        bool x = ('0' == zero);
        bool y = ('0' == one);
    }))
){
    private import mach.text.parse.numeric.exceptions;
    auto ParseBase(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
        return ParseBaseGeneric!(T, base, (ch){
            NumberParseException.enforceinvalid(ch == zero || ch == one);
            return ch != zero;
        })(str);
    }
}



/// Parse a string as a number in a base that requires only numeric characters,
/// and that is not unary or binary.
template ParseBase(size_t base) if(base >= 3 && base <= 10){
    auto ParseBase(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
        return ParseBaseGeneric!(T, base, (ch){
            enum auto maxch = '0' + base;
            NumberParseException.enforceinvalid(ch >= '0' && ch <= maxch);
            return ch - '0';
        })(str);
    }
}

/// Write a number as a string in a base that requires only numeric characters,
/// and that is not unary.
template WriteBase(size_t base) if(base >= 2 && base <= 10){
    auto WriteBase(T)(T number) if(isIntegral!T){
        return WriteBaseGeneric!(base, (ch){
            return cast(char)('0' + ch);
        })(number);
    }
}



/// Parse a string as a number in a base that requires both numeric and
/// no more than 26 alphabetic characters, and that is not base 32.
/// The parser is case-insensitive; e.g. 'a' and 'A' represent the same digit.
template ParseBase(size_t base) if(base > 10 && base <= 36 && base != 32){
    private import mach.traits : Unqual, isNumeric, isString;
    private import mach.text.parse.numeric.exceptions;
    auto ParseBase(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
        return ParseBaseGeneric!(T, base, (ch){
            enum auto maxlowerch = 'a' + base - 10;
            enum auto maxupperch = 'A' + base - 10;
            if(ch >= '0' && ch <= '9') return ch - '0';
            else if(ch >= 'a' && ch <= maxlowerch) return ch - 'a' + 10;
            else if(ch >= 'A' && ch <= maxupperch) return ch - 'A' + 10;
            else throw new NumberParseException(
                NumberParseException.Reason.InvalidChar
            );
        })(str);
    }
}

/// Write a number as a string in a base that requires both numeric and
/// no more than 26 alphabetic characters, and that is not base 32.
/// Accepts an optional flag determining whether alphabetic digits should be
/// written in upper- or lower-case. The flag defaults to uppercase.
template WriteBase(size_t base, bool uppercase = true) if(
    base > 10 && base <= 36 && base != 32
){
    auto WriteBase(T)(T number) if(isIntegral!T){
        return WriteBaseGeneric!(base, (ch){
            if(ch < 10){
                return cast(char)('0' + ch);
            }else{
                static if(uppercase) return cast(char)('A' + ch - 10);
                else return cast(char)('a' + ch - 10);
            }
        })(number);
    }
}



/// Parse a string as a number in base 32 using the RFC 4648 alphabet.
/// The input must be unsigned.
/// The parser is case-insensitive; e.g. 'a' and 'A' represent the same digit.
/// The padding symbol '=' is treated the same as '0' if present, but may only
/// appear at the end of the input string.
/// https://en.wikipedia.org/wiki/Base32#RFC_4648_Base32_alphabet
template ParseBase(size_t base) if(base == 32){
    private import mach.traits : Unqual, isNumeric, isString;
    private import mach.text.parse.numeric.exceptions;
    auto ParseBase(T = ulong, S)(auto ref S str) if(isString!S && isNumeric!T){
        return ParseBaseGeneric!(
            T, base, false, true, (ch){return ch == '=';}, (){}, (){}, (ch){
                if(ch >= '2' && ch <= '9') return ch - '2' + 26;
                else if(ch >= 'a' && ch <= 'z') return ch - 'a';
                else if(ch >= 'A' && ch <= 'Z') return ch - 'A';
                else if(ch == '=') return 0;
                else throw new NumberParseException(
                    NumberParseException.Reason.InvalidChar
                );
            }
        )(str);
    }
}

/// Write a number as a string in base 32 using the RFC 4648 alphabet.
/// The input must be unsigned.
/// Accepts an optional flag determining whether alphabetic digits should be
/// written in upper- or lower-case. The flag defaults to uppercase.
/// https://en.wikipedia.org/wiki/Base32#RFC_4648_Base32_alphabet
template WriteBase(size_t base, bool uppercase = true) if(base == 32){
    auto WriteBase(T)(T number) if(isIntegral!T) in{
        static if(isSigned!T) assert(number >= 0, "Cannot write negative number.");
    }body{
        return WriteBaseGeneric!(base, '-', uppercase ? 'A' : 'a', (ch){
            if(ch < 26){
                static if(uppercase) return cast(char)('A' + ch);
                else return cast(char)('a' + ch);
            }else{
                return cast(char)('2' + ch - 26);
            }
        })(number);
    }
}



/// Parse a string as a number in base 64.
/// The input must be unsigned.
/// The padding symbol '=' is treated the same as '0' if present, but may only
/// appear at the end of the input string.
/// https://en.wikipedia.org/wiki/Base64#Examples
template ParseBase(size_t base) if(base == 64){
    auto ParseBase(T = ulong, S)(auto ref S str) if(isString!S && isNumeric!T){
        return ParseBaseGeneric!(
            T, base, false, true, (ch){return ch == '=';}, (){}, (){}, (ch){
                if(ch >= '0' && ch <= '9') return ch - '0' + 52;
                else if(ch >= 'a' && ch <= 'z') return ch - 'a' + 26;
                else if(ch >= 'A' && ch <= 'Z') return ch - 'A';
                else if(ch == '+') return 62;
                else if(ch == '/') return 63;
                else if(ch == '=') return 0;
                else throw new NumberParseException(
                    NumberParseException.Reason.InvalidChar
                );
            }
        )(str);
    }
}

/// Write a number as a string in base 64.
/// The input must be unsigned.
/// https://en.wikipedia.org/wiki/Base64#Examples
template WriteBase(size_t base) if(base == 64){
    auto WriteBase(T)(T number) if(isIntegral!T) in{
        static if(isSigned!T) assert(number >= 0, "Cannot write negative number.");
    }body{
        return WriteBaseGeneric!(base, '-', 'A', (ch){
            if(ch < 26) return cast(char)('A' + ch);
            else if(ch < 52) return cast(char)('a' + ch - 26);
            else if(ch == 62) return '+';
            else if(ch == 63) return '/';
            else return cast(char)('0' + ch - 52);
        })(number);
    }
}



/// Write a number as a string in a given base, left-padded with zeroes.
/// The amount of padding depends on the size of the input type.
/// The input must be unsigned.
auto WriteBasePaddedGeneric(size_t base, alias digit, T)(T number) if(
    base > 1 && isIntegral!T && is(typeof({auto ch = digit(0);}))
)in{
    static if(isSigned!T) assert(number >= 0, "Cannot write negative number.");
}body{
    alias Digit = typeof(digit(0));
    alias Digits = immutable(Digit)[];
    Digits str;
    static if(isIntegral!T && ispow2(base)){
        static if(!isSigned!T) alias n = number;
        else auto n = cast(Unsigned!T) number;
        enum size_t mask = base - 1;
        enum size_t inc = clog2(base);
        enum size_t size = T.sizeof << 3;
        enum size_t len = divceil(size, inc);
        enum size_t shiftinit0 = size - (size % inc);
        enum size_t shiftinit1 = shiftinit0 - (shiftinit0 == size ? inc : 0);
        size_t shift = shiftinit1;
        str.reserve(len);
        str ~= digit(n >> shift);
        shift -= inc;
        while(shift >= inc){
            str ~= digit((n >> shift) & mask);
            shift -= inc;
        }
        str ~= digit(n & mask);
        return str;
    }else{
        alias N = Unqual!(Unsigned!T);
        auto len = clog!base(N.max);
        str.reserve(cast(size_t) len);
        N div = 1;
        foreach(i; 0 .. len){
            str = digit((number / div) % base) ~ str;
            div *= base;
        }
        return str;
    }
}

/// Write a number as a string in a base that requires only numeric characters,
/// and that is not unary.
template WriteBasePadded(size_t base) if(base >= 2 && base <= 10){
    auto WriteBasePadded(T)(T number) if(isIntegral!T){
        return WriteBasePaddedGeneric!(base, (ch){
            return cast(char)('0' + ch);
        })(number);
    }
}
/// Write a number as a string in a base that requires both numeric and
/// no more than 26 alphabetic characters.
/// Accepts an optional flag determining whether alphabetic digits should be
/// written in upper- or lower-case. The flag defaults to uppercase.
template WriteBasePadded(size_t base, bool uppercase = true) if(
    base > 10 && base <= 36
){
    auto WriteBasePadded(T)(T number) if(isIntegral!T){
        return WriteBasePaddedGeneric!(base, (ch){
            if(ch < 10){
                return cast(char)('0' + ch);
            }else{
                static if(uppercase) return cast(char)('A' + ch - 10);
                else return cast(char)('a' + ch - 10);
            }
        })(number);
    }
}



/// Parse a signed base 10 integer from a string.
alias parseint = ParseBase!10;
/// Parse a signed hexadecimal integer from a string.
alias parsehex = ParseBase!16;
/// Parse a signed octal integer from a string.
alias parseoct = ParseBase!8;
/// Parse a signed binary integer from a string.
alias parsebin = ParseBase!2;
/// Parse an unsigned base 32 integer from a string.
alias parseb32 = ParseBase!32;
/// Parse an unsigned base 64 integer from a string.
alias parseb64 = ParseBase!64;

/// Write a signed base 10 integer as a string.
alias writeint = WriteBase!10;
/// Write an unsigned padded hexadecimal integer as a string.
alias writehex = WriteBasePadded!16;
/// Write a signed octal integer as a string.
alias writeoct = WriteBase!8;
/// Write an unsigned padded binary integer as a string.
alias writebin = WriteBasePadded!2;
/// Write an unsigned base 32 integer as a string.
alias writeb32 = WriteBase!32;
/// Write an unsigned base 64 integer as a string.
alias writeb64 = WriteBase!64;



version(unittest){
    private:
    import mach.test;
    auto IntsTest(T)(T num){
        tests("byte", {
            if(num >= byte.min && num <= byte.max) NumTest!byte(cast(byte) num);
        });
        tests("ubyte", {
            if(num >= ubyte.min && num <= ubyte.max) NumTest!ubyte(cast(ubyte) num);
        });
        tests("short", {
            if(num >= short.min && num <= short.max) NumTest!short(cast(short) num);
        });
        tests("ushort", {
            if(num >= ushort.min && num <= ushort.max) NumTest!ushort(cast(ushort) num);
        });
        tests("int", {
            if(num >= int.min && num <= int.max) NumTest!int(cast(int) num);
        });
        tests("uint", {
            if(num >= uint.min && num <= uint.max) NumTest!uint(cast(uint) num);
        });
        tests("long", {
            if(num >= long.min && num <= long.max) NumTest!long(cast(long) num);
        });
        tests("ulong", {
            if(num >= ulong.min && num <= ulong.max) NumTest!ulong(cast(ulong) num);
        });
    }
    auto NumTest(T)(T num){
        tests("Decimal", {
            BaseTest!(ParseBase!10, WriteBase!10, T)(num);
        });
        tests("Hex", {
            BaseTest!(ParseBase!16, WriteBase!16, T)(num);
            if(num >= 0){
                BaseTest!(ParseBase!16, WriteBasePadded!16, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!16, WriteBasePadded!16, T)(num);});
            }
        });
        tests("Octal", {
            BaseTest!(ParseBase!8, WriteBase!8, T)(num);
            if(num >= 0){
                BaseTest!(ParseBase!8, WriteBasePadded!8, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!8, WriteBasePadded!8, T)(num);});
            }
        });
        tests("Binary", {
            BaseTest!(ParseBase!2, WriteBase!2, T)(num);
            if(num >= 0){
                BaseTest!(ParseBase!2, WriteBasePadded!2, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!2, WriteBasePadded!2, T)(num);});
            }
        });
        tests("Ternary", {
            BaseTest!(ParseBase!3, WriteBase!3, T)(num);
            if(num >= 0){
                BaseTest!(ParseBase!3, WriteBasePadded!3, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!3, WriteBasePadded!3, T)(num);});
            }
        });
        tests("Base 32", {
            if(num >= 0){
                BaseTest!(ParseBase!32, WriteBase!32, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!32, WriteBase!32, T)(num);});
            }
        });
        tests("Base 64", {
            if(num >= 0){
                BaseTest!(ParseBase!64, WriteBase!64, T)(num);
            }else{
                testfail({BaseTest!(ParseBase!64, WriteBase!64, T)(num);});
            }
        });
        tests("Unary", {
            if(num >= -64 && num <= 64) BaseTest!(ParseBase!1, WriteBase!1, T)(num);
        });
    }
    auto BaseTest(alias parse, alias write, T)(T num){
        testeq(parse!T(write(num)), num);
    }
}
unittest{
    tests("Simple", {
        tests("Writing", {
            testeq(WriteBase!10(0), "0");
            testeq(WriteBase!10(1), "1");
            testeq(WriteBase!10(-1), "-1");
            testeq(WriteBase!10(10), "10");
            testeq(WriteBase!10(-10), "-10");
            testeq(WriteBase!10(123456789), "123456789");
            testeq(WriteBase!1(0), "");
            testeq(WriteBase!1(1), "1");
            testeq(WriteBase!1(-1), "-1");
            testeq(WriteBase!1(4), "1111");
            testeq(WriteBase!1(-4), "-1111");
            testeq(WriteBase!2(0), "0");
            testeq(WriteBase!2(1), "1");
            testeq(WriteBase!2(-1), "-1");
            testeq(WriteBase!2(2), "10");
            testeq(WriteBase!3(3), "10");
            testeq(WriteBase!3(-3), "-10");
            testeq(WriteBase!16(0x1234abcd), "1234ABCD");
            testeq(WriteBase!16(0xabcd1234), "ABCD1234");
        });
        tests("Parsing", {
            testeq(ParseBase!10("0"), 0);
            testeq(ParseBase!10("1"), 1);
            testeq(ParseBase!10("-1"), -1);
            testeq(ParseBase!10("10"), 10);
            testeq(ParseBase!10("-10"), -10);
            testeq(ParseBase!10("123456789"), 123456789);
            testeq(ParseBase!1(""), 0);
            testeq(ParseBase!1("1"), 1);
            testeq(ParseBase!1("-1"), -1);
            testeq(ParseBase!1("1111"), 4);
            testeq(ParseBase!1("-1111"), -4);
            testeq(ParseBase!2("0"), 0);
            testeq(ParseBase!2("1"), 1);
            testeq(ParseBase!2("-1"), -1);
            testeq(ParseBase!2("10"), 2);
            testeq(ParseBase!3("10"), 3);
            testeq(ParseBase!3("-10"), -3);
            testeq(ParseBase!16("1234abcd"), 0x1234abcd);
            testeq(ParseBase!16("ABCD1234"), 0xabcd1234);
        });
        tests("Combination", {
            IntsTest(0);
            IntsTest(1);
            IntsTest(10);
            IntsTest(100);
            IntsTest(123);
            IntsTest(255);
            IntsTest(256);
            IntsTest(12341234);
            IntsTest(int.max);
            IntsTest(long.max);
            IntsTest(uint.max);
            IntsTest(ulong.max);
            IntsTest(-1);
            IntsTest(-10);
            IntsTest(-100);
            IntsTest(-123);
            IntsTest(-255);
            IntsTest(-256);
            IntsTest(-12341234);
            IntsTest(int.min);
            IntsTest(long.min);
        });
    });
}
