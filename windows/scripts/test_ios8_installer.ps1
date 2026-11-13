[CmdletBinding()]
param([string]$InstallerPath)
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or -not $env:RUNNER_TEMP) { throw 'Installer fixture is restricted to a GitHub Windows runner.' }
$fixture = Join-Path $env:RUNNER_TEMP 'ios8 installer smoke'
$installDir = Join-Path $fixture 'IOS8 VPN'
$appExe = Join-Path $installDir 'IOS8VPN.exe'
$ios8ProfileDir = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) 'Hiddify'
$marker = Join-Path $ios8ProfileDir 'ios8-upgrade-preservation-test.txt'
if ((Test-Path $fixture) -or (Test-Path $ios8ProfileDir)) { throw 'Installer fixture paths already exist; refusing to modify them.' }
if (-not $InstallerPath) {
  $files = @(Get-ChildItem dist -Recurse -File -Filter '*-windows-setup.exe')
  if ($files.Count -ne 1) { throw 'Expected exactly one Windows installer.' }
  $InstallerPath = $files[0].FullName
}
$InstallerPath = (Resolve-Path $InstallerPath).Path
New-Item $fixture -ItemType Directory | Out-Null
$shell = New-Object -ComObject WScript.Shell

function Get-IOS8Links {
  $folders = @(
    [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory),
    [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonDesktopDirectory),
    [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs),
    [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonPrograms),
    [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)
  )
  @($folders | Where-Object { $_ } | ForEach-Object { Join-Path $_ 'IOS8 VPN.lnk' } |
    Where-Object { Test-Path $_ } | Sort-Object -Unique)
}

function Install-Fixture([string]$LogName) {
  $log = Join-Path $fixture $LogName
  $arguments = @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/SP-',
    '/TASKS=desktopicon,launchAtStartup', ('/DIR="' + $installDir + '"'), ('/LOG="' + $log + '"'))
  $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    if (Test-Path $log) { Get-Content $log -Tail 30 }
    throw "Installer failed with exit code $($process.ExitCode)."
  }
}

function Assert-IOS8Links {
  $links = @(Get-IOS8Links)
  if ($links.Count -lt 3) { throw 'Desktop, Start menu and startup shortcuts must all be created.' }
  foreach ($path in $links) {
    $target = $shell.CreateShortcut($path).TargetPath
    if ([IO.Path]::GetFullPath($target) -ine [IO.Path]::GetFullPath($appExe)) {
      throw "Wrong shortcut target: $path -> $target"
    }
    Write-Host "Verified shortcut: $path -> IOS8VPN.exe"
  }
}

try {
  Install-Fixture 'first-install.log'
  if (-not (Test-Path $appExe)) { throw 'Installed IOS8VPN.exe is missing.' }
  $version = (Get-Item $appExe).VersionInfo
  if ($version.ProductName -ne 'IOS8 VPN' -or $version.ProductVersion -notlike '1.0.0*') {
    throw "Wrong product metadata: $($version.ProductName) $($version.ProductVersion)"
  }
  Assert-IOS8Links
  # Simulate the previous broken shortcuts, then perform a real overwrite install.
  foreach ($path in @(Get-IOS8Links)) {
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = Join-Path $installDir 'HiddifyAdmin.exe'
    $shortcut.Save()
  }
  New-Item $ios8ProfileDir -ItemType Directory | Out-Null
  Set-Content $marker 'existing-user-data-must-survive-upgrade'
  Install-Fixture 'overwrite-install.log'
  Assert-IOS8Links
  if ((Get-Content $marker -Raw).Trim() -ne 'existing-user-data-must-survive-upgrade') {
    throw 'Overwrite installation changed existing user data.'
  }
  Write-Host 'IOS8 installer smoke passed: product version, all GUI shortcuts, repair on overwrite, and user-data preservation.'
} finally {
  $uninstaller = Join-Path $installDir 'unins000.exe'
  if (Test-Path $uninstaller) {
    $cleanup = Start-Process -FilePath $uninstaller -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART') -Wait -PassThru
    if ($cleanup.ExitCode -ne 0) { Write-Warning "Fixture uninstall exited $($cleanup.ExitCode)." }
  }
  if (Test-Path $marker) { Remove-Item $marker -Force }
  if ((Test-Path $ios8ProfileDir) -and -not (Get-ChildItem $ios8ProfileDir -Force)) { Remove-Item $ios8ProfileDir }
}
