#!/bin/sh

# Copyright 2020 Steffen Hirschmann <steffen.hirschmann@ipvs.uni-stuttgart.de>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

#
# This program reads a latex formula from stdin and transforms it to an inline
# svg link. (I use it with Firefox for Mattermost, other combinations might
# also work).
#

HEADER="""\\documentclass[preview]{standalone}
\\usepackage{amsmath}
\\begin{document}
\\begin{equation*}"""

FOOTER="""\\end{equation*}
\\end{document}"""


# Temp dir to compile latex source
dir="$(mktemp -d)"
mkdir -p "$dir"
cd "$dir" || exit 1
# Remove temp dir at exit
trap "rm -rf \"$dir\"" EXIT


f="$dir/pic.tex"
printf "%s\\n" "$HEADER" >"$f"
cat >>"$f" # Stdin is your formula
printf "%s\\n" "$FOOTER" >>"$f"

# Build pdf, crop it and transform it to svg
latexmk -pdf "$f" || exit 2
pdfcrop "$dir/pic.pdf" || exit 3
inkscape -l "$dir/pic.svg" "$dir/pic-crop.pdf" || exit 4

# Transform pic to inline svg base64 coded image link
# and paste it to the clipboard
imgdata="$(base64 "$dir/pic.svg")"
[ -n "$imgdata" ] || exit 5
printf "![img](data:image/svg+xml;base64,%s)" "$imgdata" | xsel -b -i

echo
echo "Image data has been pasted to clipboard"
echo

