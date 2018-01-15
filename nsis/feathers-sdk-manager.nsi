;NSIS Modern User Interface
;Basic Example Script
;Written by Joost Verburg

;--------------------------------
;Includes

	!include "MUI2.nsh"
	!include "FileFunc.nsh"

;--------------------------------
;General

	;Name and file
	Name "Feathers SDK Manager"
	OutFile "FeathersSDKManagerInstaller-${VERSION}.exe"

	;Default installation folder
	InstallDir "$PROGRAMFILES\Feathers SDK Manager"
	
	;Get installation folder from registry if available
	InstallDirRegKey HKCU "Software\FeathersSDKManager" ""

	;Request application privileges for Windows Vista and higher
	RequestExecutionLevel admin
	
Function .onInit
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"UninstallString"
	StrCmp $R0 "" done
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
		"Setup has detected that another version of Feathers SDK Manager is already installed. \
		Choose $\"OK$\" to remove the previous version or $\"Cancel$\" to cancel this upgrade." \
		IDOK run_uninstaller
		Abort
	run_uninstaller:
		ClearErrors
		
		;look for the nsis uninstaller as a special case
		StrCmp $R0 "$\"$INSTDIR\uninstall.exe$\"" 0 +3
			ExecWait '$R0 _?=$INSTDIR'
				Goto +2
				ExecWait '$R0'
	
		IfErrors uninstall_fail uninstall_success
		uninstall_fail:
			Quit
		uninstall_success:
			Delete "$INSTDIR\uninstall.exe"
			RmDir "$INSTDIR"
	done:
FunctionEnd

;--------------------------------
;Interface Settings

	!define MUI_HEADERIMAGE
	!define MUI_HEADERIMAGE_BITMAP "header.bmp"
	!define MUI_WELCOMEFINISHPAGE_BITMAP "wizard.bmp"
	!define MUI_FINISHPAGE_RUN "$INSTDIR\Feathers SDK Manager.exe"
	!define MUI_FINISHPAGE_RUN_TEXT "Run Feathers SDK Manager"
	!define MUI_FINISHPAGE_NOAUTOCLOSE
	!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
	!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
	!define MUI_ABORTWARNING

;--------------------------------
;Pages

	!insertmacro MUI_PAGE_WELCOME
	!insertmacro MUI_PAGE_DIRECTORY
	!insertmacro MUI_PAGE_INSTFILES
	!insertmacro MUI_PAGE_FINISH
	
	!insertmacro MUI_UNPAGE_CONFIRM
	!insertmacro MUI_UNPAGE_INSTFILES
	
;--------------------------------
;Languages
 
	!insertmacro MUI_LANGUAGE "English"
	
;--------------------------------
;Installer Sections

Section "FeathersSDKManager" SecFeathersSDKManager

	;copy all files
	SetOutPath "$INSTDIR"
	File "Feathers SDK Manager\Feathers SDK Manager.exe"
	File "Feathers SDK Manager\FeathersSDKManager.swf"
	File "Feathers SDK Manager\mimetype"
	File "Feathers SDK Manager\icon16.png"
	File "Feathers SDK Manager\icon32.png"
	File "Feathers SDK Manager\icon48.png"
	File "Feathers SDK Manager\icon128.png"
	File "Feathers SDK Manager\icon512.png"
	SetOutPath "$INSTDIR\META-INF"
	File "Feathers SDK Manager\META-INF\signatures.xml"
	SetOutPath "$INSTDIR\META-INF\AIR"
	File "Feathers SDK Manager\META-INF\AIR\application.xml"
	File "Feathers SDK Manager\META-INF\AIR\hash"
	SetOutPath "$INSTDIR\Adobe AIR\Versions\1.0"
	File "Feathers SDK Manager\Adobe AIR\Versions\1.0\Adobe AIR.dll"
	SetOutPath "$INSTDIR\Adobe AIR\Versions\1.0\Resources"
	File "Feathers SDK Manager\Adobe AIR\Versions\1.0\Resources\CaptiveAppEntry.exe"
	
	;Store installation folder
	WriteRegStr HKCU "Software\FeathersSDKManager" "" $INSTDIR
	
	;Create uninstaller
	WriteUninstaller "$INSTDIR\uninstall.exe"
	
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"DisplayName" "Feathers SDK Manager"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"Publisher" "Bowler Hat LLC"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"URLInfoAbout" "https://feathersui.com/sdk/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"DisplayVersion" "${VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"HelpLink" "https://feathersui.com/help/sdk/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"DisplayIcon" "$\"$INSTDIR\Feathers SDK Manager.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"NoModify" 0x1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"NoRepair" 0x1
	
	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager" \
		"EstimatedSize" "$0"
	
	;Create Start Menu entry
	CreateShortCut "$SMPROGRAMS\Feathers SDK Manager.lnk" "$INSTDIR\Feathers SDK Manager.exe"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

	Delete "$INSTDIR\Feathers SDK Manager.exe"
	Delete "$INSTDIR\FeathersSDKManager.swf"
	Delete "$INSTDIR\mimetype"
	Delete "$INSTDIR\icon16.png"
	Delete "$INSTDIR\icon32.png"
	Delete "$INSTDIR\icon48.png"
	Delete "$INSTDIR\icon128.png"
	Delete "$INSTDIR\icon512.png"
	Delete "$INSTDIR\uninstall.exe"
	Delete "$INSTDIR\META-INF\signatures.xml"
	Delete "$INSTDIR\META-INF\AIR\application.xml"
	Delete "$INSTDIR\META-INF\AIR\hash"
	Delete "$INSTDIR\Adobe AIR\Versions\1.0\Adobe AIR.dll"
	Delete "$INSTDIR\Adobe AIR\Versions\1.0\Resources\CaptiveAppEntry.exe"
	RMDir "$INSTDIR\META-INF\AIR"
	RMDir "$INSTDIR\META-INF"
	RMDir "$INSTDIR\Adobe AIR\Versions\1.0\Resources"
	RMDir "$INSTDIR\Adobe AIR\Versions\1.0"
	RMDir "$INSTDIR\Adobe AIR\Versions\"
	RMDir "$INSTDIR\Adobe AIR\"
	RMDir "$INSTDIR"
	
	Delete "$SMPROGRAMS\Feathers SDK Manager.lnk"
	
	DeleteRegKey /ifempty HKCU "Software\FeathersSDKManager"
	
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKManager"
SectionEnd