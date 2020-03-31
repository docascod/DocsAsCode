#! /bin/bash
# set -xe

allpdf=""
outputPDF="out.pdf"
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
            echo "extension not supported. only pdf."
            exit -1
            ;;
    esac

  done

done

if [ ! -z "$allpdf" ] 
then
    echo "assemble: "$allpdf
    qpdf --empty $outputPDF --pages $allpdf "--"
else
    echo "nothing to assemble"
fi