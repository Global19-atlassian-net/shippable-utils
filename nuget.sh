#!/bin/sh
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.

usage()
{
cat <<EOF
Usage:
  $0 -h
  $0 <command> [<command-args>]

Description:
  Nuget commands setup for running in shippable

Commands:
  commands
    init
      Description:
        download nuget.exe and setup a fresh NuGet.config in the working directory.

    addSource <name> <url> [<user> <apikey>]
      Description:
        Add a source [and set the apikey for it if user and apikey passed]
      args:
        name: The name of the source
        url: The url for the source
        user: the user for the source
        apikey: the apikey for the source

    restore
      Description:
        Restore the packages (download all referenced nuget packages)

    pack <version> [<nuspec> ...]
      Description:
        Pack a nuspec file or files. If no nuspec passed it is assumed that *.nuspec should be packed
      args:
        version: The version to set for the nupkg
        nuspec a nuspec to pack

    push <source> [<nupkg> ...]
      Description:
        push a nupkg or packages. If no nupkg is passed it is assumed that *.nupkg should be pushed
      args:
        source: A nuget source to push to
        nupkg - a nupkg file to push
EOF
}

while getopts ":h" opt
do
  case "${opt}" in
    h )  usage; exit 0 ;;
    \?)  echo "unrecognized option: $OPTARG" 1>&2
         exit 1
         ;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
	echo "Invalid Params: Requires a command argument" 1>&2
	usage
	exit 1
fi

COMMAND=$1
shift
NUGET_CONFIG="./NuSpec.config"

case "$COMMAND" in
  init)
    if [ "$#" -ne 0 ]; then
      echo "Invalid Params: restore takes no arguments" 1>&2
      usage
      exit 1
    fi
    


    cat > "$NUGET_CONFIG" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="Official NuGet Gallery" value="https://www.nuget.org/api/v2/" />
  </packageSources>
</configuration>
EOF
    curl -LO http://nuget.org/nuget.exe
    ;;

  addSource)
    if [ "$#" -ne 2 ] && [ "$#" -ne 4 ]; then
      echo "Invalid Params: Requires at least a name and url and optionally both a username and apikey" 1>&2
      usage
      exit 1
    fi

    NAME="$1"
    SOURCE="$2"
    MYGET_USER="$3"
    MYGET_API_KEY="$4"
    mono nuget.exe sources add -Name "$NAME" -Source "$SOURCE" -UserName "$MYGET_USER" -Password "$MYGET_API_KEY" -ConfigFile "$NUGET_CONFIG"
    # Hide the apikey output during the run of this command by redirecting to /dev/null
    mono nuget.exe setApiKey "$MYGET_API_KEY" -Source "$SOURCE" -ConfigFile "$NUGET_CONFIG" -NonInteractive 1>/dev/null
    ;;

  restore)
    if [ "$#" -ne 0 ]; then
      echo "Invalid Params: restore takes no arguments" 1>&2
      usage
      exit 1
    fi
    rm -rf packages
    mono nuget.exe restore -ConfigFile "$NUGET_CONFIG" -NonInteractive
    ;;

  pack)
    if [ "$#" -lt 1 ]; then
      echo "Invalid Params: Requires a version" 1>&2
      usage
      exit 1
    fi
    VERSION="$1"
    shift
    nuspecs="${@}"
    [ $# -eq 0 ] && nuspecs=*.nuspec
    for nuspec in $nuspecs; do
      echo "Packing $nuspec $VERSION"
      TMP_FILE=`mktemp /tmp/XXXXXXXXXX`
      NUSPEC="${TMP_FILE}.nuspec"
      mv "$TMP_FILE" "$NUSPEC"
      sed 's/\[VERSION\]/'"$VERSION"'/' "$nuspec" > "$NUSPEC"
      mono nuget.exe pack "$NUSPEC" -BasePath .
    done
    ;;

  push)
    if [ "$#" -ne 1 ]; then
      echo "Invalid Params: push takes at least a source to push to" 1>&2
      usage
      exit 1
    fi

    SOURCE=$1
    shift

    nupkgs="${@}"
    [ $# -eq 0 ] && nupkgs=*.nupkg
    for nupkg in $nupkgs; do
      echo "Pushing $nupkg"
      mono nuget.exe push "$nupkg" -ConfigFile "$NUGET_CONFIG" -NonInteractive -Source "$SOURCE"
    done
    ;;
esac




