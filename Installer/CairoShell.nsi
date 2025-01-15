;--------------------------------
; CairoShell.nsi

!ifndef ARCBITS | ARCNAME | NETTARGET | OUTNAME
!error Defines not set, compile CairoShell_<32|64>.nsi instead!"
!endif

; The name of the installer
Name "Cairo Desktop Environment"

; Use Unicode rather than ANSI
Unicode True

; The file to write
OutFile "${OUTNAME}.exe"

; The default installation directory
InstallDir "$PROGRAMFILES${ARCBITS}\Cairo Shell"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\CairoShell" "Install_Dir"

; Request admin rights on Vista+ (when UAC is turned on)
RequestExecutionLevel Admin 

; Minimum .NET Framework release (4.7.1)
!define MIN_FRA_RELEASE "461308"

!define MUI_ABORTWARNING
!include "MUI.nsh"
!include "LogicLib.nsh"

;--------------------------------
; Pages

  !define MUI_ICON inst_icon.ico
  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_RIGHT
  !define MUI_HEADERIMAGE_BITMAP header_img.bmp
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP left_img.bmp
  !define MUI_UNICON inst_icon.ico
  ;!define MUI_COMPONENTSPAGE_SMALLDESC
  !define MUI_WELCOMEFINISHPAGE_BITMAP left_img.bmp
  !define MUI_WELCOMEPAGE_TEXT "$(PAGE_Welcome_Text_${NETTARGET})"
  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !define MUI_FINISHPAGE_TITLE_3LINES
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "$(PAGE_Finish_RunText)"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchCairo"
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "License.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  
  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !define MUI_FINISHPAGE_TITLE_3LINES
  !insertmacro MUI_UNPAGE_WELCOME
  !define MUI_UNCONFIRMPAGE_TEXT_TOP "$(PAGE_UnDir_TopText)"
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"

;--------------------------------
; Initialization

!macro EnsureAllUserRights
  UserInfo::GetAccountType
  Pop $0
  ReadEnvStr $1 "__COMPAT_LAYER"
  ${If} $0 != "Admin"
  ${AndIf} $0 != "Power"
  ${AndIf} $1 != "RunAsInvoker"
    MessageBox MB_IconStop "Administrator rights required!"
    SetErrorLevel 740 ; ERROR_ELEVATION_REQUIRED
    Quit
  ${EndIf}
!macroend

Function .onInit
  SetShellVarContext All
  !insertmacro EnsureAllUserRights
  
  Call InitializeSectionDefaults
FunctionEnd

Function un.onInit
  SetShellVarContext All
  !insertmacro EnsureAllUserRights
FunctionEnd

;--------------------------------
; Installer
    
Section "$(SECT_cairo)" cairo

  SectionIn RO

  ; Check .NET version
  StrCmp ${NETTARGET} "net471" 0 no_net_check
    Call AbortIfBadFramework
  no_net_check:

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  Call AbortIfRunning
  
  ; Put file there
  DetailPrint "Installing Cairo files"
  File /r "..\Cairo Desktop\Cairo Desktop\bin\Release\${NETTARGET}\publish-${ARCNAME}\"

  ; Start menu shortcuts
  CreateShortcut "$SMPROGRAMS\Cairo Desktop.lnk" "$INSTDIR\CairoDesktop.exe"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\CairoShell "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "DisplayName" "Cairo Desktop Environment"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "DisplayIcon" '"$INSTDIR\RemoveCairo.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "DisplayVersion" "BUILD_VERSION"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "UninstallString" '"$INSTDIR\RemoveCairo.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "URLInfoAbout" "https://cairodesktop.com"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "Publisher" "Cairo Development Team"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell" "NoRepair" 1
  WriteUninstaller "$INSTDIR\RemoveCairo.exe"

SectionEnd

; Run at startup
Section /o "$(SECT_startupCU)" startupCU
  
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "CairoShell" "$INSTDIR\CairoDesktop.exe"
  
SectionEnd

; Replace Explorer
Section /o "$(SECT_shellCU)" shellCU
  
  WriteRegStr HKCU "Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "Shell" "$INSTDIR\CairoDesktop.exe"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "CairoShell"
  
