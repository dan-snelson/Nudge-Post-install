#!/bin/sh
##########################################################
# A script to determine the client-side output of Nudge. #
##########################################################

osProductVersion=$( /usr/bin/sw_vers -productVersion )

case "${osProductVersion}" in

	10*	)
			echo "<result>N/A; macOS ${osProductVersion}</result>"
			;;

	11* | 12* | 13* | 14* )
			loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
			requiredOS=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/com.github.macadmins.Nudge.plist requiredMinimumOSVersion )
			logEntries=$( /usr/bin/grep com.github.macadmins.Nudge /var/log/Nudge.log | /usr/bin/tail -5 | /usr/bin/awk '{ split($2, split_time, "."); $2 = split_time[1]; print }' | /usr/bin/cut -d ' ' -f -2,6- )
			echo "<result>Required OS: ${requiredOS}
${logEntries}</result>"
			;;
esac

exit 0
