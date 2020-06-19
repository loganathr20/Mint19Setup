#to change uppercase filenames to lowercase 
#!/bin/sh
if [ $# -eq 0 ] ; then
echo Usage: $0 Files
exit 0
fi
for f in $* ; do
g=`echo $f | tr "[A-Z]" "[a-z]"`
echo mv -i $f $g
mv -i $f $g
done

