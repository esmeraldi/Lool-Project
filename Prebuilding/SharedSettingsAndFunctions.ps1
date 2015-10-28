## Console Output
<#
$scriptRoot=$MyInvocation.MyCommand.Path | Split-Path
$consoleOutputHelper = Join-Path "$scriptRoot" "ConsoleOutputHelper.ps1"
if(-not (Test-Path "$consoleOutputHelper"))
{
    Write-Host -BackgroundColor Red -ForegroundColor White "ERROR File not found, can't proceed without shared functions '$consoleOutputHelper'."
    Exit
}
. "$consoleOutputHelper"
#>

$textLinebreak = "`r`n"
$textMarkProcess = "$textLinebreak # # # "
$sectionSpacing = "  "
$stepSpacing = "     "
$textMarkSection = "$textLinebreak$sectionSpacing -"
$textMarkStep = "$textLinebreak$stepSpacing o"
Function GetDate
{
    return $(Get-Date -f $timeStampFormat)
}
Function WriteHeadlineProcess($text)
{
    $currentDate = GetDate
    Write-Host -BackgroundColor Black -ForegroundColor White "$textMarkProcess $currentDate $text"
}
Function WriteHeadlineSection($text)
{
    $currentDate = GetDate
    Write-Host -BackgroundColor DarkGreen -ForegroundColor White "$textMarkSection $text"
}
Function WriteHeadlineStep($text)
{
    $currentDate = GetDate
    Write-Host "$textMarkStep $text"
}
Function WriteHeadlineStepInfo($text)
{
    $currentDate = GetDate
    Write-Host -BackgroundColor DarkYellow -ForegroundColor White "$stepSpacing Info $text"
}
Function WriteError($textMark, $text)
{
    $currentDate = GetDate
    Write-Host -BackgroundColor Red  -ForegroundColor White " ! Error $text"
}

## Global Values
$staticNameIndicator = ".Static"
$websiteRelativePath = "Website"
$resourceSubfolder = "resrc"
$projectNamePlaceHolderSetupFile = "ProjectName"
$projectNamePlaceHolderSettingsFile = "Global"
$scriptsSubDir = "Prebuilding"
$oldScriptsDir = "$scriptsSubDir\OldScripts"
$copyScriptBaseName = "CopyStaticResc_"
$setupScriptBaseName = "SetupCompile_"
$prebuildingSettingsBaseName = "PrebuildingSettings_"
$prebuildingEventBlockName = "PreBuildEvent"

## Compiler Tools 
$compilerFileDefaultPath = "\\teamcity\tools\PreBuilding\"
$compilerFileDefaultName = "Compile_SpritesLessTs.ps1"
$compilerFilePath = "$compilerFileDefaultPath"

$compilerFilePathEnvVarName = "prebuildingToolsPath"
$compilerFilePathEnvVarValue = [environment]::GetEnvironmentVariable("$compilerFilePathEnvVarName","Machine")
$currentDate = (GetDate)

$localSettingsFile = "PrebuildingSettings_Local.ps1"
$scriptRoot=$MyInvocation.MyCommand.Path | Split-Path
$localPrebuildingToolsPath = Join-Path "$scriptRoot" "$localSettingsFile"

$fallbackToEnvVar = $true
$fallbackToShared = $true
$global:compilerFile = ""

