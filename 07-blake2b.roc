app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task

main =
    Stdout.line "Call instead: roc test 07-blake2b.roc"

# TESTS ########################################################################

## Helper function for tests
hex : List U8 -> Str
hex = \hash ->
    List.map hash u8Hex |> Str.joinWith ""

## Helper function for tests
u8Hex : U8 -> Str
u8Hex = \n ->
    Str.fromUtf8 [u4HexChar (n // 16), u4HexChar (n % 16)]
    |> Result.withDefault "00"

u4HexChar : U8 -> U8
u4HexChar = \n -> if n >= 10 then n - 10 + 'a' else n + '0'

# Test from spec: https://datatracker.ietf.org/doc/html/rfc7693#appendix-A
expect
    hash = blake2b512 (Str.toUtf8 "abc") WithoutKey
    expectedHash = [
        "ba80a53f981c4d0d6a2797b69f12f6e9",
        "4c212f14685ac4b74b12bb6fdbffa2d1",
        "7d87c5392aab792dc252d5de4533cc95",
        "18d38aa8dbf1925ab92386edd4009923",
    ]
    hex hash == Str.joinWith expectedHash ""

# Test from wikipedia: https://en.wikipedia.org/wiki/BLAKE_(hash_function)
expect
    hash = blake2b512 [] WithoutKey
    expectedHash = "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce"
    hex hash == expectedHash

# Test from wikipedia: https://en.wikipedia.org/wiki/BLAKE_(hash_function)
expect
    hash = blake2b512 (Str.toUtf8 "The quick brown fox jumps over the lazy dog") WithoutKey
    expectedHash = "a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918"
    hex hash == expectedHash

# Test from wikipedia: https://en.wikipedia.org/wiki/BLAKE_(hash_function)
expect
    hash = blake2b512 (Str.toUtf8 "The quick brown fox jumps over the lazy dof") WithoutKey
    expectedHash = "ab6b007747d8068c02e25a6008db8a77c218d94f3b40d2291a7dc8a62090a744c082ea27af01521a102e42f480a31e9844053f456b4b41e8aa78bbe5c12957bb"
    hex hash == expectedHash

# IMPLEMENTATION ###############################################################

# https://www.blake2.net/

# The following table summarizes various parameters and their ranges:
#
#                 | BLAKE2b          | BLAKE2s          |
#   --------------+------------------+------------------+
#    Bits in word | w = 64           | w = 32           |
#    Rounds in F  | r = 12           | r = 10           |
#    Block bytes  | bb = 128         | bb = 64          |
#    Hash bytes   | 1 <= nn <= 64    | 1 <= nn <= 32    |
#    Key bytes    | 0 <= kk <= 64    | 0 <= kk <= 32    |
#    Input bytes  | 0 <= ll < 2**128 | 0 <= ll < 2**64  |
#   --------------+------------------+------------------+
#    G Rotation   | (R1, R2, R3, R4) | (R1, R2, R3, R4) |
#     constants = | (32, 24, 16, 63) | (16, 12,  8,  7) |
#   --------------+------------------+------------------+
#
# These variables are used in the algorithm description:
#
# IV[0..7]  Initialization Vector (constant).
# SIGMA[0..9]  Message word permutations (constant).
# p[0..7]  Parameter block (defines hash and key sizes).
# m[0..15]  Sixteen words of a single message block.
# h[0..7]  Internal state of the hash.
# d[0..dd-1]  Padded input blocks.  Each has "bb" bytes.
# t  Message byte offset at the end of the current block.
# f  Flag indicating the last block.

# blake2b224 : List U8, [WithKey (List U8), WithoutKey] -> List U8
# blake2b224 = \input, withKey ->
#    blake2b input withKey 28

# blake2b256 : List U8, [WithKey (List U8), WithoutKey] -> List U8
# blake2b256 = \input, withKey ->
#    blake2b input withKey 32

blake2b512 : List U8, [WithKey (List U8), WithoutKey] -> List U8
blake2b512 = \input, withKey ->
    blake2b input withKey 64

## BLAKE2-b hash function.
##
## Key and data input are split and padded into "dd" message blocks
## d[0..dd-1], each consisting of 16 words (or "bb" bytes).
##
## If a secret key is used (kk > 0), it is padded with zero bytes and
## set as d[0].  Otherwise, d[0] is the first data block.  The final
## data block d[dd-1] is also padded with zero to "bb" bytes (16 words).
##
## The number of blocks is therefore dd = ceil(kk / bb) + ceil(ll / bb).
## However, in the special case of an unkeyed empty message (kk = 0 and
## ll = 0), we still set dd = 1 and d[0] consists of all zeros.
##
## The following procedure processes the padded data blocks into an
## "nn"-byte final hash value.
blake2b : List U8, [WithKey (List U8), WithoutKey], U64 -> List U8
blake2b = \input, withKey, hashBytesLength ->
    ll = List.len input
    endPad = List.repeat 0x00 ((128 - (ll % 128)) % 128)
    (preprocessedInput, kk) =
        when (withKey, input) is
            (WithoutKey, []) -> (List.repeat 0x00 128, 0)
            (WithoutKey, _) -> (List.concat input endPad, 0)
            (WithKey key, _) ->
                keyLen = List.len key
                keyBlock = List.concat key (List.repeat 0x00 (128 - keyLen))
                (List.join [keyBlock, input, endPad], keyLen)

    # Make 128 bytes input blocks ("d[0..dd-1]")
    inputBlocks = List.chunksOf preprocessedInput 128
    # Initialize the state ("h")
    initialState =
        blake2bIV
        |> List.update 0 \w ->
            Num.bitwiseXor w 0x01010000
            |> Num.bitwiseXor (Num.shiftLeftBy kk 8)
            |> Num.bitwiseXor hashBytesLength
    # Help function to split counter into high and low U64 parts
    split = \ctr ->
        high = Num.shiftRightZfBy ctr 64 |> Num.toU64
        low = Num.bitwiseAnd ctr 0xffffffffffffffff |> Num.toU64
        { high, low }
    # Process padded key and data blocks (except the last one)
    updatedState =
        List.dropLast inputBlocks 1
        |> List.walkWithIndex initialState \state, block, i ->
            ctr = (Num.toU128 i + 1) * 128 # bb = 128 bytes
            compress state block (split ctr) Bool.false

    # Process final block
    lastBlock = List.last inputBlocks |> Result.withDefault []
    lastCtr = if kk == 0 then Num.toU128 ll else Num.toU128 ll + 128 # bb = 128 bytes
    compress updatedState lastBlock (split lastCtr) Bool.true
    |> List.joinMap u64ToLeBytes
    |> List.takeFirst hashBytesLength

## Compression function takes the state vector ("h" in spec),
## message block vector ("m" in spec),
## a 2w-bit (128-bit) offset counter ("t" in spec),
## and final block indicator flag ("f" in spec),
## and returns the new state vector.
compress : List U64, List U8, { low : U64, high : U64 }, Bool -> List U64
compress = \state, block, ctr, finalBlockFlag ->
    # Pad the block and convert to U64 words
    blockWords =
        List.concat block (List.repeat 0x00 (128 - List.len block))
        |> List.chunksOf 8
        |> List.map u64FromLeBytes
    # Initialize local vector with state and IV
    vInit =
        List.concat state blake2bIV
        |> List.update 12 \word -> Num.bitwiseXor word ctr.low
        |> List.update 13 \word -> Num.bitwiseXor word ctr.high
        |> List.update 14 \word ->
            if finalBlockFlag then Num.bitwiseXor word Num.maxU64 else word

    # Cryptographic mixing step
    sigmaMixingStep = \v, (a, b, c, d), si, sj ->
        x = List.get blockWords si |> Result.withDefault 0
        y = List.get blockWords sj |> Result.withDefault 0
        va = List.get v a |> Result.withDefault 0
        vb = List.get v b |> Result.withDefault 0
        vc = List.get v c |> Result.withDefault 0
        vd = List.get v d |> Result.withDefault 0
        (vaNew, vbNew, vcNew, vdNew) = mixing va vb vc vd x y
        List.set v a vaNew
        |> List.set b vbNew
        |> List.set c vcNew
        |> List.set d vdNew
    # Cryptographic mixing round
    sigmaMixingRound = \v, round ->
        s = sigmaRound round
        sigmaMixingStep v (0, 4, 8, 12) s.0 s.1
        |> sigmaMixingStep (1, 5, 9, 13) s.2 s.3
        |> sigmaMixingStep (2, 6, 10, 14) s.4 s.5
        |> sigmaMixingStep (3, 7, 11, 15) s.6 s.7
        |> sigmaMixingStep (0, 5, 10, 15) s.8 s.9
        |> sigmaMixingStep (1, 6, 11, 12) s.10 s.11
        |> sigmaMixingStep (2, 7, 8, 13) s.12 s.13
        |> sigmaMixingStep (3, 4, 9, 14) s.14 s.15
    # Apply 12 mixing rounds to the local vector
    newV =
        sigmaMixingRound vInit 0
        |> sigmaMixingRound 1
        |> sigmaMixingRound 2
        |> sigmaMixingRound 3
        |> sigmaMixingRound 4
        |> sigmaMixingRound 5
        |> sigmaMixingRound 6
        |> sigmaMixingRound 7
        |> sigmaMixingRound 8
        |> sigmaMixingRound 9
        |> sigmaMixingRound 10
        |> sigmaMixingRound 11
    # XOR the two halves of v
    List.map3 state (List.sublist newV { start: 0, len: 8 }) (List.sublist newV { start: 8, len: 8 }) \hi, vi, vii ->
        Num.bitwiseXor hi vi |> Num.bitwiseXor vii

blake2bIV : List U64
blake2bIV = [
    0x6a09e667f3bcc908,
    0xbb67ae8584caa73b,
    0x3c6ef372fe94f82b,
    0xa54ff53a5f1d36f1,
    0x510e527fade682d1,
    0x9b05688c2b3e6c1f,
    0x1f83d9abfb41bd6b,
    0x5be0cd19137e2179,
]

## Selection permutation for one mixing round
sigmaRound : U8 -> (U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64, U64)
sigmaRound = \round ->
    when round is
        0 -> (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
        1 -> (14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3)
        2 -> (11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4)
        3 -> (7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8)
        4 -> (9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13)
        5 -> (2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9)
        6 -> (12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11)
        7 -> (13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10)
        8 -> (6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5)
        9 -> (10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0)
        _ -> sigmaRound (round % 10)

## The mixing function mixes two words x, y
## with four words v[a], v[b], v[c], v[d]
## and returns these four words modified.
## The vector v is the working vector of the blake algorithm.
##
## mixing va, vb, vc, vd, x, y -> new (va, vb, vc, vd)
mixing : U64, U64, U64, U64, U64, U64 -> (U64, U64, U64, U64)
mixing = \va, vb, vc, vd, x, y ->
    vaTemp = Num.addWrap va vb |> Num.addWrap x
    vdTemp = Num.bitwiseXor vd vaTemp |> rotr64 32 # R1 = 32
    vcTemp = Num.addWrap vc vdTemp
    vbTemp = Num.bitwiseXor vb vcTemp |> rotr64 24 # R2 = 24
    vaNew = Num.addWrap vaTemp vbTemp |> Num.addWrap y
    vdNew = Num.bitwiseXor vdTemp vaNew |> rotr64 16 # R3 = 16
    vcNew = Num.addWrap vcTemp vdNew
    vbNew = Num.bitwiseXor vbTemp vcNew |> rotr64 63 # R4 = 63
    (vaNew, vbNew, vcNew, vdNew)

## Cyclic rotatation to the right the bits of a U64 word.
## word >>> n = (word >> n) XOR (word << 64-n)
rotr64 : U64, U8 -> U64
rotr64 = \word, n ->
    Num.shiftRightZfBy word n
    |> Num.bitwiseXor (Num.shiftLeftBy word (64 - n))

u64FromLeBytes : List U8 -> U64
u64FromLeBytes = \bytes ->
    List.walkWithIndex bytes 0 \sum, b, i ->
        sum + Num.shiftLeftBy (Num.intCast b) (8 * Num.toU8 i)

## Helper function to extract individual bytes from an integer
u64ToLeBytes : U64 -> List U8
u64ToLeBytes = \b -> [
        Num.bitwiseAnd 0xff b,
        Num.bitwiseAnd 0xff00 b |> Num.shiftRightZfBy 8,
        Num.bitwiseAnd 0xff0000 b |> Num.shiftRightZfBy (8 * 2),
        Num.bitwiseAnd 0xff000000 b |> Num.shiftRightZfBy (8 * 3),
        Num.bitwiseAnd 0xff00000000 b |> Num.shiftRightZfBy (8 * 4),
        Num.bitwiseAnd 0xff0000000000 b |> Num.shiftRightZfBy (8 * 5),
        Num.bitwiseAnd 0xff000000000000 b |> Num.shiftRightZfBy (8 * 6),
        Num.bitwiseAnd 0xff00000000000000 b |> Num.shiftRightZfBy (8 * 7),
    ]
    |> List.map Num.toU8

# HELPER #######################################################################

### Helper function for displaying local v for debugging
# showV : List U64, U64 -> Str
# showV = \v, chunkSize ->
#    List.map v \w ->
#        hex (List.reverse (u64ToLeBytes w))
#    |> List.chunksOf chunkSize
#    |> List.map (\chunks -> Str.joinWith chunks " ")
#    |> Str.joinWith "\n"
#    |> Str.withPrefix "\n"
