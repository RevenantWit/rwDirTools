<#
.SYNOPSIS
Creates a new directory with validation and optional interactive prompting.

.DESCRIPTION
New-rwDirPath creates a new folder under a specified path. Returns full paths by 
default (use -Name for just the folder name). Interactive by default - provide 
-DirName to skip prompting. Validates against invalid characters, reserved names 
on Windows, and prevents duplicate folder creation.

.PARAMETER Path
Parent directory where folder will be created. Accepts pipeline input.
Default: Current location

.PARAMETER DirName
Folder name to create. Optional - if not provided, function prompts interactively.
Accepts pipeline input.

.PARAMETER Name
Return only the folder name (default returns full path).

.PARAMETER Object
Return the DirectoryInfo object instead of a string path.
Useful for accessing properties like .Parent, .CreationTime, etc.

.EXAMPLE
$folder = New-rwDirPath -Path C:\Temp -DirName "MyFolder" -Object
# Creates folder, returns DirectoryInfo object

.EXAMPLE
New-rwDirPath -Path C:\Temp -DirName "MyFolder"
# Creates folder, returns full path

.EXAMPLE
New-rwDirPath -Path C:\Temp
# Interactively prompts for folder name, returns full path

.EXAMPLE
New-rwDirPath -Path C:\Temp -DirName "MyFolder" -Name
# Creates folder, returns just the name

.EXAMPLE
"C:\Temp" | New-rwDirPath -DirName "MyFolder"
# Pipeline input, returns full path

