@echo on
set cwd="%~dp0"
set love="%cwd%bin\love.exe"
set b7z="%cwd%bin\7z.exe"
set output=game
@echo on

%b7z% a -tzip %output%.zip %cwd%*.lua %cwd%assets %cwd%libs %cwd%ffi %cwd%states %cwd%ui -mmt -mx0

copy /b %love%+%output%.zip %output%.exe

%b7z% a -tzip %output%-dist.zip %cwd%%output%.exe %cwd%bin/love.dll %cwd%bin/lua51.dll %cwd%bin/mpg123.dll %cwd%bin/OpenAL32.dll %cwd%bin/SDL2.dll %cwd%bin/DevIL.dll %cwd%love-patch.diff

del %output%.zip
del %output%.exe
