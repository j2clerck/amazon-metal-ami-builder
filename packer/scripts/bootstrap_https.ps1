write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"
#Enable WinRM with default settings
Enable-PSRemoting -SkipNetworkProfileCheck -Force

#Create TLS certificate
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "myHost"

#Remove WinRM HTTP Configuration and add HTTPS one
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"

New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
&cmd.exe /c winrm set winrm/config/service/auth @{Basic="true"}
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP

#Restart the service to use the HTTPS Listener
Restart-Service -Name "winrm"