#!/bin/sh

#  version.sh
#  SYKeyboard
#
#  Created by Mateusz Siatrak on 6/22/23.
#  Edited by 서동환 on 9/10/24.
#  - Downloaded from https://medium.com/@mateuszsiatrak/automating-build-number-increments-in-xcode-with-custom-format-a-practical-guide-bcc90a19f716
#

# This script is designed to increment the build number consistently across all targets.

# Navigating to the 'SYKeyboard' directory inside the source root.
cd "$SRCROOT/XCConfig"

# Get the current date in the format "YYYYMMDD".
current_date=$(date "+%Y%m%d")

# Parse the 'Shared.xcconfig' file to retrieve the previous build number.
# The 'awk' command is used to find the line containing "BUILD_NUMBER"
# and the 'tr' command is used to remove any spaces.
previous_build_number=$(awk -F "=" '/BUILD_NUMBER/ {print $2}' Shared.xcconfig | tr -d ' ')

# Extract the date part and the counter part from the previous build number.
previous_date="${previous_build_number:0:8}"
counter="${previous_build_number:8}"

# If the current date matches the date from the previous build number,
# increment the counter. Otherwise, reset the counter to 1.
new_counter=$((current_date == previous_date ? counter + 1 : 1))

# Combine the current date and the new counter to create the new build number.
new_build_number="${current_date}${new_counter}"

# Use 'sed' command to replace the previous build number with the new build
# number in the 'Shared.xcconfig' file.
sed -i -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" Shared.xcconfig

# Remove the backup file created by 'sed' command.
rm -f Shared.xcconfig-e
