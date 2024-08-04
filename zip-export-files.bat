for /f "tokens=*" %%a in ('type project.godot ^| findstr "config/version"') do set VersionLine=%%a
for /f "tokens=2 delims==\=" %%a in ("%VersionLine%") do set Version=%%a
set VersionNumber=%Version:~1,-1%
echo %VersionNumber%

pushd Export

pushd Windows
set ZipFileNameWindows=dots-and-blanks-v%VersionNumber%-Windows.zip
tar -caf %ZipFileNameWindows% --exclude=%ZipFileNameWindows% *
popd
move Windows\%ZipFileNameWindows% .

pushd Web
set ZipFileNameWeb=dots-and-blanks-v%VersionNumber%-Web.zip
tar -caf %ZipFileNameWeb% --exclude=%ZipFileNameWeb% *
popd
move Web\%ZipFileNameWeb% .
