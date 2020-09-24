#! /bin/bash
# set -xe

# source yq_functions.sh

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

twoColsStart="##2colsstart##"
twoColsRow="##2colsrow##"
twoColsEnd="##2colsend##"

workingdir=$PWD

tmpfile=$1.tmp
currenttmpdir="$(dirname "$tmpfile")"
filenametmp="$(basename -- "$tmpfile")"

case "$1" in
*.md )
        cp $1 $tmpfile
        cd $currenttmpdir
        sed -i "s/<kbd>\(.*\)<\/kbd>/kbd:\[\1\]/g" $filenametmp
        sed -i "s/==\([^=].*[^=]\)==/[.yellow-background]#\1#/g" $filenametmp
        sed -i -e "s/<!-- 2cols -->/$twoColsStart/g" $filenametmp
        sed -i -e "s/<!-- newcol -->/$twoColsRow/g" $filenametmp
        sed -i -e "s/<!-- end_2cols -->/$twoColsEnd/g" $filenametmp        
        pandoc -s -f markdown -t asciidoc --lua-filter=/usr/local/bin/templates/replaceMeta.lua $filenametmp -o $2
        # go back into working dir
        cd $workingdir
        # fix attributes bad convertion
        sed -i -e "s/\\\{/{/g" $2        
        ;;
*.rst ) 
        cp $1 $tmpfile
        # fix bug with enbeded rst -> go into input folder
        cd $currenttmpdir
        pandoc -s -f rst -t rst $filenametmp -o $2.tmp
        sed -i -e "s/\.\. container:: newslide/<<</g" $2.tmp

        sed -i -e "s/^\([ \t]*\).. container:: sliderow/\1$twoColsStart/g" $2.tmp
        sed -i -e "s/^\([ \t]*\).. container:: slidecol/\1$twoColsRow/g" $2.tmp
        sed -i -e "s/^\([ \t]*\).. container:: endsliderow/\1$twoColsEnd/g" $2.tmp

        sed -i -e "s/^\([ \t]*\).. container:: 2cols/\1$twoColsStart/g" $2.tmp
        sed -i -e "s/^\([ \t]*\).. container:: newcol/\1$twoColsRow/g" $2.tmp
        sed -i -e "s/^\([ \t]*\).. container:: end_2cols/\1$twoColsEnd/g" $2.tmp        

        sed -i -e "s/:download:\`\(.*\)\`/\`\1\`_/g" $2.tmp

        sed -i "/container:: only/{
          :a;N;/container:: endonly/!ba;/$3/p;s/.. container:: only\n\n   $3\n\(.*\)\n.*/\1/g}" $2.tmp
        sed -i "/container:: only/{
          :a;N;/container:: endonly/!ba;//d}" $2.tmp

        echo "VERSION: $3"
        cat $2.tmp


        pandoc -s -f rst -t asciidoc $2.tmp -o $2
        rm -f $2.tmp 
        # go back into working dir
        cd $workingdir
        # fix attributes bad convertion
        sed -i -e "s/\\\{/{/g" $2
        # remove text bloc title
        sed -i -e "/^\.Note/d" $2
        sed -i -e "/^\.Warning/d" $2
        sed -i -e "/^\.Tip/d" $2
        sed -i -e "/^\.Caution/d" $2
        sed -i -e "/^\.Important/d" $2

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

# add fullwidth on tables and autowidth on columns
# if [ ! -z table_fullwidth ] && [ '$table_fullwidth'  = true ]; then sed -i "s/\[cols=/\[%autowidth.stretch,cols=/g" $2 ; fi

# fix image bloc vs inline
sed -i "s/^image:\([^:].*\)\[\([^]]*\)\]$/image::\1[\2]/g" $2

# manage multi columns
sed -i -e "s/\([ \t]*\)$twoColsStart/\1\[cols=2*a,%autowidth.stretch,frame=none,grid=none,stripes=none\]\n|===/g" $2
sed -i -e "s/\([ \t]*\)$twoColsRow/\1|/g" $2
sed -i -e "s/\([ \t]*\)$twoColsEnd/\1|===/g" $2
sed -i -e '/^____/d' $2
sed -i ':a;N;$!ba;s/--\n|/|/g' $2
sed -i ':a;N;$!ba;s/--\n\n|==/|==/g' $2

# clear diagram blocs
sed -i -e "s/\[source,graphviz/\[graphviz/g" $2
sed -i -e "s/\[source,mermaid/\[mermaid/g" $2
sed -i -e "s/\[source,plantuml/\[plantuml/g" $2
sed -i -e "s/\[source,vega-lite/\[vegalite/g" $2
sed -i -e "s/\[source,vegalite/\[vegalite/g" $2
sed -i -e "s/\[source,vega/\[vega/g" $2

# force break before subtitles
# echo $(readVarInYml $default_tmp_builddir/full.yml heading.h2.breakbefore)
# if [ ! -z heading_h2_breakbefore ] && [ '$heading_h2_breakbefore'  = true ]; then sed -i -e 's/^== /<<<\n== /g' $2 ; fi
# if [ ! -z heading_h3_breakbefore ] && [ '$heading_h3_breakbefore'  = true ]; then sed -i -e 's/^=== /<<<\n=== /g' $2 ; fi
# if [ ! -z heading_h4_breakbefore ] && [ '$heading_h4_breakbefore'  = true ]; then sed -i -e 's/^==== /<<<\n==== /g' $2 ; fi
# if [ ! -z heading_h5_breakbefore ] && [ '$heading_h5_breakbefore'  = true ]; then sed -i -e 's/^===== /<<<\n===== /g' $2 ; fi
# if [ ! -z heading_h6_breakbefore ] && [ '$heading_h6_breakbefore'  = true ]; then sed -i -e 's/^====== /<<<\n====== /g' $2 ; fi

exit 0
