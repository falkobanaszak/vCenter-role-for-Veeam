# Creating a new vCenter server role with cumulative privileges and permissions to use with Veeam Backup & Replication V10

This PowerShell / PowerCLI script lets you create a new vCenter server role with all the cumulative privileges and permissions to use them with Veeam Backup & Replication V10.

The privileges used are based on the recommendations out of the Veeam Help Center which you can find here:
[Cumulative Permission for VMware vSphere - Veeam Help Center](https://helpcenter.veeam.com/docs/backup/permissions/cumulativepermissions.html?ver=100)

Simply execute the script and follow the steps to fill in the relevant data like your vCenter server name, the username and your password. The script will then ask you to choose a name for your new role and automatically creates it.

![Example execution of the script](https://github.com/falkobanaszak/vCenter-role-for-Veeam/blob/master/vCenter-role-for-Veeam-Output.png)

Feel free to give me feedback on this script, as I want to further improve it.

**Already planned improvements**
 - [ ] Add a function to assign a user to the role
 
You can get the script here: [New_vCenterRole_Veeam.ps1](https://github.com/falkobanaszak/vCenter-role-for-Veeam/blob/master/New_vCenterRole_Veeam.ps1)

Successful tested against: 
- VMware vCenter 6.5
- VMware vCenter 6.7
- VMware vCenter 7.0
