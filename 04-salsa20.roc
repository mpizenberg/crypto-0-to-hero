app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task

main =
    Stdout.line "Call instead: roc test 04-salsa20.roc"

# TESTS ########################################################################

# A word is an element of {0, 1, ..., 2³²-1}
expect 0xc0a8787e == 3232266366

# The sum of two words u,v is (u+v mod 2³²)
expect Num.addWrap 0xc0a8787e_u32 0x9fd1161d_u32 == 0x60798e9b

# XOR: u ⊕ v = ∑i [ 2^i * (ui + vi − 2*ui*vi) ]
expect Num.bitwiseXor 0xc0a8787e_u32 0x9fd1161d_u32 == 0x5f796e63

# Bitwise left rotation
expect wrapShiftLeftWordBy 0b0001_u32 3 == 0b1000_u32
expect wrapShiftLeftWordBy 0_u32 14 == 0_u32

# Bitwise left rotation is modulo 2³²-1 for the exponents
expect wrapShiftLeftWordBy 0xc0a8787e_u32 5 == 0x150f0fd8

# Quarterrounds
expect quarterround [0x00000000, 0x00000000, 0x00000000, 0x00000000] == [0x00000000, 0x00000000, 0x00000000, 0x00000000]
expect quarterround [0x00000001, 0x00000000, 0x00000000, 0x00000000] == [0x08008145, 0x00000080, 0x00010200, 0x20500000]
expect quarterround [0x00000000, 0x00000001, 0x00000000, 0x00000000] == [0x88000100, 0x00000001, 0x00000200, 0x00402000]
expect quarterround [0x00000000, 0x00000000, 0x00000001, 0x00000000] == [0x80040000, 0x00000000, 0x00000001, 0x00002000]
expect quarterround [0x00000000, 0x00000000, 0x00000000, 0x00000001] == [0x00048044, 0x00000080, 0x00010000, 0x20100001]
expect quarterround [0xe7e8c006, 0xc4f9417d, 0x6479b4b2, 0x68c67137] == [0xe876d72b, 0x9361dfd5, 0xf1460244, 0x948541a3]
expect quarterround [0xd3917c5b, 0x55f1c407, 0x52a58a7a, 0x8f887a3b] == [0x3e2f308c, 0xd90a8f36, 0x6ab2a923, 0x2883524c]

# Rowrounds
expect
    r1 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r2 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r3 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r4 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]

    rr1 = [0x08008145, 0x00000080, 0x00010200, 0x20500000]
    rr2 = [0x20100001, 0x00048044, 0x00000080, 0x00010000]
    rr3 = [0x00000001, 0x00002000, 0x80040000, 0x00000000]
    rr4 = [0x00000001, 0x00000200, 0x00402000, 0x88000100]

    rowround [r1, r2, r3, r4] == [rr1, rr2, rr3, rr4]

# Rowrounds
expect
    r1 = [0x08521bd6, 0x1fe88837, 0xbb2aa576, 0x3aa26365]
    r2 = [0xc54c6a5b, 0x2fc74c2f, 0x6dd39cc3, 0xda0a64f6]
    r3 = [0x90a2f23d, 0x067f95a6, 0x06b35f61, 0x41e4732e]
    r4 = [0xe859c100, 0xea4d84b7, 0x0f619bff, 0xbc6e965a]

    rr1 = [0xa890d39d, 0x65d71596, 0xe9487daa, 0xc8ca6a86]
    rr2 = [0x949d2192, 0x764b7754, 0xe408d9b9, 0x7a41b4d1]
    rr3 = [0x3402e183, 0x3c3af432, 0x50669f96, 0xd89ef0a8]
    rr4 = [0x0040ede5, 0xb545fbce, 0xd257ed4f, 0x1818882d]

    rowround [r1, r2, r3, r4] == [rr1, rr2, rr3, rr4]

# Columnrounds
expect
    r1 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r2 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r3 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r4 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]

    cr1 = [0x10090288, 0x00000000, 0x00000000, 0x00000000]
    cr2 = [0x00000101, 0x00000000, 0x00000000, 0x00000000]
    cr3 = [0x00020401, 0x00000000, 0x00000000, 0x00000000]
    cr4 = [0x40a04001, 0x00000000, 0x00000000, 0x00000000]

    columnround [r1, r2, r3, r4] == [cr1, cr2, cr3, cr4]