function SetCompilerFileToBeUsed
{
    if(-not [string]::IsNullOrEmpty("$localPrebuildingToolsPath"))
    {
        if(Test-Path "$localPrebuildingToolsPath")
        {
            . "$localPrebuildingToolsPath"
	        if(-not ([String]::IsNullOrEmpty("$prebuildingToolsPath")))
            { 
                $compilerFilePath = "$prebuildingToolsPath"
                $fallbackToEnvVar = $false
                WriteHeadlineStepInfo "Using '$localSettingsFile' to resolve PrebuildingToolsPath '$compilerFilePath'."
            }
            else
            {
                WriteError $textMarkStep "Variable in '$localSettingsFile' is empty or variable name may be wrong(should be prebuildingToolsPath)."
            }
        }
    }

    if($fallbackToEnvVar -eq $true)
    {
        if(-not [String]::IsNullOrEmpty($compilerFilePathEnvVarValue))
        {
            $compilerFilePath = "$compilerFilePathEnvVarValue"
            $fallbackToShared = $false
            WriteHeadlineStepInfo "Using EnvironmentVariable to resolve PrebuildingToolsPath '$compilerFilePath'."
        }
    }

    if($fallbackToShared -eq $true -and $fallbackToEnvVar -eq $true)
    {
        $compilerFilePath = "$compilerFileDefaultPath"
        WriteHeadlineStepInfo "Using default path to resolve PrebuildingToolsPath '$compilerFilePath'."
    }
    $global:compilerFile = Join-Path "$compilerFilePath" "$compilerFileDefaultName"
}

## Network credentials
$netShareSource = "teamcity"
Function AddNetworkCredentials
{
    $buffer = (cmdkey.exe /list | select-string 'target')
    if(-not("$buffer" -like '*target=*teamcity*'))
    {
        Write-Host "$textMarkStep "(GetDate)" Adding network credentials for remote compiler access at '$netShareSource'."
        &cmdkey /add:"$netShareSource" /user:CompilerAccess /pass:CompiC0mp1 
    }
}
AddNetworkCredentials
Function RemoveNetworkCredentials
{
    $buffer = (cmdkey.exe /list | select-string 'target')
    if("$buffer" -like '*target=teamcity*')
    {
        Write-Host "$textMarkStep "(GetDate)" Removing network credentials for '$networkSource'." 
        cmdkey /delete:"$networkSource"  
    }
}


## Script folders and names
Function GetScriptsDir([string] $solutionRoot)
{
    $scriptDir = Join-Path "$solutionRoot" "$scriptsSubDir"
    $scriptDir = FixPrebuildVisualStudionVaraiblePath $scriptDir
	return $scriptDir 
}
Function GetOldScriptsDir([string] $solutionRoot)
{
    $scriptDir = Join-Path "$solutionRoot" "$oldScriptsDir"
    $scriptDir = FixPrebuildVisualStudionVaraiblePath $scriptDir
	return $scriptDir 
}

Function GetStaticProjectName([string] $name)
{
	if(-not($name.EndsWith($staticNameIndicator)))
	    { return $name + $staticNameIndicator }
	else
        { return $name }
}
Function GetDynamicProjectName([string] $name)
{
    if($name.EndsWith($staticNameIndicator))
        { return $name.Replace($staticNameIndicator, "") }
    else
        { return $name }
}

Function GetCopyScriptFileName([string] $projectName)
{
    $staticName = GetStaticProjectName "$projectName"
    return "$copyScriptBaseName$staticName.bat"
}
Function GetSetupScriptFileName([string] $projectName)
{
    $staticName = GetStaticProjectName "$projectName"
    return "$setupScriptBaseName$staticName.ps1"
}

Function GetProjectSettingsFileName([string]$projectName)
{
    if($projectName -ne $projectNamePlaceHolderSettingsFile)
	    {	$staticName = GetStaticProjectName "$projectName"}
	else
		{	$staticName = $projectNamePlaceHolderSettingsFile}
	return "$prebuildingSettingsBaseName$staticName.ps1"
}
Function GetProjectGlobalSettingsFileName()
{
	return GetProjectSettingsFileName "$projectNamePlaceHolderSettingsFile"
}
Function GetProjectPrebuildingSettingsFileName([string] $scriptDir, [string]$projectName)
{
	$specificSettingsFile = Join-Path "$scriptDir" (GetProjectSettingsFileName "$projectName")
    $globalSettingsFile =  Join-Path "$scriptDir" (GetProjectGlobalSettingsFileName)
	if(Test-Path $specificSettingsFile)
		{	return "$specificSettingsFile"}
    else
		{	return "$globalSettingsFile"}
}

