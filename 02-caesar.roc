app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task

main =
    Stdout.line! "Call instead: roc test caesar.roc"

expect caesar "abc" 1 == Ok "bcd"
expect caesar "abc" 25 == Ok "zab"

caesar : Str, U8 -> Result Str _
caesar = \plaintext, shift ->
    Str.toUtf8 plaintext
    |> List.map \c -> (c - 'a' + shift) % 26 + 'a'
    |> Str.fromUtf8
