# Creating a new vCenter server role with cumulative privileges and permissions to use with Veeam Backup & Replication V12

This PowerShell / PowerCLI script lets you create a new vCenter server role with all the cumulative privileges and permissions to use them with Veeam Backup & Replication V12.

The privileges used are based on the recommendations out of the Veeam Help Center which you can find here:
[Cumulative Permission for VMware vSphere - Veeam Help Center](https://helpcenter.veeam.com/docs/backup/permissions/cumulativepermissions.html?ver=120)

Simply execute the script and follow the steps to fill in the relevant data like your vCenter server name, the username and your password. The script will then ask you to choose a name for your new role and automatically creates it. If the role already exists, the code will check for any missing privileges and prompt if you want them added. Finally you will havce the choice to add a user to this role, if you select yes, this will be added at the vCenter root level.

![Example execution of the script](/vCenter-role-for-Veeam-Output.png)

Feel free to give me feedback on this script, as I want to further improve it.

**Recent Improvements**
 - [X] Add a function to assign a user to the role
 - [X] Add a function to check against an existing role, print the missing privileges and let the user decide to apply the missing privileges to the already existing role
 
You can get the script here: [New_vCenterRole_Veeam.ps1](/New_vCenterRole_Veeam.ps1)

Successful tested against: 
- VMware vCenter 6.5
- VMware vCenter 6.7
- VMware vCenter 7.0
- Veeam Backup & Replication Version 10
- Veeam Backup & Replication Version 11
- Veeam Backup & Replication Version 12
