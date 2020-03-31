#! /bin/bash
# set -xe

case $1 in
  build) shift
         source buildDoc.sh $*
         ;; 
  check) shift
         source checkDoc.sh $*
         ;;
  assemble) shift
         source assembleDoc.sh $*
         ;;
  *) echo "usage : build sourcefiles\n check sourcefiles";;
esac
