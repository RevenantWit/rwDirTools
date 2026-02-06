<#
.SYNOPSIS
Selects one or more directories with full validation, filtering, and 
automatic GUI/text fallback.

.DESCRIPTION
Get-rwDirPath provides robust directory selection with smart defaults. 
Returns full paths by default (use -Name for just names). Supports single/multi 
selection, exclusion filters, empty directory filtering, and automatically uses 
Out-GridView when available, falling back to CLI menus otherwise.

.PARAMETER Path
Base path to search for directories. Accepts pipeline input.
Default: Current location

.PARAMETER ExcludeDir
Directory names to exclude (like Get-ChildItem -Exclude). Supports wildcards.
Example: @("bin","obj",".*")

.PARAMETER NoEmptyDir
Exclude directories with no contents.

.PARAMETER SingleDir
Allow only one directory selection.

.PARAMETER Name
Return directory names only (default returns full paths).

.PARAMETER Object
Return DirectoryInfo objects instead of strings.
Useful for accessing properties like .Parent, .CreationTime, etc.

.PARAMETER Title
Title shown in selection interface.
Default: "Select A Folder"

.EXAMPLE
$folder = Get-rwDirPath -Path ".\Input" -SingleDir
# Single directory, returns full path

.EXAMPLE
$folders = Get-rwDirPath -Path ".\Mods" -NoEmptyDir
# Multiple directories, excludes empty ones, returns full paths

.EXAMPLE
$names = Get-rwDirPath -Path ".\Projects" -Name
# Multiple directories, returns names only

.EXAMPLE
$objects = Get-rwDirPath -Path ".\Source" -Object
# Returns DirectoryInfo objects with metadata

.EXAMPLE
$filtered = Get-rwDirPath -Path ".\Source" -ExcludeDir @("bin","obj","temp")
# Excludes specified directories, returns full paths

.EXAMPLE
".\Mods" | Get-rwDirPath -SingleDir -NoEmptyDir -Verbose
# Pipeline input, single selection, non-empty only, verbose logging

