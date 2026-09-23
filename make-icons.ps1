Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
    param($x, $y, $w, $h, $r)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, $r*2, $r*2, 180, 90)
    $path.AddArc($x + $w - $r*2, $y, $r*2, $r*2, 270, 90)
    $path.AddArc($x + $w - $r*2, $y + $h - $r*2, $r*2, $r*2, 0, 90)
    $path.AddArc($x, $y + $h - $r*2, $r*2, $r*2, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-Icon {
    param(
        [int]$size,
        [string]$outFile,
        [bool]$maskable = $false,
        [bool]$squareBg = $false
    )
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $blue = [System.Drawing.Color]::FromArgb(255, 29, 111, 214)
    $brush = New-Object System.Drawing.SolidBrush $blue

    if ($squareBg) {
        $g.FillRectangle($brush, 0, 0, $size, $size)
    } else {
        $radius = [int]($size * 0.18)
        $path = New-RoundedRectPath 0 0 $size $size $radius
        $g.FillPath($brush, $path)
    }

    # grid content: 2x2 white rounded squares representing a "Bingo" grid, one filled as a marker dot
    $pad = if ($maskable) { $size * 0.30 } else { $size * 0.20 }
    $inner = $size - ($pad * 2)
    $gap = $inner * 0.12
    $cell = ($inner - $gap) / 2
    $white = [System.Drawing.Color]::White
    $whiteBrush = New-Object System.Drawing.SolidBrush $white
    $cellRadius = $cell * 0.22

    $positions = @(
        @{x = $pad; y = $pad},
        @{x = $pad + $cell + $gap; y = $pad},
        @{x = $pad; y = $pad + $cell + $gap},
        @{x = $pad + $cell + $gap; y = $pad + $cell + $gap}
    )
    for ($i = 0; $i -lt 4; $i++) {
        $p = $positions[$i]
        $cp = New-RoundedRectPath $p.x $p.y $cell $cell $cellRadius
        if ($i -eq 3) {
            $accent = [System.Drawing.Color]::FromArgb(255, 178, 216, 255)
            $ab = New-Object System.Drawing.SolidBrush $accent
            $g.FillPath($ab, $cp)
            $ab.Dispose()
        } else {
            $g.FillPath($whiteBrush, $cp)
        }
        $cp.Dispose()
    }

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    [System.IO.File]::WriteAllBytes($outFile, $ms.ToArray())
    $ms.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    $whiteBrush.Dispose()
    $brush.Dispose()
}

New-Icon -size 192 -outFile ".\icons\icon-192.png" -maskable $false -squareBg $false
New-Icon -size 512 -outFile ".\icons\icon-512.png" -maskable $false -squareBg $false
New-Icon -size 512 -outFile ".\icons\icon-512-maskable.png" -maskable $true -squareBg $true
New-Icon -size 180 -outFile ".\icons\icon-180.png" -maskable $false -squareBg $true
New-Icon -size 32 -outFile ".\icons\favicon-32.png" -maskable $false -squareBg $false

Write-Host "Icons erstellt."
