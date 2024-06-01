app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task

main =
    Stdout.line "Call instead: roc test 05-aes-128.roc"

# TESTS ########################################################################

# Tests are coming from official NIST documentation:
# https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core128.pdf

# XOR key addition
expect
    block = [0x6bc1bee2, 0x2e409f96, 0xe93d7e11, 0x7393172a]
    output = [0x40bfabf4, 0x06ee4d30, 0x42ca6b99, 0x7a5c5816]

    blockToState block
    |> addKey (keyFromHexWords [0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c])
    |> Bool.isEq (blockToState output)

# Block to State round trip
expect
    block = [0x40bfabf4, 0x06ee4d30, 0x42ca6b99, 0x7a5c5816]
    blockToState block |> stateToBlock == block

# Substitution
expect
    block = [0x40bfabf4, 0x06ee4d30, 0x42ca6b99, 0x7a5c5816]
    output = [0x090862bf, 0x6f28e304, 0x2c747fee, 0xda4a6a47]
    subBytes (blockToState block) |> stateToBlock == output

# Shift row
expect
    block = [0x090862bf, 0x6f28e304, 0x2c747fee, 0xda4a6a47]
    output = [0x09287f47, 0x6f746abf, 0x2c4a6204, 0xda08e3ee]
    shiftRows (blockToState block) |> stateToBlock == output

# Multiplication in GF(2⁸)
expect mulGf 0x57 0x01 == 0x57
expect mulGf 0x57 0x02 == 0xae
expect mulGf 0x57 0x04 == 0x47
expect mulGf 0x57 0x08 == 0x8e
expect mulGf 0x57 0x10 == 0x07
expect mulGf 0x57 0x20 == 0x0e
expect mulGf 0x57 0x40 == 0x1c
expect mulGf 0x57 0x80 == 0x38

expect mulGf 0x57 0x13 == 0xfe

# Mix columns
expect
    block = [0x09287f47, 0x6f746abf, 0x2c4a6204, 0xda08e3ee]
    output = [0x529f16c2, 0x978615ca, 0xe01aae54, 0xba1a2659]
    mixColumns (blockToState block) |> stateToBlock == output

# Add round key 1
expect
    block = [0x529f16c2, 0x978615ca, 0xe01aae54, 0xba1a2659]
    output = [0xf265e8d5, 0x1fd2397b, 0xc3b9976d, 0x9076505c]
    key = [0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c]
    { k1 } = expandKey (keyFromHexWords key)

    blockToState block
    |> addKey k1
    |> Bool.isEq (blockToState output)

# Add round key 2
expect
    block = [0x0f31e929, 0x319a3558, 0xaec95893, 0x39f04d87]
    output = [0xfdf37cdb, 0x4b0c8c1b, 0xf7fcd8e9, 0x4aa9bbf8]
    key = [0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c]
    { k2 } = expandKey (keyFromHexWords key)

    blockToState block
    |> addKey k2
    |> Bool.isEq (blockToState output)

# Full AES-128 block encryption
expect
    block = [0x6bc1bee2, 0x2e409f96, 0xe93d7e11, 0x7393172a]
    output = [0x3ad77bb4, 0x0d7a3660, 0xa89ecaf3, 0x2466ef97]
    key = keyFromHexWords [0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c]
    roundKeys = expandKey key

    blockToState block
    |> aes128 key roundKeys
    |> Bool.isEq (blockToState output)

# IMPLEMENTATION ###############################################################

# Implementation done from official NIST documentation:
# https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf

## Word is a U32 represented as 4 bytes.
##
## Bytes are numbered from least significant to most significant.
## Usually, with hex notation it means: w = 0xb3b2b1b0.
Word : {
    b0 : U8,
    b1 : U8,
    b2 : U8,
    b3 : U8,
}

## Apply bytes rotations on a word.
rotWord : Word -> Word
rotWord = \w -> {
    b0: w.b3,
    b1: w.b0,
    b2: w.b1,
    b3: w.b2,
}

## Perform substitutions (SBOX) on a word.
subWord : Word -> Word
subWord = \w -> {
    b0: sbox w.b0,
    b1: sbox w.b1,
    b2: sbox w.b2,
    b3: sbox w.b3,
}

## Perform XOR of two U32 words.
xorWord : Word, Word -> Word
xorWord = \w1, w2 -> {
    b0: Num.bitwiseXor w1.b0 w2.b0,
    b1: Num.bitwiseXor w1.b1 w2.b1,
    b2: Num.bitwiseXor w1.b2 w2.b2,
    b3: Num.bitwiseXor w1.b3 w2.b3,
}

