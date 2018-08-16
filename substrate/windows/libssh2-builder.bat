pushd C:\
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" %Libssh2Arch%
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools_msbuild.bat"
popd

nmake /f NMakefile BUILD_STATIC_LIB=1 WITH_WINCNG=1
