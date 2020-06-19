#!/bin/bash


for f in *.webm
do
    name=`echo "$f" | sed -e "s/.webm$//g"`
#    ffmpeg -i "$f" -vn -ar 44100 -ac 2 -ab 192k -f mp3 "$name.mp3"
#     ffmpeg -fflags +genpts -i "$f" -r 24 1.mp4
     ffmpeg -fflags +genpts -i "$f" -r 24 "$name.mp4"
done


# ffmpeg -fflags +genpts -i 1.webm -r 24 1.mp4
# for f in *.mp4; do ffmpeg -i "$f" -vn -c:a libmp3lame -ar 44100 -ac 2 -ab 192k "${f/%mp4/mp3}"; done



