<#
.SYNOPSIS
  Prepare a machine for DaaS projects
.DESCRIPTION
  Prepare a Windows 8.1 or 2012R2 for running DaaS projects by dowloading and installing software.

  At minimum, these will be installed:
    - Chocolatey
    - 7 Zip
    - Git
    - Puppet
    - IMDisk
    - Ruby
    - Vagrant
    - Packer
    - Packer Windows building environment

  A Virtualization platform will also be installed and/or configured. Supported platforms are:
    - Virtualbox
    - VMWare Workstation

  Depending on the chosen platform, more configuration will be allowed such as the Virtual Machines folder, License keys/files where they apply.

  The best way to launch this installation program is to get the latest version from the Internet first:

  [PS] Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -Virtualbox -Verbose

  While we are in development, use:
  Start-BitsTransfer https://raw.githubusercontent.com/inin-apac/puppet-me/master/install/win-8.1-client.ps1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -Virtualbox -Verbose

.PARAMETER Usage
  Prints this help and exits.
.PARAMETER Version
  Displays the version of this installer and exists.
.PARAMETER Virtualbox
  When used, Virtualbox will be installed and configured.
  Only one of -HyperV, -Virtualbox, -VMWare can be specified.
.PARAMETER VMWare
  When used, VMWare Workstation will be installed and configured.
  Only one of -HyperV, -Virtualbox, -VMWare can be specified.
.PARAMETER VMWareLicense
  Contains the license key to configure VMWare Workstation.  
  If not provided, the license key will have to be entered manually the first time VMWare is used.
.PARAMETER VirtualMachinesHome
  Contains the location virtual machines will be stored.  
  The Default value depends on the Virtualization platform that was chosen.
  Alias: VMHome
.PARAMETER PackerHome
  Contains the location where the Packer Windows building environment will be stored.
  When used, it will update $env:PACKER_HOME
  Warning: This folder can grow quite big!
  Default: $env:PACKER_HOME or $env:UserProfile\Documents\packer
.PARAMETER VagrantHome
  Contains the location where Vagrant Data will be stored such as Vagrant boxes.  
  When used, it will update $env:VAGRANT_HOME
  Warning: This folder can grow quite big!
  Default value: $env:VAGRANT_HOME or $env:UserProfile/.vagrant.d
.PARAMETER VagrantVMWareLicense
  Contains the location of the license file for the Vagrant VMWare Plugin.
.PARAMETER CacheRoot
  Contains the location of the cache for ISO, MSI, etc files.  
  When used, it will update $env:DAAS_CACHE
  Alias: DaasCache
  Default: $env:DAAS_CACHE or $env:ProgramData\DaaS\Cache
.PARAMETER CacheConfig
  Contains the location of the JSON document that describe the Cache source locations.
  By Default, this document is downloaded from the Internet.
  Using this parameter is for debugging purposes.
.PARAMETER PackerBuild
  When all software is installed, Packer will be executed to build the given list of Vagrant boxes.
.PARAMETER PackerLoad
  When all software is installed, Packer will be executed to build and load the given list of Vagrant boxes.
.PARAMETER Network
  can be used to force the installation to believe it is run on a given network.  
  Both an ip address and a network (in the cidr form) must be given.  
  See examples.
.PARAMETER Force
  Forces the script to check software versions, update the cache, etc.
  Without Force, the script will try to perform these only once every few hours.
  The idea behind is software and downloads do not change very often, so if they are locally stored in the last 4 hours,
  there is a high chance they are up-to-date. This flash allows to override this assumption.
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -Version
  Will print the current version of Puppet-Me
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -Virtualbox
  Will install all the software and Virtualbox in their default locations.
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -VMWare -VirtualMachineHomes D:\VMWare -VMWareLicense 12345-asdgv-123-scvb-123
  Will install all the software and VMWare Workstation. VMWare Workstation will be stored in D:\VMWare.
  The given license key will be applied to VMWare Workstation.
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -Virtualbox -PackerLoad cic-2015R3
  Will install all the software and Virtualbox in their default locations.
  Once installed, packer is invoked to build the Vagrant box for CIC 2015R3 with Virtualbox.
  Once built, the resulting box is loaded in the Vagrant boxes, so it can be used in "vagrant up"
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -VMWare -PackerBuild windows-8.1-enterprise-eval
  Will install all the software and Virtualbox in their default locations.
  Once installed, packer is invoked to build the Vagrant box for Windows 8.1 Enterprise Evaluation with VMWare Workstation.
.EXAMPLE
  Start-BitsTransfer http://tinyurl.com/win-8-1 $env:TEMP ; & $env:TEMP\win-8.1-client.ps1 -VMWare -PackerBuild all
  Will install all the software and Virtualbox in their default locations.
  Once installed, packer is invoked to build all Vagrant box available with VMWare Workstation.
.NOTES
  Version 0.5.0
