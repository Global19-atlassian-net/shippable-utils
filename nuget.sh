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
    init <api-key>
      Description:
        download nuget.exe and setup sources
      args:
        api-key - The MyGet apikey for the quantum-build user

    restore
      Description:
        Restore the packages (download all referenced nuget packages)

    pack <version> [<nuspec> ...]
      Description:
        Pack a nuspec file or files. If no nuspec passed it is assumed that *.nuspec should be packed
      args:
        version: The version to set for the nupkg
        nuspec a nuspec to pack

    push [<nupkg> ...]
      Description:
        push a nupkg or packages. If no nupkg is passed it is assumed that *.nupkg should be pushed
      args:
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
    if [ "$#" -ne 1 ]; then
      echo "Invalid Params: Requires a api-key and nothing else" 1>&2
      usage
      exit 1
    fi

    MYGET_API_KEY=$1

    cat > "$NUGET_CONFIG" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="Official NuGet Gallery" value="https://www.nuget.org/api/v2/" />
  </packageSources>
</configuration>
EOF
    curl -LO http://nuget.org/nuget.exe
    mono nuget.exe sources add -Name "Castle-Development" -Source https://www.myget.org/F/castle-development/ -UserName quantum-build -Password "$MYGET_API_KEY" -ConfigFile "$NUGET_CONFIG"
    mono nuget.exe setApiKey "$MYGET_API_KEY" -Source "Castle-Development" -ConfigFile "$NUGET_CONFIG" -NonInteractive 1>/dev/null
    ;;

  restore)
    if [ "$#" -ne 0 ]; then
      echo "Invalid Params: restore takes no arguments" 1>&2
      usage
      exit 1
    fi
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
      TMP_FILE=`mktemp /tmp/config.XXXXXXXXXX`
      sed 's/\[VERSION\]/'"$VERSION"'/' "$nuspec" > "$TMP_FILE"
      mv "$TMP_FILE" "$nuspec"
      mono nuget.exe pack "$nuspec"
    done
    ;;

  push)
    nupkgs="${@}"
    [ $# -eq 0 ] && nupkgs=*.nupkg
    for nupkg in $nupkgs; do
      echo "Pushing $nupkg"
      mono nuget.exe push "$nupkg" -ConfigFile "$NUGET_CONFIG" -NonInteractive -Source "Castle-Development"
    done
    ;;
esac




