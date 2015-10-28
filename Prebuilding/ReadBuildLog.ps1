Param(
[string]$LogFile)

$fileContent = [System.IO.File]::ReadAllText("$LogFile")
$contentToRemove = @(": error")

foreach($stringToRemove in $contentToRemove)
{
    $fileContent = $fileContent.Replace("$stringToRemove","")
}
Write-Host $fileContent