## One 128-bit key for AES-128.
## A key is composed of four U32 words.
Key : {
    w0 : Word,
    w1 : Word,
    w2 : Word,
    w3 : Word,
}

## Helper function to read a key from a U32, useful for tests.
keyFromHexWords : List U32 -> Key
keyFromHexWords = \words ->
    when words is
        [w0, w1, w2, w3] ->
            {
                w0: bytes w0,
                w1: bytes w1,
                w2: bytes w2,
                w3: bytes w3,
            }

        _ -> crash "keyFromHexWords must be called with exactly 4 U32"

## Helper function to extract individual bytes from a U32
bytes : U32 -> { b0 : U8, b1 : U8, b2 : U8, b3 : U8 }
bytes = \b -> {
    b0: Num.bitwiseAnd 0xff b |> Num.toU8,
    b1: Num.bitwiseAnd 0xff00 b |> Num.shiftRightZfBy 8 |> Num.toU8,
    b2: Num.bitwiseAnd 0xff0000 b |> Num.shiftRightZfBy 16 |> Num.toU8,
    b3: Num.shiftRightZfBy b 24 |> Num.toU8,
}

## Round keys.
## Each key is 128 bit (16 bytes U8).
RoundKeys : {
    k1 : Key,
    k2 : Key,
    k3 : Key,
    k4 : Key,
    k5 : Key,
    k6 : Key,
    k7 : Key,
    k8 : Key,
    k9 : Key,
    k10 : Key,
}

