#! /bin/bash
# set -xe

# load utilities
source parse_yaml.sh

function cleanVar {
    local varValue=$1
    if [ -z varValue ] || [ "$varValue" = '~' ]
    then
        echo ""
    else
        echo $varValue
    fi
}

function build_doc {

  local input_file=$1
  local conditions=$2

  local pathname=$(cd "$(dirname "$input_file")"; pwd)/
  local filenameWithExtension=$(basename -- "$input_file")
  local filenameNoExtension="${filenameWithExtension%.*}"
  local destination_folder=$pathname

  [[ ! -z "$DEFAULT_DESTINATION" ]] && destination_folder=$DEFAULT_DESTINATION

  echo "process file: "$filenameWithExtension

  # prepare outputs
  2meta.sh $input_file /tmp/meta.txt
  source /tmp/meta.txt

  # clean array
  declare -a outputs_arr
  for output in "${outputs[@]}"; do
    if [[ $output == output* ]]; then
      # clean output entries
      output=${output//[-,'']/}
      outputs_arr+=( "$output" )
    fi
  done
  if [ ${#outputs_arr[@]} -eq 0 ]; then
    outputs_arr=("$DEFAULT_OUTPUT")
  fi

  # create a copy of output (for merging with custom)
  cp -rf /output/ /_output/

  # merge custom output from documents root
  if [[ -d /documents/_output/ ]] ; then
    cp -rf /documents/_output/* /_output/
  fi

  # merge custom output from file folder - override documents customisation
  if [[ -d $pathname/_output/ ]] ; then
    cp -rf $pathname/_output/* /_output/
  fi

  # set merged destination output folder
  local current_output_template_path=/tmp/buildir/

  # load utilities
  source parse_yaml.sh

  # for each output
  for output in "${outputs_arr[@]}"; do
       # create temporary folder for custom output
       mkdir -p $current_output_template_path 2>/dev/null

       # split each output on . char
       IFS='.' read -r -a pathArray <<< "$output"

       local output_path=/_
       # foreach part of the output
       for i in "${pathArray[@]}"; do
               # add this part to the source path
               output_path+=$i/

               # force files (only) copy on destination path
               cp -f $output_path/* $current_output_template_path 2>/dev/null
       done

       cp -rf $(gem environment gemdir)/gems/asciidoctor-pdf-$ASCIIDOCTOR_PDF_VERSION/data/themes/* $current_output_template_path/

       echo " - process output: "$output

      # prepare to launch commands to produce output
      ## Ramdom bug with parse_yaml, sometimes it genrates double separator => fix with _# and sed
      eval $(parse_yaml $current_output_template_path/config.yml "" "_#" | sed "s/_#_#/_/g" | sed "s/_#/_/g")
      eval $(parse_yaml $current_output_template_path/dac-theme.yml "" "_#" | sed "s/_#_#/_/g" | sed "s/_#/_/g")
      eval $(parse_yaml $current_output_template_path/dac_custom-theme.yml "" "_#" | sed "s/_#_#/_/g" | sed "s/_#/_/g")
      source $current_output_template_path/build.dac

       # launch process
      process $input_file $pathname $destination_folder $filenameNoExtension $version
      postprocess $input_file $pathname $destination_folder $filenameNoExtension

       # clear temp folder
       rm -rf $current_output_template_path
  done

  # remove ouput copy
  rm -rf /_output/

}

[[ -z "$DEFAULT_OUTPUT" ]] && DEFAULT_OUTPUT=output.document

while [[ $# -gt 0 ]]
do

  files=( $1 )
  for file in "${files[@]}"
  do

    case "${file,,}" in
    *.md | *.rst | *.adoc) 
            build_doc $file
            shift
            ;;
    *)
            echo "extension not supported. only rst,md, adoc."
            exit -1
            ;;
    esac

  done
done
