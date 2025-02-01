# Set up Graph libraries
$modules = @('Microsoft.Graph.Users', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Applications', 'Microsoft.Graph.DirectoryObjects', 'Microsoft.Graph.Identity.Governance') 

foreach ($module in $modules) { 
   Install-Module -Name $module -Scope CurrentUser -AllowClobber -Force
}

foreach ($module in $modules) { 
  Import-Module -Name $module 
}