SectionEnd

  ;Language strings

  LangString PAGE_Welcome_Text_net471 ${LANG_ENGLISH} "This installer will guide you through the installation of Cairo.\r\n\r\nBefore installing, please ensure .NET Framework 4.7.1 or higher is installed, and that any running instance of Cairo is ended.\r\n\r\nClick Next to continue."
  LangString PAGE_Welcome_Text_net6.0-windows ${LANG_ENGLISH} "This installer will guide you through the installation of Cairo.\r\n\r\nBefore installing, please ensure that any running instance of Cairo is ended.\r\n\r\nClick Next to continue."
  LangString PAGE_Finish_RunText ${LANG_ENGLISH} "Start Cairo Desktop Environment"
  LangString PAGE_UnDir_TopText ${LANG_ENGLISH} "Please be sure that you have closed Cairo before uninstalling to ensure that all files are removed. All files in the directory below will be removed."
  LangString DLOG_RunningText ${LANG_ENGLISH} "Cairo is currently running. Please exit Cairo from the Cairo menu and run this installer again."
  LangString DLOG_RunningText2 ${LANG_ENGLISH} "Cairo is currently running. Please exit Cairo from the Cairo menu."
  LangString DLOG_DotNetText ${LANG_ENGLISH} "Cairo requires Microsoft .NET Framework 4.7.1 or higher. Please install this from the Microsoft web site and install Cairo again."
  LangString SECT_cairo ${LANG_ENGLISH} "Cairo Desktop (required)"
  LangString SECT_startupCU ${LANG_ENGLISH} "Run at startup (current user)"
  LangString SECT_shellCU ${LANG_ENGLISH} "Advanced: Disable Explorer (current user)"
  LangString DESC_cairo ${LANG_ENGLISH} "Installs Cairo and its required components."
  LangString DESC_startupCU ${LANG_ENGLISH} "Makes Cairo start up when you log in."
  LangString DESC_shellCU ${LANG_ENGLISH} "Run Cairo instead of Windows Explorer. Note: this also disables UWP/Windows Store apps and other features in Windows using that technology."

  LangString PAGE_Welcome_Text_net471 ${LANG_FRENCH} "Cet installateur va vous guider au long de l'installation de Cairo.\r\n\r\nAvant d'installer, veuillez vous assurer que le .NET Framework 4.7.1 ou plus récent est installé, et que vous avez quitté toute instance de Cairo encore en cours de fonctionnement.\r\n\r\nCliquez sur Suivant pour continuer."
  LangString PAGE_Welcome_Text_net6.0-windows ${LANG_FRENCH} "Cet installateur va vous guider au long de l'installation de Cairo.\r\n\r\nAvant d'installer, veuillez vous assurer que vous avez quitté toute instance de Cairo encore en cours de fonctionnement.\r\n\r\nCliquez sur Suivant pour continuer."
  LangString PAGE_Finish_RunText ${LANG_FRENCH} "Démarrer l'environnement de bureau Cairo"
  LangString PAGE_UnDir_TopText ${LANG_FRENCH} "Veuillez vérifier que vous avez fermé Cairo avant de le désinstaller pour assurer que tous les fichiers soient supprimés. All files in the directory below will be removed."
  LangString DLOG_RunningText ${LANG_FRENCH} "Cairo est en cours de fonctionnement. Veuillez quitter Cairo depuis le menu Cairo et lancer de nouveau cet installateur."
  LangString DLOG_RunningText2 ${LANG_FRENCH} "Cairo est en cours de fonctionnement. Veuillez quitter Cairo depuis le menu Cairo."
  LangString DLOG_DotNetText ${LANG_FRENCH} "Cairo nécessite le Microsoft .NET Framework 4.7.1 ou plus récent. Veuillez l'installer depuis le site web de Microsoft et installer de nouveau Cairo."
  LangString SECT_cairo ${LANG_FRENCH} "Bureau Cairo (requis)"
  LangString SECT_startupCU ${LANG_FRENCH} "Lancer au démarrage (utilisateur actuel)"
  LangString SECT_shellCU ${LANG_FRENCH} "Utilisateurs avancés uniquement : remplacer l'Explorateur Windows (utilisateur actuel)"
  LangString DESC_cairo ${LANG_FRENCH} "Installer Cairo et ses composants requis."
  LangString DESC_startupCU ${LANG_FRENCH} "Démarrer Cairo lorsque vous vous connectez."
  LangString DESC_shellCU ${LANG_FRENCH} "Lancer Cairo au lieu de l'Explorateur Windows. Notez que cela désactive également de nombreuses fonctionnalités nouvelles dans Windows."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${cairo} $(DESC_cairo)
    !insertmacro MUI_DESCRIPTION_TEXT ${startupCU} $(DESC_startupCU)
    !insertmacro MUI_DESCRIPTION_TEXT ${shellCU} $(DESC_shellCU)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller

Section "Uninstall"

  System::Call 'kernel32::OpenMutex(i 0x100000, i 0, t "CairoShell")p.R1'
  IntPtrCmp $R1 0 notRunning
    System::Call 'kernel32::CloseHandle(p $R1)'
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(DLOG_RunningText)" /SD IDOK
    Quit
  
  notRunning:

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\CairoShell"
  DeleteRegKey HKLM SOFTWARE\CairoShell
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "CairoShell"
  DeleteRegValue HKCU "Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "Shell"

  ; Remove files and uninstaller. Includes historical files
  ; If we allowed customizing the install dir, this would be bad
  ; (e.g. if someone installed into another existing directory)
  ; If we allow this in the future, need to write an uninstall log.
  RMDir /r "$INSTDIR"

SectionEnd

;--------------------------------
; Functions

