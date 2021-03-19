#!/bin/bash

####################################################################################################
#
#	Nudge Post-install
#
#	Purpose: Configures Nudge to company standards post-install
#	https://github.com/macadmins/nudge/blob/main/README.md#configuration
#
####################################################################################################
#
# HISTORY
#
# 	Version 0.0.1, 19-Mar-2021, Dan K. Snelson (@dan-snelson)
#		Original version
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.1"
scriptResult=""
authorizationKey="${4}"				# Authorization Key to prevent unauthorized execution via Jamf Remote
requiredMinimumOSVersion="${5}"		# 11.2.3
requiredInstallationDate="${6}"		# 2021-03-17
jsonPath="/usr/local/companyname/scripts/com.companyname.Nudge.json"
launchAgentPath="/Library/LaunchAgents/com.companyname.Nudge.plist"
launchDaemonPath="/Library/LaunchDaemons/com.companyname.Nudge.logger.plist"
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for a specified value in Parameter 4 to prevent unauthorized script execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function authorizationCheck() {

	if [[ "${authorizationKey}" != "PurpleMonkeyDishwasher" ]]; then

		scriptResult+="Error: Incorrect Authorization Key; exiting."
		echo "${scriptResult}"
		exit 1

	else

		scriptResult+="Correct Authorization Key, proceeding; "

	fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo " "
echo "###"
echo "# Nudge Post-install (${scriptVersion})"
echo "###"
echo " "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Authorization
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

authorizationCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Hide Nudge in Finder & Launchpad
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Hide Nudge in Finder …"
/usr/bin/chflags hidden "/Applications/Utilities/Nudge.app" 

echo "Hide Nudge in Launchpad …"
/usr/bin/sqlite3 $(/usr/bin/sudo find /private/var/folders -name com.apple.dock.launchpad)/db/db "DELETE FROM apps WHERE title='Nudge'"
/usr/bin/killall Dock

scriptResult+="Hid ${1} in Finder & Launchpad; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create Nudge Logger LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f ${launchDaemonPath} ]]; then

	echo "Unload ${launchDaemonPath} …"
	/bin/launchctl unload -w "${launchDaemonPath}"

	echo "Remove ${launchDaemonPath} …"
	/bin/rm -fv ${launchDaemonPath}
	scriptResult+="Removed ${launchDaemonPath}; "

fi

echo "Create ${launchDaemonPath} …"

cat <<EOF > ${launchDaemonPath}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.companyname.Nudge.Logger</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/log</string>
		<string>stream</string>
		<string>--predicate</string>
		<string>subsystem == 'com.github.macadmins.Nudge'</string>
		<string>--style</string>
		<string>syslog</string>
		<string>--color</string>
		<string>none</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardOutPath</key>
	<string>/var/log/com.companyname.log</string>
</dict>
</plist>
EOF

/bin/launchctl load -w "${launchDaemonPath}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Write Nudge JSON client-side
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f ${jsonPath} ]]; then
	echo "Remove ${jsonPath} …"
	/bin/rm -fv ${jsonPath}
	scriptResult+="Removed ${jsonPath}; "
fi

echo "Create ${jsonPath} …"
/usr/bin/touch ${jsonPath}
scriptResult+="Created ${jsonPath}; "

echo "Write ${jsonPath} …"

