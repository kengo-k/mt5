rmdir /s /q %temp%\test_result
xcopy /y %1 %temp%\test_result\
showPositionSummary.hta
