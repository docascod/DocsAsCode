#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

workingdir=$PWD

currentdir="$(dirname "$1")"
filename="$(basename -- "$1")"

case "$1" in
*.md ) 
        cp $1 $2
        ;;
*.rst )
        cd $currentdir
        pandoc -s -f rst -t markdown $1 -o $2
        cd $workingdir
        ;;
*.adoc )
        asciidoc -b docbook $1 -o /tmp/asciidocmd.xml
        pandoc -s -f docbook -t markdown /tmp/asciidocmd.xml > $2
        rm -f /tmp/asciidocmd.xml 2>/dev/null
        ;;

*)
        echo "extension not supported. only rst,md, adoc."
        exit -1
        ;;
esac

exit 0