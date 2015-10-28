$scriptRoot=$MyInvocation.MyCommand.Path | Split-Path
$sharedBehaviourFile = Join-Path "$scriptRoot" "SharedSettingsAndFunctions.ps1"
if(-not (Test-Path "$sharedBehaviourFile"))
{
    Write-Host -BackgroundColor Red -ForegroundColor White "ERROR File not found, can't proceed without shared functions: $sharedBehaviourFile"
    Exit
}
. "$sharedBehaviourFile"


$global:stopWatch = new-object system.diagnostics.stopWatch
$global:stopWatch.Start()
$global:projectName = "Dedon.Static"
$global:projectName = GetStaticProjectName "$global:projectName"

WriteHeadlineProcess "Setup & compiling for '$global:projectName' - Building resources Glue, Less and TypeScript"
WriteHeadlineSection "Resolving compiler file location."
SetCompilerFileToBeUsed

$global:projectNameExtended = "";
$global:solutionRootDir = "$scriptRoot\.."
$global:projectDir = Resolve-Path "$global:solutionRootDir\$global:projectName"
$global:rescDir =  Resolve-Path (GetStaticResourceDir "$global:solutionRootDir" "$global:projectName")
$global:cssDir = $global:jsDir = $global:jsAmdModules = $global:lessDir = $global:tsDir = $global:tsAmdModules = $global:imgDir = $global:imgSpriteDir = $global:imgRtlDir = ""

function Compile()
{
    if(Test-Path "$global:compilerFile")
    {
	    . "$global:compilerFile"
	    if(Test-Path "$rescDir")
	    {
            WriteHeadlineSection "'$global:projectName' - Loading Settings"
		    $globalSettings = GetProjectPrebuildingSettingsFileName "$scriptRoot" ""
	        if(-not (Test-Path "$globalSettings"))
	        {
		        WriteError $textMarkStep "File not found, can't proceed without '$globalSettings'."
		        StopScript $true
	        }
	        . "$globalSettings"
	        if(($useRetina -eq $null) -or ($tscVersion -eq $null) -or ($tscBuildAmdModule -eq $null) -or ($buildAllJs -eq $null))
	        {
                WriteError $textMarkStep "Unable to load all settings from '$globalSettings'."
		        WriteError $textMarkStep "Ensure the following settings are set:" '$useRetina, $tscVersion, $tscBuildAmdModule, $buildAllJs'
		        StopScript $true    
	        }
	        WriteHeadlineStepInfo "Using global settings from '$globalSettings'."
	    
	        $projectSettings = GetProjectPrebuildingSettingsFileName "$scriptRoot" "$projectName"
            if([string]::Equals("$projectSettings", "$globalSettings") -eq $false)
            {
	            if(Test-Path "$projectSettings")
	            {
		            WriteHeadlineStepInfo "Using additional settings from '$projectSettings'."
		            . "$projectSettings"
	            }
            }

            CompileProject ""
            
            foreach($partialProject in $partialProjects)
            {
                CompileProject $partialProject;
            }

		    StopScript $false
	    }
	    else
	    {
		    WriteError $textMarkSection "Resource directory is not existent '$rescDir'."
		    StopScript $false
	    }
    }
    else
    {
	    WriteError $textMarkSection "Compiler not find '$compilerFile'"
	    WriteError $textMarkSection "Please make sure the file exists, reference included in '$sharedBehaviourFile'."
	    StopScript $false
    }
}


Function InitRescFolderPath([string] $additionalSubfolder)
{
    $global:rescDir =  Resolve-Path (GetStaticResourceDir "$global:solutionRootDir" "$global:projectName")
    $global:rescDir = Join-Path "$global:rescDir" "$additionalSubfolder"
    $global:cssDir = Join-Path "$rescDir" "\css"
    $global:jsDir = Join-Path "$rescDir" "js"
    $global:jsAmdModulesDir = Join-Path $jsDir "modules"
    $global:lessDir = Join-Path "$rescDir" "less"
    $global:tsDir = Join-Path "$rescDir" "ts"
    $global:tsAmdModulesDir = Join-Path $tsDir "modules"
    $global:imgDir = Join-Path "$rescDir" "img"
    $global:imgSpriteDir = Join-Path "$imgDir" "sprite"
    $global:imgRtlDir = Join-Path "$imgDir" "sprite-rtl"
}

Function CompileProject([string] $projectName)
{
    InitRescFolderPath "$projectName"
    SetExtendedProjectName "$projectName"

	if(Test-Path "$rescDir")
	{
        BuildSprites "$global:imgSpriteDir" "$global:imgRtlDir" "$global:rescDir" $useRetina "$spritesLessTemplate"
     
        BuildJavaScript  "$global:tsDir" "$global:jsDir" "$tscversion" "$global:tsAmdModulesDir" $buildAllJs $false $projectName

        BuildJavaScript  "$global:tsDir" "$global:jsDir" "$tscversion" "$global:tsAmdModulesDir" $buildAllJs $tscBuildAmdModule $projectName

        if([string]::IsNullOrEmpty($projectName))
        {
            BuildJavaScriptBundle "$global:jsDir" $javaScriptBundles  
            BuildLess "$global:lessDir" "$global:cssDir" $lessFiles $lessFolder $compressCss      
        }
    }
    else
    {
        WriteError $textMarkSection "Resource directory project '$projectName' is not existent '$rescDir'."
		StopScript $false
    }
}

Function SetExtendedProjectName($additionalName)
{
    $extention = "";
    if(-not([String]::IsNullOrEmpty($additionalName)))
    {
        $extention= ":$additionalName"
    }
    
    $global:projectNameExtended = "$global:projectName$extention"
}

