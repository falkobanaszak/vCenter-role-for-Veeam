<#
.SYNOPSIS
    New_vCenterRole_Veeam.ps1 - PowerShell Script to create a new vCenter Role with all the required permission for Veeam Backup & Replication. 
.DESCRIPTION
    This script is used to create a new role on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Veeam Backup & Replication
    The permissions are based on the Veeam Help Center Cumulative Permissions and can be found here: https://helpcenter.veeam.com/docs/backup/permissions/cumulativepermissions.html?ver=100
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Falko Banaszak, https://virtualhome.blog, Twitter: @Falko_Banaszak
    
    Change Log    V1.00, 21/04/2020 - Initial version: Creates a new vCenter role with privileges required for Veeam Backup & Replication operations
.LICENSE
    MIT License
    Copyright (c) 2019 Falko Banaszak
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

# Here are all necessary and cumualative vCenter Privileges needed for all operations of Veeam Backup & Replication V10
$VeeamPrivileges = @(
'Cryptographer.Access',
'Cryptographer.AddDisk',
'Cryptographer.Encrypt',
'Cryptographer.EncryptNew',
'Cryptographer.Migrate',
'DVPortgroup.Create',
'DVPortgroup.Delete',
'DVPortgroup.Modify',
'Datastore.AllocateSpace',
'Datastore.Browse',
'Datastore.Config',
'Datastore.DeleteFile',
'Datastore.FileManagement',
'Extension.Register',
'Extension.Unregister',
'Folder.Create',
'Folder.Delete',
'Global.DisableMethods',
'Global.EnableMethods',
'Global.Licenses',
'Global.LogEvent',
'Global.ManageCustomFields',
'Global.SetCustomField',
'Global.Settings',
'Host.Config.Network',
'Host.Config.Storage',
'InventoryService.Tagging.AttachTag',
'Network.Assign',
'Network.Config',
'Resource.AssignVMToPool',
'Resource.ColdMigrate',
'Resource.CreatePool',
'Resource.DeletePool',
'Resource.HotMigrate',
'StoragePod.Config',
'System.Anonymous',
'System.Read',
'System.View',
'VApp.AssignResourcePool',
'VApp.AssignVM',
'VApp.Unregister',
'VirtualMachine.Config.AddExistingDisk',
'VirtualMachine.Config.AddNewDisk',
'VirtualMachine.Config.AddRemoveDevice',
'VirtualMachine.Config.AdvancedConfig',
'VirtualMachine.Config.Annotation',
'VirtualMachine.Config.ChangeTracking',
'VirtualMachine.Config.DiskExtend',
'VirtualMachine.Config.DiskLease',
'VirtualMachine.Config.EditDevice',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Config.Rename',
'VirtualMachine.Config.Resource',
'VirtualMachine.Config.Settings',
'VirtualMachine.GuestOperations.Execute',
'VirtualMachine.GuestOperations.Modify',
'VirtualMachine.GuestOperations.Query',
'VirtualMachine.Interact.ConsoleInteract',
'VirtualMachine.Interact.DeviceConnection',
'VirtualMachine.Interact.GuestControl',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Interact.PowerOn',
'VirtualMachine.Interact.Suspend',
'VirtualMachine.Inventory.Delete',
'VirtualMachine.Inventory.Register',
'VirtualMachine.Inventory.Unregister',
'VirtualMachine.Provisioning.DiskRandomAccess',
'VirtualMachine.Provisioning.DiskRandomRead',
'VirtualMachine.Provisioning.GetVmFiles',
'VirtualMachine.Provisioning.PutVmFiles',
'VirtualMachine.State.CreateSnapshot',
'VirtualMachine.State.RemoveSnapshot',
'VirtualMachine.State.RevertToSnapshot')

# Load the PowerCLI SnapIn and set the configuration
Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server Name to connect to
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

# Provide a name for your new role
$NewRole = Read-Host "Enter your desired name for the new vCenter role"
Write-Host "Thanks, your new vCenter role will be named $NewRole" -ForegroundColor Green

# Creating the new role with the needed permissions
New-VIRole -Name $NewRole -Privilege (Get-VIPrivilege -Id $VeeamPrivileges) | Out-Null
Write-Host "Your new vCenter role has been created, here it is:" -ForegroundColor Green
Get-VIRole -Name $NewRole | Select-Object Description, PrivilegeList, Server, Name | Format-List

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