Function LaunchCairo
  IfFileExists "$WINDIR\explorer.exe" 0 std_exec
    Exec '"$WINDIR\explorer.exe" "$INSTDIR\CairoDesktop.exe"' ; use the shell to launch as current user (otherwise notification area breaks)
    goto end_launch
  std_exec:
    Exec '$INSTDIR\CairoDesktop.exe /restart=true'
  end_launch:
FunctionEnd

Function InitializeSectionDefaults
  IfSilent +2
    SectionSetFlags ${startupCU} 1
FunctionEnd

Function .onInstSuccess
  IfSilent 0 +2
    Call LaunchCairo
FunctionEnd

Function AbortIfRunning
  DetailPrint "Checking if Cairo is currently running"
  StrCpy $R0 "0" ; current retry count

  IfSilent 0 +3
    StrCpy $R2 "10" ; 10 retries when running silent
    Goto check
  StrCpy $R2 "2" ; 2 retries when running normally

  check:
    System::Call 'kernel32::OpenMutex(i 0x100000, i 0, t "CairoShell")p.R1'
    IntPtrCmp $R1 0 notRunning running running

  retry:
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(DLOG_RunningText2)" /SD IDOK
    IntOp $R0 $R0 + 1
    Sleep 1000
    Goto check

  running:
    System::Call 'kernel32::CloseHandle(p $R1)'
    IntCmp $R0 $R2 abort retry abort

  abort:
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(DLOG_RunningText)"
    Quit

  notRunning:
FunctionEnd

; https://nsis.sourceforge.io/How_to_Detect_any_.NET_Framework
; Check .NET framework release version and quit if too old
Function AbortIfBadFramework
  DetailPrint "Checking currently installed .NET Framework version"
 
  ; Save the variables in case something else is using them
  Push $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $R1
  Push $R2
  Push $R3
  Push $R4
  Push $R5
  Push $R6
  Push $R7
  Push $R8
 
  ; Major
  StrCpy $R5 "0"
 
  ; Minor
  StrCpy $R6 "0"
 
  ; Build
  StrCpy $R7 "0"
 
  ; No Framework
  StrCpy $R8 "0.0.0"
 
  StrCpy $0 0
 
  loop:
 
  ; Get each sub key under "SOFTWARE\Microsoft\NET Framework Setup\NDP"
  EnumRegKey $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP" $0
  StrCmp $1 "" done ;jump to end if no more registry keys
  IntOp $0 $0 + 1
  StrCpy $2 $1 1 ;Cut off the first character
  StrCpy $3 $1 "" 1 ;Remainder of string
 
  ; Loop if first character is not a 'v'
  StrCmpS $2 "v" start_parse loop
 
  ; Parse the string
  start_parse:
  StrCpy $R1 ""
  StrCpy $R2 ""
  StrCpy $R3 ""
  StrCpy $R4 $3
 
  StrCpy $4 1
 
  parse:
  StrCmp $3 "" parse_done ; If string is empty, we are finished
  StrCpy $2 $3 1 ; Cut off the first character
  StrCpy $3 $3 "" 1 ; Remainder of string
  StrCmp $2 "." is_dot not_dot ; Move to next part if it's a dot
 
  is_dot:
  IntOp $4 $4 + 1 ; Move to the next section
  goto parse ; Carry on parsing
 
  not_dot:
  IntCmp $4 1 major_ver
  IntCmp $4 2 minor_ver
  IntCmp $4 3 build_ver
  IntCmp $4 4 parse_done
 
  major_ver:
  StrCpy $R1 $R1$2
  goto parse ; Carry on parsing
 
  minor_ver:
  StrCpy $R2 $R2$2
  goto parse ; Carry on parsing
 
  build_ver:
  StrCpy $R3 $R3$2
  goto parse ; Carry on parsing
 
  parse_done:
 
  IntCmp $R1 $R5 this_major_same loop this_major_more
  this_major_more:
  StrCpy $R5 $R1
  StrCpy $R6 $R2
  StrCpy $R7 $R3
  StrCpy $R8 $R4
 
  goto loop
 
  this_major_same:
  IntCmp $R2 $R6 this_minor_same loop this_minor_more
  this_minor_more:
  StrCpy $R6 $R2
  StrCpy $R7 $R3
  StrCpy $R8 $R4
  goto loop
 
  this_minor_same:
  IntCmp R3 $R7 loop loop this_build_more
  this_build_more:
  StrCpy $R7 $R3
  StrCpy $R8 $R4
  goto loop
 
  done:
 
  ReadRegDWORD $R9 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" Release
  IntCmp $R9 ${MIN_FRA_RELEASE} end wrong_framework end
 
  wrong_framework:
  MessageBox MB_OK|MB_ICONSTOP "$(DLOG_DotNetText)"
  Quit
 
  end:
 
  ; Pop the variables we pushed earlier
  Pop $R8
  Pop $R7
  Pop $R6
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
 
FunctionEnd
