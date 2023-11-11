#!/bin/sh
#http://www.thegeekstuff.com/2011/01/advanced-regular-expressions-in-grep-command-with-10-examples-%E2%80%93-part-ii/


# GENERAL
# print lines begining with range of letters
grep ^[A-D] table.txt


# REGEX
# search for word which has any single character followed by ello
grep ".ello" demo.txt

# OR, all the below examples produce the same results
grep "stuff\|more" demo.txt
grep -E "stuff|more" demo.txt
grep -e "stuff" -e "more" demo.txt

# AND, there is no AND so regex works
grep 'Manager.*Sales' employee.txt

# AND & OR
grep 'Manager.*Sales\|Developer*Tech' employee.txt

# begin with 1 and endswith C
grep '^1.*C$' file.txt


# FLAGS
# print everything that doesn't contain the query
grep -v ^Da* table.txt

# -i forgets about case sensitivity
grep -i ^DA table.txt

# show only the matched string, not the entire line in which it is present within.
grep -o "Meow" table.txt

# print the file containing the query including thos within subdirs
grep -r ^David ~/scripts-x14.04/bash/*

# print the name of the file(s) which matches the query
grep -l ^David ~/some_dir/*

# count the number of matches
grep -c "stuff" table.txt

# show the line numbers of the matches
grep -n "go" demo.txt

# search only for the full word
grep -w "of" table.txt

# print 3 lines after the match (-B for before the match & -C for before and after)
grep -A 3 "of" table.txt


