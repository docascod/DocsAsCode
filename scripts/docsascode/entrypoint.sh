#! /bin/bash
# set -xe

declare -a generatedFiles

case $1 in
  build) shift
         # init list of generated files
         # launch build of files
         source buildDoc.sh $*
         # return generated files list
         # echo ${generatedFiles[@]}
         ;; 
  check) shift
         source checkDoc.sh $*
         ;;
  assemble) shift
         source assembleDoc.sh $*
         ;;
  *) printf "usage : build sourcefiles\n check sourcefiles\nassemble pdfFiles\n";;
esac
