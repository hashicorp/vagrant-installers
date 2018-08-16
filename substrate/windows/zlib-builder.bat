pushd C:\
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" %ZlibArch%
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools_msbuild.bat"
popd

nmake /f win32/Makefile.msc