Function StopScript([bool] $handbreak)
{
    $currentDate = (GetDate)
	$global:stopWatch.Stop()
	$time = $global:stopWatch.Elapsed
	WriteHeadlineProcess "Elapsed time: $time"
	if($handbreak -eq $true)
	{
		Exit
	}
}

Function BuildSprites($imgSpriteDir, $imgRtlDir, $rescDir, $useRetina, $spritesLessTemplate)
{
    WriteHeadlineSection "'$projectNameExtended' - Building sprites"
	
	$lessTemplate = ""    
    $spritesTemplatePath = Join-Path "$rescDir" "$spritesLessTemplate"
    if([system.io.file]::Exists("$spritesTemplatePath"))
	{
		$lessTemplate = "$spritesTemplatePath"
	}

    if($spritesTemplatePath.Contains("[fix]"))
    {
        $lessTemplate = "$glueTemplateFix"
    }
    
    if(Test-Path "$imgSpriteDir")
	    { glue "$imgSpriteDir" "$rescDir" $useRetina $lessTemplate}
    if(Test-Path "$imgRtlDir")
	    { glue "$imgRtlDir" "$rescDir" $useRetina $lessTemplate}
}

Function BuildLess($lessDir, $cssDir,  [string[]]$additionalLessFiles, $lessFolder, $compressFile)
{
    WriteHeadlineSection "'$projectNameExtended' - Building CSS from Less"
    if(Test-Path "$lessDir")
	{ 
        if(-not [string]::IsNullOrEmpty($fileAdditionalName))
        {
            $fileAdditionalName += "."
        }

		$lessFilesToCompile += @(Join-Path "$lessDir" $fileAdditionalName"all.less")
		$lessFilesToCompile += @(Join-Path "$lessDir" $fileAdditionalName"all-rtl.less")

        foreach($lessFile in $lessFiles)
		{
            $additionalFile = Join-Path "$lessDir" "$lessFile"
            if(-not (Test-Path "$additionalFile"))
                { WriteHeadlineStepInfo "File not existant: '$additionalFile'" }

            $lessFilesToCompile += @($additionalFile)

        }
	
        lessc $lessFilesToCompile "$cssDir" $compressFile

        
        foreach($folder in $lessFolder)
		{
			$lessSubfolderPath = Join-Path "$lessDir" $folder
			$cssSubFolderPath = Join-Path "$cssDir" $folder
			if(Test-Path $lessSubfolderPath)
			{
				$lessFilesFromSubfolder = filesFromDir "less" "$lessSubfolderPath" $false
				if($lessFilesFromSubfolder.Count -gt 0)
					{ lessc $lessFilesFromSubfolder "$cssSubFolderPath" $compressFile }
			}
		}
	}
}

Function BuildJavaScript($tsDir, $jsDir, $tscversion, $tsAmdModulesDir, $buildAllJs, $tscBuildAmdModule, $additionalName)
{
    WriteHeadlineSection "'$projectNameExtended' - Building JavaScript from Typescript"
    
    if($tscBuildAmdModule -eq $false)
	{
		if((Test-Path "$tsDir"))
		{
			$typeScriptFiles = filesFromDir "ts" "$tsDir" $true			
			tsc "$jsDir" $typeScriptFiles $buildAllJs $tscversion $tscBuildAmdModule $additionalName
		}
	}
	else
	{
        if((Test-Path "$tsAmdModulesDir"))
        {
			$typeScriptFiles = filesFromDir "ts" "$tsAmdModulesDir" $true  		    
            if($typeScriptFiles -ne $null )
			{
				if($typeScriptFiles.Count -gt 0)
    			    {tsc "$jsAmdModulesDir" $typeScriptFiles $false $tscversion $tscBuildAmdModule $additionalName}
			}
        }
	}
}

Function BuildJavaScriptBundle($jsDir, $javaScriptBundles)
{
	WriteHeadlineSection "'$projectNameExtended' - Building JavaScript Bundles"

    if($javaScriptBundles.Count -lt 1)
    {
        WriteHeadlineStepInfo "No Bundles defined."
    }
    else
    {
		foreach($bundle in $javaScriptBundles)
		{
			$bundleLocation = Join-Path "$jsDir" "$bundle"
			$bundleBasePath = [System.IO.Path]::GetDirectoryName("$bundleLocation")
			$filesToBundle = @()

			if(Test-Path "$bundleLocation")
			{
				$relativeToBundleFilePaths = [system.io.file]::ReadAllLines("$bundleLocation")
				foreach($relativeFilePath in $relativeToBundleFilePaths)
				{
					if(-not [string]::IsNullOrEmpty("$relativeFilePath"))
					{
						$absoluteFileLocation = Join-Path "$bundleBasePath" "$relativeFilePath"
						if(Test-Path "$absoluteFileLocation")
						{
							$filesToBundle += @("$absoluteFileLocation")
						}
						else
						{
							WriteError $textMarkStep "File to be bundled is missing '$absoluteFileLocation'."
							Exit
						}
					}
				}
			}
			else
			{
				WriteError $textMarkStep "Bundle file not existant '$bundleLocation'."
				WriteError $textMarkStep "Abborting compiling process."
				Exit
			}

			$contentToWrite = ""
			foreach($fileToBundle in $filesToBundle)
			{
				$contentToWrite += ReadContentFromFile "$fileToBundle"
			}
			$destBundleLocation = $bundleLocation.Replace("$bundleNameIdentifier", "")
			
			WriteHeadlineStep "Creating bundle '$destBundleLocation' from files: $filesToBundle"
			WriteContentToFile "$destBundleLocation" "$contentToWrite"

			compressJs "$destBundleLocation" "$bundleBasePath"
		}
	}
}

Compile
WriteHeadlineProcess "Done compiling for '$global:projectName'."