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
	Name "Feathers SDK Installer"
	OutFile "FeathersSDKInstaller-${VERSION}.exe"

	;Default installation folder
	InstallDir "$PROGRAMFILES\Feathers SDK Installer"
	
	;Get installation folder from registry if available
	InstallDirRegKey HKCU "Software\FeathersSDKInstaller" ""

	;Request application privileges for Windows Vista and higher
	RequestExecutionLevel admin
	
Function .onInit
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"UninstallString"
	StrCmp $R0 "" done
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
		"Setup has detected that another version of Feathers SDK Installer is already installed. \
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
	!define MUI_FINISHPAGE_RUN "$INSTDIR\Feathers SDK Installer.exe"
	!define MUI_FINISHPAGE_RUN_TEXT "Run Feathers SDK Installer"
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

Section "FeathersSDKInstaller" SecFeathersSDKInstaller

	;copy all files
	SetOutPath "$INSTDIR"
	File "FeathersSDKInstaller\Feathers SDK Installer.exe"
	File "FeathersSDKInstaller\FeathersSDKInstaller.swf"
	File "FeathersSDKInstaller\mimetype"
	File "FeathersSDKInstaller\icon16.png"
	File "FeathersSDKInstaller\icon32.png"
	File "FeathersSDKInstaller\icon48.png"
	File "FeathersSDKInstaller\icon128.png"
	File "FeathersSDKInstaller\icon512.png"
	SetOutPath "$INSTDIR\META-INF"
	File "FeathersSDKInstaller\META-INF\signatures.xml"
	SetOutPath "$INSTDIR\META-INF\AIR"
	File "FeathersSDKInstaller\META-INF\AIR\application.xml"
	File "FeathersSDKInstaller\META-INF\AIR\hash"
	SetOutPath "$INSTDIR\Adobe AIR\Versions\1.0"
	File "FeathersSDKInstaller\Adobe AIR\Versions\1.0\Adobe AIR.dll"
	SetOutPath "$INSTDIR\Adobe AIR\Versions\1.0\Resources"
	File "FeathersSDKInstaller\Adobe AIR\Versions\1.0\Resources\CaptiveAppEntry.exe"
	
	;Store installation folder
	WriteRegStr HKCU "Software\FeathersSDKInstaller" "" $INSTDIR
	
	;Create uninstaller
	WriteUninstaller "$INSTDIR\uninstall.exe"
	
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"DisplayName" "Feathers SDK Installer"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"Publisher" "Bowler Hat LLC"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"URLInfoAbout" "http://feathersui.com/sdk/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"DisplayVersion" "${VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"HelpLink" "http://feathersui.com/help/sdk/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"DisplayIcon" "$\"$INSTDIR\Feathers SDK Installer.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"NoModify" 0x1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"NoRepair" 0x1
	
	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller" \
		"EstimatedSize" "$0"
	
	;Create Start Menu entry
	CreateShortCut "$SMPROGRAMS\Feathers SDK Installer.lnk" "$INSTDIR\Feathers SDK Installer.exe"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

	Delete "$INSTDIR\Feathers SDK Installer.exe"
	Delete "$INSTDIR\FeathersSDKInstaller.swf"
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
	
	Delete "$SMPROGRAMS\Feathers SDK Installer.lnk"
	
	DeleteRegKey /ifempty HKCU "Software\FeathersSDKInstaller"
	
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\com.feathersui.FeathersSDKInstaller"
SectionEnd