# Columnrounds
expect
    r1 = [0x08521bd6, 0x1fe88837, 0xbb2aa576, 0x3aa26365]
    r2 = [0xc54c6a5b, 0x2fc74c2f, 0x6dd39cc3, 0xda0a64f6]
    r3 = [0x90a2f23d, 0x067f95a6, 0x06b35f61, 0x41e4732e]
    r4 = [0xe859c100, 0xea4d84b7, 0x0f619bff, 0xbc6e965a]

    cr1 = [0x8c9d190a, 0xce8e4c90, 0x1ef8e9d3, 0x1326a71a]
    cr2 = [0x90a20123, 0xead3c4f3, 0x63a091a0, 0xf0708d69]
    cr3 = [0x789b010c, 0xd195a681, 0xeb7d5504, 0xa774135c]
    cr4 = [0x481c2027, 0x53a8e4b5, 0x4c1f89c5, 0x3f78c9c8]

    columnround [r1, r2, r3, r4] == [cr1, cr2, cr3, cr4]

# Doubleround
expect
    r1 = [0x00000001, 0x00000000, 0x00000000, 0x00000000]
    r2 = [0x00000000, 0x00000000, 0x00000000, 0x00000000]
    r3 = [0x00000000, 0x00000000, 0x00000000, 0x00000000]
    r4 = [0x00000000, 0x00000000, 0x00000000, 0x00000000]

    dr1 = [0x8186a22d, 0x0040a284, 0x82479210, 0x06929051]
    dr2 = [0x08000090, 0x02402200, 0x00004000, 0x00800000]
    dr3 = [0x00010200, 0x20400000, 0x08008104, 0x00000000]
    dr4 = [0x20500000, 0xa0000040, 0x0008180a, 0x612a8020]

    doubleround [r1, r2, r3, r4] == [dr1, dr2, dr3, dr4]

# Doubleround
expect
    r1 = [0xde501066, 0x6f9eb8f7, 0xe4fbbd9b, 0x454e3f57]
    r2 = [0xb75540d3, 0x43e93a4c, 0x3a6f2aa0, 0x726d6b36]
    r3 = [0x9243f484, 0x9145d1e8, 0x4fa9d247, 0xdc8dee11]
    r4 = [0x054bf545, 0x254dd653, 0xd9421b6d, 0x67b276c1]

    dr1 = [0xccaaf672, 0x23d960f7, 0x9153e63a, 0xcd9a60d0]
    dr2 = [0x50440492, 0xf07cad19, 0xae344aa0, 0xdf4cfdfc]
    dr3 = [0xca531c29, 0x8e7943db, 0xac1680cd, 0xd503ca00]
    dr4 = [0xa74b2ad6, 0xbc331c5c, 0x1dda24c7, 0xee928277]

    doubleround [r1, r2, r3, r4] == [dr1, dr2, dr3, dr4]

# Little endian
expect littleendian 0x00000000 == 0x00000000
expect littleendian 0x564b1e09 == 0x091e4b56
expect littleendian 0xfffffffa == 0xfaffffff

# Salsa20
expect
    zeros = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    salsa20 zeros == zeros

# Salsa20
expect
    input = [
        [211, 159, 13, 115, 76, 55, 82, 183, 3, 117, 222, 37, 191, 187, 234, 136],
        [49, 237, 179, 48, 1, 106, 178, 219, 175, 199, 166, 48, 86, 16, 179, 207],
        [31, 240, 32, 63, 15, 83, 93, 161, 116, 147, 48, 113, 238, 55, 204, 36],
        [79, 201, 235, 79, 3, 81, 156, 47, 203, 26, 244, 243, 88, 118, 104, 54],
    ]
    output = [
        [109, 42, 178, 168, 156, 240, 248, 238, 168, 196, 190, 203, 26, 110, 170, 154],
        [29, 29, 150, 26, 150, 30, 235, 249, 190, 163, 251, 48, 69, 144, 51, 57],
        [118, 40, 152, 157, 180, 57, 27, 94, 107, 42, 236, 35, 27, 111, 114, 114],
        [219, 236, 232, 135, 111, 155, 110, 18, 24, 232, 95, 158, 179, 19, 48, 202],
    ]
    salsa20 input == output

# Salsa20
expect
    input = [
        [88, 118, 104, 54, 79, 201, 235, 79, 3, 81, 156, 47, 203, 26, 244, 243],
        [191, 187, 234, 136, 211, 159, 13, 115, 76, 55, 82, 183, 3, 117, 222, 37],
        [86, 16, 179, 207, 49, 237, 179, 48, 1, 106, 178, 219, 175, 199, 166, 48],
        [238, 55, 204, 36, 31, 240, 32, 63, 15, 83, 93, 161, 116, 147, 48, 113],
    ]
    output = [
        [179, 19, 48, 202, 219, 236, 232, 135, 111, 155, 110, 18, 24, 232, 95, 158],
        [26, 110, 170, 154, 109, 42, 178, 168, 156, 240, 248, 238, 168, 196, 190, 203],
        [69, 144, 51, 57, 29, 29, 150, 26, 150, 30, 235, 249, 190, 163, 251, 48],
        [27, 111, 114, 114, 118, 40, 152, 157, 180, 57, 27, 94, 107, 42, 236, 35],
    ]
    salsa20 input == output

