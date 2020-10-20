#! /bin/bash
# set -xe

allpdf=""

outputPDF="out.pdf"
[[ ! -z "$DEFAULT_NAME" ]] && outputPDF=$DEFAULT_NAME

destination_folder="."
[[ ! -z "$DEFAULT_DESTINATION" ]] && destination_folder=$DEFAULT_DESTINATION

while [[ $# -gt 0 ]]
do

  files=( $1 )
  for file in "${files[@]}"
  do

    case "${file,,}" in
    *.pdf) 
            allpdf=$allpdf" "$file
            shift
            ;;
    *)
            printf "extension not supported. only pdf.\n"
            exit -1
            ;;
    esac

  done

done


if [ ! -z "$allpdf" ] 
then
    echo -e "assemble: "$allpdf
    qpdf --empty $destination_folder/$outputPDF --pages $allpdf "--"
    if [ -f $destination_folder/$outputPDF ]; then
      printf "  → file generated: "$destination_folder"/"$outputPDF"\n"
      generatedFiles=( "$destination_folder/$outputPDF" )
    else
      printf "  → NO file generated\n"
    fi
else
    printf "nothing to assemble\n"
fi
