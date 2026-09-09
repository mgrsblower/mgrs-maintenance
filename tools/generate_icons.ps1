Add-Type -AssemblyName System.Drawing

$src512 = 'assets\icons\mgrs-icon-512.png'
$src192 = 'C:\Users\ogi\Documents\MGRS\public\icons\mgrs-icon-192.png'
$srcMask = 'C:\Users\ogi\Documents\MGRS\public\icons\mgrs-icon-maskable-512.png'

# Web icons
Copy-Item $src512 'web\icons\Icon-512.png' -Force
Copy-Item $src192 'web\icons\Icon-192.png' -Force
Copy-Item $srcMask 'web\icons\Icon-maskable-512.png' -Force

function Resize-Image($sourcePath, $destPath, $width, $height) {
    $srcImage = [System.Drawing.Image]::FromFile($sourcePath)
    $newBitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graph = [System.Drawing.Graphics]::FromImage($newBitmap)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graph.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graph.DrawImage($srcImage, 0, 0, $width, $height)
    $graph.Dispose()
    $srcImage.Dispose()
    $newBitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $newBitmap.Dispose()
}

# Favicon and maskable-192
Resize-Image $src512 'web\favicon.png' 48 48
Resize-Image $srcMask 'web\icons\Icon-maskable-192.png' 192 192

# Android mipmap icons
Resize-Image $src512 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' 48 48
Resize-Image $src512 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' 72 72
Resize-Image $src512 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' 96 96
Resize-Image $src512 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' 144 144
Resize-Image $src512 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' 192 192

# iOS AppIcon assets
$iosDir = 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
if (Test-Path $iosDir) {
    Resize-Image $src512 "$iosDir\Icon-App-1024x1024@1x.png" 1024 1024
    Resize-Image $src512 "$iosDir\Icon-App-20x20@1x.png" 20 20
    Resize-Image $src512 "$iosDir\Icon-App-20x20@2x.png" 40 40
    Resize-Image $src512 "$iosDir\Icon-App-20x20@3x.png" 60 60
    Resize-Image $src512 "$iosDir\Icon-App-29x29@1x.png" 29 29
    Resize-Image $src512 "$iosDir\Icon-App-29x29@2x.png" 58 58
    Resize-Image $src512 "$iosDir\Icon-App-29x29@3x.png" 87 87
    Resize-Image $src512 "$iosDir\Icon-App-40x40@1x.png" 40 40
    Resize-Image $src512 "$iosDir\Icon-App-40x40@2x.png" 80 80
    Resize-Image $src512 "$iosDir\Icon-App-40x40@3x.png" 120 120
    Resize-Image $src512 "$iosDir\Icon-App-60x60@2x.png" 120 120
    Resize-Image $src512 "$iosDir\Icon-App-60x60@3x.png" 180 180
    Resize-Image $src512 "$iosDir\Icon-App-76x76@1x.png" 76 76
    Resize-Image $src512 "$iosDir\Icon-App-76x76@2x.png" 152 152
    Resize-Image $src512 "$iosDir\Icon-App-83.5x83.5@2x.png" 167 167
}

Write-Output 'All Android, Web, and iOS icons generated and copied successfully.'
