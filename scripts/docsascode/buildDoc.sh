#! /bin/bash
# set -xe

# load utilities
source yq_functions.sh
source meta_tools.sh

function build_doc {

  local input_file=$1

  local pathname=$(cd "$(dirname "$input_file")"; pwd)/
  local filenameWithExtension=$(basename -- "$input_file")
  local filenameNoExtension="${filenameWithExtension%.*}"
  local destination_folder=$pathname

  [[ ! -z "$DEFAULT_DESTINATION" ]] && destination_folder=$DEFAULT_DESTINATION

  printf "process file: "$filenameWithExtension"\n"

  # prepare outputs
  initMeta $input_file

  local meta_outputs=$(readInMeta keywords $DEFAULT_OUTPUT)
  meta_outputs=(${meta_outputs//,/ })
  
  # clean array
  declare -a outputs_arr
  for output in "${meta_outputs[@]}"; do
    if [[ $output == output* ]]; then
      # clean output entries
      output=${output//[-,'']/}
      outputs_arr+=( "$output" )
    fi
  done
  
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

  # for each output
  for output in "${outputs_arr[@]}"; do
      # create temporary folder for custom output
      mkdir -p $current_output_template_path 2>/dev/null      

      # split each output on . char
      IFS='.' read -r -a pathArray <<< "$output"

      local output_path=/_
      
      printf " - process output: "$output"\n"

      # foreach part of the output
      for i in "${pathArray[@]}"; do
          # add this part to the source path
          output_path+=$i/
          
          if [ -d "$output_path" ]; then

            # move yaml config files in temp folder to prevent current config crush
            mkdir $current_output_template_path/yaml_tmp
            mv $output_path/config.yml $current_output_template_path/yaml_tmp/ 2>/dev/null
            mv $output_path/dac_custom-theme.yml $current_output_template_path/yaml_tmp/ 2>/dev/null          
            
            # force files (only) copy on destination path
            cp -f $output_path/* $current_output_template_path 2>/dev/null
            
            # merge new config on previous
            mergeYml $current_output_template_path/config.yml $current_output_template_path/yaml_tmp/config.yml
            mergeYml $current_output_template_path/dac_custom-theme.yml $current_output_template_path/yaml_tmp/dac_custom-theme.yml
  
            # remove temp yaml folder
            rm -rf $current_output_template_path/yaml_tmp/
  
            # Check if any fonts dir exists in the template and add any ttf file from it
            for font in $(ls $output_path/*.ttf 2>/dev/null)
            do
              if [ ! -f $(gem environment gemdir)/gems/asciidoctor-pdf-$ASCIIDOCTOR_PDF_VERSION/data/fonts/$i ]
              then
                  cp -f $font $(gem environment gemdir)/gems/asciidoctor-pdf-$ASCIIDOCTOR_PDF_VERSION/data/fonts/
              fi
            done

          else
            printf "  → output ["$output"] not found\n"  >&2
          fi
      done

      if [ -d "$output_path" ]; then

        # cp basic asciidoctor themes for dac theme extend
        cp -rf $(gem environment gemdir)/gems/asciidoctor-pdf-$ASCIIDOCTOR_PDF_VERSION/data/themes/* $current_output_template_path/
    
        # prepare to launch commands to produce output
        rm -f $ymlFile 
        mergeYml $ymlFile $current_output_template_path/config.yml
        mergeYml $ymlFile $current_output_template_path/dac-theme.yml
        mergeYml $ymlFile $current_output_template_path/dac_custom-theme.yml
  
        source $current_output_template_path/build.dac
  
         # launch process
        resultFile=$(process $input_file $pathname $destination_folder $filenameNoExtension)
  
        if [ -f $destination_folder/$resultFile ]; then
          printf "  → file generated: "$resultFile"\n"
          generatedFiles+=( "$destination_folder$resultFile" )
          chown $PID:$GID $destination_folder$resultFile
        else
          printf "  → File ["$destination_folder$resultFile"] NOT generated\n" >&2
        fi
  
         # clear temp folder
         rm -rf $current_output_template_path

       fi
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
            printf "extension not supported. only rst,md, adoc.\n"
            exit -1
            ;;
    esac

  done
done
