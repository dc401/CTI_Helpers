<#
#intelImageCrawlerPS v1.0

Takes an input list of web addresses and then has Microsoft Cognitive
API's analyze the images for context and spits it back out with the originl
URI. 

Requirements:
Powershell v3 or higher and a Microsoft API key for "Computer Vision"

Note: The reason why you have to specify https:// or http:// with the domain
is because the Microsoft API throws a bad request error if you don't. Instead
of concatenating the prefix; you never know if it's https or http. So feel
free to modify.


This is licensed under GPLv2 and is free for use with no warranties.

Usage: intelimageCrawlerPS.ps1 -i fileofurls.txt -k apikey -t tempresultsfile  

-i parameter = a list of single line urls such as https://google.com
-k parameter = api key that you get when you sign up with Microsoft
-t parameter = file path for temporary file

dennis.chow[AT]scissecurity.com
www.scissecurity.com

#>

#cli_parameters
param([string]$i, [string]$k, [string]$t);

#grab into array use .toString per object [string] in front of variable causes all to be one object
$domainList = Get-Content $i.toString()



ForEach ($x in $domainList)
{
    [string]$caturl = $x + $( Invoke-WebRequest -Uri $x -UserAgent "scissecurity.com" ).Images.src
    echo $caturl | Out-File -Append $t
    #Lazy to do event based check. Used sleep instead. Don't hate.
    Sleep 1
}

#Begin Text Analytics API Call with Invoke-RestMethod wrapper
[string]$apiUrlimage = "https://api.projectoxford.ai/vision/v1.0/analyze?visualFeatures=Categories,Tags,Description,Faces,ImageType,Color,Adult"

[string]$apiUrlocr = "https://api.projectoxford.ai/vision/v1.0/ocr?language=unk&detectOrientation=true"

[string]$apiKey = $k


$headers = @{ "Ocp-Apim-Subscription-Key" = $apiKey }

#Grab New URL list
$urlList = Get-Content $t.toString()

ForEach ($z in $urlList)
{
    
    #create json object
    $imageUri = @{url = $z.toString() };
    $jsonimg = ConvertTo-Json $imageUri;


    $imageResults = Invoke-RestMethod -Method Post -Uri $apiUrlimage -Headers $headers -Body $jsonimg -ContentType "application/json"  -ErrorAction Stop
    $ocrResults = Invoke-RestMethod -Method Post -Uri $apiUrlocr -Headers $headers -Body $jsonimg -ContentType "application/json"  -ErrorAction Stop

    #One liner `n is equivalent to \n
    Write-Host `n $z `n
    Write-Host $imageResults.tags `n $imageReuslts.description `n $imageResults.categories `n $imageResults.adult

    #$ocrResults = Invoke-RestMethod -Method Post -Uri $apiUrlocr -Headers $headers -Body $jsonimg -ContentType "application/json"  -ErrorAction Stop
    Write-Host `n $ocrResults.regions.lines.words.text
    
    #Too lazy to do a Wait-Event item. Don't hate.
    Sleep 2
}

#remove temp files
rm $t