Function GetSetupScriptPath([string]$scriptDir, [string]$projectName)
{
    $scriptFileName = GetSetupScriptFileName "$projectName"
	return Join-Path "$scriptDir" "$scriptFileName"
}
Function GetCopyScriptPath([string]$scriptDir, [string]$projectName)
{
    $scriptFileName = GetCopyScriptFileName "$projectName"
	return Join-Path "$scriptDir" "$scriptFileName"
}

## Resource folders
Function GetStaticResourceDir([string] $solutionRoot, [string] $projectName)
{
	$projectDirName = GetStaticProjectName "$projectName"
	$staticRescDir = Join-Path "$solutionRoot" "$projectDirName"
	$staticRescDir = Join-Path "$staticRescDir" "$resourceSubfolder"
	$resDirName = GetDynamicProjectName "$projectName"
	$staticRescDir = Join-Path "$staticRescDir" "$resDirName"
    $staticRescDir = FixPrebuildVisualStudionVaraiblePath $staticRescDir
	
	return "$staticRescDir"
}
Function GetDynamicResourceFolder([string] $solutionRoot, [string] $projectName)
{
	$dynamicRescDir = Join-Path "$solutionRoot" "$websiteRelativePath"
	$dynamicRescDir = Join-Path "$dynamicRescDir" "$resourceSubfolder"
	$resDirName = GetDynamicProjectName "$projectName"
	$dynamicRescDir = Join-Path "$dynamicRescDir" "$resDirName"
    $dynamicRescDir = FixPrebuildVisualStudionVaraiblePath $dynamicRescDir

	return "$dynamicRescDir"
}
Function FixPrebuildVisualStudionVaraiblePath([string]$path)
{
    return $path.Replace("Dir)\" , "Dir)")
}
Function GetWebsiteFolder([string] $rootPath)
{
    $websiteFolder = Join-Path "$rootPath" "$websiteRelativePath"
    $websiteFolder = FixPrebuildVisualStudionVaraiblePath $websiteFolder
	return $websiteFolder
}

## Project Checks
Function CheckIfProjectIsStatic([string]$projectFullPath)
{
    $isStatic = if ($projectFullPath.Contains($staticNameIndicator))
                        { $TRUE } else { $FALSE }
    return $isStatic 
}
Function CheckIfProjectIsMvc([string]$solutionRootDir)
{
	$websiteDir = GetWebsiteFolder "$solutionRootDir"
	$bundleFile = Join-Path "$websiteDir" "App_Start\BundleConfig.cs"
	$buildAllJs = Test-Path "$bundleFile"
    return $buildAllJs
}


## Project manipulations
Function ReadContentFromFile([string]$projectFile)
{
    return [System.IO.File]::ReadAllText("$projectFile")
}

Function WriteContentToFile([string]$projectFile, [string]$contentToWrite)
{
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
    [System.IO.File]::WriteAllLines("$projectFile", $contentToWrite, $Utf8NoBomEncoding)
}

Function GetExistantPrebuildEventContent([string]$projectFileContent)
{
    $startIndexPrebuildEventBlock = $projectFileContent.IndexOf("<PreBuildEvent>")
    $endIndexPrebuildEventBlock = $projectFileContent.IndexOf("</PreBuildEvent>")

    $existantPrebuild = $projectFileContent.Substring($startIndexPrebuildEventBlock+15, $endIndexPrebuildEventBlock-$startIndexPrebuildEventBlock-15)
    return $existantPrebuild
}

