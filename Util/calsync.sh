#!/bin/bash

# copy the file from the phone to the pc

PPATH=
cp $PPATH/mydates.ics /tmp

#start evolution with the filename as an argument.
#evolution must not running at this point!

evolution /tmp/mydates.ics
# copy the evolution file to the phone

cp ~/.local/share/evolution/calendar/system/calendar.ics $PATH



