Add-Type -AssemblyName System.Drawing

function New-AppIcon {
    param(
        [string]$OutputPath,
        [bool]$IncludeBackground
    )

    $size = 1024
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $bgColor = [System.Drawing.ColorTranslator]::FromHtml("#0A0F14")
    $accentColor = [System.Drawing.ColorTranslator]::FromHtml("#22D3B0")

    if ($IncludeBackground) {
        $bgBrush = New-Object System.Drawing.SolidBrush $bgColor
        $radius = 180
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
        $path.AddArc($size - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
        $path.AddArc($size - $radius * 2, $size - $radius * 2, $radius * 2, $radius * 2, 0, 90)
        $path.AddArc(0, $size - $radius * 2, $radius * 2, $radius * 2, 90, 90)
        $path.CloseFigure()
        $g.FillPath($bgBrush, $path)
    }

    $cx = $size / 2
    $cy = $size / 2
    $hexR = 300

    $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($i = 0; $i -lt 6; $i++) {
        $angleDeg = -90 + 60 * $i
        $angleRad = $angleDeg * [Math]::PI / 180
        $x = $cx + $hexR * [Math]::Cos($angleRad)
        $y = $cy + $hexR * [Math]::Sin($angleRad)
        $pts.Add((New-Object System.Drawing.PointF([float]$x, [float]$y)))
    }
    $hexPen = New-Object System.Drawing.Pen($accentColor, 28)
    $hexPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPolygon($hexPen, $pts.ToArray())

    # Lock body (rounded rect), filled
    $bodyW = 300
    $bodyH = 220
    $bodyX = $cx - $bodyW / 2
    $bodyY = $cy - 10
    $bodyRadius = 46
    $bodyPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $bodyPath.AddArc($bodyX, $bodyY, $bodyRadius * 2, $bodyRadius * 2, 180, 90)
    $bodyPath.AddArc($bodyX + $bodyW - $bodyRadius * 2, $bodyY, $bodyRadius * 2, $bodyRadius * 2, 270, 90)
    $bodyPath.AddArc($bodyX + $bodyW - $bodyRadius * 2, $bodyY + $bodyH - $bodyRadius * 2, $bodyRadius * 2, $bodyRadius * 2, 0, 90)
    $bodyPath.AddArc($bodyX, $bodyY + $bodyH - $bodyRadius * 2, $bodyRadius * 2, $bodyRadius * 2, 90, 90)
    $bodyPath.CloseFigure()
    $bodyBrush = New-Object System.Drawing.SolidBrush($accentColor)
    $g.FillPath($bodyBrush, $bodyPath)

    # Padlock shackle (top-half arc), ends tucked slightly into the body
    $shackleW = 210
    $shackleH = 260
    $shackleX = $cx - $shackleW / 2
    $shackleY = $bodyY + 30 - $shackleH / 2
    $shacklePen = New-Object System.Drawing.Pen($accentColor, 40)
    $shacklePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $shacklePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawArc($shacklePen, $shackleX, $shackleY, $shackleW, $shackleH, 180, 180)

    # Keyhole (dark, punched into the lock body)
    $keyBrush = New-Object System.Drawing.SolidBrush($bgColor)
    $g.FillEllipse($keyBrush, $cx - 24, $cy + 40, 48, 48)
    $keyTri = @(
        (New-Object System.Drawing.PointF([float]($cx - 17), [float]($cy + 70))),
        (New-Object System.Drawing.PointF([float]($cx + 17), [float]($cy + 70))),
        (New-Object System.Drawing.PointF([float]($cx + 9), [float]($cy + 122))),
        (New-Object System.Drawing.PointF([float]($cx - 9), [float]($cy + 122)))
    )
    $g.FillPolygon($keyBrush, $keyTri)

    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$iconDir = "C:\Repos\PrivateSandbox\apps\mobile_flutter\assets\icon"
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null
New-AppIcon -OutputPath "$iconDir\icon_full.png" -IncludeBackground $true
New-AppIcon -OutputPath "$iconDir\icon_foreground.png" -IncludeBackground $false
Write-Output "Done"