.NOTES
Returns full paths by default (more reliable for scripting).
Use -Name only when you specifically need folder names.
Use -Object to get DirectoryInfo objects with full metadata.
Case-insensitive matching on Windows, case-sensitive on Unix.
#>
Function Get-rwDirPath {
	[CmdletBinding()]
	[OutputType([string[]])]
	[OutputType([System.IO.DirectoryInfo[]])]
	param(
		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Path = (Get-Location).Path,

		[Parameter()]
		[string[]]$ExcludeDir = @(),

		[Parameter()]
		[switch]$NoEmptyDir,

		[Parameter()]
		[switch]$SingleDir,

		[Parameter()]
		[switch]$Name,

		[Parameter()]
		[switch]$Object,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Title = "Select A Folder"
	)

	process {
		try {
			Write-Verbose "Get-rwDirPath invoked with Path='$Path', ExcludeDir=$($ExcludeDir.Count) items, NoEmptyDir=$NoEmptyDir, SingleDir=$SingleDir, Name=$Name, Object=$Object"
			
			if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
				Write-Warning "Path '$Path' does not exist or is not a directory."
				return @()
			}

			Write-Verbose "Path validation successful. Beginning directory enumeration."

			# Enhanced error handling: distinguish between error types
			$gciErrors = $null
			$childDirs = Get-ChildItem -LiteralPath $Path -Directory -Exclude $ExcludeDir -ErrorAction SilentlyContinue -ErrorVariable gciErrors

			$totalEnumerated = @($childDirs).Count
			$skippedDirs = @($gciErrors).Count
			Write-Verbose "Directory enumeration found $totalEnumerated accessible directories"

			if ($gciErrors) {
				foreach ($err in $gciErrors) {
					if ($err.Exception -is [System.UnauthorizedAccessException]) {
						Write-Warning "Access denied to '$($err.TargetObject)'. This directory will be skipped."
						Write-Verbose "UnauthorizedAccessException on: $($err.TargetObject)"
					} elseif ($err.Exception -is [System.IO.IOException]) {
						Write-Warning "I/O error accessing '$($err.TargetObject)': $($err.Exception.Message)"
						Write-Verbose "IOException on: $($err.TargetObject) - $($err.Exception.Message)"
					} else {
						Write-Warning "Error enumerating '$($err.TargetObject)': $($err.Exception.Message)"
						Write-Verbose "General error on: $($err.TargetObject) - Type: $($err.Exception.GetType().Name) - $($err.Exception.Message)"
					}
				}
				Write-Verbose "Enumeration encountered $skippedDirs error(s) during directory traversal"
			}

			if (-not $childDirs -or (@($childDirs)).Count -eq 0) {
				Write-Warning "No directories found in '$Path' after applying exclusions."
				return @()
			}

			Write-Verbose "Processing $totalEnumerated directories for filtering."

			# Log ExcludeDir validation
			if ($ExcludeDir -and $ExcludeDir.Count -gt 0) {
				Write-Verbose "ExcludeDir filter applied: $($ExcludeDir -join ', ')"
			}

			# Filter empty directories if requested - keep original DirectoryInfo objects
			$emptyCount = 0
			if ($NoEmptyDir) {
				Write-Verbose "Filtering empty directories..."
				$foldersInfo = $childDirs |
					Where-Object {
						$folder = $_
						try {
							$hasContent = $null -ne ([System.IO.Directory]::EnumerateFileSystemEntries($folder.FullName) | Select-Object -First 1)
							if (-not $hasContent) { $emptyCount++ }
							$hasContent
						} catch {
							Write-Verbose "Cannot enumerate '$($folder.FullName)': $($_.Exception.Message)"
							$false
						}
					}
				$remainingCount = @($foldersInfo).Count
				Write-Verbose "Filtered empty directory check: removed $emptyCount empty directories. $remainingCount directories remain."
			} else {
				$foldersInfo = $childDirs
				Write-Verbose "Skipping empty directory filter. $(@($foldersInfo).Count) directories available."
			}

			if ((@($foldersInfo)).Count -eq 0) {
				Write-Warning "No directories remain after filtering."
				return @()
			}

			Write-Verbose "Presenting $(@($foldersInfo).Count) directories for selection."

			# Create display version for menus
			$foldersPath = $foldersInfo | Select-Object Name, FullName

			# Try GUI first, fallback to CLI
			$skipGridView = [System.Environment]::GetEnvironmentVariable('SKIP_GRIDVIEW') -eq '1'
			$ogvCmd = if ($skipGridView) { $null } else { Get-Command -Name Out-GridView -CommandType Cmdlet -ErrorAction SilentlyContinue }
			
			if ($ogvCmd) {
				# Use Out-GridView (GUI)
				Write-Verbose "Out-GridView is available. Using GUI mode for selection."
				
				if ($SingleDir) {
					Write-Verbose "Single-selection mode enabled in Out-GridView"
					$selectedFolders = $foldersPath | Out-GridView -Title $Title -OutputMode Single
				} else {
					Write-Verbose "Multi-selection mode enabled in Out-GridView"
					$selectedFolders = $foldersPath | Out-GridView -Title $Title -OutputMode Multiple
				}

				if ($selectedFolders) {
					Write-Verbose "User selected $(@($selectedFolders).Count) folder(s) via Out-GridView"
					
					# Map to original DirectoryInfo objects for -Object flag
					if ($Object) {
						Write-Verbose "Returning DirectoryInfo objects"
						return @($foldersInfo | Where-Object { $_.FullName -in $selectedFolders.FullName })
					} elseif ($Name) {
						return @($selectedFolders | Select-Object -ExpandProperty Name)
					} else {
						return @($selectedFolders | Select-Object -ExpandProperty FullName)
					}
				} else {
					Write-Verbose "User cancelled selection in Out-GridView"
					return @()
				}
			} else {
				# Fallback to CLI menu
				Write-Verbose "Out-GridView not available. Using CLI menu fallback for selection."
				
				$folderNames = @($foldersPath | Select-Object -ExpandProperty Name)
				$mode = if ($SingleDir) { 'Single' } else { 'Multiple' }
				Write-Verbose "Presenting CLI menu with $($folderNames.Count) options in '$mode' mode"
				$selectedNames = Out-rwMenuCLI -Title $Title -Options $folderNames -Mode $mode				
				if (-not $selectedNames) {
					Write-Verbose "User cancelled selection or made no selection in CLI menu"
					return @()
				}

				Write-Verbose "User selected $(@($selectedNames).Count) folder(s) via CLI menu: $($selectedNames -join ', ')"

				# Convert selected names back to original DirectoryInfo objects
				if ($SingleDir) {
					# Single selection returns a single string
					if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
						$selectedFolders = $foldersInfo | Where-Object { $_.Name -ieq $selectedNames }
					} else {
						$selectedFolders = $foldersInfo | Where-Object { $_.Name -eq $selectedNames }
					}
				} else {
					# Multiple selection returns array of strings
					if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
						$selectedFolders = $foldersInfo | Where-Object { 
							$current = $_
							$selectedNames | Where-Object { $current.Name -ieq $_ }
						}
					} else {
						$selectedFolders = $foldersInfo | Where-Object { $_.Name -in $selectedNames }
					}
				}

				if ($selectedFolders) {
					if ($Object) {
						Write-Verbose "Returning DirectoryInfo objects"
						return @($selectedFolders)
					} elseif ($Name) {
						Write-Verbose "Returning names for $(@($selectedFolders).Count) folder(s)"
						return @($selectedFolders | Select-Object -ExpandProperty Name)
					} else {
						Write-Verbose "Returning full paths for $(@($selectedFolders).Count) folder(s)"
						return @($selectedFolders | Select-Object -ExpandProperty FullName)
					}
				} else {
					Write-Warning "Unable to map selected names back to folder objects."
					Write-Verbose "Expected: $($selectedNames -join ', '); Available: $($foldersInfo.Name -join ', ')"
					return @()
				}
			}
		} catch {
			Write-Error "Get-rwDirPath failed: $($_.Exception.Message)"
			Write-Verbose "Exception details: $($_ | Out-String)"
			return @()
		}
	}
}
