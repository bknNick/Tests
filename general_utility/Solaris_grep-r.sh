#Solaris has no grep -r option, so I wrote myself one. 
#Prompts for pattern and path then searches for that pattern in every file within the path (grep -r...). 
#Stores some stuff in a temp file (./grep-r) which it later deletes (or deletes after a ctrl+C)
#If anybody ever sees this and could use such a thing, here ya go (it's a one liner (as multiline scripts are a hastle to move around servers if you need a specific thing done)):

read -p "Enter the pattern youre looking for (CASE SENSITIVE) : " pattern && read -p "Enter the path in where to search: " SearchPath && tempfile="./grep-r" && for file in $(find $SearchPath -type f 2>/dev/null); do if grep -I $pattern $file >/dev/null; then echo $file >> $tempfile; fi; done && for entry in $(cat $tempfile); do echo "" && echo $entry && echo "" && grep -I $pattern $entry; done && rm -rf $tempfile && trap "{ rm -rf $tempfile; }" 2;