#>
[CmdLetBinding(SupportsShouldProcess, DefaultParameterSetName="Usage")]
Param( # {{{2
  [Parameter(Position=1, Mandatory=$false, ParameterSetName='Usage')]
  [switch] $Usage,
  [Parameter(Position=1, Mandatory=$true, ParameterSetName='Version')]
  [switch] $Version,
  [Parameter(Position=1, Mandatory=$true,  ParameterSetName='Virtualbox')]
  [switch] $Virtualbox,
  [Parameter(Position=1, Mandatory=$true,  ParameterSetName='VMWare')]
  [switch] $VMWare,
  [Parameter(Position=2, Mandatory=$false, ParameterSetName='VMWare')]
  [Parameter(Position=2, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Alias('VMHome', 'VirtualMachines')]
  [string] $VirtualMachinesHome,
  [Parameter(Position=3, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $VMWareLicense,
  [Parameter(Position=3, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=4, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $PackerHome,
  [Parameter(Position=4, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=5, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $VagrantHome,
  [Parameter(Position=6, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $VagrantVMWareLicense,
  [Parameter(Position=5, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=7, Mandatory=$false, ParameterSetName='VMWare')]
  [Alias('DaasCache')]
  [string] $CacheRoot,
  [Parameter(Position=6, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=8, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $CacheConfig,
  [Parameter(Position=7, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=9, Mandatory=$false, ParameterSetName='VMWare')]
  [System.Management.Automation.PSCredential] $Credential,
  [Parameter(Position=8, Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=10, Mandatory=$false, ParameterSetName='VMWare')]
  [string[]] $PackerBuild,
  [Parameter(Position=9,  Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=11, Mandatory=$false, ParameterSetName='VMWare')]
  [string[]] $PackerLoad,
  [Parameter(Position=10,  Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=12, Mandatory=$false, ParameterSetName='VMWare')]
  [switch] $NoUpdateCache,
  [Parameter(Position=11,  Mandatory=$false, ParameterSetName='Virtualbox')]
  [Parameter(Position=13, Mandatory=$false, ParameterSetName='VMWare')]
  [string] $Network
) # }}}2
begin # {{{2
{
  $CURRENT_VERSION = '0.5.0'
  $GitHubRoot      = "https://raw.githubusercontent.com/inin-apac/puppet-me"
  $PuppetMeLastUpdate      = "${env:TEMP}/last_updated-puppetme"
  $PuppetMeUpdateFrequency = 4 # hours
  $PuppetMeUpdated         = $false
  $PuppetMeShouldUpdate    = $Force -or !(Test-Path $PuppetMeLastUpdate) -or ([DateTime]::Now.AddHours(-$PuppetMeUpdateFrequency) -gt (Get-ChildItem $PuppetMeLastUpdate).LastWriteTime)

  if ($PuppetMeShouldUpdate) { Write-Verbose "All installs should be run" } else { Write-Verbose "Installs were checked recently, let's give the Internet a break!" }
  switch($PSCmdlet.ParameterSetName)
  {
    'Usage'
    {
      Get-Help -Path $PSCmdlet.MyInvocation.MyCommand.Path
      exit
    }
    'Version'
    {
      Write-Output $CURRENT_VERSION
      exit
    }
    'Hyper-V'
    {
      $Virtualization = 'Hyper-V'
    }
    'Virtualbox'
    {
      $Virtualization = 'Virtualbox'
    }
    'VMWare'
    {
      $Virtualization = 'VMWare'
    }
  }

  if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
  {
    Throw "This installer must be run as an ADministrator"
  }
  if (! $PSBoundParameters.ContainsKey('CacheConfig'))
  {
    $CacheConfig = "${GitHubRoot}/${CURRENT_VERSION}/config/sources.json"
  }

  if (! $PSBoundParameters.ContainsKey('PackerHome'))
  {
    if ([string]::IsNullOrEmpty($env:PACKER_HOME))
    {
      $PackerHome =  "${env:UserProfile}\Documents\packer"
    }
    else
    {
      $PackerHome = $env:PACKER_HOME
    }
  }
  [Environment]::SetEnvironmentVariable('PACKER_HOME', $PackerHome, 'User')

  if (! $PSBoundParameters.ContainsKey('VagrantHome'))
  {
    if ([string]::IsNullOrEmpty($env:VAGRANT_HOME))
    {
      $VagrantHome =  "${env:UserProfile}\.vagrant.d"
    }
    else
    {
      $VagrantHome = $env:VAGRANT_HOME
    }
  }
  [Environment]::SetEnvironmentVariable('VAGRANT_HOME', $VagrantHome, 'User')

  if (! $PSBoundParameters.ContainsKey('CacheRoot'))
  {
    if ([string]::IsNullOrEmpty($env:DAAS_CACHE))
    {
      $CacheRoot =  "${env:ProgramData}\DaaS\cache"
    }
    else
    {
      $CacheRoot = $env:DAAS_CACHE
    }
  }
  [Environment]::SetEnvironmentVariable('DAAS_CACHE', $CacheRoot, 'User')


  Write-Debug "Installing Virtualization:    $Virtualization"
  Write-Debug "Installing Packer Windows in: $PackerHome"
  Write-Debug "Installing Vagrant Data in:   $VagrantHome"
  Write-Debug "Installing Cache in:          $CacheConfig"
} # }}}2
process # {{{2
{
  function Download-File([string] $Source, [string] $Destination) # {{{3
  {
    Start-BitsTransfer -Source $Source -Destination $Destination -ErrorAction Stop
  } # }}}3

  function ConvertFrom-Ini # {{{3
  {
    Param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [string] $InputObject
    )
    process
    {
      $config = [ordered]@{}
      $InputObject -split "`n" | Foreach {
        switch -regex ($_)
        {
          '(.+?)\s*=\s*"(.*)"' # Key
          {
              $name,$value = $matches[1..2]
              $config[$name] = $value
          }
        }
      }
      return $config
    }
  } # }}}3

  function Install-Package # {{{3
  {
    Param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [string] $Package,
      [Parameter(Mandatory=$false)]
      [string] $InstallArguments,
      [Parameter(Mandatory=$false)]
      [switch] $Upgrade
    )
    $results = chocolatey list --local-only $Package | Select-String -Pattern "^${Package}\s+(.*)"

    if ($results -ne $null)
    {
      $current = $results.matches[0].Groups[1].Value
      Write-Debug "  $Package v$current is installed"

      if ($PuppetMeShouldUpdate)
      {
        $results = chocolatey list $Package | Select-String -Pattern "^${Package}\s+(.*)"

        if ($results -ne $null)
        {
          $available = $results.matches[0].Groups[1].Value
          Write-Debug "  $Package v$available is available"

          if ($Upgrade -and ($current -ne $available))
          {
            Write-Output "  Upgrading to $Package v$available"
            chocolatey upgrade -y $Package
            if (! $?) { Throw "$Package not upgraded. Error: $LASTEXITCODE" }
            $PuppetMeUpdated = $true
          }
          else
          {
            Write-Verbose "$Package v$available is already installed"
          }
        }
      }
      else
      {
        Write-Verbose "$Package v$current is installed and was checked less than ${PuppetMeUpdateFrequency} hours ago, skipping..."
      }
    }
    else
    {
      Write-Verbose "Installing $Package"
      if ($PSBoundParameters.ContainsKey('InstallArguments'))
      {
        chocolatey install -y $Package --installarguments $InstallArguments
      }
      else
      {
        chocolatey install -y $Package
      }
      if (! $?) { Throw "$Package not installed. Error: $LASTEXITCODE" }
    }
    $new_path  = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    $new_path += ';'
    $new_path += (Get-ItemProperty -Path 'HKCU:\Environment' -Name PATH).Path
    if ($env:PATH -ne $new_path)
    {
      Write-Verbose "Updating PATH"
      Write-Debug   "Updating PATH to $new_path"
      $env:PATH = $new_path
    }
  } # }}}3

  function Install-Gem([string] $Gem) # {{{3
  {
    if (! (Get-Command gem -ErrorAction SilentlyContinue))
    {
      Install-Package ruby -Force
    }

    if ( gem list --local | Where { $_ -match "${Gem}.*" } )
    {
      $current = ''
      $results = gem list --local | Select-String -Pattern "^${Gem}\s+\((.*)\)"

      if ($results.matches.Length -gt 0)
      {
        $current = $results.matches[0].Groups[1].Value
      }

      if ($Upgrade -and $PuppetMeShouldUpdate)
      {
        Write-Verbose "Upgrading $Gem v$current"
        gem update $Gem
        if (! $?) { Throw "$Gem not upgraded. Error: $LASTEXITCODE" }
        $PuppetMeUpdated = $true
      }
      else
      {
        Write-Verbose "$Gem v$current is already installed"
      }
    }
    else
    {
      Write-Verbose "Installing $Gem"
      gem install $Gem
      if (! $?) { Throw "$Gem not installed. Error: $LASTEXITCODE" }
    }
  } # }}}3

  function Enable-HyperV() # {{{3
  {
    $hyperv_status = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -Verbose:$False

    if ($hyperv_status.State -eq 'Disabled')
    {
      Write-Verbose "Enabling Hyper-V"
      Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

      $hyperv_status = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -Verbose:$False
      if ($hyperv_status.State -eq 'Disabled')
      {
        Throw "Unable to enable Hyper-V"
      }
      elseif ($hyperv_status.State -eq 'EnablePending')
      {
        Write-Warning "Hyper-V is enabled, but needs a restart before being usable"
      }
    }
    elseif  ($hyperv_status.State -eq 'Enabled')
    {
      Write-Verbose "Hyper-V is already enabled"
      return
    }
    elseif ($hyperv_status.State -eq 'EnablePending')
    {
      Write-Warning "Hyper-V is being enabled and needs a restart before being usable"
    }
  } # }}}3

  function Disable-HyperV() # {{{3
  {
    $hyperv_status = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -Verbose:$False

    if ($hyperv_status.State -eq 'Enabled')
    {
      Write-Verbose "Disabling Hyper-V"
      Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -NoRestart

      $hyperv_status = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -Verbose:$False

      if ($hyperv_status.State -eq 'Enabled')
      {
        Throw "Unable to disable Hyper-V"
      }
      elseif ($hyperv_status.State -eq 'DisablePending')
      {
        Write-Warning "Hyper-V is disabled, but needs a restart"
      }
    }
    elseif ($hyperv_status.State -eq 'EnablePending')
    {
      Write-Warning "Hyper-V is being enabled and needs a restart before you can disable it"
    }
    elseif  ($hyperv_status.State -eq 'Disabled')
    {
      Write-Verbose "Hyper-V is already disabled"
    }
  } # }}}3

  function Install-Virtualbox([string] $VirtualMachinesHome) # {{{3
  {
    Disable-HyperV
    Install-Package 'virtualbox' -Upgrade

    if ($env:VBOX_MSI_INSTALL_PATH -eq $null) { $env:VBOX_MSI_INSTALL_PATH = [System.Environment]::GetEnvironmentVariable("VBOX_MSI_INSTALL_PATH", "Machine") }
    $vboxManage=Join-Path $env:VBOX_MSI_INSTALL_PATH 'VBoxManage.Exe'

    $vboxVersion= & $vboxManage --version
    if (! $?) { Throw "Cannot query Virtualbox for its version, Error: $LastExitCode" }

    # Set Virtual Machines Home {{{4
    if (! [string]::IsNullOrEmpty($VirtualMachinesHome))
    {
      $results = & $vboxManage list systemproperties | Select-String -Pattern '^Default machine folder:\s*(.*)'

      if ($results.matches.Length -gt 0)
      {
        $current_home = $results.matches[0].Groups[1].Value
        Write-Verbose "Current Virtual Machines Home: $current_home"
        if ($current_home -ne $VirtualMachinesHome)
        {
          Write-Verbose "  Updating to $VirtualMachinesHome"
          & $vboxManage setproperty machinefolder "$VirtualMachinesHome"
          if (! $?) { Throw "Cannot set Virtualbox Virtual Machine home to `"$VirtualMachinesHome`", Error: $LastExitCode" }
        }
      }
      else
      {
        Write-Verbose "  Setting to $VirtualMachinesHome"
        & $vboxManage setproperty machinefolder "$VirtualMachinesHome"
        if (! $?) { Throw "Cannot set Virtualbox Virtual Machine home to `"$VirtualMachinesHome`", Error: $LastExitCode" }
      }
    } # }}}4

    # Install or Upgrade Virtualbox Extension Pack {{{4
    $vboxExtensionPackInfo = & $vboxManage list extpacks | % { if ($_ -match "(.*)\s*:\s+(.*)") { @{ $matches[1]=$matches[2]; } } }

    if ($vboxVersion -ne "$($vboxExtensionPackInfo.Version)r$($vboxExtensionPackInfo.Revision)")
    {
      $vboxExtensionPack="Oracle_VM_VirtualBox_Extension_Pack-$($vboxVersion -replace 'r','-').vbox-extpack"
      $url="http://download.virtualbox.org/virtualbox/$($vboxVersion -replace 'r.*','')/${vboxExtensionPack}"

      Write-Verbose "Downloading Virtualbox Extension Pack v${vboxVersion}"
      Download-File $url (Join-Path $env:TEMP $vboxExtensionPack)
      Write-Verbose "Installing Virtualbox Extension Pack v${vboxVersion}"
      & $vboxManage extpack install --replace (Join-Path $env:TEMP $vboxExtensionPack)
      if (! $?) { Throw "Cannot install Virtualbox Extension Pack v${vboxVersion}, Error: $LastExitCode" }
    }
    else
    {
      Write-Verbose "Virtualbox Extension Pack v$vboxVersion is already installed"
    } # }}}4
  } # }}}3

  function Install-VMWare([string] $VirtualMachinesHome, [string] $License) # {{{3
  {
    Disable-HyperV
    if ([string]::IsNullOrEmpty($License))
    {
      Install-Package -Package 'vmwareworkstation' -Upgrade
    }
    else
    {
      Install-Package -Package 'vmwareworkstation' -InstallArguments "SERIALNUMBER=$License" -Upgrade
    }

    # Set Virtual Machines Home {{{4
    if (! [string]::IsNullOrEmpty($VirtualMachinesHome))
    {
      if (! (Test-Path $VirtualMachinesHome))
      {
        New-Item -Path $VirtualMachinesHome -ItemType Directory | Out-Null
      }

      $filename = Join-Path $env:APPDATA (Join-Path 'VMWare' 'preferences.ini')
      if (Test-Path $filename)
      {
        $preferences  = Get-Content -Raw -Path $filename | ConvertFrom-Ini
      }
      else
      {
        $preferences  = @{}
      }
      $current_home = $preferences['prefvmx.defaultVMPath']

      Write-Verbose "Current Virtual Machines Home: $current_home"
      if (($current_home -eq $null) -or ($current_home -ne $VirtualMachinesHome))
      {
        Write-Verbose "  Updating to $VirtualMachinesHome"
        $preferences['prefvmx.defaultVMPath'] = $VirtualMachinesHome
        If (! (Test-Path (Join-Path $env:APPDATA 'VMWare')))
        {
          New-Item -Path (Join-Path $env:APPDATA 'VMWare') -ItemType Directory | Out-Null
        }
        $preferences.Keys | Foreach { Write-Output "$_ = `"$($preferences[$_])`"" } | Set-Content -Path $filename
      }
      else
      {
        Write-Verbose "  is already set properly"
      }
    } # }}}4
  } # }}}3

  function Install-VagrantPlugin # {{{3
  {
    Param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [string] $Plugin,
      [Parameter(Mandatory=$false)]
      [string] $License
    )

    if ( (vagrant plugin list) | Where { $_ -match "${Plugin}.*" } )
    {
      $results = (vagrant plugin list) | Select-String -Pattern "^${Plugin}\s+\((.*)\)"

      if ($results.matches.Length -gt 0)
      {
        $current = $results.matches[0].Groups[1].Value
        Write-Verbose "Vagrant Plugin $Plugin v$current is already installed"
      }
    }
    else
    {
      Write-Verbose "Installing Vagrant Plugin $Plugin"
      # As long as https://github.com/jantman/vagrant-r10k/commit/773a6bbe9e49a6fec8751e3108300521bd0e26fb is not in vagrant,
      #  we have to loop ourselves in case bundle fails to contact vagrant's plugin website:
      foreach ($try  in 1..5)
      {
        Write-Debug "Updating Vagrant plugin, Try = $try"
        vagrant plugin install $Plugin
        if ($?) { break }
      }
      if (! $?) { Throw "Vagrant Plugin $Plugin not installed. Error: $LASTEXITCODE" }
    }

    if (! [string]::IsNullOrEmpty($License))
    {
      # Checking if license was applied properly or not
      vagrant box list 2>&1 | Out-Null
      if (! $?)
      {
        Write-Verbose "Licensing Vagrant Plugin $Plugin"
        vagrant plugin license $Plugin "$License"
        if (! $?) { Throw "Vagrant Plugin $Plugin not licensed. Error: $LASTEXITCODE" }
      }
    }
  } # }}}3

  function Update-VagrantPlugin # {{{3
  {
    Param(
      [Parameter(Mandatory=$false)]
      [switch] $All
    )

    if ($PuppetMeShouldUpdate)
    {
      # As long as https://github.com/jantman/vagrant-r10k/commit/773a6bbe9e49a6fec8751e3108300521bd0e26fb is not in vagrant,
      #  we have to loop ourselves in case bundle fails to contact vagrant's plugin website:
      foreach ($try  in 1..5)
      {
        Write-Debug "Updating Vagrant plugin, Try = $try"
        vagrant plugin update
        if ($?) { return }
      }
      if (! $?) { Throw "Could not upgrade Vagrant Plugins. Error: $LASTEXITCODE" }
    }
  } # }}}3

  function Start-VPN # {{{3
  {
    Param(
      [Parameter(Mandatory=$true)]
      [string] $VPNProfile
    )

    Write-Verbose "Starting VPN $($location.vpn)"
    $vpn_provider = 'AnyConnect'
    $vpn_profile  = $null
    Get-VPNProfile -Provider $vpn_provider -ErrorAction SilentlyContinue | Foreach {
      Write-Verbose "Checking $VPNProvider profile $_"
      if ($_ -match $location.vpn)
      {
        $vpn_profile = $_
        break
      }
    }

    if ($vpn_profile -eq $null)
    {
      Throw [System.IO.FileNotFoundException] $VPNProfile
    }
    Write-Verbose "Connecting to $vpn_provider profile $vpn_profile"
    $creds = Get-VaultCredential -Resource $vpn_profile -ErrorAction SilentlyContinue
    if ($creds -eq $null) { $creds = $Credential }
    if ($creds -eq $null)
    {
      $creds = Get-Credential -Message "Please enter your credentials to connect to $VPNProvider profile $vpn_profile"
    }
    $vpn_session = Connect-VPN -Provider $vpn_provider -ComputerName $vpn_profile  -Credential $creds -Verbose:$false
    Set-VaultCredential -Resource $vpn_profile -Credential $creds
    return $vpn_session
  } # }}}3

  function Cache-Source # {{{3
  {
    Param(
      [Parameter(Mandatory=$true)]
      [string] $Uri,
      [Parameter(Mandatory=$true)]
      [string] $Destination,
      [Parameter(Mandatory=$false)]
      [string] $Network
    )

    if ($PSBoundParameters.ContainsKey('Network'))
    {
      $local_ip_address = $Network
    }
    else
    {
      $ipconfig = Get-NetIPAddress | ? { ($_.AddressFamily -eq 'IPv4') -and ($_.PrefixOrigin -eq 'Dhcp') }
      $local_ip_address = "$($ipconfig.IPAddress)/$($ipconfig.PrefixLength)"
    }
    Write-Verbose "My address: $local_ip_address"

    if (! (Test-Path $Destination))
    {
      Write-Output "Creating Cache folder: $Destination"
      New-Item -Path $Destination -ItemType Directory | Out-Null
      if (! $?) { Throw "Unable to create folder $Destination. Error: $LastExitCode" }
    }

    Write-Verbose "Downloading sources configuration"
    $config = Join-Path $env:TEMP 'config.json'
    Write-Verbose "  into $config"
    if (Test-Path $config)
    {
      Write-Verbose "  removing old version"
      Remove-Item -Path $config -Force
    }
    #Start-BitsTransfer -Source $Uri -Destination (Join-Path $env:TEMP 'config.json') -Verbose:$false
    (New-Object System.Net.Webclient).DownloadFile($Uri, $config)

    $sources          = (Get-Content -Raw -Path $config | ConvertFrom-Json)
    $credentials      = @{}
    $connected_drives = @()
    $missed_sources   = @()
    $vpn_session      = $null

    Write-Verbose "Downloading $($sources.Count) sources"
    foreach ($source in $sources)
    {
      switch ($source.action)
      {
        delete
        {
          $path = Join-Path $Destination $source.destination
          if (Test-Path $path)
          {
            Write-Output "Deleting $($source.Name)..."
            Remove-Item $path -Recurse
          }
        }
        default
        {
          Write-Output "Validating $($source.Name)..."
          $source_destination = $Destination
          if ($source.destination -ne $null)
          {
            $source_destination = Join-Path $CacheRoot $source.destination
          }
          if (! (Test-Path $source_destination))
          {
            Write-Verbose "Creating $source_destination"
            New-Item -Path $source_destination -ItemType Directory | Out-Null
          }
          if (($source.filename -notlike '*`**') -and ($source.filename -notlike '*`?*'))
          {
            $source_destination = Join-Path $source_destination $source.filename
          }

          if ((Test-Path $source_destination) -and ($source.checksum -ne $null))
          {
            Write-Verbose "Destination exists..."
            if (Test-Path "${source_destination}.$($source.checksum.type)")
            {
              Write-Verbose "  Importing its $($source.checksum.type) checksum"
              $checksum = Get-Content "${source_destination}.$($source.checksum.type)"
            }
            else
            {
              Write-Verbose "  Calculating its $($source.checksum.type) checksum"
              $checksum = (Get-FileHash $source_destination -Algorithm $source.checksum.type).Hash
            }
            if ($checksum -eq $source.checksum.value)
            {
              Write-Output "  is already downloaded and verified ($($source.checksum.type))"
              if (!(Test-Path "${source_destination}.$($source.checksum.type)"))
              {
                Write-Verbose "  Exporting its $($source.checksum.type) checksum"
                Write-Output $checksum | Set-Content "${source_destination}.$($source.checksum.type)" -Encoding Ascii
              }
              continue
            }
            else
            {
              Write-Verbose "  $($source.checksum.type) Checksums differ, downloading again..."
              Write-Verbose "    (expected: $($source.checksum), local: $checksum)"
            }
          }
          $location=$null
          foreach ($loc in $source.locations)
          {
            Write-Verbose "  Checking in $($loc.location), regex: $($loc.network)"
            if ($local_ip_address -match $loc.network)
            {
              $location=$loc
              break
            }
          }
          if ($location -ne $null)
          {
            if ($location.vpn -ne $null)
            {
              try
              {
                $vpn_session = Start-VPN -VPNProfile $location.vpn
              }
              catch [System.IO.FileNotFoundException]
              {
                Write-Error "There was no VPN Profile that matched $($location.vpn), skipping this download"
                $missed_sources += $location
                continue
              }
              catch [System.Security.Authentication.InvalidCredentialException]
              {
                Write-Error "Could not connect to VPN Profile $($location.vpn), skipping this download"
                $missed_sources += $location
                continue
              }
            }

            Write-Output  "Downloading $($source.Name) From $($location.location)..."
            $source_url="$($location.url)$($source.filename)"
            if ($source_url -match '^([^:]+)://([^/]+)/([^/]+)/(.*)')
            {
              $source_protocol = $matches[1].ToLower()
              $source_host     = $matches[2]
              if ($source_protocol -eq 'smb')
              {
                $source_share  = [System.Web.HttpUtility]::UrlDecode($matches[3])
                $source_path   = [System.Web.HttpUtility]::UrlDecode($matches[4]) -replace '/', '\'
                $source_url    = "\\${source_host}\${source_share}\${source_path}"
                $source_root   = "\\${source_host}\${source_share}"
                $location_type = 'smb'
                 
              }
              else
              {
                $source_share  = ''
                $source_path   = [System.Web.HttpUtility]::UrlDecode($matches[3] + '/' + $matches[4])
                $source_root   = "http://${source_host}/" + [System.Web.HttpUtility]::UrlDecode($matches[3])
                $location_type = $location.type
              }
            }
            else
            {
              Write-Error "Invalid URL: $source_url"
              $missed_sources += $location
              continue
            }
            $creds = Get-VaultCredential -Resource $source_root -ErrorAction SilentlyContinue
            if ($creds -eq $null) { $creds = $Credential }

            Write-Verbose "  Source: $source_url"
            if ($creds -ne $null) { Write-Verbose "  User:   $($creds.Username)" }
            Write-Verbose "  Dest:   $source_destination"
            Write-Verbose "  Type:   $location_type"

            # 1st, try with the logged in user
            if ($PSCmdlet.ShouldProcess($source_destination, "Downloading from $source_host"))
            {
              $request_args = @{}
              $downloaded=$false

              switch ($location_type)
              {
                'akamai'
                {
                  if ($creds -eq $null)
                  {
                    $creds = Get-Credential -Message "Enter your credentials to connect to Akamai"
                  }
                  $request_args['Credential']     = $creds
                  $request_args['Authentication'] = 'Ntlm'
                }
                'smb'
                {
                  if ((Get-PSDrive | where Root -eq $source_root) -eq $null)
                  {
                    # Get the last drive available
                    $drive_letter = (ls function:[d-z]: -n | ?{ !(test-path $_) } | Select -Last 1) -replace ':',''
                    $psdrive_args = @{ Name = $drive_letter; PSProvider = 'FileSystem'; Root = $source_root }
                    if ($creds -ne $null)
                    {
                      $psdrive_args['Credential'] = $creds
                    }
                    $drive = New-PSDrive @psdrive_args -ErrorAction SilentlyContinue
                    if ($drive -eq $null)
                    {
                      $creds = Get-Credential -Message "Enter your credentials to connect to share $source_share on $source_host"
                      if ($creds -eq $null)
                      {
                        Write-Error "Credentials were not entered, skipping this download"
                        $missed_sources += $location
                        continue
                      }
                      $psdrive_args['Credential'] = $creds
                      $drive = New-PSDrive @psdrive_args -ErrorAction SilentlyContinue
                      if ($drive -eq $null)
                      {
                        Write-Error "Cannot connect to share $source_share on $source_host, skipping this download"
                        $missed_sources += $location
                        continue
                      }
                    }
                  }
                }
              }

              for($try=0; $try -lt 2; $try++)
              {
                try
                {
                  Start-BitsTransfer -Source $source_url -Destination $source_destination @request_args -ErrorAction Stop
                  $downloaded=$true
                }
                catch
                {
                  Write-Error $_
                  Write-Verbose "Type: $($_.GetType())"

                  if ($_.Message -match '^HTTP status 401:.*')
                  {
                    Write-Verbose "Collecting credential"
                    if ($source_protocol -eq 'smb')
                    {
                      $creds = Get-Credential -Message "Enter your credentials to connect to share $source_share on $source_host"
                      $request_args['Credential'] = $creds
                    }
                    else
                    {
                      $creds = Get-Credential -Message "Enter your credentials to connect to $source_host over $source_protocol"
                      $request_args['Credential'] =  $creds
                    }
                  }
                  else
                  {
                    break
                  }
                }
              }
              if ($downloaded)
              {
                Write-Verbose "Successful download"
                if ($creds -ne $null)
                {
                  Set-VaultCredential -Resource $source_root -Credential $creds
                }
              }
              if (! $downloaded)
              {
                Write-Error "Unable to download $source_url"
                $missed_sources += $location
              }
            }
          }
          else
          {
            Write-Warning " Cannot download $($source.Name), no location found"
            $missed_sources += $source
          }
        }
      }
    }
    if ($vpn_session -ne $null)
    {
      Write-Verbose "Disconnecting from $($vpn_session.Provider) $($vpn_session.ComputerName)"
      Disconnect-VPN $vpn_session
    }
    if ($connected_drives.Count -gt 0)
    {
      Write-Verbose "Disconnecting $($connected_drives.Count) Windows shares"
      $connected_drives | Foreach {
        Remove-PSDrive -Name $_ -ErrorAction SilentlyContinue
        Write-Verbose "Disconnected from $($_.Root)"
      }
    }
    if ($missed_sources.Count -gt 0)
    {
      Throw "$($missed_sources.Count) sources were not downloaded"
    }
  } # }}}3

  if (Get-Command 'chocolatey.exe' -ErrorAction SilentlyContinue)
  {
    Install-Package 'chocolatey' -Upgrade
  }
  else
  {
    Write-Verbose "Installing Chocolatey"
    Download-File "https://chocolatey.org/install.ps1" "${env:TEMP}/Install-Chocolatey.ps1"
    & $env:TEMP/Install-Chocolatey.ps1
  }

  Install-Package 'MD5'
  Install-Package 'psget' -Upgrade
  if ($?)
  {
    $env:PsModulePath = [Environment]::GetEnvironmentVariable("PsModulePath")
    Import-Module "C:\Program Files\Common Files\Modules\PsGet\PsGet.psm1" -ErrorAction Stop -Verbose:$false
  }
  Install-Package '7zip'
  Install-Package 'git' -Upgrade

  switch ($Virtualization)
  {
    'Hyper-V'
    {
      Enable-HyperV
    }
    'Virtualbox'
    {
      Install-Virtualbox $VirtualMachinesHome
    }
    'VMWare'
    {
      Install-VMWare $VirtualMachinesHome $VMWareLicense
    }
  }

  Install-Package 'vagrant' -Upgrade
  Install-VagrantPlugin 'vagrant-host-shell'
  if ($Virtualization -eq 'VMWare')
  {
    $args = @{}
    if ($PSBoundParameters.ContainsKey('VagrantVMWareLicense')) { $args['License'] = $VagrantVMWareLicense }
    Install-VagrantPlugin 'vagrant-vmware-workstation' @args
  }
  Update-VagrantPlugin -All

  Install-Package 'packer' -Upgrade
  
  Write-Verbose "Installing Packer Plugin provisioner wait"
  #Download-File 'https://github.com/gildas/packer-provisioner-wait/releases/download/v0.1.0/packer-provisioner-wait-0.1.0-win.7z' $env:TEMP
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/gildas/packer-provisioner-wait/releases/download/v0.1.0/packer-provisioner-wait-0.1.0-win.7z', "$env:TEMP\packer-provisioner-wait-0.1.0-win.7z")
  & "${env:ProgramFiles}\7-Zip\7z.exe" e -y -oC:\ProgramData\chocolatey\lib\packer\tools $env:TEMP\packer-provisioner-wait-0.1.0-win.7z | Out-Null
  if (! $?) { Throw "Packer Plugin packer-provisioner-wait not installed. Error: $LASTEXITCODE" }

  Install-Package 'puppet'
  Install-Package 'imdisk'
  Install-Package 'ruby' -Upgrade

  # Set Firewall rules for Ruby {{{3
  $rules = Get-NetFirewallRule | Where Name -match 'TCP.*ruby'
  if ($rules -eq $null)
  {
    New-NetFirewallRule -Name TCP_Ruby_Inbound -DisplayName "Ruby Interpreter (CUI) (TCP-In)" -Description "Ruby Interpreter (CUI) (TCP-In)" -Profile Private,Public -Direction Inbound -Action Allow -Protocol TCP -EdgeTraversalPolicy DeferToUser -Program C:\tools\ruby21\bin\ruby.exe -Enabled True
  }
  else
  {
    $rules | Foreach {
      if (($_.Profiles -band 6) -ne 6) # 0=Any, 1=Domain, 2=Private, 4=Public
      {
        Set-NetFirewallRule -InputObject $_ -Profile Private,Public
      }
    }
  }
  $rules = Get-NetFirewallRule | Where Name -match 'UDP.*ruby'
  if ($rules -eq $null)
  {
    New-NetFirewallRule -Name UDP_Ruby_Inbound -DisplayName "Ruby Interpreter (CUI) (UDP-In)" -Description "Ruby Interpreter (CUI) (UDP-In)" -Profile Private,Public -Direction Inbound -Action Allow -Protocol UDP -EdgeTraversalPolicy DeferToUser -Program C:\tools\ruby21\bin\ruby.exe -Enabled True
  }
  else
  {
    $rules | Foreach {
      if (($_.Profiles -band 6) -ne 6) # 0=Any, 1=Domain, 2=Private, 4=Public
      {
        Set-NetFirewallRule -InputObject $_ -Profile Private,Public
      }
    }
  }
  # }}}3
  Install-Gem     'bundler'
  Install-Gem     'savon'
  #Install-Module  Posh-VPN -Update -Verbose:$Verbose
  Install-Module  -ModuleUrl https://github.com/gildas/posh-vpn/releases/download/0.1.3/posh-vpn-0.1.3.zip -Update -Verbose:$false
  if ($?)
  {
    Import-Module Posh-VPN -ErrorAction Stop -Verbose:$false
  }
  Install-Module  -ModuleUrl https://github.com/gildas/posh-vault/releases/download/0.1.1/posh-vault-0.1.1.zip -Update -Verbose:$false
  if ($?)
  {
    Import-Module Posh-Vault -ErrorAction Stop -Verbose:$false
  }

  $PackerWindows = Join-Path $PackerHome 'packer-windows'
  If (! (Test-Path $PackerWindows)) { New-Item -Path $PackerWindows -ItemType Directory | Out-Null }
  if (Test-Path (Join-Path $PackerWindows '.git'))
  {
    Write-Verbose "Updating Packer Windows repository"
    & git -C "$PackerWindows" pull
    if (! $?) { Throw "Packer Windows not updated. Error: $LASTEXITCODE" }
  }
  else
  {
    Write-Verbose "Cloning Packer Windows repository"
    & git clone https://github.com/gildas/packer-windows.git $PackerWindows
    if (! $?) { Throw "Packer Windows not cloned. Error: $LASTEXITCODE" }
  }
  if (Test-Path (Join-Path $PackerWindows 'Gemfile'))
  {
    Push-Location $PackerWindows
    if ($PuppetMeShouldUpdate)
    {
      bundle install
      if (! $?)
      {
        $exitcode = $LASTEXITCODE
        Pop-Location
        Throw "Packer Windows not bundled. Error: $exitcode"
      }
      $PuppetMeUpdated = $true
    }
    Pop-Location
  }

  # Create/Update the filestamp to indicate installs/upgrades where performed
  if ($PuppetMeUpdated)
  {
    Write-Verbose "Updating the `"Last Update`" timestamp"
    echo $null > $PuppetMeLastUpdate
  }

  if ($NoUpdateCache)
  {
    Write-Verbose "Cache will not be updated"
  }
  else
  {
    $args = @{}
    if ($PSBoundParameters.ContainsKey('Network')) { $args['Network'] = $Network }
    Cache-Source -Uri $CacheConfig -Destination $CacheRoot @args
  }

  if ($PackerBuild.Length -gt 0)
  {
    Push-Location $PackerHome\packer-windows
    $PackerBuild | Foreach {
      $rake_rule="build:$($Virtualization.ToLower()):$_"
      Write-Verbose "Raking $rake_rule"
      rake $rake_rule
    }
    Pop-Location
  }
  if ($PackerLoad.Length -gt 0)
  {
    Push-Location $PackerHome\packer-windows
    $PackerLoad | Foreach {
      $rake_rule="load:$($Virtualization.ToLower()):$_"
      Write-Verbose "Raking $rake_rule"
      rake $rake_rule
    }
    Pop-Location
  }
  Write-Verbose "Your Computer is ready"
} # }}}2