.NOTES
Validates against invalid filename characters and Windows reserved device names.
Supports -WhatIf and -Confirm for safety.
Maximum 5 retry attempts in interactive mode.
#>
Function New-rwDirPath {
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([string])]
	param(
		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Path = (Get-Location).Path,

		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$DirName,

		[switch]$Name,

		[switch]$Object
	)

	process {
		try {
			if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
				Write-Warning "Path '$Path' does not exist or is not a directory."
				return $null
			}

			# Use module-level reserved device names and pre-compiled pattern
			$reservedDeviceNames = $script:WindowsReservedDeviceNames
			$reservedPattern = $script:ReservedNamePattern
			if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
				Write-Verbose "Skipping Windows reserved device name checks on non-Windows platform."
			}

			$folderInfo = $null
			$validPath = $false

			# Helper function to validate and create folder
			$tryCreate = {
				param($folderName)

				if (-not $folderName) { return $false }

				# Normalize whitespace
				$folderName = $folderName.Trim()
				if (-not $folderName) { return $false }

				# Check for invalid filename characters
				$invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
				if ($folderName.IndexOfAny($invalidChars) -ne -1 -or $folderName.Contains('\') -or $folderName.Contains('/')) {
					Write-Warning "Folder name contains invalid characters or path separators. Please try again."
					Write-Verbose "Invalid characters detected in: '$folderName'"
					return $false
				}

				# Disallow current/parent directory references
				if ($folderName -in @('.', '..')) {
					Write-Warning "Folder name '$folderName' is not valid (reserved reference). Please try again."
					return $false
				}

				# Enhanced Windows reserved name validation using pre-compiled pattern
				if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
					$baseFileName = $folderName.TrimEnd('.',' ').ToUpperInvariant()
					
					# Check if base name is reserved
					if ($reservedDeviceNames -contains $baseFileName) {
						Write-Warning "Folder name '$folderName' is a reserved device name on Windows. Please choose a different name."
						Write-Verbose "Reserved device name matched: $baseFileName"
						return $false
					}
					
					# Check for edge cases using cached regex pattern (faster than rebuilding)
					if ($reservedPattern -and $folderName -match $reservedPattern) {
						Write-Warning "Folder name '$folderName' matches a reserved device name pattern on Windows. Please choose a different name."
						Write-Verbose "Reserved pattern matched: $($Matches[0])"
						return $false
					}
				}

				$folderPath = Join-Path -Path $Path -ChildPath $folderName

				# Check if folder already exists
				if (-not (Test-Path -LiteralPath $folderPath -PathType Container)) {
					if ($PSCmdlet.ShouldProcess($folderPath, 'Create directory')) {
						try {
							$createdFolder = New-Item -Path $folderPath -ItemType Directory -ErrorAction Stop
							$folderInfo = $createdFolder
							Write-Verbose "Successfully created directory: $folderPath"
							return $true
						} catch {
							Write-Warning "Failed to create directory '$folderPath': $($_.Exception.Message)"
							Write-Verbose "Creation error type: $($_.Exception.GetType().Name)"
							return $false
						}
					} else {
						Write-Verbose "Directory creation cancelled by user (-WhatIf or -Confirm)"
						return $false
					}
				} else {
					Write-Verbose "Directory already exists: $folderPath"
					return 'Exists'
				}
			}

			# Non-interactive mode
			if ($DirName) {
				$folderName = $DirName.Trim()
				Write-Verbose "Non-interactive mode: Creating folder '$folderName' in '$Path'"
				$result = & $tryCreate $folderName
				if ($result -eq 'Exists') {
					Write-Warning "Folder '$folderName' already exists under '$Path'."
					return $null
				} elseif ($result -eq $true) {
					$validPath = $true
				} else {
					return $null
				}
			} else {
				# Interactive mode with retry loop and error recovery
				Write-Verbose "Interactive mode: Prompting user for folder name"
				$retryCount = 0
				$maxRetries = 5
				try {
					do {
						$rawInput = Read-Host -Prompt "`nEnter New Folder Name"
						$folderName = if ($rawInput) { $rawInput.Trim() } else { $null }

						if ($folderName) {
							$result = & $tryCreate $folderName
							if ($result -eq $true) {
								$validPath = $true
								Write-Verbose "Folder created successfully on attempt $($retryCount + 1)"
							} elseif ($result -eq 'Exists') {
								$retryCount++
								Write-Verbose "Folder exists, retry attempt $retryCount of $maxRetries"
								if (-not (Out-rwMenuCLI -Title "$folderName Already Exists. Do You Want To Try Again?" -Mode YesNo)) {
									$folderInfo = $null
									Write-Verbose "User chose not to retry after folder exists"
									break
								}
							} else {
								$retryCount++
								Write-Verbose "Validation error, retry attempt $retryCount of $maxRetries"
								if (-not (Out-rwMenuCLI -Title "Do You Want To Try Again?" -Mode YesNo)) {
									$folderInfo = $null
									Write-Verbose "User chose not to retry after validation error"
									break
								}
							}
						} else {
							$retryCount++
							Write-Verbose "Empty input, retry attempt $retryCount of $maxRetries"
							if (-not (Out-rwMenuCLI -Title "Nothing Was Entered. Do You Want To Try Again?" -Mode YesNo)) {
								$folderInfo = $null
								Write-Verbose "User chose not to retry after empty input"
								break
							}
						}

						if ($retryCount -ge $maxRetries) {
							Write-Warning "Maximum retry attempts ($maxRetries) reached. Aborting interactive mode."
							Write-Verbose "Interactive session terminated due to retry limit"
							break
						}
					} until ($validPath)
				} finally {
					if ($Host.UI.RawUI -and -not $env:CI) {
						Write-Host ""
					}
					Write-Verbose "Interactive session ended (attempts: $retryCount, success: $validPath)"
				}
			}

			# Return result based on switches
			if ($folderInfo) {
				if ($Object) {
					Write-Verbose "Returning DirectoryInfo object"
					return $folderInfo
				} elseif ($Name) {
					Write-Verbose "Returning folder name: $($folderInfo.Name)"
					return $folderInfo.Name
				} else {
					Write-Verbose "Returning full path: $($folderInfo.FullName)"
					return $folderInfo.FullName
				}
			} else {
				Write-Verbose "Returning null (operation did not complete successfully)"
				return $null
			}
		} catch {
			Write-Error "New-rwDirPath failed: $($_.Exception.Message)"
			Write-Verbose "Exception type: $($_.Exception.GetType().Name); Call stack: $($_.InvocationInfo.PositionMessage)"
			return $null
		}
	}
}
