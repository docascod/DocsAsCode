#!/bin/bash

ymlFile=/tmp/buildir/full.yml

function readVarInYml {
  local varPath=$1
  local defaultVal='""'
  local varValue=""
  if [[ "$#" == 2 ]]; then 
    defaultVal=$2
    varValue=$(yq r --defaultValue $defaultVal $ymlFile $varPath)
  else
    defaultVal=""
    varValue=$(yq r --defaultValue __NOTHING__ $ymlFile $varPath)
  fi
  
  if [ "$varValue" = '__NOTHING__' ]
  then
    echo ""
  elif [ "$varValue" = '~' ]
  then
    echo "$defaultVal"
  else
    echo $varValue
  fi
}

function mergeYml {
  local file1=$1
  local file2=$2
  # if first file not exists -> create it
  if [ ! -f $file1 ]; then
   touch $file1
  fi
  # do merge only if second file exists
  if [ -f $file2 ]; then
    yq m -i -x $file1 $file2
  fi
}

function testreadVarInYml {
  local tmpYmlFile=$ymlFile
  ymlFile=/tmp/test.yaml
  printf "a:\n  b: c\n  e: ~\n" > $ymlFile

  cat $ymlFile
  if [ "$(readVarInYml a.b D)" != 'c' ];  then printf "exit 1: $(readVarInYml a.b D)\n"; fi
  if [ "$(readVarInYml a.b)" != 'c' ];    then printf "exit 2: $(readVarInYml a.b)\n"; fi
  if [ "$(readVarInYml a.c D)" != 'D' ];  then printf "exit 3: $(readVarInYml a.c D)\n"; fi
  if [ "$(readVarInYml a.c)" != '' ];     then printf "exit 4: $(readVarInYml a.c)\n"; fi
  if [ "$(readVarInYml a.e D)" != 'D' ];  then printf "exit 5: $(readVarInYml a.e D)\n"; fi
  if [ "$(readVarInYml a.e)" != '' ];     then printf "exit 6: $(readVarInYml a.e)\n"; fi

  rm -rf /tmp/test.yml
  ymlFile=$tmpYmlFile
}
