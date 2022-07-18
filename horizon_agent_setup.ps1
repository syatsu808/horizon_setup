Set-ExecutionPolicy RemoteSigned -Force
Import-Module NJCliPSh
#Install-PackageProvider -Name NuGet -Force
#Install-Module -Name "PnP.PowerShell" -Force

# Download packages from app.servpac.com/docs and store in directory
$check_horizon_folder = [bool](Get-ChildItem -Path 'C:\' | Where-Object Name -like 'Horizon_Setup')
if($check_horizon_folder -eq $false){
	mkdir C:\Horizon_Setup
}

$check_log_file = [bool](Get-ChildItem -Path 'C:\Horizon_Setup' | Where-Object Name -like 'horizon_setup_log.txt')
if($check_log_file -eq $false){
	New-Item -Path "C:\Horizon_Setup\" -Name "horizon_setup_log.txt" -ItemType File -Value "Initializing log file"
}

$logfile = "C:\Horizon_Setup\horizon_setup_log.txt"

Function download_packages {
	Add-Content $logfile "`nDownloading files from app.servpac.com/docs"
	#$WebClient = New-Object System.Net.WebClient
	#$WebClient.DownloadFile("https://app.servpac.com/docs/VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe", "C:\Horizon_Setup\VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe")
	#$WebClient.DownloadFile("https://app.servpac.com/docs/VMware-Horizon-Agent-Direct-Connection-x86_64-8.4.0-18964730.exe", "C:\Horizon_Setup\VMware-Horizon-Agent-Direct-Connection-x86_64-8.4.0-18964730.exe")
	#$WebClient.DownloadFile("https://app.servpac.com/docs/ZoomInstallerVDI.msi", "C:\Horizon_Setup\ZoomInstallerVDI.msi")
	Invoke-WebRequest -Uri "https://servpac-my.sharepoint.com/:u:/g/personal/syatsu_luhina_com1/EY7E_Lt30p5HhKjaUyOT_tQBKqt8Bk-YG1hQC0CVXU5tSw?e=NTlfXh&download=1" -OutFile "C:\Horizon_Setup\VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe" 
	Add-Content $logfile "`nDownloading Horizon Agent."
	Start-Sleep -s 900
	Invoke-WebRequest -Uri "https://servpac-my.sharepoint.com/:u:/g/personal/syatsu_luhina_com1/ES7mlpqkPghGhLUNKtMYxh4Br793C-oy6yrKrlRP0PLtuQ?e=SkrIfa&download=1" -Outfile "C:\Horizon_Setup\VMware-Horizon-Agent-Direct-Connection-x86_64-8.4.0-18964730.exe"
	Add-Content $logfile "`nDownloading Horizon Direct Connect"
	Start-Sleep -s 600
	Invoke-WebRequest -Uri "https://servpac-my.sharepoint.com/:u:/g/personal/syatsu_luhina_com1/EXAsiP8KeTJDiyAG6eb5lycBd4D86K2BYaULYgRfemTYZw?e=dJVqs1&download=1" -Outfile "C:\Horizon_Setup\ZoomInstallerVDI.msi"
	Add-Content $logfile "`nDownloading Zoom VDI"
	Start-Sleep -s 600
	Restart-Service -name 'Windows Installer' -Force
	Restart-Computer -Force
	
	
}

Function install_horizon_agent {
    Add-Content $logfile "`nInstalling All Horizon Agent Components..."
	Restart-Service -name 'Windows Installer' -Force
	Start-Sleep -s 30
	cmd.exe /C 'C:\Horizon_Setup\VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe /s /v" /qn ADDLOCAL=ALL"'
	Start-Sleep -s 300
}

Function install_horizon_directconnect {
	Add-Content $logfile "`nInstalling Horizon Direct Connect Component..."
	Restart-Service -name 'Windows Installer' -Force
	Start-Sleep -s 30
    cmd.exe /C 'C:\Horizon_Setup\VMware-Horizon-Agent-Direct-Connection-x86_64-8.4.0-18964730.exe /s /v" /qn LISTENPORT=443 MODIFYFIREWALL=1"'
    Start-Sleep -s 300
}

Function cleanup_horizon_installation {
    Add-Content $logfile "`nRemoving un-needed Horizon Agent Components..."
	Restart-Service -name 'Windows Installer' -Force
	Start-Sleep -s 30
    cmd.exe /C 'C:\Horizon_Setup\VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe /s /v" /qn REMOVE=GEOREDIR,PerfTracker,SdoSensor,SerialPortRedirection,SmartCard,VMWMediaProviderProxy"'
    Start-Sleep -s 300
}

Function install_zoom_vdi {
    Add-Content $logfile "`nInstalling Zoom VDI..."
    Restart-Service -name 'Windows Installer' -Force
	Start-Sleep -s 30
	msiexec /i "C:\Horizon_Setup\ZoomInstallerVDI.msi" /quiet /qn /norestart /log C:\Horizon_Setup\Zoom_install.log
	Start-Sleep -s 300
}


$horizon_agent = [bool](Get-ChildItem -Path 'C:\Horizon_Setup' | Where-Object Name -like 'VMware-Horizon-Agent-x86_64-2111.1-8.4.0-19066669.exe')
$horizon_direct_connect = [bool](Get-ChildItem -Path 'C:\Horizon_Setup'| Where-Object Name -like 'VMware-Horizon-Agent-Direct-Connection-x86_64-8.4.0-18964730.exe')
$zoom_vdi = [bool](Get-ChildItem -Path 'C:\Horizon_Setup' | Where-Object Name -like 'ZoomInstallerVDI.msi')
if(($horizon_agent -eq $false) -or ($horizon_direct_connect -eq $false) -or ($zoom_vdi -eq $false)){
	Add-Content $logfile "`npackages not found, downloading from servpac server..."
 	download_packages
}
#Store Horizon Agent Registry Path way and check if listed
$HorizonAgentRegistry = Get-ChildItem -Path 'HKLM:\SOFTWARE\VMware, Inc.\Installer\'
if(!$HorizonAgentRegistry -and $horizon_agent){
	Add-Content $logfile "`nNo Horizon Agent Registries listed, installing agent..."
	install_horizon_agent
}

#Store Horizon Agent Registry PerfTracker key value and output as string then check value if installed
$HorizonAgentSetupCheck = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\Installer\Features_HorizonAgent') | Select-Object -ExpandProperty PerfTracker | Out-String
if($HorizonAgentSetupCheck.Trim() -like 'Local'){
	Add-Content $logfile "`nHorizon Agent Installation check. Found unneeded packages installed, removing services...."
	cleanup_horizon_installation
}

$HorizonDirectConnectRegistry = [bool](Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\Agent\Configuration\XMLAPI')
if($HorizonDirectConnectRegistry -eq $false -and $horizon_direct_connect){
	Add-Content $logfile "`nStarting Horizon Agent Direct Connection setup..."
	install_horizon_directconnect
}

#Store Zoom registry pathway then check if HorizonCheck completed and if Zoom not installed yet
$ZoomRegistry = Get-ChildItem -Path 'HKLM:\SOFTWARE\WOW6432Node\Zoom VDI'
if($HorizonAgentSetupCheck.Trim() -like 'Absent' -and !$ZoomRegistry -and $zoom_vdi){
	Add-Content $logfile "`nSetting up Zoom for VDI..."
	install_zoom_vdi
	Restart-Computer -Force
}


