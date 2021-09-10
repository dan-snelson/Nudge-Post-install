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

Beginning with **Nudge 1.1.0**, Mac Admins can leverage `userInterface : actionButtonPath` to execute a [Jamf Pro policy](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Jamf_Self_Service_for_macOS_URL_Schemes.html).

```json
"userInterface": {
	"actionButtonPath": "jamfselfservice://content?entity=policy&id=1&action=execute",
```

To open **System Preferences > Software Update** (i.e., Nudge v1.0.0 behavior), [delete the entire `actionButtonPath` line](https://github.com/dan-snelson/Nudge-Post-install/blob/main/Nudge-Post-install.bash#L319).

---

If you find this useful, please consider an upvote for [Suppport "Date" Key in Jamf Custom JSON Schema](https://www.jamf.com/jamf-nation/feature-requests/10232/).
