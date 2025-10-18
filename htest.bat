@echo off
setlocal enabledelayedexpansion

if "%~2"=="" (
    echo Usage: %~n0 ModuleName file1 [file2 ...]
    exit /b 1
)

set "MODULE=%~1"

set "HEADER=%TEMP%\htest_header.ghci"
echo :set prompt "" > "%HEADER%"
echo :load %MODULE% >> "%HEADER%"

set "TESTS=%TEMP%\htest_tests.ghci"
<NUL set /p "=let tests = [" > "%TESTS%"

for %%F in (%*) do (
  if exist "%%~F" (
    setlocal disabledelayedexpansion
    for /f "usebackq tokens=* delims=" %%A in ("%%~F") do (
      set "LINE=%%A"
      setlocal enabledelayedexpansion
      if "!LINE:~0,8!"=="#import " (
        >> "%HEADER%" echo !LINE:~1!
      )
      endlocal
    )
    endlocal
  )
)

set "COUNT_ALL=0"
for %%F in (%*) do (
  if exist "%%~F" (
    set "FUNC=%%~nF"
    set "LINE_COUNT=0"
    set "FUNC_CALL="
    set "EXPECTED="
    set /a "COUNT_ALL+=1"
    setlocal disabledelayedexpansion
    for /f "usebackq tokens=* delims=" %%A in ("%%~F") do (
      set "LINE=%%A"
      setlocal enabledelayedexpansion
      if "!LINE:~0,2!"=="#/" (
        REM skip comment
        ) else if "!LINE:~0,8!"=="#import " (
        REM skip imports, already handled
        ) else (
        set /a LINE_COUNT+=1
        set /a IS_EVEN_LINE=!LINE_COUNT! %% 2
        if !IS_EVEN_LINE! equ 1 (
          set "ARGS_LINE=!LINE!"
          set "ARGS_LINE=!ARGS_LINE:\"=__ESC_QUOTE__!"
          set "PARSED_ARGS="
          set "IN_QUOTES=0"
          set "TEMP_ARG="
          set q="
          set "PARSE_DONE=0"
          for /l %%i in (0,1,1000) do (
            if !PARSE_DONE! equ 0 (
              set "CHAR=!ARGS_LINE:~%%i,1!"
              if "!CHAR!"=="" set "PARSE_DONE=1"
              if !PARSE_DONE! equ 0 (
                if "!CHAR!"==" " (
                  if !IN_QUOTES! equ 0 (
                    if defined TEMP_ARG (
                      set "PARSED_ARGS=!PARSED_ARGS! !TEMP_ARG!"
                      set "TEMP_ARG="
                      ) else (
                      set "PARSED_ARGS=!PARSED_ARGS! "
                    )
                    ) else (
                    set "TEMP_ARG=!TEMP_ARG!!CHAR!"
                  )
                  ) else (
                  if "!CHAR!"==!q! (
                    if !IN_QUOTES! equ 0 (
                      set "IN_QUOTES=1"
                      ) else (
                      set "IN_QUOTES=0"
                    )
                    ) else (
                    set "TEMP_ARG=!TEMP_ARG!!CHAR!"
                  )
                )
              )
            )
          )
          if defined TEMP_ARG set "PARSED_ARGS=!PARSED_ARGS! !TEMP_ARG!"
          set "PARSED_ARGS=!PARSED_ARGS:__ESC_QUOTE__=\"!"
          if defined PARSED_ARGS set "LINE=!PARSED_ARGS:~1!"
          if not defined PARSED_ARGS set "LINE="
          set "FUNC_CALL=!FUNC! !LINE!"
          if !COUNT_ALL! equ 1 (
            if !LINE_COUNT! neq 1 (
              <NUL set /p "=, " >> "%TESTS%"
            )
          )

          if not !COUNT_ALL! equ 1 (
            <NUL set /p "=, " >> "%TESTS%"
          )
          ) else (
          set "EXPECTED=!LINE!"
          set "EXPECTED=!EXPECTED:(=(!"
          set "EXPECTED=!EXPECTED:)=)!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL:\=\\!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:\¶"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:\¶"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:\¶"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:\¶"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:\¶"=¶"!"
          set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:¶"=\"!"

          <NUL set /p "=let actual = (%MODULE%.!FUNC_CALL!); expected = (!EXPECTED!) in (expected == actual, "!FUNC_CALL_ESCAPED!" ++ "\nExpected: " ++ show expected ++ "\nActual: " ++ show actual)" >> "%TESTS%"
        )
      )
      for /f "tokens=1,* delims=|" %%X in ("!LINE_COUNT!|!FUNC_CALL!") do (
        endlocal
        set "LINE_COUNT=%%X"
        set "FUNC_CALL=%%Y"
      )
    )
    endlocal & set "COUNT_ALL=!COUNT_ALL!"
  )
)

echo Total files processed: %count_all%
>> "%TESTS%" echo ]

set "SCRIPT=%TEMP%\htest.ghci"
type "%HEADER%" > "%SCRIPT%"
type "%TESTS%" >> "%SCRIPT%"
>> "%SCRIPT%" echo mapM_ ^(\ t -^> putStrLn ^(snd t ++ ^(if fst t then "\nPASS\n" else "\nFAIL\n"^)^)^) tests
>> "%SCRIPT%" echo putStrLn ^("Total: " ++ show ^(length tests^)^)
>> "%SCRIPT%" echo putStrLn ^("Failed: " ++ show ^(length ^(filter ^(\ t -^> fst t == False^) tests^)^)^)

ghci < "%SCRIPT%"

if not defined HTEST_KEEP_TEMP_FILES (
    del "%HEADER%" 2>nul
    del "%TESTS%" 2>nul
    del "%SCRIPT%" 2>nul
)

endlocal
