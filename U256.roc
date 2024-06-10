module [U256, zero, one, maxU256, addChecked, add, sub, subChecked, subWrap, mulChecked, mul, rem, shiftLeftBy, shiftRightZfBy]

# Python stuff to make sure poly1305 does not overflow on U256
# >>> r = 0x0ffffffc0ffffffc0ffffffc0fffffff
# >>> m = 2 ** 128 - 1
# >>> r
# 21267647620597763993911028882763415551
# >>> m
# 340282366920938463463374607431768211455
# >>> p = 2**130 - 5
# >>> ((p-1) + m) * r
# 36185027355887360936757271413509520653628350481296541067171779279045489852423
# >>> 2**256
# 115792089237316195423570985008687907853269984665640564039457584007913129639936

# TESTS ########################################################################

# bitLength
expect bitLength { high: 0, low: 0 } == 0
expect bitLength { high: 0, low: 1 } == 1
expect bitLength { high: 0, low: Num.maxU128 } == 128
expect bitLength { high: 1, low: Num.maxU128 } == 129
expect bitLength { high: bit127 - 1, low: Num.maxU128 } == 255
expect bitLength { high: bit127, low: Num.maxU128 } == 256
expect bitLength { high: Num.maxU128, low: Num.maxU128 } == 256

# shift left
expect shiftLeftBy zero 0 == zero
expect shiftLeftBy zero 1 == zero
expect shiftLeftBy zero 128 == zero
expect shiftLeftBy one 0 == one
expect shiftLeftBy one 1 == { high: 0, low: 2 }
expect shiftLeftBy { high: 1, low: 1 } 1 == { high: 2, low: 2 }
expect shiftLeftBy one 127 == { high: 0, low: bit127 }
expect shiftLeftBy one 128 == { high: 1, low: 0 }
expect shiftLeftBy one 129 == { high: 2, low: 0 }
expect shiftLeftBy one 255 == { high: bit127, low: 0 }

# shift right
expect shiftRightZfBy zero 0 == zero
expect shiftRightZfBy zero 1 == zero
expect shiftRightZfBy zero 128 == zero
expect shiftRightZfBy one 0 == one
expect shiftRightZfBy one 1 == zero
expect shiftRightZfBy { high: 1, low: 1 } 1 == { high: 0, low: bit127 }
expect shiftRightZfBy { high: 1, low: 1 } 128 == { high: 0, low: 1 }
expect shiftRightZfBy { high: 1, low: 1 } 129 == { high: 0, low: 0 }
expect shiftRightZfBy { high: bit127, low: 0 } 127 == { high: 1, low: 0 }
expect shiftRightZfBy { high: bit127, low: 0 } 128 == { high: 0, low: bit127 }
expect shiftRightZfBy { high: bit127, low: 0 } 255 == { high: 0, low: 1 }

# addition
expect addChecked zero zero == Ok zero
expect addChecked one zero == Ok one
expect addChecked zero one == Ok one
expect addChecked one one == Ok { high: 0, low: 2 }
expect addChecked one { high: 0, low: Num.maxU128 } == Ok { high: 1, low: 0 }
expect addChecked { high: 0, low: Num.maxU128 } one == Ok { high: 1, low: 0 }
expect addChecked zero maxU256 == Ok maxU256
expect addChecked one maxU256 == Err Overflow
expect addChecked { high: 1, low: 2 } { high: 3, low: 4 } == Ok { high: 4, low: 6 }
expect add { high: 1, low: 2 } { high: 3, low: 4 } == { high: 4, low: 6 }

# multiplication of two U128 into U256
expect mul128 0 0 == zero
expect mul128 1 0 == zero
expect mul128 0 1 == zero
expect mul128 1 1 == one
expect mul128 2 bit127 == { high: 1, low: 0 }
expect mul128 3 bit127 == { high: 1, low: bit127 }
expect mul128 bit127 bit127 == { high: Num.shiftLeftBy 1 126, low: 0 }
expect mul128 Num.maxU128 Num.maxU128 == { high: 0xfffffffffffffffffffffffffffffffe, low: 0x00000000000000000000000000000001 }

