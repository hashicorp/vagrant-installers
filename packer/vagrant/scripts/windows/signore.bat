mkdir C:\signore
"C:\Program Files\7-Zip\7z.exe" x -y -o"C:\signore" C:\Windows\Temp\signore.zip

setx PATH "%PATH%;C:\signore" /m
