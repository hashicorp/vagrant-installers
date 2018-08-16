pushd C:\
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" %CurlArch%
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools_msbuild.bat"
popd

nmake /f Makefile.vc mode=static WITH_ZLIB=static WITH_SSH2=static ENABLE_WINSSL=yes MACHINE=%CurlArch% WITH_DEVEL="..\deps"
