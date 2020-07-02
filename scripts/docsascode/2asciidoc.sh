#! /bin/bash
# set -xe

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

workingdir=$PWD

tmpfile=$1.tmp
currenttmpdir="$(dirname "$tmpfile")"
filenametmp="$(basename -- "$tmpfile")"

case "$1" in
*.md ) 
        # Fix a bug in kramdoc about checkboxes
        sed -e "s/\* \[ \] /\* \\\[ \\\] /g" $1 > $tmpfile
        sed -i -e "s/\* \[x\] /\* \\\[x\\\] /gI" $tmpfile
        # replace <kbd>
        sed -i "s/<kbd>\(.*\)<\/kbd>/kbd:\[\1\]/g" $tmpfile
        kramdoc --format=GFM --output=$2 $tmpfile
        # fix attributes bad convertion
        sed -i -e "s/\\\{/{/g" $2
        # add autowidth on tables
        sed -i "s/\[cols=/\[%autowidth.stretch,cols=/g" $2
        ;;
*.rst ) 
        sed -e "s/\.\. newslide::/<<</g" $1 > $tmpfile
        # fix bug with enbeded rst -> go into input folder
        cd $currenttmpdir
        pandoc -s -f rst -t asciidoc $filenametmp -o $2 
        # go back into working dir
        cd $workingdir
        # fix attributes bad convertion
        sed -i -e "s/\\\{/{/g" $2
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
