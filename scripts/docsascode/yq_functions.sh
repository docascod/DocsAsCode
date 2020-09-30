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

function testreadVarInYml {
  local tmpYmlFile=$ymlFile
  ymlFile=/tmp/test.yaml
  printf "a:\n  b: c\n  e: ~\n" > $ymlFile

  cat $ymlFile
  if [ "$(readVarInYml a.b D)" != 'c' ];  then echo "exit 1: $(readVarInYml a.b D)"; fi
  if [ "$(readVarInYml a.b)" != 'c' ];    then echo "exit 2: $(readVarInYml a.b)"; fi
  if [ "$(readVarInYml a.c D)" != 'D' ];  then echo "exit 3: $(readVarInYml a.c D)"; fi
  if [ "$(readVarInYml a.c)" != '' ];     then echo "exit 4: $(readVarInYml a.c)"; fi
  if [ "$(readVarInYml a.e D)" != 'D' ];  then echo "exit 5: $(readVarInYml a.e D)"; fi
  if [ "$(readVarInYml a.e)" != '' ];     then echo "exit 6: $(readVarInYml a.e)"; fi

  rm -rf /tmp/test.yml
  ymlFile=$tmpYmlFile
}
