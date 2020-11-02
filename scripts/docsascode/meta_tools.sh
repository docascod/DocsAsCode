#! /bin/bash
# set -xe

metaFile=/tmp/meta.yml
customMetaFile="__NOFILE__"

function initMeta {
  if [ "$#" -ne 1 ]; then
    printf "Illegal number of parameters\n"
    exit -1
  fi

  local currentdir="$(dirname "$1")"
  local filename="$(basename -- "$1")"

  rm -f $metaFile 2>/dev/null
  touch $metaFile

  case "$1" in
  *.md ) 
    pandoc -s -f markdown-smart -t json --shift-heading-level-by=-1 $1 | yq r - meta -P > $metaFile
    # cp $metaFile /documents/metamd.yaml
    ;;

  *.rst )
    local workingdir=$PWD
    cd $currentdir
    pandoc -s -f rst -t json $1 | yq r - meta -P > $metaFile
    # cp $metaFile /documents/metarst.yaml
    cd $workingdir
    ;;

  *.adoc )
    asciidoctor $1 -a doctype=book -o /tmp/asciidoctmp.html
    pandoc -s -f html -t json $1 | yq r - meta -P > $metaFile
    rm -f /tmp/asciidoctmp.html 2>/dev/null
    ;;
  
  *)
    printf "extension not supported. only rst,md, adoc.\n"
    exit -1
    ;;
  esac

  customMetaFile=$(readInMeta extra_meta $customMetaFile)
  if [ ! $customMetaFile = '__NOFILE__' ] && [ ! -f $currentdir/$customMetaFile ]; then
    printf "extra metadata file "$customMetaFile" not exists -> ignored\n"
    customMetaFile="__NOFILE__"
  fi
}

function readInMeta {
  local varPath=$1
  local defaultVal=""
  local result="__NOTHING__"

  ## if have a second param (default value)
  if [ "$#" == 2 ]; then
    defaultVal=$2
  fi

  [ $customMetaFile != '__NOFILE__' ] && result=$(yq r --defaultValue __NOTHING__ $customMetaFile $varPath)

  if [ "$result" = '__NOTHING__' ]; then

    ## type of param (single or list)
    local type=$(yq r --defaultValue __NOTYPE__ $metaFile $varPath.t)

    case "$type" in
      '__NOTYPE__' )
        result="__NOTHING__"
        ;;
      'MetaInlines' )
        result=$(yq r --defaultValue __NOTHING__ $metaFile $varPath.c.*.c)
        ;;
      'MetaList' | 'MetaBlocks')
        result=$(yq r --defaultValue __NOTHING__ $metaFile $varPath.c.*.c.*.c)
        ;;
    esac

  fi

  if [ "$result" = '__NOTHING__' ]; then 
    echo $defaultVal
  else
    echo $result      
  fi
}

# return only extra meta keys : not 'title', 'author', 'keywords',  'date', 'lang'
function getExtraMetaKeys {
  local classicalKeys=("title", "author", "keywords", "date", "lang")
  
  local allKeys=( $(yq r --printMode p $metaFile '*') )
  declare -a extraKeys

  for elem in "${allKeys[@]}"
  do 
    [[ ! " ${classicalKeys[*]} " == *"$elem"* ]] && extraKeys+=( "$elem" ) 
  done

  [ $customMetaFile != '__NOFILE__' ] && allKeysExtra=( $(yq r --printMode p $customMetaFile '*') )
  for elem in "${allKeysExtra[@]}"
  do 
    [[ ! " ${classicalKeys[*]} " == *"$elem"* ]] && extraKeys+=( "$elem" ) 
  done

  echo ${extraKeys[@]}
}

# echo title=$(readInMeta title)
# keys=( $(readInMeta keywords) )
# for output in "${keys[@]}"; do
#   echo key=$output
# done