cat <<EOF > ${jsonPath}
{
	"optionalFeatures": {
	  "asyncronousSoftwareUpdate": true,
	  "attemptToFetchMajorUpgrade": true,
	  "enforceMinorUpdates": true
	},
	"osVersionRequirements": [
	  {
		"aboutUpdateURL_disabled": "https://servicenow.companyname.com/support?id=kb_article_view&sysparm_article=KB86753099",
		"aboutUpdateURLs": [
		  {
			"_language": "en",
			"aboutUpdateURL": "https://servicenow.companyname.com/support?id=kb_article_view&sysparm_article=KB86753099"
		  }
		],
		"majorUpgradeAppPath": "/Applications/Install macOS Big Sur.app",
		"requiredInstallationDate": "${requiredInstallationDate}T10:00:00Z",
		"requiredMinimumOSVersion": "${requiredMinimumOSVersion}",
		"targetedOSVersions": [
		  "11.0",
		  "11.0.1",
		  "11.1",
		  "11.2",
		  "11.2.1",
		  "11.2.2"
		]
	  }
	],
	"userExperience": {
	  "allowedDeferrals": 9,
	  "allowedDeferralsUntilForcedSecondaryQuitButton": 5,
	  "approachingRefreshCycle": 60,
	  "approachingWindowTime": 72,
	  "elapsedRefreshCycle": 300,
	  "imminentRefeshCycle": 600,
	  "imminentWindowTime": 24,
	  "initialRefreshCycle": 18000,
	  "maxRandomDelayInSeconds": 1200,
	  "noTimers": false,
	  "nudgeRefreshCycle": 60,
	  "randomDelay": true
	},
	"userInterface": {
	  "fallbackLanguage": "en",
	  "forceFallbackLanguage": false,
	  "forceScreenShotIcon": false,
	  "iconDarkPath": "/usr/local/company/icons/WAS.icns",
	  "iconLightPath": "/usr/local/company/icons/WAS.icns",
	  "screenShotDarkPath": "/usr/local/company/icons/nudgeInstructionsDark.png",
	  "screenShotLightPath": "/usr/local/company/icons/nudgeInstructions.png",
	  "simpleMode": false,
	  "singleQuitButton": true,
	  "updateElements": [
		{
		  "_language": "en",
		  "mainHeader": "Critical macOS Update Available",
		  "subHeader": "",
		  "mainContentHeader": "A critical macOS update is available",
		  "mainContentSubHeader": "Updates may take 45 minutes or longer",
		  "actionButtonText": "Open Software Update",
		  "mainContentNote": "Instructions",
		  "mainContentText": "To perform the update now, click \"Open Software Update,\" review the on-screen instructions by clicking \"More Info…\" then click \"Update Now.\" (Click screenshot below.)\n\nIf you are unable to perform this update now, click \"Later\" (which will no longer be visible once the ${requiredInstallationDate} deadline has passed).\n\nPlease see KB0054571 or contact the Global Service Department with questions:\n+1 (801) 555-1212.",
		  "informationButtonText": "View KB86753099 …",
		  "primaryQuitButtonText": "Later",
		  "secondaryQuitButtonText": "secondaryQuitButtonText"
		}
	  ]
	}
}
EOF

scriptResult+="Wrote Nudge JSON file to ${jsonPath}; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f ${launchAgentPath} ]]; then

	echo "Unload ${launchAgentPath} …"
	/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"

	echo "Remove ${launchAgentPath} …"
	/bin/rm -fv ${launchAgentPath}
	scriptResult+="Removed ${launchAgentPath}; "

fi

echo "Create ${launchAgentPath} …"

cat <<EOF > ${launchAgentPath}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.companyname.Nudge.plist</string>
	<key>LimitLoadToSessionType</key>
	<array>
		<string>Aqua</string>
	</array>
	<key>ProgramArguments</key>
	<array>
		<string>/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge</string>
		<string>-json-url</string>
		<string>file:////${jsonPath}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
	</array>
</dict>
</plist>
EOF

scriptResult+="Created ${launchAgentPath}; "

echo "Set ${launchAgentPath} file permissions ..."
/usr/sbin/chown root:wheel ${launchAgentPath}
/bin/chmod 644 ${launchAgentPath}
/bin/chmod +x ${launchAgentPath}
scriptResult+="Set ${launchAgentPath} file permissions; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# https://github.com/macadmins/nudge/blob/main/build_assets/postinstall-launchagent
# Only enable the LaunchAgent if there is a user logged in, otherwise rely on built in LaunchAgent behavior
if [[ -z "$loggedInUser" ]]; then
	echo "Did not detect user"
elif [[ "$loggedInUser" == "loginwindow" ]]; then
	echo "Detected Loginwindow Environment"
elif [[ "$loggedInUser" == "_mbsetupuser" ]]; then
	echo "Detect SetupAssistant Environment"
elif [[ "$loggedInUser" == "root" ]]; then
	echo "Detect root as currently logged-in user"
else
	# Unload the LaunchAgent so it can be triggered on re-install
	/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
	# Kill Nudge just in case (say someone manually opens it and not launched via LaunchAgent
	/usr/bin/killall Nudge
	# Load the LaunchAgent
	/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl load -w "${launchAgentPath}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0