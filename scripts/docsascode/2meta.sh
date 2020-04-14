#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

case "$1" in
*.md ) 
        pandoc -s -f markdown -t plain --template=/usr/local/bin/templates/plain_meta.tex $1 > $2
        ;;
*.rst )
        pandoc -s -f rst -t plain --template=/usr/local/bin/templates/plain_meta.tex $1 > $2
        ;;
*.adoc )
        asciidoctor $1 -a doctype=book -o /tmp/asciidoctmp.html
        pandoc -s -f html -t plain --template=/usr/local/bin/templates/plain_meta.tex /tmp/asciidoctmp.html > $2
        rm -f /tmp/asciidoctmp.html 2>/dev/null
        ;;

*)
        echo "extension not supported. only rst,md, adoc."
        exit -1
        ;;
esac
exit 0