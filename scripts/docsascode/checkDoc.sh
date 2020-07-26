#! /bin/bash
# set -xe

function check_doc {

        scriptdir=/usr/local/bin/
        pathname=$(cd "$(dirname "$1")"; pwd)/
        filenameWithExtension=$(basename -- "$1")
        filenameNoExtension="${filenameWithExtension%.*}"

        temp_output=$pathname
        # "/tmp"
        destination_folder=$pathname
        input_file="/tmp/cleared.txt"

        workingdir=$PWD

        currentdir="$(dirname "$1")"
        filename="$(basename -- "$1")"

        # clear input doc
        case "$1" in
        *.md ) 
                pandoc -s -f gfm -t plain --lua-filter=/usr/local/bin/templates/clearForCheck.lua $1 > $input_file
                ;;
        *.rst )
                cd $currentdir
                pandoc -s -f rst -t rst $filenameWithExtension -o $input_file.tmp
                pandoc -s -f rst -t plain --lua-filter=/usr/local/bin/templates/clearForCheck.lua $input_file.tmp > $input_file
                rm -rf $input_file.tmp
                cd $workingdir
                ;;
        *.adoc )
                asciidoctor $1 -a doctype=book -o /tmp/$filenameNoExtension.html        
                pandoc -s -f html -t plain --lua-filter=/usr/local/bin/templates/clearForCheck.lua /tmp/$filenameNoExtension.html > $input_file
                ;;

        *)
                echo "extension not supported. only rst,md, adoc."
                exit -1
                ;;
        esac

        # detect language
        sh $scriptdir/2meta.sh $1 /tmp/meta.txt
        source /tmp/meta.txt
        lang="fr-FR"

        # check spell & grammar
        current_exe_folder="/tmp/_check/"

        mkdir $current_exe_folder
        cp -rf /checks/$lang/* $current_exe_folder
        if [[ -d $pathname/_check/$lang/ ]] ; then
        cp -rf $pathname/_check/$lang/* $current_exe_folder
        fi

        source $current_exe_folder/check.dac

        echo "process file: "$1

        #merge all .dict file into a single with pws header and remove blank lines
        echo personal_ws-1.1 ${lang:0:2} 0 > $current_exe_folder/.personnal.pws
        cat $current_exe_folder/*.dict >> $current_exe_folder/.personnal.pws 2>/dev/null
        sed -i '/^$/d' $current_exe_folder/.personnal.pws

        #process check
        process $input_file

        # export results in Junit XMl format

        # remove tmp files
        rm -f /tmp/cleared.txt >> /dev/null
        rm -f /tmp/meta.txt >> /dev/null
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
