#!/bin/bash
clear


echo " Local branches" 
git branch
echo  "\n " 

echo "Local Head Revision  "
git rev-parse HEAD

echo " \n "

echo " Remote branches" 
echo " git branch -vv : Pointer to Origin:Remote Branch " 
git branch -vv
echo  "\n " 

echo " Remote Head Revision" 
git ls-remote --heads 

# git remote show origin
echo  "\n " 
git status

echo  "Thank you !! " 