## Salsa20
# expect
#    input = [
#        [6, 124, 83, 146, 38, 191, 9, 50, 4, 161, 47, 222, 122, 182, 223, 185],
#        [75, 27, 0, 216, 16, 122, 7, 89, 162, 104, 101, 147, 213, 21, 54, 95],
#        [225, 253, 139, 176, 105, 132, 23, 116, 76, 41, 176, 207, 221, 34, 157, 108],
#        [94, 94, 99, 52, 90, 117, 91, 220, 146, 190, 239, 143, 196, 176, 130, 186],
#    ]
#    output = [
#        [8, 18, 38, 199, 119, 76, 215, 67, 173, 127, 144, 162, 103, 212, 176, 217],
#        [192, 19, 233, 33, 159, 197, 154, 160, 128, 243, 219, 65, 171, 136, 135, 225],
#        [123, 11, 68, 86, 237, 82, 20, 155, 133, 189, 9, 83, 167, 116, 194, 78],
#        [122, 127, 195, 185, 185, 204, 188, 90, 245, 9, 183, 248, 226, 85, 245, 104],
#    ]
#    repeat input salsa20 1000000 == output

## Salsa20 initialization with k0 and k1
expect
    k0 = List.range { start: At 1, end: At 16 }
    k1 = List.range { start: At 201, end: At 216 }
    n = List.range { start: At 101, end: At 116 }
    output = [
        [69, 37, 68, 39, 41, 15, 107, 193, 255, 139, 122, 6, 170, 233, 217, 98],
        [89, 144, 182, 106, 21, 51, 200, 65, 239, 49, 222, 34, 215, 114, 40, 126],
        [104, 197, 7, 225, 197, 153, 31, 2, 102, 78, 76, 176, 84, 245, 246, 184],
        [177, 160, 133, 130, 6, 72, 149, 119, 192, 195, 132, 236, 234, 103, 246, 74],
    ]
    salsa20k0k1 k0 k1 n == output

## Salsa20 initialization with just k
expect
    k = List.range { start: At 1, end: At 16 }
    n = List.range { start: At 101, end: At 116 }
    output = [
        [39, 173, 46, 248, 30, 200, 82, 17, 48, 67, 254, 239, 37, 18, 13, 247],
        [241, 200, 61, 144, 10, 55, 50, 185, 6, 47, 246, 253, 143, 86, 187, 225],
        [134, 85, 110, 246, 161, 163, 43, 235, 231, 94, 171, 51, 145, 214, 112, 29],
        [14, 232, 5, 16, 151, 140, 183, 141, 171, 9, 122, 181, 104, 182, 177, 193],
    ]
    salsa20k k n == output

## Encryption of an example plaintext
expect
    k = List.repeat 0x00 32 |> List.set 0 0x80
    nonce = List.repeat 0x00 8
    input = List.repeat 0x00 128
    output =
        [
            [0xe3be8fdd, 0x8beca2e3, 0xea8ef947, 0x5b29a6e7],
            [0x003951e1, 0x097a5c38, 0xd23b7a5f, 0xad9f6844],
            [0xb22c9755, 0x9e2723c7, 0xcbbd3fe4, 0xfc8d9a07],
            [0x44652a83, 0xe72a9c46, 0x1876af4d, 0x7ef1a117],
            [0x8da2b74e, 0xef1b6283, 0xe7e20166, 0xabcae538],
            [0xe9716e46, 0x69e2816b, 0x6b20c5c3, 0x56802001],
            [0xcc1403a9, 0xa117d12a, 0x2669f456, 0x366d6ebb],
            [0x0f1246f1, 0x265150f7, 0x93cdb4b2, 0x53e348ae],
        ]
        |> List.join
        |> List.map \u32 ->
            { b0, b1, b2, b3 } = bytes u32
            [Num.toU8 b3, Num.toU8 b2, Num.toU8 b1, Num.toU8 b0]
        |> List.join

    encrypt input k nonce == output

# IMPLEMENTATION ###############################################################

