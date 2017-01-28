#!/usr/bin/env bash

###
#
# Download and converts Tabletop Simulator binary mods to usable .json files.
#
# Reqiures: mongodb, jq, curl, and sed.
###
yell() { echo "$0: $*" >&2; }
die() { yell "$1"; exit "$2"; }
try() { $1 || die "$2" "$3"; }

if [ $# -ne 1 ]; then
	echo "Usage: ${0} URL"
	exit 1
fi

# Set to true to use title as filename, false to use ID as filename.
NAME=false

# Fetch download link and title.
URL="${1}"
API="http://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v0001/" 
MID=`echo ${URL} | sed 's/.*id=\([0-9]*\)/\1/'`
MOD=`curl -s --data "itemcount=1&publishedfileids[0]=${MID}&format=json" ${API}`
DLL=`echo ${MOD} | jq '.response.publishedfiledetails[0].file_url'`
DLL=`echo ${DLL} | sed 's/"//g'`
TIT=`echo ${MOD} | jq '.response.publishedfiledetails[0].title'`
TIT=`echo ${TIT} | sed 's/"//g'`

if [ "${NAME}" == "true" ]; then
	FLN="${TIT}"
else
	FLN="${MID}"
fi

echo "Downloading ${TIT}"
try "curl -s ${DLL} -o ${FLN}" "Download failed" 2


# Convert bson to json, remove artifacts, and whitespace formating
bsondump "${FLN}" 2>/dev/null                                                  |\
sed -r 's/(\"DrawImage\":)\{[^\}]*\"\$binary\":(\"[^\}\"]*\")([^\}]*)\}/\1\2/' |\
jq -M .                                                                        |\
sed 's/"SaveName": "None"/"SaveName": "'"${TIT}"'"/'                           |\
sed 's/"GameMode": "None"/"GameMode": "'"${TIT}"'"/'                           |\
sed '/null/d'                                                                  > "${FLN}.json"

rm "${FLN}"
if [ -s "${FLN}.json" ]; then
	echo "Saved on ${FLN}.json"
else
	echo "Saving failed" 
	rm "${FLN}.json"
	exit 3
fi

exit 0