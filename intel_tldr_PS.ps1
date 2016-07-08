<#
#inteltldrPS v1.0 - Intelligence Too Lazy Didn't Read

Requirements:
Powershell v3 or higher and a Microsoft API key for "Text Analytics"

Note: You may get hit or miss results using this API. It requires
very clearn and scrubbed text without special characters in most
cases. In our opinion it isn't ready for prime time yet. It also
refuses to handle larger text files.

This is licensed under GPLv2 and is free for use with no warranties.

Usage: intelimageCrawlerPS.ps1 -i urloftext -k apikey

-i parameter = a list of single line urls such as https://google.com/robots.txt
-k parameter = api key that you get when you sign up with Microsoft

dennis.chow[AT]scissecurity.com
www.scissecurity.com

#>

#cli_parameters
param([string]$i, [string]$k);


#Microsoft Cognitive API is picky. Have to have prescrubbed plain text.
#html tag stripper function
function htmlStrip ($results)
	{
	#using .NET toString method to ensure PS doesn't interpret same var incorrectly
	$results = $results.toString()
	$results -replace '<[^>]*(>|$)'
	}



<#
#get input url from UI
Try
{
	#UI is too ugly
	#$sourceUrl = [string]$Host.ui.ReadLine()
	[string]$sourceUrl = Read-Host "Enter a URL such as https://foobar.com"
}
Catch
{
	Write-Host "URL requires http:// or https:// prefix e.g. https://cnn.com"
}
#>


#New instance .NET client as object
$webClient = New-Object Net.WebClient
[string]$results = $webClient.DownloadString($i)

#Call local function htmlStrip and utilize explicit argument else null
[string]$cleanResults = htmlStrip $results



#convert to awful JSON format for API required input
$body = [ordered]@{
    "documents" = 
	@(
        @{ "language" = "en"; "id" = $i; "text" = $cleanResults }
    )
}

$jsonBody = $body | ConvertTo-Json

#Begin Text Analytics API Call with Invoke-RestMethod wrapper
[string]$apiUrlphrases = "https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/keyPhrases"
[string]$apiUrlsent = "https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/sentiment"
[string]$apiKey = $k


$headers = @{ "Ocp-Apim-Subscription-Key" = $apiKey }

$resultPhrases = Invoke-RestMethod -Method Post -Uri $apiUrlphrases -Headers $headers -Body $jsonBody -ContentType "application/json"  -ErrorAction Stop

$resultSent = Invoke-RestMethod -Method Post -Uri $apiUrlsent -Headers $headers -Body $jsonBody -ContentType "application/json"  -ErrorAction Stop

#Write-Host "Key Phrases:" $resultPhrases.documents.keyPhrases
$resultPhrases.documents.KeyPhrases | Group-Object | Sort-Object
Write-Host "Sentiment Score:"$resultSent.documents.score