rem Usage: build config-folder [DEV=Y] [pull]
rem   config-folder contains linkbuild.json (default: current directory)
rem   e.g. build Tests\stats DEV=Y
if "%~1"=="" (dyalog.exe LOAD="linkbuildboot.aplf") else dyalog.exe LOAD="linkbuildboot.aplf" BUILD_CONFIG="%~1" %2 %3
