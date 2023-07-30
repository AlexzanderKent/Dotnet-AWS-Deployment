# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Install .NET Framework (Optional - Uncomment if required)
# Install-WindowsFeature NET-Framework-XXX
& CMD /C start /w pkgmgr /iu:IIS-WebServerRole;IIS-WebServer;IIS-CommonHttpFeatures;IIS-StaticContent;IIS-DefaultDocument;IIS-DirectoryBrowsing;IIS-HttpErrors;IIS-HttpRedirect;IIS-ApplicationDevelopment;IIS-ASPNET;IIS-NetFxExtensibility;IIS-ASP;IIS-CGI;IIS-ISAPIExtensions;IIS-ISAPIFilter;IIS-ServerSideIncludes;IIS-HealthAndDiagnostics;IIS-HttpLogging;IIS-LoggingLibraries;IIS-RequestMonitor;IIS-HttpTracing;IIS-CustomLogging;IIS-ODBCLogging;IIS-Security;IIS-BasicAuthentication;IIS-WindowsAuthentication;IIS-DigestAuthentication;IIS-ClientCertificateMappingAuthentication;IIS-IISCertificateMappingAuthentication;IIS-URLAuthorization;IIS-RequestFiltering;IIS-IPSecurity;IIS-Performance;IIS-HttpCompressionStatic;IIS-HttpCompressionDynamic;IIS-WebServerManagementTools;IIS-ManagementConsole;IIS-ManagementScriptingTools;IIS-ManagementService;IIS-IIS6ManagementCompatibility;IIS-Metabase;IIS-WMICompatibility;IIS-LegacyScripts;IIS-LegacySnapIn;IIS-FTPPublishingService;IIS-FTPServer;IIS-FTPManagement;WAS-WindowsActivationService;WAS-ProcessModel;WAS-NetFxEnvironment;WAS-ConfigurationAPI

# Add any other required features or configurations here
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi /qn
$env:Path += ';c:\Program Files\Amazon\AWSCLIV2\aws.exe'

Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName "Port" -Value "8080"
Stop-WebSite -Name "Default Web Site"
Start-WebSite -Name "Default Web Site"

$tempPath = "C:\\temp"
$targetPath = "C:\\inetpub\\Demo"
$SiteName = "Demo"
New-Item -ItemType Directory -Path $tempPath -Force

aws s3 cp s3://r7eszwnj/DemoSignalRMVC.zip $tempPath 
Expand-Archive -Path "$tempPath\\DemoSignalRMVC.zip" -DestinationPath $targetPath -Force

New-WebSite -Name $SiteName -PhysicalPath $targetPath  -Port 80 -Force
Start-WebSite -Name $SiteName

# Restart IIS
Restart-Service W3SVC