app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task
import U256 exposing [U256]

main =
    Stdout.line "Call instead: roc test 06-poly1305.roc"

# TESTS ########################################################################

expect
    key = { r: 0xa806d542fe52447f336d555778bed685, s: 0x1bf54941aff6bf4afdb20dfb8a800301 }
    message = Str.toUtf8 "Cryptographic Forum Research Group"
    toLeBytes (poly1305OneTimeMac message key) == [0xa8, 0x06, 0x1d, 0xc1, 0x30, 0x51, 0x36, 0xc6, 0xc2, 0x2b, 0x8b, 0xaf, 0x0c, 0x01, 0x27, 0xa9]

# IMPLEMENTATION ###############################################################

# Implementation done by reading both:
# - https://datatracker.ietf.org/doc/html/rfc7539#section-2.5
# - https://cr.yp.to/mac/poly1305-20050329.pdf

## Key for the One-Time MAC Poly1305.
## The (r, s) pairs must always be unique.
Key : { r : U128, s : U128 }

## Compute the poly1305 One-Time MAC of a message
poly1305OneTimeMac : List U8, Key -> U128
poly1305OneTimeMac = \message, key ->
    # key.r is clamped
    r = { high: 0, low: Num.bitwiseAnd key.r 0x0ffffffc0ffffffc0ffffffc0fffffff }
    # p = 2^130 - 5
    p = { high: 0x03, low: 0xfffffffffffffffffffffffffffffffb }
    List.chunksOf message 16
    |> List.walk U256.zero \accum, block ->
        a = U256.add accum (pad block)
        m = U256.mul r a
        U256.rem m p
    |> U256.add { high: 0, low: key.s }
    |> .low

## Take some bytes in little endian order,
## pad with 0x01, and convert to a U256.
pad : List U8 -> U256
pad = \bytes ->
    len = List.len bytes
    lastPad = U256.shiftLeftBy U256.one (8 * Num.toU8 len)
    U256.add { high: 0, low: fromLeBytes bytes } lastPad

## Convert a sequence of little endian U8 bytes into a U128 number.
fromLeBytes : List U8 -> U128
fromLeBytes = \bytes ->
    List.walkWithIndex bytes 0 \sum, b, i ->
        sum + Num.shiftLeftBy (Num.toU128 b) (8 * Num.toU8 i)

## Helper function to extract individual bytes from an integer
toLeBytes : U128 -> List U8
toLeBytes = \b -> [
        Num.bitwiseAnd 0xff b,
        Num.bitwiseAnd 0xff00 b |> Num.shiftRightZfBy 8,
        Num.bitwiseAnd 0xff0000 b |> Num.shiftRightZfBy (8 * 2),
        Num.bitwiseAnd 0xff000000 b |> Num.shiftRightZfBy (8 * 3),
        Num.bitwiseAnd 0xff00000000 b |> Num.shiftRightZfBy (8 * 4),
        Num.bitwiseAnd 0xff0000000000 b |> Num.shiftRightZfBy (8 * 5),
        Num.bitwiseAnd 0xff000000000000 b |> Num.shiftRightZfBy (8 * 6),
        Num.bitwiseAnd 0xff00000000000000 b |> Num.shiftRightZfBy (8 * 7),
        Num.bitwiseAnd 0xff0000000000000000 b |> Num.shiftRightZfBy (8 * 8),
        Num.bitwiseAnd 0xff000000000000000000 b |> Num.shiftRightZfBy (8 * 9),
        Num.bitwiseAnd 0xff00000000000000000000 b |> Num.shiftRightZfBy (8 * 10),
        Num.bitwiseAnd 0xff0000000000000000000000 b |> Num.shiftRightZfBy (8 * 11),
        Num.bitwiseAnd 0xff000000000000000000000000 b |> Num.shiftRightZfBy (8 * 12),
        Num.bitwiseAnd 0xff00000000000000000000000000 b |> Num.shiftRightZfBy (8 * 13),
        Num.bitwiseAnd 0xff0000000000000000000000000000 b |> Num.shiftRightZfBy (8 * 14),
        Num.bitwiseAnd 0xff000000000000000000000000000000 b |> Num.shiftRightZfBy (8 * 15),
    ]
    |> List.map Num.toU8
