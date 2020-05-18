#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

tmpfile=/tmp/work.tmp
case "$1" in
*.md ) 
        # Fix a bug in kramdoc about checkboxes
        sed -e "s/\* \[ \] /\* \\\[ \\\] /g" $1 > $tmpfile
        sed -i -e "s/\* \[x\] /\* \\\[x\\\] /gI" $tmpfile
        # end of fix
        kramdoc --format=GFM --output=$2 $tmpfile
        # fix attributes bad convertion
        sed -i -e "s/\\\{/{/g" $2
        ;;
*.rst )
        sed -e "s/\.\. newslide::/<<</g" $1 > $tmpfile
        pandoc -s -f rst -t asciidoc $tmpfile -o $2
        ;;
*.adoc )
        cp $1 $2
        ;;

*)
        echo "extension not supported. only rst,md and adoc."
        exit -1
        ;;
esac
rm -f $tmpfile


# clear diagram blocs
sed -i -e "s/\[source,graphviz/\[graphviz/g" $2
sed -i -e "s/\[source,mermaid/\[mermaid/g" $2
sed -i -e "s/\[source,plantuml/\[plantuml/g" $2
sed -i -e "s/\[source,vega-lite/\[vegalite/g" $2

exit 0
