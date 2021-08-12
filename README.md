# Nudge-Post-install
## Jamf Pro Post-install script to configure Nudge

On the off-chance this may help other Jamf Pro admins, we’re currently testing a [Nudge post-install script](https://github.com/dan-snelson/Nudge-Post-install/blob/main/Nudge-Post-install.bash), which we’ve added to a Jamf Pro policy as a Script payload, specifying the following:

### Jamf Pro Script Parameter Labels

- Parameter 4: Authorization Key
- Parameter 5: Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
- Parameter 6: Required Minimum OS Version (i.e., 11.5.2)
- Parameter 7: Required Installation Date & Time (i.e., 2021-08-18T10:00:00Z)
- Parameter 8: Configuration Files to Reset (i.e., None (blank) | All | JSON | LaunchAgent | LaunchDaemon)

![Jamf Pro Script Parameter Labels](images/Screen%20Shot%202021-03-22%20at%2012.55.06%20PM.png)


---

If you find this useful, please consider an upvote for [Suppport "Date" Key in Jamf Custom JSON Schema](https://www.jamf.com/jamf-nation/feature-requests/10232/).
