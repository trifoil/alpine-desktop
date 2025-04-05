#!/bin/bash

apk update 
apk add texmf-dist 
apk add texlive-full
apk add texstudio

read -n 1 -s -r -p "Done. Press any key to continue..."
