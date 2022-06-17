#!/bin/sh
########################################################
# A script to determine the number of Nudge deferrals. #
########################################################

osProductVersion=$( /usr/bin/sw_vers -productVersion )

case "${osProductVersion}" in

	10*	)
			echo "<result>N/A; macOS ${osProductVersion}</result>"
			;;

	11* | 12* | 13* )
			loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
			deferrals=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/com.github.macadmins.Nudge.plist userDeferrals )
			echo "<result>${deferrals}</result>"
			;;
esac

exit 0