# multiplication of two U256
expect mulChecked zero zero == Ok zero
expect mulChecked zero one == Ok zero
expect mulChecked one zero == Ok zero
expect mulChecked one one == Ok one
expect mulChecked maxU256 one == Ok maxU256
expect mulChecked { high: 1, low: 0 } { high: 1, low: 0 } == Err Overflow
expect mulChecked { high: 1, low: 0 } { high: 0, low: Num.maxU128 } == Ok { high: Num.maxU128, low: 0 }
expect mulChecked { high: 0, low: Num.maxU128 } { high: 0, low: Num.maxU128 } == Ok { high: 0xfffffffffffffffffffffffffffffffe, low: 0x00000000000000000000000000000001 }
expect mulChecked { high: 1, low: 1 } { high: 0, low: Num.maxU128 } == Ok maxU256
expect mulChecked { high: 0, low: 10669302975710760130990824415874176645 } { high: 1, low: 147908425225540690611047796896236663363 } == Ok { high: 0x0b83fe991ca66800489155dcd69e8426, low: 0xba2779453994ac90ed284034da565ecf }

# modulo
expect rem zero one == zero
expect rem one one == zero
expect rem maxU256 one == zero
expect rem zero { high: 0, low: 2 } == zero
expect rem one { high: 0, low: 2 } == one
expect rem { high: 0, low: 2 } { high: 0, low: 2 } == zero
expect rem maxU256 { high: 0, low: 2 } == one
expect rem { high: 0, low: 23 } { high: 0, low: 13 } == { high: 0, low: 10 }
expect rem { high: 23, low: 0 } { high: 13, low: 0 } == { high: 10, low: 0 }
expect rem { high: 23, low: 0 } { high: 0, low: 13 } == { high: 0, low: 12 }

# subWrap for positive difference
expect subWrap zero zero == zero
expect subWrap one zero == one
expect subWrap one one == zero
expect subWrap { high: 1, low: 0 } zero == { high: 1, low: 0 }
expect subWrap { high: 1, low: 0 } { high: 1, low: 0 } == zero
expect subWrap { high: 1, low: 0 } one == { high: 0, low: Num.maxU128 }

# subWrap for negative difference
expect subWrap zero one == maxU256
expect subWrap zero maxU256 == one
expect subWrap zero { high: 0, low: 2 } == sub maxU256 one
expect subWrap { high: 12, low: 3 } { high: 13, low: 4 } == sub maxU256 { high: 1, low: 0 }

# IMPLEMENTATION ###############################################################

U256 : { high : U128, low : U128 }

maxU256 : U256
maxU256 = { high: Num.maxU128, low: Num.maxU128 }

zero : U256
zero = { high: 0, low: 0 }

one : U256
one = { high: 0, low: 1 }

bit127 = 0x80000000000000000000000000000000

bitLength : U256 -> U16
bitLength = \{ high, low } ->
    if high >= bit127 then
        256
    else if high > 0 then
        128 + (128 - Num.countLeadingZeroBits high |> Num.toU16)
    else
        128 - Num.toU16 (Num.countLeadingZeroBits low)

shiftLeftBy : U256, U8 -> U256
shiftLeftBy = \{ high, low }, shift ->
    if shift >= 128 then
        { high: Num.shiftLeftBy low (shift - 128), low: 0 }
    else if shift == 0 then
        # Special case needed for 0 because shift right by 128
        # is undefined behavior: https://github.com/roc-lang/roc/issues/6789
        { high, low }
    else
        {
            high: Num.bitwiseOr (Num.shiftLeftBy high shift) (Num.shiftRightZfBy low (128 - shift)),
            low: Num.shiftLeftBy low shift,
        }

shiftRightZfBy : U256, U8 -> U256
shiftRightZfBy = \{ high, low }, shift ->
    if shift >= 128 then
        { high: 0, low: Num.shiftRightZfBy high (shift - 128) }
    else
        { high: Num.shiftRightZfBy high shift, low: Num.bitwiseOr (Num.shiftRightZfBy low shift) (Num.shiftLeftBy high (128 - shift)) }

addChecked : U256, U256 -> Result U256 [Overflow]
addChecked = \{ high: high1, low: low1 }, { high: high2, low: low2 } ->
    (newLow, carryLow) =
        when Num.addChecked low1 low2 is
            Ok newLow12 -> (newLow12, 0)
            Err Overflow -> (Num.addWrap low1 low2, 1)

    high12 <- Num.addChecked high1 high2 |> Result.try
    newHigh <- Num.addChecked high12 carryLow |> Result.map
    { high: newHigh, low: newLow }

