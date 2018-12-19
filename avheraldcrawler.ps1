
$VerbosePreference = "Continue"
$ErrorActionPreference = "Continue"

# Calculate latest proccesed article
$articleIndex = 1
$articleNr = '445873f3'
$nameParts = ''
(get-item C:\temp\fotos\*).Name | % {
    $nameParts = $_.Split('-')
    if($nameParts.Count -gt 1) {
        $fileIndex = [Int32]::Parse($nameParts[0])
        $fileNr = $nameParts[1]

        if($articleIndex -lt $fileIndex) {
            $articleIndex = $fileIndex
            $articleNr = $fileNr
        }
    }
}

# Let's crawl
$ie = new-object -ComObject "InternetExplorer.Application"


while($true) {
    $url = "http://avherald.com/h?opt=0&article=$articleNr"
    $sc = ""
    Write-Verbose "Processing article '$articleIndex':'$articleNr': '$url'" 
    $ie.silent = $true
    $ie.navigate($url)
    while($ie.Busy) { Start-Sleep -Milliseconds 100 }
    Start-Sleep 10
    $sc = $ie.Document.documentElement.innerHTML

    $sc -match "article=([a-z0-9]+)" -eq $false
    $nextArticleNr = $Matches[1]

    $matches = ([regex]'http://avherald.com\/img\/([\w-_.]+)').Matches($sc).Value

    if($matches.Count -gt 0)
    {
        $i = 1
        $matches | % {
            try {
                Invoke-WebRequest $_ -OutFile "C:\temp\fotos\$articleIndex-$articleNr-$i.jpg"
                Write-Verbose "getting image $_" 
            } catch {
                Write-Error "article:'$articleNr' - i:'$i' imageurl:'$_'" -ErrorAction Continue
            }

            $i = $i + 1
        }
        Write-Verbose "$i Images found in article '$articleNr': '$url'" 
    } else {
        Write-Verbose "No images in article $articleNr" 
    }

    $articleIndex = $articleIndex + 1
    $articleNr = $nextArticleNr
}