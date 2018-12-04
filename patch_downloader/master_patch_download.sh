#!/bin/bash

wget -nc --restrict-file-names=nocontrol --no-http-keep-alive --html-extension --user mark.eva@fivium.co.uk --password Mandems123  --save-cookies=/oracle/scripts/APOo/patch_downloader/cookies --keep-session-cookies \
--no-check-certificate "https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=391477724442568&id=756671.1&_afrWindowMode=0&_adf.ctrl-state=jn51t81sp_4"  \
-O /oracle/scripts/APOo/patch_downloader/patch_master_note.txt 