add : U256, U256 -> U256
add = \{ high: high1, low: low1 }, { high: high2, low: low2 } ->
    (newLow, carryLow) =
        when Num.addChecked low1 low2 is
            Ok newLow12 -> (newLow12, 0)
            Err Overflow -> (Num.addWrap low1 low2, 1)
    { high: high1 + high2 + carryLow, low: newLow }

# Multiply two U256 and return an error if there is an overflow
mulChecked : U256, U256 -> Result U256 [Overflow]
mulChecked = \{ high: h1, low: l1 }, { high: h2, low: l2 } ->
    z11 = mul128 h1 h2
    z00 = mul128 l1 l2
    z10 = mul128 h1 l2
    z01 = mul128 l1 h2
    if z11.high > 0 || z11.low > 0 then
        Err Overflow
    else
        mid <- addChecked z10 z01 |> Result.try
        if mid.high > 0 then
            Err Overflow
        else
            addChecked z00 { high: mid.low, low: 0 }

mul : U256, U256 -> U256
mul = \x, y ->
    when mulChecked x y is
        Ok z -> z
        Err Overflow -> crash "Overflow"

## Multiply two U128 numbers and output a U256 number
mul128 : U128, U128 -> U256
mul128 = \x, y ->
    # Decompose x = 2^64 x1 + x0
    x1 = Num.shiftRightZfBy x 64
    x0 = Num.bitwiseAnd x 0x0000000000000000ffffffffffffffff
    # Decompose y = 2^64 y1 + y0
    y1 = Num.shiftRightZfBy y 64
    y0 = Num.bitwiseAnd y 0x0000000000000000ffffffffffffffff
    # multiply each parts of x and y with each other
    z11 = x1 * y1
    z00 = x0 * y0
    z10 = x1 * y0
    z01 = x0 * y1
    # compute middle component
    (mid, carry1) =
        when Num.addChecked z10 z01 is
            Ok sum -> (sum, 0)
            Err Overflow -> (Num.addWrap z10 z01, 1)
    # compute the lowest component
    (low, carry0) =
        midLow = Num.shiftLeftBy mid 64
        when Num.addChecked z00 midLow is
            Ok sum -> (sum, 0)
            Err Overflow -> (Num.addWrap z00 midLow, 1)
    # compute the highest component
    midHigh = Num.shiftRightZfBy mid 64
    high = z11 + carry0 + midHigh + Num.shiftLeftBy carry1 64
    { high, low }

## Compute modulo for U256 integers.
## Do not compute rem _ 0, since it will never terminate.
rem : U256, U256 -> U256
rem = \dividend, divisor ->
    dividendBitLength = bitLength dividend |> Num.toI16
    divisorBitLength = bitLength divisor |> Num.toI16
    remHelper dividend divisor (dividendBitLength - divisorBitLength)

remHelper : U256, U256, I16 -> U256
remHelper = \remainder, divisor, bitLengthDiff ->
    if bitLengthDiff < 0 then
        remainder
    else
        adjustedDivisor = shiftLeftBy divisor (Num.toU8 bitLengthDiff)
        newRemainder =
            if greaterThanOrEqual remainder adjustedDivisor then
                sub remainder adjustedDivisor
            else
                remainder

        remHelper newRemainder divisor (bitLengthDiff - 1)

greaterThanOrEqual : U256, U256 -> Bool
greaterThanOrEqual = \{ high: high1, low: low1 }, { high: high2, low: low2 } ->
    if high1 > high2 then
        Bool.true
    else if high1 == high2 then
        low1 >= low2
    else
        Bool.false

sub : U256, U256 -> U256
sub = \x, y ->
    if greaterThanOrEqual x y then
        subWrap x y
    else
        crash "Overflow"

subChecked : U256, U256 -> Result U256 [Overflow]
subChecked = \x, y ->
    if greaterThanOrEqual x y then
        Ok (subWrap x y)
    else
        Err Overflow

subWrap : U256, U256 -> U256
subWrap = \{ high: high1, low: low1 }, { high: high2, low: low2 } ->
    (newLow, borrow) =
        when Num.subChecked low1 low2 is
            Ok low -> (low, 0)
            Err Overflow -> (Num.subWrap low1 low2, 1)

    { high: Num.subWrap high1 (Num.addWrap high2 borrow), low: newLow }
