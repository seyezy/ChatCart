@echo off
call flutter pub get
for %%F in (development staging production) do (
  call flutter build apk --flavor %%F --release
  if errorlevel 1 exit /b 1
  call flutter build appbundle --flavor %%F --release
  if errorlevel 1 exit /b 1
)