## Wrapping bitwise left rotation for U32 words
wrapShiftLeftWordBy : U32, U8 -> U32
wrapShiftLeftWordBy = \word, n ->
    Num.bitwiseOr (Num.shiftLeftBy word n) (Num.shiftRightZfBy word (32 - n))

## Quarterround
##
## If y = (y0, y1, y2, y4)
## then quarterround(y) = (z0, z1, z2, z3) where
##
##     z1 = y1 ⊕ ((y0 + y3) <<< 7)
##     z2 = y2 ⊕ ((z1 + y0) <<< 9)
##     z3 = y3 ⊕ ((z2 + z1) <<< 13)
##     z0 = y0 ⊕ ((z3 + z2) <<< 18)
quarterround : List U32 -> List U32
quarterround = \words ->
    when words is
        [y0, y1, y2, y3] ->
            z1 = Num.bitwiseXor y1 (wrapShiftLeftWordBy (Num.addWrap y0 y3) 7)
            z2 = Num.bitwiseXor y2 (wrapShiftLeftWordBy (Num.addWrap z1 y0) 9)
            z3 = Num.bitwiseXor y3 (wrapShiftLeftWordBy (Num.addWrap z2 z1) 13)
            z0 = Num.bitwiseXor y0 (wrapShiftLeftWordBy (Num.addWrap z3 z2) 18)
            [z0, z1, z2, z3]

        _ ->
            crash "quarterround must be called on 4 words exactly"

## Rowround
##
## if y = (y0, y1, ..., y15)
## then rowround(y) = (z0, z1, ..., z15) where
##
##     (z0,  z1,  z2,  z3)  = quarterround(y0,  y1,  y2,  y3)
##     (z5,  z6,  z7,  z4)  = quarterround(y5,  y6,  y7,  y4)
##     (z10, z11, z8,  z9)  = quarterround(y10, y11, y8,  y9)
##     (z15, z12, z13, z14) = quarterround(y15, y12, y13, y14)
rowround : List (List U32) -> List (List U32)
rowround = \rows ->
    when rows is
        [[y0, y1, y2, y3], [y4, y5, y6, y7], [y8, y9, y10, y11], [y12, y13, y14, y15]] ->
            qr1 = quarterround [y0, y1, y2, y3]
            qr2 = quarterround [y5, y6, y7, y4]
            qr3 = quarterround [y10, y11, y8, y9]
            qr4 = quarterround [y15, y12, y13, y14]
            [qr1, rotateRight qr2 1, rotateRight qr3 2, rotateRight qr4 3]

        _ -> crash "rowround must be called on 4 rows exactly"

## Helper function to rotate a 4-element list
rotateRight : List a, U8 -> List a
rotateRight = \list, n ->
    when (n, list) is
        (1, [x2, x3, x4, x1]) | (2, [x3, x4, x1, x2]) | (3, [x4, x1, x2, x3]) ->
            [x1, x2, x3, x4]

        _ -> crash "rotateRight can only be called with 1, 2 or 3 on 4-element lists"

## Columnround
##
## A column round is basically a rowround on the transposed 4x4 matrix
columnround : List (List U32) -> List (List U32)
columnround = \matrix ->
    transpose4x4 matrix |> rowround |> transpose4x4

## Helper function to transpose a 4x4 matrix
transpose4x4 : List (List U32) -> List (List U32)
transpose4x4 = \rows ->
    when rows is
        [[y0, y1, y2, y3], [y4, y5, y6, y7], [y8, y9, y10, y11], [y12, y13, y14, y15]] ->
            [[y0, y4, y8, y12], [y1, y5, y9, y13], [y2, y6, y10, y14], [y3, y7, y11, y15]]

        _ -> crash "transpose4x4 must be called on a 4x4 matrix"

## Doubleround is a columnround followed by a rowround
doubleround = \matrix -> rowround (columnround matrix)

## Convert big endian U32 into little endian
littleendian : U32 -> U32
littleendian = \b ->
    { b0, b1, b2, b3 } = bytes b
    Num.shiftLeftBy b0 24 + Num.shiftLeftBy b1 16 + Num.shiftLeftBy b2 8 + b3

## Salsa20
salsa20 : List (List U8) -> List (List U8)
salsa20 = \plaintext ->
    # Transform the 4x16 U8 bytes lists into 4x4 U32 lists
    matrix : List (List U32)
    matrix =
        rowU8 <- List.map plaintext
        u8x4 <- List.map (List.chunksOf rowU8 4)
        toLeWord u8x4

    # 10 doublerounds
    shuffled : List (List U32)
    shuffled =
        matrix |> repeat doubleround 10

    List.map2 matrix shuffled \matrixRow, shuffledRow ->
        # Add initial matrix and shuffled rows
        rowSum = List.map2 matrixRow shuffledRow Num.addWrap
        # Back to U8 bytes from U32, with inverted endianness
        List.joinMap rowSum \u32 ->
            { b0, b1, b2, b3 } = bytes u32
            [Num.intCast b0, Num.intCast b1, Num.intCast b2, Num.intCast b3]

