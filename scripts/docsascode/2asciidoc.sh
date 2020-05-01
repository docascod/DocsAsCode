#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

case "$1" in
*.md ) 
        kramdoc --format=GFM --output=$2 $1
        ;;
*.rst )
        pandoc -s -f rst -t asciidoc $1 -o $2
        ;;
*.adoc )
        cp $1 $2
        ;;

*)
        echo "extension not supported. only rst,md, adoc."
        exit -1
        ;;
esac

# clear diagram blocs
sed -i -e "s/\[source,graphviz/\[graphviz/g" $2
sed -i -e "s/\[source,mermaid/\[mermaid/g" $2
sed -i -e "s/\[source,plantuml/\[plantuml/g" $2
sed -i -e "s/\[source,vega-lite/\[vegalite/g" $2

exit 0
