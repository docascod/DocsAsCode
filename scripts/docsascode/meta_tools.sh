#! /bin/bash
# set -xe

meta_from_currentfile=/tmp/meta.yml
global_meta_file="__NOFILE__"
associated_meta_file="__NOFILE__"

function initMeta {
  if [ "$#" -ne 1 ]; then
    printf "Illegal number of parameters\n"
    exit -1
  fi

  local currentdir="$(dirname "$1")"
  local filename="$(basename -- "$1")"

  rm -f $meta_from_currentfile 2>/dev/null
  touch $meta_from_currentfile

  ## try to extract meta from current document
  case "$1" in
  *.md ) 
    pandoc -s -f markdown-smart -t json --shift-heading-level-by=-1 $1 | yq e - meta -P > $meta_from_currentfile
    # cp $meta_from_currentfile /documents/metamd.yaml
    ;;

  *.rst )
    local workingdir=$PWD
    cd $currentdir
    pandoc -s -f rst -t rst $filename -o /tmp/fullrst.rst
    pandoc -s -f rst -t json $filename | yq e - meta -P > $meta_from_currentfile
    # cp $meta_from_currentfile /documents/metarst.yaml
    rm -r /tmp/fullrst.rst
    cd $workingdir
    ;;

  *.adoc )
    asciidoctor $1 -a doctype=book -o /tmp/asciidoctmp.html
    pandoc -s -f html -t json $1 | yq e - meta -P > $meta_from_currentfile
    rm -f /tmp/asciidoctmp.html 2>/dev/null
    ;;
  
  *)
    printf "extension not supported. only rst,md, adoc.\n"
    exit -1
    ;;
  esac

  ## try to link meta from external global meta file (indicated with extra_meta key)
  global_meta_file=$(readInMeta extra_meta $global_meta_file)
  if [ ! $global_meta_file = '__NOFILE__' ]; then
    if [ ! -f $currentdir/$global_meta_file ]; then
      printf "extra metadata file "$global_meta_file" not exists -> ignored\n"
      global_meta_file="__NOFILE__"
    elif ! yq validate $global_meta_file; then 
      printf "extra metadata file is not valid\n"
      global_meta_file="__NOFILE__"
    fi
  fi

  ## try to link meta from associated meta file (current file with extra meta extension)
  associated_meta_file=$1".meta"
  if [ ! -f $associated_meta_file ]; then
    associated_meta_file="__NOFILE__"
  elif ! yq validate $associated_meta_file; then 
    printf "extra metadata file is not valid\n"
    associated_meta_file="__NOFILE__"
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

  ## search path in global meta
  [ $global_meta_file != '__NOFILE__' ] && result=$(yq e "$varPath" // '__NOTHING__' $global_meta_file)

  if [ "$result" = '__NOTHING__' ]; then

    ## or search path in associated meta
    [ $associated_meta_file != '__NOFILE__' ] && result=$(yq e "$varPath" // '__NOTHING__' $associated_meta_file)
    if [ "$result" = '__NOTHING__' ]; then

      ## finaly search meta in current doc meta
      ## type of param (single or multiple
      local type=$(yq e "$varPath" // '__NOTYPE__' $meta_from_currentfile.t)
  
      case "$type" in
        '__NOTYPE__' )
          result="__NOTHING__"
          ;;
        'MetaInlines' )
          result=$(yq e "$varPath" // '__NOTHING__' $meta_from_currentfile.c.*.c)
          ;;
        'MetaList' | 'MetaBlocks' )
          result=$(yq e "$varPath" // '__NOTHING__' $meta_from_currentfile.c.*.c.*.c)
          ## TODO return nice array
          ;;
      esac

    fi

  fi

  if [ "$result" = '__NOTHING__' ]; then 
    echo $defaultVal
  else
    echo $result      
  fi
}

# return only extra meta keys : not 'title', 'author', 'keywords',  'date', 'lang'
function getExtraMetaKeys {
  local classicalKeys=("title", "author", "keywords", "date", "lang", "extra_meta")
  
  local allKeys=( $(yq r --printMode p $meta_from_currentfile '*') )
  declare -a extraKeys

  for elem in "${allKeys[@]}"
  do 
    [[ ! " ${classicalKeys[*]} " == *"$elem"* ]] && extraKeys+=( "$elem" ) 
  done

  [ $associated_meta_file != '__NOFILE__' ] && allKeysExtraAssociated=( $(yq r --printMode p $associated_meta_file '*') )
  for elem in "${allKeysExtraAssociated[@]}"
  do 
    if [[ ! " ${classicalKeys[*]} " == *"$elem"* ]] && [[ ! " ${extraKeys[*]} " ==  *"$elem"* ]]; then 
      extraKeys+=( "$elem" )
    fi
  done

  [ $global_meta_file != '__NOFILE__' ] && allKeysExtra=( $(yq r --printMode p $global_meta_file '*') )
  for elem in "${allKeysExtra[@]}"
  do 
    if [[ ! " ${classicalKeys[*]} " == *"$elem"* ]] && [[ ! " ${extraKeys[*]} " ==  *"$elem"* ]]; then 
      extraKeys+=( "$elem" )
    fi
  done
  echo ${extraKeys[@]}
}

# echo title=$(readInMeta title)
# keys=( $(readInMeta keywords) )
# for output in "${keys[@]}"; do
#   echo key=$output
# done
