#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

case "$1" in
*.md ) 
        pandoc -s -f markdown -t rst $1 -o $2
        ;;
*.rst )
        cp $1 $2
        ;;
*.adoc )
        asciidoc -b docbook $1 -o /tmp/asciidocmd.xml
        pandoc -s -f docbook -t rst /tmp/asciidocmd.xml > $2
        rm -f /tmp/asciidocmd.xml 2>/dev/null
        ;;

*)
        echo "extension not supported. only rst,md, adoc."
        exit -1
        ;;
esac

exit 0