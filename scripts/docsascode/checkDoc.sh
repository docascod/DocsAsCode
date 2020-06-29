#! /bin/bash
# set -xe
DEFAULT_OUTPUT=output.document

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
        pandoc -s -f rst -t plain --lua-filter=/usr/local/bin/templates/clearForCheck.lua $1 > $input_file
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
process $input_file


# export results in Junit XMl format

# remove tmp files
rm -f /tmp/cleared.txt >> /dev/null
rm -f /tmp/meta.txt >> /dev/null

