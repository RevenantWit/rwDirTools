function Out-rwDirSelection {
	param(
		[System.IO.DirectoryInfo[]]$Selection,
		[switch]$ReturnName,
		[switch]$ReturnObject
	)

	Write-Verbose "Out-rwDirSelection input: Type=$($Selection.GetType().FullName) Count=$($Selection.Count) Items=$($Selection -join ', ')"

	if ($ReturnObject) { 
		Write-Verbose "Returning DirectoryInfo[] array"
		return , $Selection 
	}

	if ($ReturnName) { 
		Write-Verbose "Returning Name[] array: $($Selection.Name -join ', ')"
		return , $Selection.Name 
	}
	
	Write-Verbose "Returning FullName[] array: $($Selection.FullName -join ', ')"
	return , $Selection.FullName
}
