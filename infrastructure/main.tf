provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "EC2S3AccessPolicy"
  description = "Policy for EC2 instance to access S3 bucket"
  policy      = file("IAM-Policy.json")  # The content of the policy JSON file from Step 1
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2S3AccessInstanceProfile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web_server" {
  ami           = "ami-0af9bde3e71173fe2"  # Replace with your desired AMI ID
  instance_type = "t3.small"  # Replace with your desired instance type
  key_name      = "WEBSERVER_KP"  # Replace with your EC2 key pair
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name  # Associate the IAM role with the instance

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  user_data = <<-EOF
    <powershell>
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
    </powershell>
  EOF

  tags = {
    Name = "MyAppServer"
  }
  // You can specify other settings like security groups, IAM role, etc. here.
}

resource "aws_security_group" "web_server_sg" {
  name_prefix = "web-server-sg"
  
  // Allow inbound traffic on port 80 from any source (0.0.0.0/0) for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   // Allow inbound traffic on port 3389 (RDP) only from your IP address
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["120.23.17.201/32"]  # Replace YOUR_PUBLIC_IP with your actual public IP address
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_eip" "web_server_eip" {
  instance = aws_instance.web_server.id
}
*/

resource "aws_route53_record" "ec2_instance_dns" {
  zone_id = "Z2U5VNSAKP97MK"  # Reference the hosted zone created in Step 1

  name    = "demo.alexzander.info"  # Replace with the subdomain you want to use
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web_server.public_ip]  # Reference the public IP of your EC2 instance

  // If you want to use an alias (e.g., pointing to an ELB or CloudFront), you can use the following instead of the 'records' attribute
  // alias {
  //   name                   = aws_lb.my_load_balancer.dns_name
  //   zone_id                = aws_lb.my_load_balancer.zone_id
  //   evaluate_target_health = true
  // }
}