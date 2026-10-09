param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$brandingRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'branding.json') -Raw | ConvertFrom-Json
$logoPath = Join-Path $brandingRoot $config.logo
$logo = [System.Drawing.Image]::FromFile($logoPath)
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Get-BrandComponents([string]$hex) {
    $color = [System.Drawing.ColorTranslator]::FromHtml($hex)
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    return @{ red = ($color.R / 255.0).ToString('F6', $culture); green = ($color.G / 255.0).ToString('F6', $culture); blue = ($color.B / 255.0).ToString('F6', $culture); alpha = '1.000' }
}

function Write-BrandText([string]$relative, [string]$content) {
    $target = Join-Path $brandingRoot $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    [System.IO.File]::WriteAllText($target, $content, $utf8)
}

function Write-BrandImage([string]$relative, [int]$size, [double]$artworkSize, [bool]$transparent) {
    $target = Join-Path $brandingRoot $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    $format = [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    if ($transparent) { $format = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
    $bitmap = New-Object System.Drawing.Bitmap($size, $size, $format)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $background = [System.Drawing.ColorTranslator]::FromHtml($config.iconBackground)
        if ($transparent) { $background = [System.Drawing.Color]::Transparent }
        $graphics.Clear($background)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $ratio = $artworkSize / [Math]::Max($logo.Width, $logo.Height)
        $width = [float]($logo.Width * $ratio)
        $height = [float]($logo.Height * $ratio)
        $rect = New-Object System.Drawing.RectangleF([float](($size - $width) / 2), [float](($size - $height) / 2), $width, $height)
        $graphics.DrawImage($logo, $rect)
        $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
}

try {
    Write-Output "Source: $($config.logo), $($logo.Width)x$($logo.Height); artwork is never cropped or recolored."
    $densities = @{ mdpi = 1; hdpi = 1.5; xhdpi = 2; xxhdpi = 3; xxxhdpi = 4 }
    foreach ($density in $densities.Keys) {
        $scale = $densities[$density]
        Write-BrandImage "android/app/src/main/res/mipmap-$density/ic_launcher.png" ([int](48 * $scale)) (48 * $scale) $false
        Write-BrandImage "android/app/src/main/res/drawable-$density/ic_launcher_foreground.png" ([int]($config.adaptiveCanvasDp * $scale)) ($config.adaptiveArtworkDp * $scale) $true
        Write-BrandImage "android/app/src/main/res/drawable-$density/shiftly_splash.png" ([int]($config.splashArtworkDp * $scale)) ($config.splashArtworkDp * $scale) $false
        Write-BrandImage "android/app/src/main/res/drawable-$density/shiftly_splash_android12.png" ([int]($config.splashCanvasDp * $scale)) ($config.splashArtworkDp * $scale) $true
    }
    Write-BrandText 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/shiftly_icon_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'@
    foreach ($night in @($false, $true)) {
        $values = 'values'
        $background = $config.lightBackground
        $parent = 'Theme.Light.NoTitleBar'
        if ($night) { $values = 'values-night'; $background = $config.darkBackground; $parent = 'Theme.Black.NoTitleBar' }
        Write-BrandText "android/app/src/main/res/$values/branding_colors.xml" "<resources><color name=`"shiftly_launch_background`">$background</color><color name=`"shiftly_icon_background`">$($config.iconBackground)</color></resources>"
        $styles = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/$parent">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/$parent">
        <item name="android:windowBackground">@color/shiftly_launch_background</item>
    </style>
</resources>
"@
        Write-BrandText "android/app/src/main/res/$values/styles.xml" $styles
        $styles12 = $styles.Replace('<item name="android:windowBackground">@drawable/launch_background</item>', @'
<item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/shiftly_launch_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/shiftly_splash_android12</item>
'@)
        Write-BrandText "android/app/src/main/res/$values-v31/styles.xml" $styles12
    }
    $launch = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/shiftly_launch_background" />
    <item><bitmap android:gravity="center" android:src="@drawable/shiftly_splash" /></item>
</layer-list>
'@
    Write-BrandText 'android/app/src/main/res/drawable/launch_background.xml' $launch
    Write-BrandText 'android/app/src/main/res/drawable-v21/launch_background.xml' $launch
    $icons = Get-Content -LiteralPath (Join-Path $brandingRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
    foreach ($icon in $icons.images) {
        if (!$icon.filename) { continue }
        $points = [double]($icon.size.Split('x')[0])
        $scale = [double]($icon.scale.TrimEnd('x'))
        Write-BrandImage "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)" ([int]($points * $scale)) ($points * $scale) $false
    }
    foreach ($scale in @(1, 2, 3)) {
        $suffix = ''
        if ($scale -gt 1) { $suffix = "@${scale}x" }
        Write-BrandImage "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (120 * $scale) (120 * $scale) $false
    }
    $colors = @{ info = @{ author = 'xcode'; version = 1 }; colors = @(
        @{ idiom = 'universal'; color = @{ 'color-space' = 'srgb'; components = (Get-BrandComponents $config.lightBackground) } },
        @{ idiom = 'universal'; appearances = @(@{ appearance = 'luminosity'; value = 'dark' }); color = @{ 'color-space' = 'srgb'; components = (Get-BrandComponents $config.darkBackground) } }
    ) }
    Write-BrandText 'ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json' ($colors | ConvertTo-Json -Depth 10)
    Write-Output 'Generated Android density/adaptive/launch resources and iOS icon/launch images.'
} finally { $logo.Dispose() }