## Expand a key into its 10 round keys based on the AES-128 spec.
expandKey : Key -> RoundKeys
expandKey = \k ->
    step : U8, Key, List Key -> List Key
    step = \i, tempKey, keysAccum ->
        if i >= 40 then
            keysAccum
        else
            newWord =
                if i % 4 == 0 then
                    subWord (rotWord tempKey.w3)
                    |> xorWord tempKey.w0
                    |> xorWord (roundConstant ((i // 4) + 1))
                else
                    xorWord tempKey.w0 tempKey.w3
            newTempKey = {
                w0: tempKey.w1,
                w1: tempKey.w2,
                w2: tempKey.w3,
                w3: newWord,
            }
            if i % 4 == 3 then
                step (i + 1) newTempKey (List.append keysAccum newTempKey)
            else
                step (i + 1) newTempKey keysAccum

    when step 0 k [] is
        [k1, k2, k3, k4, k5, k6, k7, k8, k9, k10] ->
            { k1, k2, k3, k4, k5, k6, k7, k8, k9, k10 }

        _ -> crash "expandKey should generate exactly 10 keys"

## Round constant for AES-128
roundConstant : U8 -> Word
roundConstant = \n ->
    b3 =
        when n is
            1 -> 0x01
            2 -> 0x02
            3 -> 0x04
            4 -> 0x08
            5 -> 0x10
            6 -> 0x20
            7 -> 0x40
            8 -> 0x80
            9 -> 0x1b
            10 -> 0x36
            _ -> crash "roundConstant only be called for 1-10"
    {
        b0: 0x00,
        b1: 0x00,
        b2: 0x00,
        b3: b3,
    }

## State array of the shape "Src" where "r" is the row and "c" the column
State : {
    s00 : U8,
    s10 : U8,
    s20 : U8,
    s30 : U8,
    s01 : U8,
    s11 : U8,
    s21 : U8,
    s31 : U8,
    s02 : U8,
    s12 : U8,
    s22 : U8,
    s32 : U8,
    s03 : U8,
    s13 : U8,
    s23 : U8,
    s33 : U8,
}

## Helper function to convert a 128 bit state (16 U8) to four U32 words.
## This is convenient to compare with manually written U32 hex.
stateToBlock : State -> List U32
stateToBlock = \s -> [
    toLeWord [s.s30, s.s20, s.s10, s.s00],
    toLeWord [s.s31, s.s21, s.s11, s.s01],
    toLeWord [s.s32, s.s22, s.s12, s.s02],
    toLeWord [s.s33, s.s23, s.s13, s.s03],
]

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

## Helper function to convert four U32 words to a 128 bit state (16 U8).
## This is convenient to write tests with U32 hex.
blockToState : List U32 -> State
blockToState = \block ->
    when List.map block bytes is
        [c0, c1, c2, c3] ->
            {
                s00: c0.b3,
                s10: c0.b2,
                s20: c0.b1,
                s30: c0.b0,
                s01: c1.b3,
                s11: c1.b2,
                s21: c1.b1,
                s31: c1.b0,
                s02: c2.b3,
                s12: c2.b2,
                s22: c2.b1,
                s32: c2.b0,
                s03: c3.b3,
                s13: c3.b2,
                s23: c3.b1,
                s33: c3.b0,
            }

        _ -> crash "block must contain exactly 4 U32 words"

## XOR with key
addKey : State, Key -> State
addKey = \s, { w0, w1, w2, w3 } -> {
    s00: Num.bitwiseXor s.s00 w0.b3,
    s10: Num.bitwiseXor s.s10 w0.b2,
    s20: Num.bitwiseXor s.s20 w0.b1,
    s30: Num.bitwiseXor s.s30 w0.b0,
    s01: Num.bitwiseXor s.s01 w1.b3,
    s11: Num.bitwiseXor s.s11 w1.b2,
    s21: Num.bitwiseXor s.s21 w1.b1,
    s31: Num.bitwiseXor s.s31 w1.b0,
    s02: Num.bitwiseXor s.s02 w2.b3,
    s12: Num.bitwiseXor s.s12 w2.b2,
    s22: Num.bitwiseXor s.s22 w2.b1,
    s32: Num.bitwiseXor s.s32 w2.b0,
    s03: Num.bitwiseXor s.s03 w3.b3,
    s13: Num.bitwiseXor s.s13 w3.b2,
    s23: Num.bitwiseXor s.s23 w3.b1,
    s33: Num.bitwiseXor s.s33 w3.b0,
}

## Substitutes bytes of the state array
subBytes : State -> State
subBytes = \s -> {
    s00: sbox s.s00,
    s10: sbox s.s10,
    s20: sbox s.s20,
    s30: sbox s.s30,
    s01: sbox s.s01,
    s11: sbox s.s11,
    s21: sbox s.s21,
    s31: sbox s.s31,
    s02: sbox s.s02,
    s12: sbox s.s12,
    s22: sbox s.s22,
    s32: sbox s.s32,
    s03: sbox s.s03,
    s13: sbox s.s13,
    s23: sbox s.s23,
    s33: sbox s.s33,
}

# Table 4. SBOX (): substitution values for the byte xy (in hexadecimal format)
# sboxArray = [99, 124, 119, 123, 242, 107, 111, 197, 48, 1, 103, 43, 254, 215, 171, 118, 202, 130, 201, 125, 250, 89, 71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 183, 253, 147, 38, 54, 63, 247, 204, 52, 165, 229, 241, 113, 216, 49, 21, 4, 199, 35, 195, 24, 150, 5, 154, 7, 18, 128, 226, 235, 39, 178, 117, 9, 131, 44, 26, 27, 110, 90, 160, 82, 59, 214, 179, 41, 227, 47, 132, 83, 209, 0, 237, 32, 252, 177, 91, 106, 203, 190, 57, 74, 76, 88, 207, 208, 239, 170, 251, 67, 77, 51, 133, 69, 249, 2, 127, 80, 60, 159, 168, 81, 163, 64, 143, 146, 157, 56, 245, 188, 182, 218, 33, 16, 255, 243, 210, 205, 12, 19, 236, 95, 151, 68, 23, 196, 167, 126, 61, 100, 93, 25, 115, 96, 129, 79, 220, 34, 42, 144, 136, 70, 238, 184, 20, 222, 94, 11, 219, 224, 50, 58, 10, 73, 6, 36, 92, 194, 211, 172, 98, 145, 149, 228, 121, 231, 200, 55, 109, 141, 213, 78, 169, 108, 86, 244, 234, 101, 122, 174, 8, 186, 120, 37, 46, 28, 166, 180, 198, 232, 221, 116, 31, 75, 189, 139, 138, 112, 62, 181, 102, 72, 3, 246, 14, 97, 53, 87, 185, 134, 193, 29, 158, 225, 248, 152, 17, 105, 217, 142, 148, 155, 30, 135, 233, 206, 85, 40, 223, 140, 161, 137, 13, 191, 230, 66, 104, 65, 153, 45, 15, 176, 84, 187, 22]

## SBOX operation of AES-128
## directly encoded as a big pattern matching instead of using an array.
##
## Values are based on Table 4 in the AES paper.
sbox : U8 -> U8
sbox = \i ->
    when i is
        0 -> 99
        1 -> 124
        2 -> 119
        3 -> 123
        4 -> 242
        5 -> 107
        6 -> 111
        7 -> 197
        8 -> 48
        9 -> 1
        10 -> 103
        11 -> 43
        12 -> 254
        13 -> 215
        14 -> 171
        15 -> 118
        16 -> 202
        17 -> 130
        18 -> 201
        19 -> 125
        20 -> 250
        21 -> 89
        22 -> 71
        23 -> 240
        24 -> 173
        25 -> 212
        26 -> 162
        27 -> 175
        28 -> 156
        29 -> 164
        30 -> 114
        31 -> 192
        32 -> 183
        33 -> 253
        34 -> 147
        35 -> 38
        36 -> 54
        37 -> 63
        38 -> 247
        39 -> 204
        40 -> 52
        41 -> 165
        42 -> 229
        43 -> 241
        44 -> 113
        45 -> 216
        46 -> 49
        47 -> 21
        48 -> 4
        49 -> 199
        50 -> 35
        51 -> 195
        52 -> 24
        53 -> 150
        54 -> 5
        55 -> 154
        56 -> 7
        57 -> 18
        58 -> 128
        59 -> 226
        60 -> 235
        61 -> 39
        62 -> 178
        63 -> 117
        64 -> 9
        65 -> 131
        66 -> 44
        67 -> 26
        68 -> 27
        69 -> 110
        70 -> 90
        71 -> 160
        72 -> 82
        73 -> 59
        74 -> 214
        75 -> 179
        76 -> 41
        77 -> 227
        78 -> 47
        79 -> 132
        80 -> 83
        81 -> 209
        82 -> 0
        83 -> 237
        84 -> 32
        85 -> 252
        86 -> 177
        87 -> 91
        88 -> 106
        89 -> 203
        90 -> 190
        91 -> 57
        92 -> 74
        93 -> 76
        94 -> 88
        95 -> 207
        96 -> 208
        97 -> 239
        98 -> 170
        99 -> 251
        100 -> 67
        101 -> 77
        102 -> 51
        103 -> 133
        104 -> 69
        105 -> 249
        106 -> 2
        107 -> 127
        108 -> 80
        109 -> 60
        110 -> 159
        111 -> 168
        112 -> 81
        113 -> 163
        114 -> 64
        115 -> 143
        116 -> 146
        117 -> 157
        118 -> 56
        119 -> 245
        120 -> 188
        121 -> 182
        122 -> 218
        123 -> 33
        124 -> 16
        125 -> 255
        126 -> 243
        127 -> 210
        128 -> 205
        129 -> 12
        130 -> 19
        131 -> 236
        132 -> 95
        133 -> 151
        134 -> 68
        135 -> 23
        136 -> 196
        137 -> 167
        138 -> 126
        139 -> 61
        140 -> 100
        141 -> 93
        142 -> 25
        143 -> 115
        144 -> 96
        145 -> 129
        146 -> 79
        147 -> 220
        148 -> 34
        149 -> 42
        150 -> 144
        151 -> 136
        152 -> 70
        153 -> 238
        154 -> 184
        155 -> 20
        156 -> 222
        157 -> 94
        158 -> 11
        159 -> 219
        160 -> 224
        161 -> 50
        162 -> 58
        163 -> 10
        164 -> 73
        165 -> 6
        166 -> 36
        167 -> 92
        168 -> 194
        169 -> 211
        170 -> 172
        171 -> 98
        172 -> 145
        173 -> 149
        174 -> 228
        175 -> 121
        176 -> 231
        177 -> 200
        178 -> 55
        179 -> 109
        180 -> 141
        181 -> 213
        182 -> 78
        183 -> 169
        184 -> 108
        185 -> 86
        186 -> 244
        187 -> 234
        188 -> 101
        189 -> 122
        190 -> 174
        191 -> 8
        192 -> 186
        193 -> 120
        194 -> 37
        195 -> 46
        196 -> 28
        197 -> 166
        198 -> 180
        199 -> 198
        200 -> 232
        201 -> 221
        202 -> 116
        203 -> 31
        204 -> 75
        205 -> 189
        206 -> 139
        207 -> 138
        208 -> 112
        209 -> 62
        210 -> 181
        211 -> 102
        212 -> 72
        213 -> 3
        214 -> 246
        215 -> 14
        216 -> 97
        217 -> 53
        218 -> 87
        219 -> 185
        220 -> 134
        221 -> 193
        222 -> 29
        223 -> 158
        224 -> 225
        225 -> 248
        226 -> 152
        227 -> 17
        228 -> 105
        229 -> 217
        230 -> 142
        231 -> 148
        232 -> 155
        233 -> 30
        234 -> 135
        235 -> 233
        236 -> 206
        237 -> 85
        238 -> 40
        239 -> 223
        240 -> 140
        241 -> 161
        242 -> 137
        243 -> 13
        244 -> 191
        245 -> 230
        246 -> 66
        247 -> 104
        248 -> 65
        249 -> 153
        250 -> 45
        251 -> 15
        252 -> 176
        253 -> 84
        254 -> 187
        255 -> 22
        _ -> crash "only 0->255 U8 allowed" # should never happen

## Shift rows operation of AES-128
shiftRows : State -> State
shiftRows = \s -> {
    s00: s.s00,
    s10: s.s11,
    s20: s.s22,
    s30: s.s33,
    s01: s.s01,
    s11: s.s12,
    s21: s.s23,
    s31: s.s30,
    s02: s.s02,
    s12: s.s13,
    s22: s.s20,
    s32: s.s31,
    s03: s.s03,
    s13: s.s10,
    s23: s.s21,
    s33: s.s32,
}

## Mix Columns operation of AES-128
mixColumns : State -> State
mixColumns = \s -> {
    # column 0
    s00: mulColumn (2, 3, 1, 1) (s.s00, s.s10, s.s20, s.s30),
    s10: mulColumn (1, 2, 3, 1) (s.s00, s.s10, s.s20, s.s30),
    s20: mulColumn (1, 1, 2, 3) (s.s00, s.s10, s.s20, s.s30),
    s30: mulColumn (3, 1, 1, 2) (s.s00, s.s10, s.s20, s.s30),
    # column 1
    s01: mulColumn (2, 3, 1, 1) (s.s01, s.s11, s.s21, s.s31),
    s11: mulColumn (1, 2, 3, 1) (s.s01, s.s11, s.s21, s.s31),
    s21: mulColumn (1, 1, 2, 3) (s.s01, s.s11, s.s21, s.s31),
    s31: mulColumn (3, 1, 1, 2) (s.s01, s.s11, s.s21, s.s31),
    # column 2
    s02: mulColumn (2, 3, 1, 1) (s.s02, s.s12, s.s22, s.s32),
    s12: mulColumn (1, 2, 3, 1) (s.s02, s.s12, s.s22, s.s32),
    s22: mulColumn (1, 1, 2, 3) (s.s02, s.s12, s.s22, s.s32),
    s32: mulColumn (3, 1, 1, 2) (s.s02, s.s12, s.s22, s.s32),
    # column 3
    s03: mulColumn (2, 3, 1, 1) (s.s03, s.s13, s.s23, s.s33),
    s13: mulColumn (1, 2, 3, 1) (s.s03, s.s13, s.s23, s.s33),
    s23: mulColumn (1, 1, 2, 3) (s.s03, s.s13, s.s23, s.s33),
    s33: mulColumn (3, 1, 1, 2) (s.s03, s.s13, s.s23, s.s33),
}

mulColumn : (U8, U8, U8, U8), (U8, U8, U8, U8) -> U8
mulColumn = \(a0, a1, a2, a3), (s0, s1, s2, s3) ->
    mulGf a0 s0
    |> Num.bitwiseXor (mulGf a1 s1)
    |> Num.bitwiseXor (mulGf a2 s2)
    |> Num.bitwiseXor (mulGf a3 s3)

## Multiplication in GF(2⁸).
## Thank you ChatGPT for the python example implementation.
mulGf : U8, U8 -> U8
mulGf = \a, b ->
    irreducible = 0b100011011
    mulGfHelp = \m1, m2, accum ->
        m2ShiftR = Num.shiftRightZfBy m2 1
        m1ShiftL = Num.shiftLeftBy m1 1
        m1Reduced = if m1ShiftL > 0xff then Num.bitwiseXor m1ShiftL irreducible else m1ShiftL
        if m2 == 0 then
            accum
        else if Num.bitwiseAnd 0x01 m2 == 0 then
            mulGfHelp m1Reduced m2ShiftR accum
        else
            mulGfHelp m1Reduced m2ShiftR (Num.bitwiseXor m1 accum)

    mulGfHelp (Num.toU16 a) (Num.toU16 b) 0
    |> Num.toU8

## AES-128 block encryption
aes128 : State, Key, RoundKeys -> State
aes128 = \s, k, ks ->
    addKey s k
    |> round ks.k1
    |> round ks.k2
    |> round ks.k3
    |> round ks.k4
    |> round ks.k5
    |> round ks.k6
    |> round ks.k7
    |> round ks.k8
    |> round ks.k9
    |> subBytes
    |> shiftRows
    |> addKey ks.k10

## One AES-128 round
round : State, Key -> State
round = \s, k ->
    subBytes s
    |> shiftRows
    |> mixColumns
    |> addKey k