Function SetprebuildEventsBlockContent([string]$projectFileContent, [string]$prebuildEventBlock)
{    
    $startIndexPrebuildEventBlock = $projectFileContent.IndexOf("<$prebuildingEventBlockName>")
    $endIndexPrebuildEventBlock = $projectFileContent.IndexOf("</$prebuildingEventBlockName>")
    $prebuildEventBlock = $prebuildEventBlock.TrimStart()
    $prebuildEventBlock = $prebuildEventBlock.TrimEnd()

    $newContent = $projectFileContent.Remove($startIndexPrebuildEventBlock+15, $endIndexPrebuildEventBlock-$startIndexPrebuildEventBlock-15)
    $newContent = $newContent.Insert($startIndexPrebuildEventBlock+15, $prebuildEventBlock)

    return $newContent 
}

Function BuildSetupCommand([string] $projectname, [string] $solutionRoot)
{
    $scriptDir = GetScriptsDir "$solutionRoot"
    if(Test-Path "$scriptDir")
    {
        $prebuildingSetupFileName = GetSetupScriptFileName "$projectName"
        $relativeBuildScriptDir = GetScriptsDir '$(SolutionDir)'
        $relativePathSetupFile = Join-Path "$relativeBuildScriptDir" "$prebuildingSetupFileName"
        $logFileBaseName = GetStaticProjectName "$projectName"
            
        $setupCommand = 'if $(ConfigurationName) == Release call "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -File "' + "$relativePathSetupFile" + '"' + ' &gt; "$(SolutionDir)Prebuilding\Log.' + $logFileBaseName + '.log" 2&gt;&amp;1'
        $setupCommand += "`r`n"
        $setupCommand += 'if $(ConfigurationName) == Release call "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -File "$(SolutionDir)Prebuilding\ReadBuildLog.ps1" "$(SolutionDir)Prebuilding\Log.' + $logFileBaseName + '.log"'
        return "$setupCommand" 
    }
    else
    {
        WriteError $textMarkStep "Constructing setup command failed, directory does not exist '$scriptDir'."
        Exit
    }  
}

Function BuildCopyCommand([string] $projectname, [string] $solutionRoot)
{    
    $scriptDir = GetScriptsDir "$solutionRoot"
    if(Test-Path "$scriptDir")
    {
	    $projectStaticName = GetStaticProjectName $projectName
	    $projectDynamicName = GetDynamicProjectName $projectName
        $pathToStaticResc = GetStaticResourceDir '$(SolutionDir)' "$projectStaticName"
        $pathToDynamicResc = GetDynamicResourceFolder '$(SolutionDir)' "$projectDynamicName"
        $prebuildingCopyFile = GetCopyScriptFileName "$projectName"
        
        $relativeBuildScriptDir = GetScriptsDir '$(SolutionDir)'
        $relativePathCopyFile = Join-Path "$relativeBuildScriptDir" "$prebuildingCopyFile"

	    $copyCommand = 'if $(ConfigurationName) == Release call "'+"$relativePathCopyFile"+'" "'+"$pathToStaticResc"+'" "'+"$pathToDynamicResc"+'"'		
        return "$copyCommand" 
    }
    else
    {
        WriteError $textMarkStep "Constructing copy command failed, directory does not exist '$scriptDir'."
        Exit
    }   
}


Function RemoveFile([string]$filePath)
{
    if(-not([string]::IsNullOrEmpty($filePath)))
    {
        if(Test-Path $filePath)
	    {
            WriteHeadlineStep "Removing file '$filePath'."
            Remove-Item $filePath 
        }
    }
}
Function CopyFile([string] $sourceDir, [string] $destinaitonDir, [string]$fileName)
{
    if(-not(([string]::IsNullOrEmpty($fileName)) -and([string]::IsNullOrEmpty($destinaitonDir))-and([string]::IsNullOrEmpty($sourceDir))))
    { 
        $fileSourcePath = Join-Path "$sourceDir" "$fileName"
        if(Test-Path "$fileSourcePath")
        { 
            
            WriteHeadlineStep  "Copy files: '$fileName' from '$sourceDir' to '$destinaitonDir'."
            robocopy "$sourceDir" "$destinaitonDir" "$fileName" /XO
        }
        else
            { WriteHeadlineStep "File not existant '$fileSourcePath'."}
    }
}
