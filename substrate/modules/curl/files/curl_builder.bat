pushd C:\
"C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" x86
"C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools_msbuild.bat"
popd

nmake /f Makefile.vc mode=
