#! /bin/bash
# set -xe

scriptdir=/usr/local/bin/
default_lang="fr-FR"

function check_doc {

        local pathname=$(cd "$(dirname "$1")"; pwd)/
        local filenameWithExtension=$(basename -- "$1")
        local filenameNoExtension="${filenameWithExtension%.*}"

        local input_file_spell="/tmp/cleared_spell.txt"
        local input_file_grammar="/tmp/cleared_grammar.txt"
        local input_file_meta="/tmp/meta.txt"

        local workingdir=$PWD
        local currentdir="$(dirname "$1")"

        # clear input doc
        case "$1" in
        *.md ) 
                pandoc -s -f gfm -t plain --lua-filter=/usr/local/bin/templates/clearForCheckSpell.lua $1 > $input_file_spell
                sed -i 's/^[ \t]*TIP://g' $input_file_spell
                sed -i 's/^[ \t]*WARNING://g' $input_file_spell
                sed -i 's/^[ \t]*NOTE://g' $input_file_spell
                sed -i 's/^[ \t]*IMPORTANT://g' $input_file_spell
                sed -i 's/^[ \t]*CAUTION://g' $input_file_spell

                pandoc -s -f gfm -t plain --lua-filter=/usr/local/bin/templates/clearForCheckGrammar.lua $1 > $input_file_grammar
                sed -i 's/^[ \t]*TIP://g' $input_file_grammar
                sed -i 's/^[ \t]*WARNING://g' $input_file_grammar
                sed -i 's/^[ \t]*NOTE://g' $input_file_grammar
                sed -i 's/^[ \t]*IMPORTANT://g' $input_file_grammar
                sed -i 's/^[ \t]*CAUTION://g' $input_file_grammar
                ;;
        *.rst )
                cd $currentdir
                pandoc -s -f rst -t rst $filenameWithExtension -o $input_file_spell.tmp
                pandoc -s -f rst -t plain --lua-filter=/usr/local/bin/templates/clearForCheckSpell.lua $input_file_spell.tmp > $input_file_spell
                pandoc -s -f rst -t plain --lua-filter=/usr/local/bin/templates/clearForCheckGrammar.lua $input_file_spell.tmp > $input_file_grammar
                rm -rf $input_file_spell.tmp
                cd $workingdir
                ;;
        *.adoc )
                asciidoctor $1 -a doctype=book -o /tmp/$filenameNoExtension.html        
                pandoc -s -f html -t plain --lua-filter=/usr/local/bin/templates/clearForCheckSpell.lua /tmp/$filenameNoExtension.html > $input_file_spell
                pandoc -s -f html -t plain --lua-filter=/usr/local/bin/templates/clearForCheckGrammar.lua /tmp/$filenameNoExtension.html > $input_file_grammar
                ;;
        esac

        # detect language
        sh $scriptdir/2meta.sh $1 $input_file_meta
        source $input_file_meta
        if [ -z ${lang+x} ]; then 
          lang=$default_lang
        fi

        # check spell & grammar
        current_exe_folder="/tmp/_check/"

        mkdir $current_exe_folder
        cp -rf /checks/$lang/* $current_exe_folder

        # merge custom check from documents root
        if [[ -d /documents/_check/$lang/ ]] ; then
          cp -rf /documents/_check/$lang/* $current_exe_folder
        fi

        # merge custom check from file folder - override documents customisation
        if [[ -d $pathname/_check/$lang/ ]] ; then
          cp -rf $pathname/_check/$lang/* $current_exe_folder
        fi

        source $current_exe_folder/check.dac

        echo -e "\nprocess file: "$1

        #merge all .dict file into a single with pws header and remove blank lines
        cat $current_exe_folder/*.dict >> $current_exe_folder/.GLOBAL.dict 2>/dev/null

        #process check spell
        check_spell $input_file_spell

        #process check grammar
        check_grammar $input_file_spell

        # export results in Junit XMl format

        # remove tmp files
        rm -f $input_file_spell >> /dev/null
        rm -f $input_file_meta >> /dev/null
        rm -rf $current_exe_folder
}

while [[ $# -gt 0 ]]
do

  files=( $1 )
  for file in "${files[@]}"
  do

    case "${file,,}" in
    *.md | *.rst | *.adoc) 
            check_doc $file
            shift
            ;;
    *)
            echo "extension not supported. only rst,md, adoc."
            exit -1
            ;;
    esac
  done

done