## Convert a sequence of 4xU8 bytes into a U32 word in little endian
toLeWord : List U8 -> U32
toLeWord = \u8x4 ->
    when u8x4 is
        [b0, b1, b2, b3] ->
            Num.intCast b0
            + Num.shiftLeftBy (Num.intCast b1) 8
            + Num.shiftLeftBy (Num.intCast b2) 16
            + Num.shiftLeftBy (Num.intCast b3) 24

        _ -> crash "Should exactly be 4 bytes"

## Helper function to extract individual bytes from a U32
bytes : U32 -> { b0 : U32, b1 : U32, b2 : U32, b3 : U32 }
bytes = \b -> {
    b0: Num.shiftRightZfBy (Num.shiftLeftBy b 24) 24,
    b1: Num.shiftRightZfBy (Num.shiftLeftBy b 16) 24,
    b2: Num.shiftRightZfBy (Num.shiftLeftBy b 8) 24,
    b3: Num.shiftRightZfBy b 24,
}

## Helper function to repeat-compose a function call
repeat : x, (x -> x), U64 -> x
repeat = \x, f, n ->
    when n is
        0 -> x
        1 -> f x
        2 -> f (f x)
        3 -> f (f (f x))
        4 -> f (f (f (f x)))
        _ ->
            d = n // 4
            r = n - 4 * d
            repeat x (\y -> repeat y f 4) d
            |> repeat f r

## Salsa20 initialization function
salsa20c1c2k0k1 : List U8, List U8, List U8, List U8, List U8 -> List (List U8)
salsa20c1c2k0k1 = \c1, c2, k0, k1, n ->
    c0 = [101, 120, 112, 97]
    c3 = [116, 101, 32, 107]

    [c0, k0, c1, n, c2, k1, c3]
    |> List.join
    |> List.chunksOf 16
    |> salsa20

## Salsa20 with two keys k0 and k1
salsa20k0k1 : List U8, List U8, List U8 -> List (List U8)
salsa20k0k1 = \k0, k1, n ->
    salsa20c1c2k0k1 [110, 100, 32, 51] [50, 45, 98, 121] k0 k1 n

## Salsa20 with a single key k
salsa20k : List U8, List U8 -> List (List U8)
salsa20k = \k, n ->
    salsa20c1c2k0k1 [110, 100, 32, 49] [54, 45, 98, 121] k k n

## Generate the U8 key byte stream of the same length as the message
salsa20KeyStream : List U8, List U8, U64 -> List U8
salsa20KeyStream = \key, nonce, messageLength ->
    salsa20N = \n ->
        if List.len key == 32 then
            { before, others } = List.split key 16
            salsa20k0k1 before others n
        else
            salsa20k key n

    expansionCount =
        if messageLength % 64 == 0 then
            messageLength // 64
        else
            messageLength // 64 + 1

    List.map (List.range { start: At 0, end: Before expansionCount }) \count ->
        List.concat nonce (u64ToLeBytes count)
        |> salsa20N
    |> List.join
    |> List.join
    |> List.takeFirst messageLength

## Helper function to extract individual bytes from a U32
u64ToLeBytes : U64 -> List U8
u64ToLeBytes = \b -> [
        Num.bitwiseAnd 0xff b,
        Num.bitwiseAnd 0xff00 b |> Num.shiftRightZfBy 8,
        Num.bitwiseAnd 0xff0000 b |> Num.shiftRightZfBy 16,
        Num.bitwiseAnd 0xff000000 b |> Num.shiftRightZfBy 24,
        Num.bitwiseAnd 0xff00000000 b |> Num.shiftRightZfBy 32,
        Num.bitwiseAnd 0xff0000000000 b |> Num.shiftRightZfBy 40,
        Num.bitwiseAnd 0xff000000000000 b |> Num.shiftRightZfBy 48,
        Num.bitwiseAnd 0xff00000000000000 b |> Num.shiftRightZfBy 56,
    ]
    |> List.map Num.intCast

## Encrypt a message with the given key and nonce using the Salsa20 cipher
encrypt : List U8, List U8, List U8 -> List U8
encrypt = \message, key, nonce ->
    keyStream = salsa20KeyStream key nonce (List.len message)
    List.map2 keyStream message Num.bitwiseXor
