#!/bin/bash

make_sandbox=false
convert_sandbox_to_image=false
has_customname=false
customname=""

# Parse options to the `pip` command
while getopts ":hsrn" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    build.sh [-options] <definition-directory>"
      echo "    <definition-directory> should have a file named Singularity containing the image's definition"
      echo "    Options  "
      echo "    -h    Display this help message."
      echo "    -s    Make sandbox."
      echo "    -r    Convert sandbox to image."
      echo "    -n <name>    Custom name of image/sandbox."
      exit 0
      ;;
    s )
    make_sandbox=true

    ;;
    r )
    convert_sandbox_to_image=true

    ;;
    n )
    has_customname=true
    customname=$OPTARG

    ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

#-s and -r is mutually exclusive
if $make_sandbox && $convert_sandbox_to_image; then
  echo "Can't make sandbox and convert to image at the same time"
fi


#Checks that there's a source directory
if [ -z "$1" ]; then
  echo "No directory specified."
  exit 1
fi

#Checks that there's a Singularity file in the directory
if [ ! -f "$1/Singularity" ]; then
  echo "No Singularity definition file in the provided directory $1."
  exit 1
fi

#Gets the source dir, removes the slash if exists
src_dir=${1%/}

#Gets the image name, check whether to use custom name
img_name=$src_dir
if $has_customname; then
  img_name=$customname
fi

if $make_sandbox || $convert_sandbox_to_image; then
  #If we're making sandbox or converting it then do a multi-stage build
  if $make_sandbox; then
    echo "Building sandbox $img_name.sbx from $src_dir/Singularity"
    sudo singularity build -s "$img_name.sbx" $src_dir/Singularity
  fi

  if $convert_sandbox_to_image; then

    if [ ! -d $img_name.sbx ]; then
      echo "Sandbox named $img_name.sbx does not exist"
    else
      echo "Converting sandbox $img_name.sbx to image $img_name.simg"
      sudo singularity build "$img_name.simg" "$img_name.sbx"
    fi


  fi
else
  #Build normally
  echo "Building image $img_name.simg from $src_dir/Singularity"
  sudo singularity build $img_name.simg $src_dir/Singularity
fi
