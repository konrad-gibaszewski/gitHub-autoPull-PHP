#!/bin/bash

# Simple bash script to copy default file into it's target positions.
#
# Copyright (c) 2013, Konrad Gibaszewski
#
# Licensed under The MIT License
# Redistributions of files must retain the above copyright notice.
#
# @copyright    Copyright (c) 2013, Konrad Gibaszewski
# @license      http://www.opensource.org/licenses/mit-license.php The MIT License

# Files to be copied from defaults
#
# config/config.default.ini
# log/git.default.log

# copyFile sourceFileName destinationFileName
#
# Copies source file into it's destination and asks if you want to edit it with nano
#
function copyFile {
    cp -pvi $1 $2
    read -p "Would you like to edit $2 (y/n [n])? "
    ([ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]) && nano $2
}

# showMessage
#
# show message to the user. Accepts up to three parameters:
# - first - title, comes in bold magenta,
# - second - message, comes in standard text color,
# - third - status, comes in bold green.
#
function showMessage {
    echo -e "\n\033[1;36m $1\033[0m $2\033[1;32m $3\033[0m";
}


# Init (copy defaults to its target positions)
showMessage "Config files" "intialising..."
copyFile config/config.default.ini config/config.ini
copyFile log/git.default.log log/git.log
showMessage "Config files" "intialising..." "OK"

# Exit msg
showMessage "Success" "Initialisation finished."
echo -e "\033[1;35m Edit\033[0m You should edit files specified below:\n
         > config/config.ini\n";
