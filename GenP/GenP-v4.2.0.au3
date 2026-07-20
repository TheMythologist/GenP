#NoTrayIcon
#RequireAdmin
#Region
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=GenP-v4.2.0.exe
#AutoIt3Wrapper_Res_Comment=GenP
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_Description=GenP
#AutoIt3Wrapper_Res_Fileversion=4.2.0
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2026
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2026
#AutoIt3Wrapper_Res_ProductName=GenP
#AutoIt3Wrapper_Res_ProductVersion=4.2.0
#AutoIt3Wrapper_Res_Field=ID|GenP-%date%-%time%
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Run_Tidy=n
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_UseX64=y
#EndRegion

#include <Array.au3>
#include <ButtonConstants.au3>
#include <Crypt.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <GuiRichEdit.au3>
#include <GuiListView.au3>
#include <GUITab.au3>
#include <GuiTreeView.au3>
#include <Inet.au3>
#include <ListBoxConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>
#include <WinAPISysWin.au3>
#include <WinAPITheme.au3>

AutoItSetOption("GUICloseOnESC", 0)

Global $g_Version = "4.2.0"
Global $g_AppWndTitle = "GenP v" & $g_Version
Global $g_AppVersion = "GenP" & @CRLF & "Originally created by uncia"

Global $patchStatesINI = @ScriptDir & "\patch_states.ini"
Global $g_aStateQueue[0][5]
Global $g_bCryptActive = False
Global $g_mAppVersionQueue = ObjCreate("Scripting.Dictionary")
Global $g_mWinTrustQueue = ObjCreate("Scripting.Dictionary")
Global $g_mAppPrimaryExe = ObjCreate("Scripting.Dictionary")
Global $idSubProgress = -1
Global $idShowBetaApps = -1
Global $idEnableGood1 = -1
Global $idEnableNGLFirewall = -1
Global $idShowLaunchBar = -1
Global $idOlderVerDl = -1
Global $idFinalCleanCheck = -1
Global $idLabelRuntimeAuto = -1

Global $g_aAllFiles[0][6]
Global $g_hAppsBar = 0
Global $g_aAppsBarBtns[0][2]
Global $g_bAppsBarBuilt = False
Global $g_idAppsBarMinBtn    = -1
Global $g_idAppsBarConfigBtn = -1
Global $g_mCheckedState = ObjCreate("Scripting.Dictionary")
Global $g_bSearchCompleted = False
Global $g_bUpdateNoticeShown = False
Global $g_idOptionsProgress = -1
Global $g_sRequiresGood1Files = "|"

Global Const $g_iLogTabIndex = 7

Global $g_idStatusTitle = -1, $g_idStatusDetail = -1
Global $g_sCurrentSearchPath = ""

If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit
EndIf

Global $MyLVGroupIsExpanded = True
Global $g_aGroupIDs[0]
Global $fInterrupt = 0
Global $FilesToPatch[0][1], $FilesToPatchNull[0][1]
Global $FilesToRestore[0][1], $fFilesListed = 0
Global $MyhGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview, $idButtonSearch, $idButtonStop
Global $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag = 1
Global $idBtnModified = 0
Global $idBtnUpdateHosts, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAFolders, $idBtnSaveOptions, $idCustomDomainListLabel, $idCustomDomainListInput
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts, $idBtnAutoUpdateHosts

Global $g_aToolCtrls, $g_aOptCtrls, $g_aCheckCtrls, $idTriggerCaptureLaunch
Global $idBtnProxySetup, $idBtnProxyToggleRun, $idBtnProxyToggleProxy, $idBtnProxyOpenLog, $idBtnProxyRemove
Global $g_idLblProxyStatus = 0

#Au3Stripper_Ignore_Variables=$g_sMITM_DIR,$g_sMITM_EXE,$g_sMITM_SCRIPT,$g_sMITM_LOG,$g_sMITM_PORT,$g_sMITM_PROXY,$g_sMITM_CERT_NAME,$g_iMitmproxyPID,$g_sOVD_EXE
Global Const $g_sMITM_DIR = @AppDataCommonDir & "\GenP\mitmproxy"
Global Const $g_sMITM_EXE = $g_sMITM_DIR & "\mitmdump.exe"
Global Const $g_sMITM_SCRIPT = $g_sMITM_DIR & "\mitmproxy_genuine_fullguard.py"
Global Const $g_sOVD_EXE = $g_sMITM_DIR & "\main.exe"
Global Const $g_sMITM_LOG = $g_sMITM_DIR & "\mitmdump.log"
Global $g_sMITM_PORT = "8080"
Global $g_sMITM_PROXY = "127.0.0.1:8080"
Global Const $g_sMITM_CERT_NAME = "mitmproxy"
Global $g_iMitmproxyPID = 0
Global $g_sLastCertError = ""
Global $g_hMitmLogWin = 0
Global $g_hMitmRichEdit = 0
Global $g_idBtnLogClose = 0
Global $g_idBtnLogClear = 0
Global $g_idBtnLogAddToHosts = 0
Global $g_idLblLogStatus = 0
Global $g_bMitmLogWindowExists = False
Global $g_bHostsInjectInProgress = False
Global $g_iMitmAppendCounter = 0
Global Const $g_iMitmLogCharCap = 500000

#Au3Stripper_Ignore_Variables=$g_sHAU_TASK_NAME,$g_sHAU_PS1_TARGET,$g_sHAU_LOG_TARGET,$g_iHAU_METHOD_NONE,$g_iHAU_METHOD_BASIC,$g_iHAU_METHOD_ADVANCED
Global Const $g_sHAU_TASK_NAME = "UpdateHostsFile"
Global Const $g_sHAU_PS1_TARGET = @WindowsDir & "\System32\drivers\etc\UpdateHostsFile.ps1"
Global Const $g_sHAU_LOG_TARGET = @WindowsDir & "\System32\drivers\etc\UpdateHostsFile.log"
Global Const $g_iHAU_METHOD_NONE = 0
Global Const $g_iHAU_METHOD_BASIC = 1
Global Const $g_iHAU_METHOD_ADVANCED = 2

#Au3Stripper_Ignore_Variables=$g_sGUDE_DIR,$g_sGUDE_TASK_NAME,$g_sGUDE_PS1_TARGET,$g_sGUDE_LOG_TARGET
Global Const $g_sGUDE_DIR        = @AppDataCommonDir & "\GenP\gude"
Global Const $g_sGUDE_TASK_NAME  = "GenP Gude Log Cleanup"
Global Const $g_sGUDE_PS1_TARGET = $g_sGUDE_DIR & "\RemoveGudeLogs.ps1"
Global Const $g_sGUDE_LOG_TARGET = $g_sGUDE_DIR & "\RemoveGudeLogs.log"

Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF, $idBtnCreateFW, $idBtnRemoveFW, $idBtnToggleFW
Global $sRuntimeInstallerText, $idLabelRuntimeInstaller, $idBtnToggleRuntimeInstaller, $sWinTrustText, $idLabelWinTrust, $idBtnToggleWinTrust, $idBtnDevOverride
Global $idBtnAGSInfo, $idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo

#Au3Stripper_Ignore_Variables=$g_aHitPatternsThisFile
Global $g_aHitPatternsThisFile[0]
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkPopup, $g_idHyperlinkLog
Global $g_idHyperlinkFW = 0, $g_idHyperlinkHosts = 0, $g_idHyperlinkWT = 0, $g_idHyperlinkAGS = 0, $g_idHyperlinkProxy = 0

Global $idBtnCollapseAll = 0, $idBtnExpandAll = 0
Global $idBtnCheckAll = 0, $idBtnUncheckAll = 0
Global $idBtnCheckUnpatched = 0, $idBtnCheckPatched = 0, $idBtnRefresh = 0

Global $g_bBetaPatchedThisRun = False
Global $g_bLightroomCloudThisRun = False

Global $idResetOnSave = 0
Global $idClearLicCaches = 0
Global $idReconcileStates = 0
Global $idCreateStates = 0
Global $idUseCustomDefault = 0
Global $idBtnSetCustomPath = 0
Global $idOptionsReminder = 0
Global $g_mOptionsSnapshot = 0
Global $g_bOptionsDirty = False
Global $g_iOptionsPollTick = 0
Global $g_bIsPatching = False
Global $g_bUxpHandledFile = False
Global $g_bPendingInfoReset = False
Global $g_bInModifiedMode = False
Global $g_bAutoPatchPending = False
Global $g_bAutoPatchRun = False

Global $g_AppCount = 0
Global $g_FilesToPatchCount = 0
Global $g_dotCounter = 0
Global $g_mScannedApps = 0
Global $g_mBlockedParents = 0
Global $g_mBlockedAppPaths = 0
Global $g_sLastScanDir = ""
Global $g_bStatusScreenReady = False
Global $g_bIsHighDpiScalingActive = False
Global $g_bFirstFileLogGap = True
Global $idBtnDummyAGS = 0
Global $idBtnRestoreAGS = 0
Global $idBtnSetTrustPath = 0
Global $idLabelTrustPath = 0
Global $g_sWinTrustPath
Global Const $g_sWT_IFEO = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
Global Const $g_sWT_SxS = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide"
Global Const $g_sWT_WT64 = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\Wintrust\Config"
Global Const $g_sWT_WT32 = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf
Global $ConfigVerVar = IniRead($sINIPath, "Info", "ConfigVer", "????")

Global $g_aExpectedCounts[6][2] = [ _
		["TargetFiles", 80], _
		["RuntimeInstallers", 2], _
		["FirewallTrust", 36], _
		["DefaultPatterns", 1], _
		["CustomPatterns", 59], _
		["Patches", 154]]

Local $sCfgProblem = _ConfigHealthProblem()
If $sCfgProblem <> "" Then
	MsgBox(BitOR($MB_OK, $MB_ICONERROR, $MB_SYSTEMMODAL), "GenP - Config Problem", $sCfgProblem)
	If Not FileExists($sINIPath) Then Exit
Else
	Local $sCountProblem = _ConfigCountProblems()
	If $sCountProblem <> "" Then
		MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "GenP - Config Incomplete", _
				"config.ini version matches (" & $g_Version & "), but the sections do not" & @CRLF & _
				"contain the expected number of entries for this build:" & @CRLF & @CRLF & _
				$sCountProblem & @CRLF & _
				"The config may be truncated or hand-edited." & @CRLF & _
				"Patching, firewall and hosts results could be incomplete." & @CRLF & _
				"Replace config.ini with the one shipped for " & $g_Version & ".")
	EndIf
EndIf

Global $bUseCustomDefault = Number(IniRead($sINIPath, "Options", "UseCustomDefault", "0"))
Global $g_sCustomDefaultPath = StringRegExpReplace(IniRead($sINIPath, "Custom_Default", "Path", ""), "\\\\+", "\\")
Global $g_sPendingCustomPath = $g_sCustomDefaultPath

Global $bUseCustomWinTrust = Number(IniRead($sINIPath, "Options", "UseCustomWinTrust", "0"))
Global $g_sCustomWinTrustPath = StringRegExpReplace(IniRead($sINIPath, "Custom_WinTrust", "Path", ""), "\\\\+", "\\")
If $bUseCustomWinTrust = 1 And $g_sCustomWinTrustPath <> "" And FileExists($g_sCustomWinTrustPath) Then
	$g_sWinTrustPath = $g_sCustomWinTrustPath
Else
	$g_sWinTrustPath = @ProgramFilesDir & "\Adobe"
EndIf
$g_sWinTrustPath = StringRegExpReplace($g_sWinTrustPath, "\\\\+", "\\")
IniDelete($sINIPath, "Options", "WinTrustPath")

Global $MyDefPath
If $bUseCustomDefault = 1 And $g_sCustomDefaultPath <> "" And FileExists($g_sCustomDefaultPath) Then
	$MyDefPath = $g_sCustomDefaultPath
Else
	$MyDefPath = @ProgramFilesDir & "\Adobe"
EndIf
$MyDefPath = StringRegExpReplace($MyDefPath, "\\\\+", "\\")

IniWrite($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe")

If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	$MyDefPath = StringRegExpReplace(@ProgramFilesDir & "\Adobe", "\\\\+", "\\")
EndIf

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = 1
Global $bOnlyAFolders = IniRead($sINIPath, "Options", "OnlyDefaultFolders", "1")
Global $bShowBetaApps = IniRead($sINIPath, "Options", "ShowBetaApps", "1")
Global $bEnableGood1 = IniRead($sINIPath, "Options", "EnableGood1", "1")
Global $bClearLicCaches = IniRead($sINIPath, "Options", "ClearLicenseCaches", "1")
Global $bShowLaunchBar = Number(IniRead($sINIPath, "Options", "ShowLaunchBar", "0"))
Global $g_iAppsBarX = Number(IniRead($sINIPath, "Options", "LaunchBarX", "-1"))
Global $g_iAppsBarY    = Number(IniRead($sINIPath, "Options", "LaunchBarY", "-1"))
Global $g_sToolbarApps = IniRead($patchStatesINI, "Info", "ToolbarApps", "")
Global $bEnableNGLFirewall = IniRead($sINIPath, "Options", "NGLFirewall", "0")

Global $g_aNGLRelativePaths[9] = [ _
		"Common Files\Adobe\Adobe Desktop Common\NGL\adobe_licensing_wf.exe", _
		"Common Files\Adobe\Adobe Desktop Common\NGL\adobe_licensing_wf_helper.exe", _
		"Common Files\Adobe\Adobe Desktop Common\LCC\adobe_licensing_helper.exe", _
		"Adobe\Adobe Substance 3D Modeler\ngl\mangl\NGLWF_CCD\adobe_licensing_wf.exe", _
		"Adobe\Adobe Substance 3D Modeler\ngl\mangl\NGLWF_CCD\adobe_licensing_wf_helper.exe", _
		"Adobe\Adobe Substance 3D Modeler\ngl\mangl\LCC\adobe_licensing_helper.exe", _
		"Adobe\Adobe Substance 3D Modeler Beta\ngl\mangl\NGLWF_CCD\adobe_licensing_wf.exe", _
		"Adobe\Adobe Substance 3D Modeler Beta\ngl\mangl\NGLWF_CCD\adobe_licensing_wf_helper.exe", _
		"Adobe\Adobe Substance 3D Modeler Beta\ngl\mangl\LCC\adobe_licensing_helper.exe" _
		]
Global $g_sEdition = IniRead($sINIPath, "Options", "Edition", "GenP")

Global $g_sThirdPartyFirewall = ""
Global $fwc = ""
Global $SelectedApps = []

Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)
Global $g_iDisplayOrientationScale = 1
Global $g_iHyperlinkClickTime = 0
Global Const $STN_CLICKED = 0

Local $tTargetFileList = IniReadSection($sINIPath, "TargetFiles")
Global $TargetFileList[0]
If Not @error Then
	ReDim $TargetFileList[$tTargetFileList[0][0]]
	For $i = 1 To $tTargetFileList[0][0]
		$TargetFileList[$i - 1] = StringReplace($tTargetFileList[$i][1], '"', "")
	Next
EndIf

$aSpecialFiles = IniReadSection($sINIPath, "CustomPatterns")
For $i = 1 To UBound($aSpecialFiles) - 1
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
	Local $sPatternList = StringLower(StringReplace(StringReplace($aSpecialFiles[$i][1], '"', ''), ' ', ''))
	If StringInStr($sPatternList, "good1") > 0 Then
		$g_sRequiresGood1Files = $g_sRequiresGood1Files & StringLower($aSpecialFiles[$i][0]) & "|"
	EndIf
Next
Global $g_aSignature = "r~~z}D99""sus8nl%o|:8myw9qoxz7q sno}9"

If $CmdLine[0] = 1 And $CmdLine[1] = "-updatehosts" Then
	UpdateHostsFile()
	Exit
EndIf

_InitializeFontLayoutEngine()

Func _ConfigSectionCount($sSection)
	Local $aSec = IniReadSection($sINIPath, $sSection)
	If @error Then Return 0
	Return $aSec[0][0]
EndFunc

Func _DefaultPatternsCount()
	Local $sVals = StringReplace(IniRead($sINIPath, "DefaultPatterns", "Values", ""), '"', "")
	$sVals = StringStripWS($sVals, 3)
	If $sVals = "" Then Return 0
	Local $a = StringSplit($sVals, ",")
	Return $a[0]
EndFunc

Func _ConfigHealthProblem()
	If Not FileExists($sINIPath) Then
		Return "The required config.ini file is missing from the tool folder." & @CRLF & _
				"GenP must be run from its original self-contained folder (config.ini alongside the exe)."
	EndIf
	Local $sCfgVer = StringStripWS(StringReplace(IniRead($sINIPath, "Info", "ConfigVer", ""), '"', ""), 3)
	If $sCfgVer = "" Then
		Return "config.ini is present but its [Info] ConfigVer entry is missing or unreadable." & @CRLF & _
				"The file may be corrupted or from an incompatible build."
	EndIf
	If $sCfgVer <> $g_Version Then
		Return "Tool version and config.ini version mismatch." & @CRLF & _
				"Tool (exe): " & $g_Version & "    config.ini: " & $sCfgVer & @CRLF & _
				"Use the config.ini that shipped with this exact build."
	EndIf
	Return ""
EndFunc

Func _ConfigCountProblems()
	Local $sMsg = ""
	For $i = 0 To UBound($g_aExpectedCounts) - 1
		Local $sSec = $g_aExpectedCounts[$i][0]
		Local $iExpected = Number($g_aExpectedCounts[$i][1])
		Local $iActual
		If $sSec = "DefaultPatterns" Then
			$iActual = _DefaultPatternsCount()
		Else
			$iActual = _ConfigSectionCount($sSec)
		EndIf
		If $iActual <> $iExpected Then
			$sMsg &= "  [" & $sSec & "]  expected " & $iExpected & ", found " & $iActual & @CRLF
		EndIf
	Next
	Return $sMsg
EndFunc

Func _CheckPatchStatesVersion()
	If Not FileExists($patchStatesINI) Then
		Return
	EndIf

	Local $sPriorVersion = IniRead($patchStatesINI, "Info", "GenPVersion", "")

	If $sPriorVersion = "" Then
		$sPriorVersion = "Unknown (pre-4.0.2)"
	EndIf

	Local $iCurrent = _VersionToNumber($g_Version)
	Local $iPrior = _VersionToNumber($sPriorVersion)

	If $iPrior < $iCurrent Then
		Local $iResult = MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING, $MB_SYSTEMMODAL), _
				"Version Upgrade Required", _
				"Your patch_states.ini is incompatible" & @CRLF & _
				"Current GenP " & $g_Version & " / Config " & $ConfigVerVar & @CRLF & _
				"For proper operation, you MUST:" & @CRLF & _
				"1. Delete patch_states.ini" & @CRLF & _
				"2. Rerun GenP to create a fresh baseline" & @CRLF & @CRLF & _
				"Continuing without this step may cause black screens." & @CRLF & @CRLF & _
				"Delete patch_states.ini now and exit? (Recommended)")

		If $iResult = $IDYES Then
			If FileDelete($patchStatesINI) Then
				IniWrite($sINIPath, "Options", "CreatedNew",        "0")
				IniWrite($sINIPath, "Options", "CreatedNewDate",    "")
				IniWrite($sINIPath, "Options", "ReconcileUsed",     "0")
				IniWrite($sINIPath, "Options", "ReconcileUsedDate", "")
				MsgBox($MB_OK, "Cleanup Complete", _
						"patch_states.ini has been deleted." & @CRLF & @CRLF & _
						"Close and run it again to create fresh baseline.")
				Exit
			Else
				MsgBox($MB_ICONERROR, "Error", "Could not delete patch_states.ini. Check file permissions.")
			EndIf
		Else
			MsgBox($MB_ICONWARNING, "Proceeding at Own Risk", _
					"If you experience issues, delete patch_states.ini and rerun.")
		EndIf
	EndIf
EndFunc

Func _VersionToNumber($sVersion)
	Local $aParts = StringSplit($sVersion, ".")
	If @error Or UBound($aParts) < 3 Then Return 0

	Local $iMajor = Number($aParts[1])
	Local $iMinor = Number($aParts[2])
	Local $iPatch = Number($aParts[3])

	Return ($iMajor * 1000000) + ($iMinor * 1000) + $iPatch
EndFunc

_CheckPatchStatesVersion()

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

MainGui()

Local $bHostsbakExists = False
If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
	$bHostsbakExists = True
EndIf

If _IsMitmproxyInstalled() Then
	GUICtrlSetState($idBtnProxyToggleRun, $GUI_ENABLE)
	GUICtrlSetState($idBtnProxyToggleProxy, $GUI_ENABLE)
	GUICtrlSetState($idBtnProxyOpenLog, $GUI_ENABLE)
	GUICtrlSetState($idBtnProxyRemove, $GUI_ENABLE)
EndIf

If StringInStr(FileRead(@WindowsDir & "\System32\drivers\etc\hosts"), "# START - Adobe Blocklist") Then
	GUICtrlSetState($idBtnCleanHosts, $GUI_ENABLE)
EndIf

_ShowUpdateNoticeIfNeeded()

If $bShowLaunchBar Then _RefreshAppsToolbar()

While 1

	If $g_iDisplayOrientationScale <> 1 And WinGetTitle($MyhGUI) <> $g_AppWndTitle Then
		WinSetTitle($MyhGUI, "", $g_AppWndTitle)
	EndIf

	Local $bHostsbakExistsNow
	If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
		$bHostsbakExistsNow = True
	Else
		$bHostsbakExistsNow = False
	EndIf

	If $bHostsbakExistsNow <> $bHostsbakExists Then
		If $bHostsbakExistsNow Then
			GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
		Else
			GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
		EndIf
		$bHostsbakExists = $bHostsbakExistsNow
	EndIf

	$g_iOptionsPollTick += 1
	If $g_iOptionsPollTick >= 50 And Not $g_bIsPatching Then
		$g_iOptionsPollTick = 0
		CheckOptionsChanged()
	EndIf

	$idMsg = GUIGetMsg()
	If _AppsBar_Dispatch($idMsg) Then ContinueLoop

	If $g_bAutoPatchPending Then
		$g_bAutoPatchPending = False
		$g_bAutoPatchRun = True
		$idMsg = $idBtnCure
	EndIf

	Select
		Case $idMsg = $GUI_EVENT_CLOSE
			GUIDelete($MyhGUI)
			_Exit()
		Case $idMsg = $GUI_EVENT_RESIZED
			ContinueCase
		Case $idMsg = $GUI_EVENT_RESTORE
			ContinueCase
		Case $idMsg = $GUI_EVENT_MAXIMIZE
			Local $iWidth
			Local $aGui = WinGetPos($MyhGUI)
			Local $aRect = _GUICtrlListView_GetViewRect($g_idListview)
			If ($aRect[2] > $aGui[2]) Then
				$iWidth = $aGui[2] - 75
			Else
				$iWidth = $aRect[2] - 25
			EndIf
			GUICtrlSendMsg($idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)

		Case $idMsg = $idButtonStop
			$ListViewSelectFlag = 0
			$fInterrupt = 1
			_ShowStatusScreen("stopped", $g_sLastScanDir)
			Sleep(1500)
			ReDim $g_aAllFiles[0][6]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()
			_ResetScanCounters()
			FillListViewWithInfo()
			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_ENABLE)
			_SetState($g_aOptCtrls, $GUI_ENABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
			GUICtrlSetState($idListview, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idBtnModified, $GUI_DISABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_DISABLE)
			_SetState($g_aCheckCtrls, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_DISABLE)
			_SetState($g_aOptCtrls, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			_ResetScanCounters()
			$g_bFirstFileLogGap = True
			_ShowStatusScreen("scanning", $MyDefPath)

			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull
			ReDim $g_aAllFiles[0][6]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $aACCDirs[2]
				$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				$aACCDirs[1] = EnvGet('ProgramFiles') & "\Common Files\Adobe"
				For $sAppsPanelDir In $aACCDirs
					If Not FileExists($sAppsPanelDir) Then ContinueLoop
					Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)
					If UBound($aSize) >= 2 Then
						$FileCount = $aSize[1]
						RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)
						ProgressWrite(0)
					EndIf
				Next
			EndIf

			$aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)
				Sleep(100)
				ProgressWrite(0)
			EndIf

			If $fInterrupt = 0 Then
				_ShowStatusScreen("complete", $MyDefPath)
				_SubProgressWrite(0)
				Sleep(3000)
			EndIf

			FillListViewWithFiles()

			_VerifyListedFiles(True)

			UpdateUIState()

			If _GUICtrlListView_GetItemCount($idListview) > 0 Then

				$ListViewSelectFlag = 1
				GUICtrlSetState($idButtonSearch, $GUI_DISABLE)
				GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
				GUICtrlSetState($idBtnCure, $GUI_ENABLE)

				If UBound($FilesToRestore) > 0 Then
					GUICtrlSetState($idBtnRestore, $GUI_ENABLE)
				EndIf
			Else
				$ListViewSelectFlag = 0
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, $GUI_DISABLE)
				GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
				GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
			EndIf

			_Expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, $GUI_ENABLE)
			GUICtrlSetState($idListview, $GUI_ENABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			_SetState($g_aToolCtrls, $GUI_ENABLE)
			_SetState($g_aOptCtrls, $GUI_ENABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)
			$g_bIsPatching = False

		Case $idMsg = $idButtonCustomFolder
			ToggleLog(0)
			MyFileOpenDialog()
			_Expand_All_Click()
			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, $GUI_DISABLE)
				GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
				GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
			Else
				GUICtrlSetState($idButtonSearch, $GUI_DISABLE)
				GUICtrlSetState($idBtnDeselectAll, $GUI_ENABLE)
				GUICtrlSetState($idBtnCure, $GUI_ENABLE)
			EndIf

		Case $idMsg = $idBtnCheckAll
			ToggleLog(0)
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				_GUICtrlListView_SetItemChecked($idListview, $i, 1)
			Next
			$ListViewSelectFlag = 1

		Case $idMsg = $idBtnUncheckAll
			ToggleLog(0)
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				_GUICtrlListView_SetItemChecked($idListview, $i, 0)
			Next
			$ListViewSelectFlag = 0

		Case $idMsg = $idBtnCheckUnpatched
			ToggleLog(0)
			Local $iCt = _GUICtrlListView_GetItemCount($idListview)
			Local $iChecked = 0
			For $i = 0 To $iCt - 1
				Local $sStatus = _GUICtrlListView_GetItemText($idListview, $i, 2)
				If $sStatus <> "Patched" Then
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
					$iChecked += 1
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				EndIf
			Next
			MemoWrite(@CRLF & "Checked " & $iChecked & " non-patched file(s) of " & $iCt & " listed.")
			$ListViewSelectFlag = ($iChecked > 0) ? 1 : 0

		Case $idMsg = $idBtnCheckPatched
			Local $iCt = _GUICtrlListView_GetItemCount($idListview)
			Local $iChecked = 0
			For $i = 0 To $iCt - 1
				Local $sStatus = _GUICtrlListView_GetItemText($idListview, $i, 2)
				If $sStatus = "Patched" Then
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
					$iChecked += 1
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				EndIf
			Next
			MemoWrite(@CRLF & "Checked " & $iChecked & " patched file(s) of " & $iCt & " listed.")
			$ListViewSelectFlag = ($iChecked > 0) ? 1 : 0

		Case $idMsg = $idBtnRefresh
			ToggleLog(0)
			$fInterrupt = 0
			_RefreshSearch()

		Case $idMsg = $idBtnCure
			Local $sCureTgtWhy = _TargetFolderReady($MyDefPath)
			If $sCureTgtWhy <> "" Then
				MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Cannot Patch - Target Folder", $sCureTgtWhy)
				LogWrite(1, "Patch aborted - target folder not ready: " & $MyDefPath)
				ContinueLoop
			EndIf
			Local $sCureCfgWhy = _ConfigHealthProblem()
			If $sCureCfgWhy <> "" Then
				Local $iCureGo = MsgBox(BitOR($MB_YESNO, $MB_DEFBUTTON2, $MB_ICONWARNING, $MB_SYSTEMMODAL), _
						"GenP - Patch With Unverified Config?", _
						$sCureCfgWhy & @CRLF & @CRLF & _
						"Patching now may apply an incomplete or wrong pattern set, which can" & @CRLF & _
						"leave Adobe apps unbootable (black screens). Continue patching anyway?")
				If $iCureGo <> $IDYES Then
					MemoWrite(@CRLF & "Patch cancelled: config.ini failed verification." & @CRLF)
					LogWrite(1, "Patch aborted by config gate: " & StringReplace($sCureCfgWhy, @CRLF, " "))
					ContinueLoop
				EndIf
				LogWrite(1, "Patch proceeding despite config gate (user confirmed).")
			EndIf
			If _PromptStopAdobeProcessesForOp("patched") = 0 Then
				LogWrite(1, "Patch aborted by user at Adobe-process prompt.")
				ContinueLoop
			EndIf
			Local $bPSE2026 = False, $bPRE2026 = False, $bORG2026 = False
			Local $aOrgItems[0], $aPseItems[0], $aPreItems[0]
			Local $iCountAll = _GUICtrlListView_GetItemCount($idListview)
			For $i = 0 To $iCountAll - 1
				If Not _GUICtrlListView_GetItemChecked($idListview, $i) Then ContinueLoop
				Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
				Local $sGrp = _GetAppGroupName($sPath)
				If $sGrp = "Elements 2026 Organizer" Then
					$bORG2026 = True
					_ArrayAdd($aOrgItems, $i)
				ElseIf $sGrp = "Photoshop Elements 2026" Then
					$bPSE2026 = True
					_ArrayAdd($aPseItems, $i)
				ElseIf $sGrp = "Premiere Elements 2026" Then
					$bPRE2026 = True
					_ArrayAdd($aPreItems, $i)
				EndIf
			Next
			If $g_bAutoPatchRun Then
				LogWrite(1, "Auto-patch (create-states): Elements 2026 'patch together' prompt skipped." & @CRLF & "All installed items already queued and ready to patch.")
			ElseIf ($bPSE2026 Or $bPRE2026 Or $bORG2026) And Not ($bPSE2026 And $bPRE2026 And $bORG2026) Then
				Local $bHasPSE = False, $bHasPRE = False, $bHasORG = False
				For $i = 0 To $iCountAll - 1
					Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
					Local $sGrp = _GetAppGroupName($sPath)
					If $sGrp = "Photoshop Elements 2026" Then $bHasPSE = True
					If $sGrp = "Premiere Elements 2026" Then $bHasPRE = True
					If $sGrp = "Elements 2026 Organizer" Then $bHasORG = True
				Next
				Local $sMissing = ""
				If $bHasPSE And Not $bPSE2026 Then $sMissing &= "  - Photoshop Elements 2026" & @CRLF
				If $bHasPRE And Not $bPRE2026 Then $sMissing &= "  - Premiere Elements 2026" & @CRLF
				If $bHasORG And Not $bORG2026 Then $sMissing &= "  - Elements 2026 Organizer" & @CRLF
				Local $iAns = MsgBox($MB_YESNOCANCEL, _
						"Elements 2026 - patch together?", _
						"Photoshop Elements, Premiere Elements and the Organizer" & @CRLF & _
						"share components and should be patched as a single unit." & @CRLF & @CRLF & _
						"These items are unchecked:" & @CRLF & $sMissing & @CRLF & _
						"Yes = auto-check them and continue" & @CRLF & _
						"No  = continue anyway (not recommended)" & @CRLF & _
						"Cancel = abort patch")
				If $iAns = $IDCANCEL Then
					$g_bIsPatching = False
					ContinueLoop
				ElseIf $iAns = $IDYES Then
					For $i = 0 To $iCountAll - 1
						Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
						Local $sGrp = _GetAppGroupName($sPath)
						If ($sGrp = "Photoshop Elements 2026" And $bHasPSE) Or _
								($sGrp = "Premiere Elements 2026" And $bHasPRE) Or _
								($sGrp = "Elements 2026 Organizer" And $bHasORG) Then
							_GUICtrlListView_SetItemChecked($idListview, $i, 1)
						EndIf
					Next
					MemoWrite(@CRLF & "Auto-checked missing Elements 2026 items for consistent patch.")
				EndIf
			EndIf

			Local $bAppsSelected = False
			For $i = 0 To $iCountAll - 1
				If _GUICtrlListView_GetItemChecked($idListview, $i) Then
					$bAppsSelected = True
					ExitLoop
				EndIf
			Next

			If $bAppsSelected And $bEnableNGLFirewall = 1 Then
				If _EnableNGLFirewallRules(False) = -99 Then
					MemoWrite(@CRLF & "Patch cancelled - add your third-party firewall rules, then patch again.")
					ContinueLoop
				EndIf
			EndIf

			$g_bAutoPatchRun = False

			ToggleLog(0)
			$g_bIsPatching = True
			$g_bBetaPatchedThisRun = False
			$g_bLightroomCloudThisRun = False
			_SetState($g_aOptCtrls, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			_SetState($g_aCheckCtrls, $GUI_DISABLE)
			GUICtrlSetState($idListview, $GUI_DISABLE)
			GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
			GUICtrlSetState($idButtonSearch, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_DISABLE)
			_SetState($g_aOptCtrls, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			_Expand_All_Click()

			Local $ItemFromList
			Local $iTotalChecked = 0, $iDone = 0
			Local $iFirstChecked = -1
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then
					$iTotalChecked += 1
					If $iFirstChecked = -1 Then $iFirstChecked = $i
				EndIf
			Next

			If $iFirstChecked >= 0 Then
				_GUICtrlListView_EnsureVisible($idListview, $iFirstChecked, 0)
			EndIf

			ProgressWrite(0)
			_SubProgressWrite(0)
			If $bEnableMD5 = 1 Then
				_Crypt_Startup()
				$g_bCryptActive = True
			EndIf

			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)
					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

					_GUICtrlListView_SetItemText($idListview, $i, "Patching...", 2)

					_GUICtrlListView_EnsureVisible($idListview, $i, 0)

					If _PathIsBeta($ItemFromList) Then
						$g_bBetaPatchedThisRun = True
						LogWrite(1, "Beta/Prerelease app detected. This may break with any update, no support provided.")
					EndIf

					If _PathIsLightroomCloud($ItemFromList) Then
						$g_bLightroomCloudThisRun = True
						LogWrite(1, "Lightroom (cloud) detected. Patched installs are unreliable - use Lightroom Classic for full compatibility.")
					EndIf

					If FileGetSize($ItemFromList) > 200 * 1024 * 1024 Then
						_PatchLargeFileWithPatterns($ItemFromList)
					Else
						MyGlobalPatternSearch($ItemFromList)
						If Not $g_bUxpHandledFile Then
							MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "medication :)")
							LogWrite(1, $ItemFromList)
						EndIf

						MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)
					EndIf

					If FileExists($ItemFromList & ".bak") Then
						_GUICtrlListView_SetItemText($idListview, $i, "Patched", 2)
					Else
						_GUICtrlListView_SetItemText($idListview, $i, "Unchanged", 2)
					EndIf

					$iDone += 1
					If $iTotalChecked > 0 Then ProgressWrite(Round($iDone / $iTotalChecked * 100))

					Sleep(50)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			If $g_bCryptActive Then
				_Crypt_Shutdown()
				$g_bCryptActive = False
			EndIf

			_FlushStateQueue()
			_RefreshAppsToolbar()

			If $idClearLicCaches <> 0 And _IsChecked($idClearLicCaches) Then _ClearLicenseCachesLight()

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False
			_SetState($g_aOptCtrls, $GUI_ENABLE)
			CheckOptionsChanged()

			If $g_bInModifiedMode Then
				_VerifyListedFiles(True)

				Local $iStillTodo = 0
				Local $iRow = _GUICtrlListView_GetItemCount($g_idListview) - 1
				_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)
				While $iRow >= 0
					Local $sStatusMod = _GUICtrlListView_GetItemText($g_idListview, $iRow, 2)
					If $sStatusMod = "Patched" Then
						_GUICtrlListView_DeleteItem($g_idListview, $iRow)
					Else
						$iStillTodo += 1
					EndIf
					$iRow -= 1
				WEnd
				_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
				_RedrawWindow($g_idListview)

				If $iStillTodo = 0 Then
					MemoWrite(@CRLF & "Modified work queue is now empty.")
					LogWrite(1, "Modified work queue drained - all files patched.")

					If $bEnableNGLFirewall = 1 Then
						MemoWrite(@CRLF & "Notice: NGL Firewall isolation rule is active; network channels are locked down.")
						MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Network Isolation Active", _
								"The NGL Firewall rule is successfully monitoring active modules." & @CRLF & @CRLF & _
								"A full system restart is not strictly mandatory for the firewall rules, " & @CRLF & _
								"but closing and reopening your applications is recommended to apply states.")
					EndIf
					_ShowEmptyModifiedNotice()
					$g_bIsPatching = False
					$g_bPendingInfoReset = False
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					MemoWrite(@CRLF & "Patching complete." & @CRLF & "You can carry on.")
				Else
					MemoWrite(@CRLF & "Unpatched: " & $iStillTodo & " file(s) still need patching (click Patch again).")
					LogWrite(1, "Unpatched: " & $iStillTodo & " file(s) remain after patch run.")
					$g_bIsPatching = False
					$g_bPendingInfoReset = True
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					GUICtrlSetState($hLogTab, $GUI_SHOW)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					MemoWrite(@CRLF & "Patching complete." & @CRLF & "You can carry on.")

					_FinalisePatchRun()
					ContinueLoop
				EndIf
			EndIf

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, $GUI_ENABLE)
			GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_ENABLE)
			_SetState($g_aOptCtrls, $GUI_ENABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the x32 bit version of Acrobat." & @CRLF & @CRLF & "Please use the x64 bit version of Acrobat.")
				LogWrite(1, "GenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
			EndIf
			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "This GenP build does not support ARM binaries, only x64.")
				LogWrite(1, "This GenP build does not support ARM binaries, only x64.")
			EndIf

			ToggleLog(1)
			GUICtrlSetState($hLogTab, $GUI_SHOW)
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
			MemoWrite(@CRLF & "Patching complete." & @CRLF & "You can carry on.")

			_FinalisePatchRun()

		Case $idMsg = $idBtnModified
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
			GUICtrlSetState($idListview, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idBtnModified, $GUI_DISABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_DISABLE)
			_SetState($g_aCheckCtrls, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_DISABLE)
			_SetState($g_aOptCtrls, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

			MemoWrite(@CRLF & "Modified workflow: scanning + verifying...")
			_RefreshSearch()

			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idListview, $GUI_ENABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
			_SetState($g_aToolCtrls, $GUI_ENABLE)
			_SetState($g_aOptCtrls, $GUI_ENABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)

			Local $iKept = _ApplyModifiedFilter()

			If $iKept = 0 Then
				$g_bIsPatching = False
				_ShowEmptyModifiedNotice()
			Else
				UpdateUIState()
			EndIf

		Case $idMsg = $idBtnRestore
			Local $sRestTgtWhy = _TargetFolderReady($MyDefPath)
			If $sRestTgtWhy <> "" Then
				MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Cannot Restore - Target Folder", $sRestTgtWhy)
				LogWrite(1, "Restore aborted - target folder not ready: " & $MyDefPath)
				ContinueLoop
			EndIf

			If _PromptStopAdobeProcessesForOp("restored") = 0 Then
				LogWrite(1, "Restore aborted by user at Adobe-process prompt.")
				ContinueLoop
			EndIf

			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & "" & @CRLF & "Config Version: " & $ConfigVerVar & "" & @CRLF)
			ToggleLog(0)
			$g_bIsPatching = True

			_SetState($g_aOptCtrls, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			_SetState($g_aCheckCtrls, $GUI_DISABLE)
			GUICtrlSetState($idListview, $GUI_DISABLE)
			GUICtrlSetState($idBtnDeselectAll, $GUI_DISABLE)
			GUICtrlSetState($idButtonSearch, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_DISABLE)
			_SetState($g_aToolCtrls, $GUI_DISABLE)
			_Expand_All_Click()

			Local $ItemFromList
			Local $iTotalChecked = 0, $iDone = 0
			Local $aRestoredPaths[0]
			Local $aUnrestoredInUse[0]
			Local $iFirstChecked = -1
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then
					$iTotalChecked += 1
					If $iFirstChecked = -1 Then $iFirstChecked = $i
				EndIf
			Next

			If $iFirstChecked >= 0 Then
				_GUICtrlListView_EnsureVisible($idListview, $iFirstChecked, 0)
			EndIf

			ProgressWrite(0)
			_SubProgressWrite(0)
			If $bEnableMD5 = 1 Then
				_Crypt_Startup()
				$g_bCryptActive = True
			EndIf

			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)

					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
					_ArrayAdd($aRestoredPaths, $ItemFromList)

					_GUICtrlListView_SetItemText($idListview, $i, "Restoring...", 2)
					_SubProgressWrite(50)

					_GUICtrlListView_EnsureVisible($idListview, $i, 0)

					Local $bOk = RestoreFile($ItemFromList)

					If $bOk = 1 Then
						_GUICtrlListView_SetItemText($idListview, $i, "Unpatched", 2)
					ElseIf $bOk = -1 Then
						_GUICtrlListView_SetItemText($idListview, $i, "In use", 2)
						_ArrayAdd($aUnrestoredInUse, $ItemFromList)
					Else
						_GUICtrlListView_SetItemText($idListview, $i, "No backup", 2)
					EndIf

					_SubProgressWrite(100)
					$iDone += 1
					If $iTotalChecked > 0 Then ProgressWrite(Round($iDone / $iTotalChecked * 100))

					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "restoring :)")
					Sleep(50)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			If $g_bCryptActive Then
				_Crypt_Shutdown()
				$g_bCryptActive = False
			EndIf

			_CleanOrphanBaks($aRestoredPaths)

			_FlushStateQueue()
			_RefreshAppsToolbar()

			If UBound($aUnrestoredInUse) > 0 Then
				Local $sUnrestMsg = UBound($aUnrestoredInUse) & " file(s) could not be restored because they were still in use:" & @CRLF & @CRLF
				For $iU = 0 To UBound($aUnrestoredInUse) - 1
					$sUnrestMsg &= "  - " & $aUnrestoredInUse[$iU] & @CRLF
				Next
				$sUnrestMsg &= @CRLF & "Their backups (.bak) have been preserved. Close any open" & @CRLF & "Adobe apps and run Restore again to finish."
				LogWrite(1, "Restore finished with " & UBound($aUnrestoredInUse) & " file(s) left unrestored (in use).")
				MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION, $MB_SYSTEMMODAL), "Some Files Not Restored", $sUnrestMsg)
			EndIf

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False

			_SetState($g_aOptCtrls, $GUI_ENABLE)
			CheckOptionsChanged()

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")

			GUICtrlSetState($idListview, $GUI_ENABLE)
			GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
			GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
			GUICtrlSetState($idBtnCure, $GUI_DISABLE)
			GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
			_SetState($g_aToolCtrls, $GUI_ENABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)
			FillListViewWithInfo()

			ToggleLog(1)
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idOnlyAFolders
			If _IsChecked($idOnlyAFolders) Then
				$bOnlyAFolders = 1
			Else
				$bOnlyAFolders = 0
			EndIf
			If Not $g_bSearchCompleted Then FillListViewWithInfo()
			CheckOptionsChanged()

		Case $idMsg = $idShowBetaApps
			If _IsChecked($idShowBetaApps) Then
				$bShowBetaApps = 1
			Else
				$bShowBetaApps = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idEnableGood1
			If _IsChecked($idEnableGood1) Then
				$bEnableGood1 = 1
			Else
				$bEnableGood1 = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idResetOnSave
			CheckOptionsChanged()

		Case $idMsg = $idFinalCleanCheck
			CheckOptionsChanged()

		Case $idMsg = $idEnableNGLFirewall
			If _IsChecked($idEnableNGLFirewall) Then
				$bEnableNGLFirewall = 1
			Else
				$bEnableNGLFirewall = 0
			EndIf
			CheckOptionsChanged()

		Case $idMsg = $idClearLicCaches
			If Not _IsChecked($idClearLicCaches) Then
				Local $iKeepLic = MsgBox(BitOR($MB_YESNO, $MB_ICONQUESTION, $MB_DEFBUTTON1, $MB_SYSTEMMODAL), _
						"Clear License Caches  -  Recommended", _
						"Clearing licence caches after patching is recommended and is on by default." & @CRLF & @CRLF & _
						"Leaving it on clears stale licence state so apps don't show licence errors" & @CRLF & _
						"straight after patching." & @CRLF & @CRLF & _
						"Keep it enabled?" & @CRLF & @CRLF & _
						"Yes = keep it on (recommended)." & @CRLF & _
						"No = turn it off.")
				If $iKeepLic <> $IDNO Then GUICtrlSetState($idClearLicCaches, $GUI_CHECKED)
			EndIf
			CheckOptionsChanged()

		Case $idMsg = $idShowLaunchBar
			CheckOptionsChanged()

		Case $idMsg = $idOlderVerDl
			CheckOptionsChanged()

		Case $idMsg = $idReconcileStates
			If _IsChecked($idReconcileStates) Then GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idCreateStates
			If _IsChecked($idCreateStates) Then GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idUseCustomDefault
			If _IsChecked($idUseCustomDefault) Then
				Local $sPickedPath = _BrowseForFolderDialog("Select the folder to open to on launch", $MyhGUI)
				If $sPickedPath <> "" Then
					GUICtrlSetData($idBtnSetCustomPath, StringRegExpReplace($sPickedPath, "\\\\+", "\\\\"))
				EndIf
			EndIf
			CheckOptionsChanged()

		Case $idMsg = $idTriggerCaptureLaunch
			CheckOptionsChanged()

		Case $idMsg = $idBtnSaveOptions
			Local $bShouldTrigger    = _IsChecked($idTriggerCaptureLaunch)
			Local $bLaunchOlderVerDl = _IsChecked($idOlderVerDl)
			SaveOptionsToConfig()

			If $bLaunchOlderVerDl Then
				GUICtrlSetState($idOlderVerDl, $GUI_UNCHECKED)
				_SnapshotOptions()
				If Not FileExists($g_sMITM_DIR) Then DirCreate($g_sMITM_DIR)
				FileInstall("resources\mitmproxy\main.exe", $g_sOVD_EXE, 1)
				If Not FileExists($g_sOVD_EXE) Then
					MemoWrite(@CRLF & "Error: could not extract Older Versions Downloader (main.exe).")
				Else
					MemoWrite(@CRLF & "Launching Older Versions Downloader   tool by MP7909.")
					Local $iPID = Run('cmd.exe /k "title Adobe Older Versions Downloader & color 0F & mode con cols=100 & .\main.exe"', $g_sMITM_DIR, @SW_SHOW)
					If $iPID = 0 Then
						MemoWrite("Error: could not open console for main.exe (code " & @error & ").")
					Else
						Local $sIconPath = @ScriptDir & "\Skull.ico"
						If FileExists($sIconPath) Then
							Local $hCon = WinWait("Adobe Older Versions Downloader", "", 2)
							If $hCon Then
								Local $aIcon = DllCall("user32.dll", "handle", "LoadImageW", _
										"handle", 0, "wstr", $sIconPath, "uint", 1, "int", 0, "int", 0, "uint", 0x10)
								If Not @error And IsArray($aIcon) And $aIcon[0] Then
									DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hCon, "uint", 0x80, "wparam", 1, "lparam", $aIcon[0])
									DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hCon, "uint", 0x80, "wparam", 0, "lparam", $aIcon[0])
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf

			If $bShouldTrigger Then
				_TriggerOneOffCaptureAndLaunch()
				GUICtrlSetState($idTriggerCaptureLaunch, $GUI_UNCHECKED)
				_SnapshotOptions()
			EndIf

			If Number($bEnableGood1) Then
				If Not _IsGudeCleanupInstalled() And IniRead($sINIPath, "Options", "GudeDismissed", "0") <> "1" Then
					_ShowGudeSetupPrompt()
				EndIf
			Else
				If _IsGudeCleanupInstalled() And IniRead($sINIPath, "Options", "GudeDismissedRemove", "0") <> "1" Then
					_ShowGudeRemovePrompt()
				EndIf
			EndIf

		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

		Case $idMsg = $idBtnDummyAGS
			InstallAGSDummy()

			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION, $MB_SYSTEMMODAL), _
					"Restart Required", _
					"Dummy AGS components have been installed." & @CRLF & @CRLF & _
					"A device restart is required so the changes take effect." & @CRLF & _
					"GenP will now restart your device. Please save any open work" & @CRLF & _
					"in other applications before continuing.")

			LogWrite(1, "Dummy AGS install - restart enforced.")
			Shutdown(BitOR(2, 16))
			Exit

		Case $idMsg = $idBtnRestoreAGS
			RestoreAGSDummy()

		Case $idMsg = $idBtnSetTrustPath
			Local $sSelected = _BrowseForFolderDialog("Select the Adobe installation folder for WinTrust", $MyhGUI)
			If $sSelected = "" Then ContinueLoop
			$g_sWinTrustPath = $sSelected
			$g_sCustomWinTrustPath = $sSelected
			$bUseCustomWinTrust = 1
			GUICtrlSetData($idLabelTrustPath, "Path: " & $g_sWinTrustPath)
			IniWrite($sINIPath, "Custom_WinTrust", "Path", $g_sWinTrustPath)
			IniWrite($sINIPath, "Options", "UseCustomWinTrust", "1")
			IniDelete($sINIPath, "Options", "WinTrustPath")
			MemoWrite(@CRLF & "WinTrust path set to: " & $g_sWinTrustPath)
			LogWrite(1, "WinTrust path changed to: " & $g_sWinTrustPath)
			_TidyConfigSpacing($sINIPath)

		Case $idMsg = $idBtnUpdateHosts
			ToggleLog(0)
			UpdateHostsFile()
			GUICtrlSetState($idBtnCleanHosts, $GUI_ENABLE)

		Case $idMsg = $idBtnCleanHosts
			RemoveHostsEntries()

		Case $idMsg = $idBtnEditHosts
			EditHosts()
			GUICtrlSetState($idBtnCleanHosts, $GUI_ENABLE)

		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		Case $idMsg = $idBtnAutoUpdateHosts
			_ShowHostsAutoUpdateDialog()

		Case $idMsg = $idBtnProxySetup
			Local $bOk = _SetupMitmproxy()
			If $bOk Then
				GUICtrlSetState($idBtnProxyToggleRun, $GUI_ENABLE)
				GUICtrlSetState($idBtnProxyToggleProxy, $GUI_ENABLE)
				GUICtrlSetState($idBtnProxyOpenLog, $GUI_ENABLE)
				GUICtrlSetState($idBtnProxyRemove, $GUI_ENABLE)
				MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Setup complete", _
						"mitmproxy installed and certificate trusted." & @CRLF & @CRLF & _
						"Next steps:" & @CRLF & _
						"  - Toggle Run to start mitmdump" & @CRLF & _
						"  - Toggle Proxy to route Windows traffic through it")
			Else
				Local $sErrMsg = "Setup failed."
				Switch @error
					Case 1
						$sErrMsg = "GenP must be running as Administrator."
					Case 2
						$sErrMsg = "Could not deploy mitmdump.exe." & @CRLF & _
								"Verify resources\mitmproxy\mitmdump.exe is in the build tree."
					Case 3
						$sErrMsg = "Could not deploy the rewrite script." & @CRLF & _
								"Verify resources\mitmproxy\mitmproxy_genuine_fullguard.py is in the build tree."
					Case 4
						$sErrMsg = "mitmdump didn't generate a certificate in 8 seconds." & @CRLF & _
								"This usually means the standalone binary couldn't unpack to %TEMP%." & @CRLF & _
								"Try running mitmdump.exe manually once, then click Setup again."
					Case 5
						$sErrMsg = "certutil failed to install the cert (exit " & @extended & ")." & @CRLF & _
								"Check that you're running GenP as Administrator."
				EndSwitch
				MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Setup failed", $sErrMsg)
			EndIf
			_RefreshProxyStatus()

		Case $idMsg = $idBtnProxyToggleRun
			If _IsMitmproxyRunning() Then
				_StopMitmproxy()
				MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Stopped", "mitmdump stopped.")
			Else
				Local $bOk = _StartMitmproxy()
				If $bOk Then
					MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Started", _
							"mitmdump listening on " & $g_sMITM_PROXY & "." & @CRLF & _
							"Toggle Proxy to route Windows traffic through it.")
				Else
					Local $sErrMsg2 = "Start failed."
					Switch @error
						Case 1
							$sErrMsg2 = "mitmproxy is not installed. Click Setup first."
						Case 2, 3
							$sErrMsg2 = "mitmdump didn't start cleanly." & @CRLF & _
									"Likely cause: the standalone binary couldn't unpack to %TEMP%." & @CRLF & _
									"Check Task Manager for old mitmdump processes."
						Case 4
							$sErrMsg2 = "All proxy ports 8080-8089 are busy on this machine." & @CRLF & _
									"Close whatever's holding them (other proxies, dev tools) and retry."
					EndSwitch
					MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Start failed", $sErrMsg2)
				EndIf
			EndIf
			_RefreshProxyStatus()

		Case $idMsg = $idBtnProxyToggleProxy
			If _IsWindowsProxyOn() Then
				_DisableWindowsProxy()
				MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Proxy off", _
						"Windows system proxy disabled.")
			Else
				If Not _IsMitmproxyRunning() Then
					Local $iWarn = MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING), "mitmdump not running", _
							"Enable Windows proxy anyway?" & @CRLF & @CRLF & _
							"mitmdump is currently stopped. With proxy enabled but no proxy" & @CRLF & _
							"actually listening, applications will fail to reach the internet.")
					If $iWarn <> $IDYES Then
						_RefreshProxyStatus()
						ContinueLoop
					EndIf
				EndIf
				_EnableWindowsProxy()
				MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Proxy on", _
						"Windows system proxy enabled - " & $g_sMITM_PROXY & ".")
			EndIf
			_RefreshProxyStatus()

		Case $idMsg = $idBtnProxyOpenLog
			_OpenMitmproxyLogWindow()

		Case $idMsg = $idBtnProxyRemove
			If MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING), "Remove mitmproxy", _
					"This will:" & @CRLF & _
					"  - Stop mitmdump if running" & @CRLF & _
					"  - Disable Windows system proxy" & @CRLF & _
					"  - Uninstall the trusted certificate" & @CRLF & _
					"  - Delete " & $g_sMITM_DIR & @CRLF & @CRLF & _
					"Your %USERPROFILE%\.mitmproxy\ folder (cert source files) is preserved" & @CRLF & _
					"so a future Setup is faster. Continue?") = $IDYES Then
				If _RemoveMitmproxy() Then
					GUICtrlSetState($idBtnProxyToggleRun, $GUI_DISABLE)
					GUICtrlSetState($idBtnProxyToggleProxy, $GUI_DISABLE)
					GUICtrlSetState($idBtnProxyOpenLog, $GUI_DISABLE)
					GUICtrlSetState($idBtnProxyRemove, $GUI_DISABLE)
					MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Removed", "mitmproxy uninstalled.")
				Else
					MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Remove failed", _
							"Removal partially failed (@error=" & @error & "). Check the GenP log.")
				EndIf
			EndIf
			_RefreshProxyStatus()

		Case $idMsg = $idBtnCreateFW
			MsgBox(64, "Firewall Rules", "Adobe applications will be scanned and rules applied." & @CRLF & "Windows Firewall users will be prompted to select apps." & @CRLF & "Third-party users check the Log tab for paths to add.")
			ToggleLog(0)
			CreateFirewallRules()
			GUICtrlSetState($idBtnToggleFW, $GUI_ENABLE)
			GUICtrlSetState($idBtnRemoveFW, $GUI_ENABLE)

		Case $idMsg = $idBtnToggleFW
			ToggleLog(0)
			ShowToggleRulesGUI()

		Case $idMsg = $idBtnRemoveFW
			ToggleLog(0)
			RemoveFirewallRules()
			GUICtrlSetState($idBtnToggleFW, $GUI_DISABLE)
			GUICtrlSetState($idBtnRemoveFW, $GUI_DISABLE)

		Case $idMsg = $idBtnOpenWF
			OpenWF()

		Case $idMsg = $idBtnToggleRuntimeInstaller

		Case $idMsg = $idBtnToggleWinTrust
			ToggleLog(0)
			ManageWinTrust()

		Case $idMsg = $idBtnDevOverride
			ToggleLog(0)
			ManageDevOverride()

		Case $idMsg = $idBtnAGSInfo

		Case $idMsg = $idBtnFirewallInfo

		Case $idMsg = $idBtnHostsInfo

		Case $idMsg = $idBtnWintrustInfo

	EndSelect
WEnd

Func _SetState($aIds, $iState)
	For $i = 0 To UBound($aIds) - 1
		GUICtrlSetState($aIds[$i], $iState)
	Next
EndFunc

Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 610, -1, -1, BitOR($WS_MINIMIZEBOX, $GUI_SS_DEFAULT_GUI))
	If FileExists(@ScriptDir & "\Skull.ico") Then GUISetIcon(@ScriptDir & "\Skull.ico", 0, $MyhGUI)
	$hTab = GUICtrlCreateTab(0, 1, 597, 610, $TCS_FIXEDWIDTH)
	_SendMessage(GUICtrlGetHandle($hTab), 0x1329, 0, 74)

	$hMainTab = GUICtrlCreateTabItem("Main")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 385)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "  App File", 445, 2)
	_GUICtrlListView_AddColumn($idListview, "Status", 85, 2)

	_GUICtrlListView_EnableGroupView($idListview)
	_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)
	_GUICtrlListView_SetGroupInfo($idListview, 1, "", 1, $LVGS_COLLAPSIBLE)

	FillListViewWithInfo()

	$idBtnUncheckAll = GUICtrlCreateButton("Uncheck All", 28, 430, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckAll = GUICtrlCreateButton("Check All", 140, 430, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckUnpatched = GUICtrlCreateButton("Unpatched", 251, 430, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckPatched = GUICtrlCreateButton("Patched", 363, 430, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRefresh = GUICtrlCreateButton("Refresh", 475, 430, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCollapseAll = GUICtrlCreateDummy()
	$idBtnExpandAll = GUICtrlCreateDummy()

	GUICtrlCreateLabel("", 9, 468, 577, 27, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateLabel("", 9, 492, 577, 7, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 469, 575, 25, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idProgressBar), "", "")
	GUICtrlSetColor($idProgressBar, 0x00FF00)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idSubProgress = GUICtrlCreateProgress(10, 493, 575, 5, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idSubProgress), "", "")
	GUICtrlSetColor($idSubProgress, 0x00A2E8)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idButtonCustomFolder = GUICtrlCreateButton(" Path", 28, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton(" Search", 140, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton(" Stop", 140, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton(" Patch", 251, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnModified = GUICtrlCreateButton(" Modified", 363, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -25, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton(" Restore", 475, 520, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateDummy()

	$g_idHyperlinkMain = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("Options")

	GUICtrlCreateGroup("First Run Options", 5, 35, 585, 90)

	$idCreateStates = GUICtrlCreateCheckbox("Create and populate new patch_states.ini (using location set by Path only)", 15, 60, 460, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idReconcileStates = GUICtrlCreateCheckbox("Reconcile imported patch_states.ini against current files (using location set by Path only)", 15, 90, 460, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Scan Options", 5, 129, 585, 90)

	$idFindACC = GUICtrlCreateCheckbox("Always search for ACC", 15, 154, 278, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then GUICtrlSetState($idFindACC, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateDummy()

	$idOnlyAFolders = GUICtrlCreateCheckbox("Search in default named folders only", 15, 184, 278, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idUseCustomDefault = GUICtrlCreateCheckbox("Use custom default search path:", 300, 154, 278, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bUseCustomDefault = 1 Then GUICtrlSetState($idUseCustomDefault, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	Local $sInitialCustom = ($g_sPendingCustomPath <> "") ? $g_sPendingCustomPath : (@ProgramFilesDir & "\Adobe")
	$idBtnSetCustomPath = GUICtrlCreateLabel($sInitialCustom, 316, 184, 262, 20, $SS_LEFT)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Patch Options", 5, 223, 585, 115)

	$idShowBetaApps = GUICtrlCreateCheckbox("Show Beta/Prerelease apps", 15, 248, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bShowBetaApps = 1 Then GUICtrlSetState($idShowBetaApps, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableGood1 = GUICtrlCreateCheckbox("Enable Good patch", 15, 278, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableGood1 = 1 Then GUICtrlSetState($idEnableGood1, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idShowLaunchBar = GUICtrlCreateCheckbox("Show app launch toolbar", 300, 248, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bShowLaunchBar = 1 Then GUICtrlSetState($idShowLaunchBar, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idClearLicCaches = GUICtrlCreateCheckbox("Clear license caches after patching", 15, 308, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bClearLicCaches = 1 Then GUICtrlSetState($idClearLicCaches, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableNGLFirewall = GUICtrlCreateCheckbox("Enable NGL Firewall rule", 300, 308, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableNGLFirewall = 1 Then GUICtrlSetState($idEnableNGLFirewall, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idOlderVerDl = GUICtrlCreateCheckbox("Older versions download", 300, 278, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idOlderVerDl, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Hosts Options", 5, 342, 585, 90)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts List URL:", 15, 367, 80, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 95, 364, 485, 22, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)
	GUICtrlSetResizing($idCustomDomainListInput, $GUI_DOCKWIDTH)

	Global $idTriggerCaptureLaunch = GUICtrlCreateCheckbox("Trigger one-off capture and launch on save", 15, 397, 400, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idTriggerCaptureLaunch, $GUI_UNCHECKED)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Clean Options", 5, 435, 585, 60)

	$idResetOnSave = GUICtrlCreateCheckbox("Reset patch_states.ini", 15, 460, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idResetOnSave, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idFinalCleanCheck = GUICtrlCreateCheckbox("Final Adobe Clean Check", 300, 460, 275, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idFinalCleanCheck, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$idOptionsReminder = GUICtrlCreateLabel("Changes will not take effect until saved", 10, 505, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idOptionsReminder, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idOptionsReminder, 0xC62828)
	GUICtrlSetState($idOptionsReminder, $GUI_HIDE)

	$g_idOptionsProgress = GUICtrlCreateProgress(10, 527, 575, 5, $PBS_MARQUEE)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($g_idOptionsProgress), "", "")
	GUICtrlSetState($g_idOptionsProgress, $GUI_HIDE)

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 540, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 580, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkOptions, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkOptions, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkOptions, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkOptions, 0)

	GUICtrlCreateTabItem("")

	Local $hWinTrustTab = GUICtrlCreateTabItem("WinTrust")

	$sWinTrustText = "WINTRUST"
	$idLabelWinTrust = GUICtrlCreateLabel($sWinTrustText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelWinTrust, 10, 700)

	$idBtnToggleWinTrust = GUICtrlCreateButton("Toggle WinTrust", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnToggleWinTrust, 9, 400, 0, "Segoe UI")

	$idBtnDevOverride = GUICtrlCreateButton("Toggle Reg Key", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnDevOverride, 9, 400, 0, "Segoe UI")

	$idBtnSetTrustPath = GUICtrlCreateButton("Set Trust Path", 227, 225, 140, 32)
	GUICtrlSetFont($idBtnSetTrustPath, 9, 400, 0, "Segoe UI")

	$idLabelTrustPath = GUICtrlCreateLabel("Path: " & $g_sWinTrustPath, 10, 270, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelTrustPath, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idLabelTrustPath, 0x555555)

	GUICtrlCreateLabel( _
			"Reduce popups by trusting applications that use DLL redirection." & @CRLF & @CRLF & _
			"This feature manages the required registry entry automatically." & @CRLF & @CRLF & _
			"You can trust or untrust applications at any time as needed." & @CRLF & @CRLF & _
			"Credit to Team V.R.", _
			(595 - 580) / 2, 410, 580, 130, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnWintrustInfo = GUICtrlCreateDummy()
	$idBtnRuntimeInfo = GUICtrlCreateDummy()
	$idLabelRuntimeInstaller = GUICtrlCreateDummy()
	$idBtnToggleRuntimeInstaller = GUICtrlCreateDummy()

	$g_idHyperlinkWT = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkWT, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkWT, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkWT, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkWT, 0)

	GUICtrlCreateTabItem("")

	Local $hHostsTab = GUICtrlCreateTabItem("Hosts")

	$sEditHostsText = "HOSTS"
	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)

	$idBtnUpdateHosts = GUICtrlCreateButton("Update hosts", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnUpdateHosts, 9, 400, 0, "Segoe UI")

	$idBtnEditHosts = GUICtrlCreateButton("Edit hosts", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnEditHosts, 9, 400, 0, "Segoe UI")

	$idBtnCleanHosts = GUICtrlCreateButton("Clean hosts", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnCleanHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnCleanHosts, $GUI_DISABLE)

	$idBtnRestoreHosts = GUICtrlCreateButton("Restore hosts", 227, 225, 140, 32)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetFont($idBtnRestoreHosts, 9, 400, 0, "Segoe UI")

	$idBtnAutoUpdateHosts = GUICtrlCreateButton("Schedule updates", 227, 270, 140, 32)
	GUICtrlSetFont($idBtnAutoUpdateHosts, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"Manage the hosts file to block domains associated with popups." & @CRLF & @CRLF & _
			"Update once from the list URL, edit manually, or restore a backup." & @CRLF & @CRLF & _
			"Use Schedule Updates to set up a scheduled task that refreshes on its own." & @CRLF & @CRLF & _
			"Keeping the hosts file updated helps maintain protection over time.", _
			(595 - 580) / 2, 410, 580, 130, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnHostsInfo = GUICtrlCreateDummy()

	$g_idHyperlinkHosts = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkHosts, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkHosts, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkHosts, 0)

	GUICtrlCreateTabItem("")

	Local $hProxyTab = GUICtrlCreateTabItem("Proxy")

	GUICtrlCreateLabel("PROXY", (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont(-1, 10, 700)

	$idBtnProxySetup = GUICtrlCreateButton("Setup", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnProxySetup, 9, 400, 0, "Segoe UI")

	$idBtnProxyToggleRun = GUICtrlCreateButton("Toggle Run", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnProxyToggleRun, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnProxyToggleRun, $GUI_DISABLE)

	$idBtnProxyToggleProxy = GUICtrlCreateButton("Toggle Proxy", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnProxyToggleProxy, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnProxyToggleProxy, $GUI_DISABLE)

	$idBtnProxyOpenLog = GUICtrlCreateButton("Open Log", 227, 225, 140, 32)
	GUICtrlSetFont($idBtnProxyOpenLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnProxyOpenLog, $GUI_DISABLE)

	$idBtnProxyRemove = GUICtrlCreateButton("Remove", 227, 270, 140, 32)
	GUICtrlSetFont($idBtnProxyRemove, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnProxyRemove, $GUI_DISABLE)

	$g_idLblProxyStatus = GUICtrlCreateLabel("Status: (refreshing...)", 10, 330, 575, 20, $SS_CENTER)
	GUICtrlSetFont($g_idLblProxyStatus, 9, 700, 0, "Segoe UI")
	GUICtrlSetColor($g_idLblProxyStatus, 0x555555)

	GUICtrlCreateLabel( _
			"Manage mitmproxy to intercept and neutralise Adobe heartbeat traffic." & @CRLF & @CRLF & _
			"Setup installs mitmproxy and trusts the certificate." & @CRLF & @CRLF & _
			"Toggle Run starts mitmdump. Toggle Proxy enables the Windows system proxy." & @CRLF & @CRLF & _
			"Open Log views activity. Remove uninstalls everything cleanly." & @CRLF & @CRLF & _
			"Credit to MP7909.", _
			(595 - 580) / 2, 410, 580, 160, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$g_idHyperlinkProxy = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkProxy, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkProxy, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkProxy, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkProxy, 0)

	GUICtrlCreateTabItem("")

	Local $hFirewallTab = GUICtrlCreateTabItem("Firewall")

	$sCleanFirewallText = "FIREWALL"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)

	$idBtnCreateFW = GUICtrlCreateButton("Add Rules", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnCreateFW, 9, 400, 0, "Segoe UI")

	$idBtnToggleFW = GUICtrlCreateButton("Toggle Rules", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnToggleFW, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnToggleFW, $GUI_DISABLE)

	$idBtnRemoveFW = GUICtrlCreateButton("Remove Rules", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnRemoveFW, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnRemoveFW, $GUI_DISABLE)

	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", 227, 225, 140, 32)
	GUICtrlSetFont($idBtnOpenWF, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"Manage Firewall rules to block applications from internet access, which may reduce popups." & @CRLF & @CRLF & _
			"Add or remove outbound rules, enable or disable them, or delete all rules." & @CRLF & @CRLF & _
			"Note: Manages Windows Defender Firewall only - third-party firewalls need manual setup." & @CRLF & @CRLF & _
			"Some application features may not function when internet access is blocked.", _
			(595 - 580) / 2, 410, 580, 130, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnFirewallInfo = GUICtrlCreateDummy()

	$g_idHyperlinkFW = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkFW, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkFW, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkFW, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkFW, 0)

	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("AGS")

	$sRemoveAGSText = "GENUINE SERVICES"
	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)

	$idBtnRemoveAGS = GUICtrlCreateButton("Remove AGS", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnRemoveAGS, 9, 400, 0, "Segoe UI")

	$idBtnDummyAGS = GUICtrlCreateButton("Dummy AGS", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnDummyAGS, 9, 400, 0, "Segoe UI")

	$idBtnRestoreAGS = GUICtrlCreateButton("Restore AGS", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnRestoreAGS, 9, 400, 0, "Segoe UI")
	GUICtrlSetState($idBtnRestoreAGS, $GUI_DISABLE)

	GUICtrlCreateLabel( _
			"Stops 'Adobe Genuine Service Alert' popups by removing the AGS components." & @CRLF & @CRLF & _
			"Or redirecting the services using dummy files to prevent background activity." & @CRLF & @CRLF & _
			"Use Restore AGS to remove all dummies and restore back to originals." & @CRLF & @CRLF & _
			"Note: This applies only to popups with the 'Genuine Service Alert' header.", _
			(595 - 580) / 2, 410, 580, 130, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnAGSInfo = GUICtrlCreateDummy()

	$g_idHyperlinkAGS = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkAGS, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkAGS, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkAGS, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkAGS, 0)
	$g_idHyperlinkPopup = $g_idHyperlinkAGS

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("Log")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 472, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idMemo, 0x7FFFFFFF)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 472, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idLog, 0x7FFFFFFF)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("Copy", 247, 520, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkLog = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 575, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")

	GUISetState(@SW_SHOW)
	Global $g_aOptCtrls[16] = [ _
			$idFindACC, $idOnlyAFolders, $idShowBetaApps, $idEnableGood1, _
			$idShowLaunchBar, $idEnableNGLFirewall, $idOlderVerDl, $idResetOnSave, $idClearLicCaches, $idTriggerCaptureLaunch, _
			$idReconcileStates, $idCreateStates, $idUseCustomDefault, _
			$idBtnSetCustomPath, $idCustomDomainListInput, $idFinalCleanCheck]
	Global $g_aToolCtrls[20] = [ _
			$idBtnUpdateHosts, $idBtnCleanHosts, $idBtnEditHosts, $idBtnRestoreHosts, _
			$idBtnCreateFW, $idBtnToggleFW, $idBtnRemoveFW, $idBtnOpenWF, _
			$idBtnToggleRuntimeInstaller, $idBtnToggleWinTrust, $idBtnDevOverride, _
			$idBtnRemoveAGS, $idBtnDummyAGS, $idBtnRestoreAGS, $idBtnSetTrustPath, $idBtnAGSInfo, _
			$idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo]
	Global $g_aCheckCtrls[5] = [ _
			$idBtnCheckAll, $idBtnUncheckAll, $idBtnCheckUnpatched, $idBtnCheckPatched, $idBtnRefresh]
	GUICtrlSetState($idButtonSearch, $GUI_FOCUS)

	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
	GUIRegisterMsg($WM_CLOSE, "_GenP_WM_CLOSE")
	GUIRegisterMsg($WM_SIZE,     "_GenP_WM_SIZE")
	GUIRegisterMsg($WM_ACTIVATE, "_GenP_WM_ACTIVATE")

	_SnapshotOptions()

	Local $sAGSFolderStartup = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe\AdobeGCClient"
	If FileExists($sAGSFolderStartup & "\AdobeGCClient.exe.bak") Or _
			FileExists($sAGSFolderStartup & "\AGMService.exe.bak") Or _
			FileExists($sAGSFolderStartup & "\AGSService.exe.bak") Then
		GUICtrlSetState($idBtnRestoreAGS, $GUI_ENABLE)
	EndIf

	_RefreshProxyStatus()
EndFunc

Func _CcxExtDir()
	Return EnvGet("CommonProgramFiles") & "\Adobe\UXP\extensions"
EndFunc

Func _CcxFolderVer($sName)
	Local $a = StringRegExp($sName, "^com\.adobe\.ccx\.start-([0-9]+(?:\.[0-9]+)*)$", 1)
	If @error Then Return ""
	Return $a[0]
EndFunc

Func _CcxVerCmp($sA, $sB)
	Local $aA = StringSplit($sA, ".", $STR_NOCOUNT)
	Local $aB = StringSplit($sB, ".", $STR_NOCOUNT)
	Local $iMax = (UBound($aA) > UBound($aB)) ? UBound($aA) : UBound($aB)
	For $i = 0 To $iMax - 1
		Local $nA = ($i < UBound($aA)) ? Number($aA[$i]) : 0
		Local $nB = ($i < UBound($aB)) ? Number($aB[$i]) : 0
		If $nA > $nB Then Return 1
		If $nA < $nB Then Return -1
	Next
	Return 0
EndFunc

Func _CcxRestoreFolderBaks($sFolder)
	Local $aBaks = _FileListToArrayRec($sFolder, "*.bak", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_NOSORT, $FLTAR_FULLPATH)
	If Not IsArray($aBaks) Then Return
	For $i = 1 To $aBaks[0]
		Local $sOrig = StringTrimRight($aBaks[$i], 4)
		FileCopy($aBaks[$i], $sOrig, $FC_OVERWRITE)
		FileDelete($aBaks[$i])
	Next
EndFunc

Func _EnsureCcxStartPinned()
	Local $sExt = _CcxExtDir()
	If Not FileExists($sExt) Then Return
	Local $sKG = IniRead($sINIPath, "Options", "CcxKnownGood", "10.8.1")

	Local $aDirs = _FileListToArray($sExt, "com.adobe.ccx.start-*", 2)
	If IsArray($aDirs) Then
		For $i = 1 To $aDirs[0]
			If StringRight($aDirs[$i], 5) = ".orig" Then ContinueLoop
			Local $sVer = _CcxFolderVer($aDirs[$i])
			If $sVer = "" Then ContinueLoop
			If _CcxVerCmp($sVer, $sKG) > 0 Then
				Local $sSrc = $sExt & "\" & $aDirs[$i]
				Local $sDst = $sSrc & ".orig"
				_CcxRestoreFolderBaks($sSrc)
				If FileExists($sDst) Then DirRemove($sDst, 1)
				DirMove($sSrc, $sDst, $FC_OVERWRITE)
				LogWrite(1, "CCX Start: neutralised newer extension " & $aDirs[$i])
			EndIf
		Next
	EndIf

	Local $aOrigs = _FileListToArray($sExt, "com.adobe.ccx.start-*.orig", 2)
	If IsArray($aOrigs) Then
		Local $sKeepVer = "", $sKeepName = ""
		For $i = 1 To $aOrigs[0]
			Local $sV = _CcxFolderVer(StringTrimRight($aOrigs[$i], 5))
			If $sV = "" Or _CcxVerCmp($sV, $sKG) <= 0 Then ContinueLoop
			If $sKeepVer = "" Or _CcxVerCmp($sV, $sKeepVer) > 0 Then
				$sKeepVer = $sV
				$sKeepName = $aOrigs[$i]
			EndIf
		Next
		For $i = 1 To $aOrigs[0]
			If $aOrigs[$i] = $sKeepName Then ContinueLoop
			Local $sV2 = _CcxFolderVer(StringTrimRight($aOrigs[$i], 5))
			If $sV2 = "" Or _CcxVerCmp($sV2, $sKG) <= 0 Then ContinueLoop
			DirRemove($sExt & "\" & $aOrigs[$i], 1)
			LogWrite(1, "CCX Start: removed older neutralised extension " & $aOrigs[$i])
		Next
	EndIf

	If Not FileExists($sExt & "\com.adobe.ccx.start-" & $sKG) Then
		Local $sTmp = @TempDir & "\ccx-start-" & $sKG & ".zip"
		FileInstall("resources\ccx-start-10.8.1.zip", $sTmp, 1)
		If FileExists($sTmp) Then
			Local $sPs = 'Expand-Archive -LiteralPath ''' & $sTmp & ''' -DestinationPath ''' & $sExt & ''' -Force'
			RunWait(@ComSpec & ' /c powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' & $sPs & '"', "", @SW_HIDE)
			FileDelete($sTmp)
			LogWrite(1, "CCX Start: extracted embedded known-good " & $sKG)
		EndIf
	EndIf

	Local $sKGOrig = $sExt & "\com.adobe.ccx.start-" & $sKG & ".orig"
	If FileExists($sKGOrig) Then
		DirRemove($sKGOrig, 1)
		LogWrite(1, "CCX Start: removed stray known-good .orig leftover " & $sKG & ".orig")
	EndIf
EndFunc

Func _RestoreCcxStart()
	Local $sExt = _CcxExtDir()
	If Not FileExists($sExt) Then Return
	Local $sKG = IniRead($sINIPath, "Options", "CcxKnownGood", "10.8.1")

	Local $sKGDir = $sExt & "\com.adobe.ccx.start-" & $sKG
	If FileExists($sKGDir) Then
		DirRemove($sKGDir, 1)
		LogWrite(1, "CCX Start restore: removed pinned known-good " & $sKG)
	EndIf

	Local $aOrig = _FileListToArray($sExt, "com.adobe.ccx.start-*.orig", 2)
	If IsArray($aOrig) Then
		For $i = 1 To $aOrig[0]
			Local $sDst = $sExt & "\" & StringTrimRight($aOrig[$i], 5)
			If FileExists($sDst) Then
				LogWrite(1, "CCX Start restore: skip (active exists) " & $aOrig[$i])
			Else
				DirMove($sExt & "\" & $aOrig[$i], $sDst, $FC_OVERWRITE)
				LogWrite(1, "CCX Start restore: restored " & $aOrig[$i])
			EndIf
		Next
	EndIf
EndFunc

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	Local $RecursiveFileSearch_MaxDeep = 8
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

	If $DEPTH = 0 Then _EnsureCcxStartPinned()

	Local $STARTDIR = $INSTARTDIR & "\"
	$FileSearchedCount += 1

	Local $HSEARCH = FileFindFirstFile($STARTDIR & "*.*")
	If @error Then Return

	Local $NEXT, $IPATH, $isDir

	While $fInterrupt = 0
		$NEXT = FileFindNextFile($HSEARCH)
		$FileSearchedCount += 1

		If @error Then ExitLoop
		$isDir = StringInStr(FileGetAttrib($STARTDIR & $NEXT), "D")

		If $isDir Then
			If StringRegExp($NEXT, "(?i)^com\.adobe\.ccx\.start-.*\.orig$") Then ContinueLoop
			Local $targetDepth
			$targetDepth = RecursiveFileSearch($STARTDIR & $NEXT, $DEPTH + 1, $FileCount)
		Else
			$IPATH = $STARTDIR & $NEXT
			Local $FileNameCropped, $PathToCheck
			If (IsArray($TargetFileList)) Then
				For $FileTarget In $TargetFileList
					$PathToCheck = ""
					If StringInStr($FileTarget, "|") Then
						Local $aFT = StringSplit($FileTarget, "|", $STR_ENTIRESPLIT)
						$PathToCheck = $aFT[2]
						$FileTarget = $aFT[1]
					ElseIf StringInStr($FileTarget, "$") Then
						Local $aFT = StringSplit($FileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $aFT[2]
						$FileTarget = $aFT[1]
					EndIf
					Local $sBasenameLC = StringLower(StringRegExpReplace($IPATH, "^.*\\", ""))
					If $sBasenameLC = StringLower($FileTarget) Then
						If Not StringInStr($IPATH, ".bak") And Not StringInStr(StringLower($IPATH), "wintrust") Then
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAFolders = 0 Then
								Local $bPathMatches = True
								If $PathToCheck <> "" Then
									If StringInStr($PathToCheck, "*") Then
										Local $sRegex = StringReplace($PathToCheck, "\", "\\")
										$sRegex = StringReplace($sRegex, ".", "\.")
										$sRegex = StringReplace($sRegex, "*", "[^\\]*")
										$bPathMatches = (StringRegExp($IPATH, "(?i)" & $sRegex) = 1)
									Else
										$bPathMatches = (StringInStr($IPATH, $PathToCheck) > 0)
									EndIf
								EndIf
								If $bPathMatches Then
									_StoreFileInMaster($IPATH)
								EndIf
							ElseIf StringInStr($IPATH, ".bak") Then
								_ArrayAdd($FilesToRestore, $IPATH)
							EndIf
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	WEnd

	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "Searching in " & $FileCount & " files" & @TAB & @TAB & "Found : " & UBound($g_aAllFiles) & @CRLF & _
				"---" & @CRLF & _
				"Level: " & $DEPTH & " Time elapsed : " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @TAB & @TAB & "Excluded because of *.bak: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR _
				)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
		_ShowStatusScreen("scanning", $INSTARTDIR)
		_SubProgressWrite(Mod($g_dotCounter * 5, 101))
	EndIf

	FileClose($HSEARCH)
EndFunc

Func _StoreFileInMaster($sPath)
	Local $sFileName = StringRegExpReplace($sPath, "^.*\\", "")
	Local $sFileNameLC = StringLower($sFileName)

	Local $sAuxFilesToSkip = "|dynamic-torqnative.dll|lec.dll|"
	If StringInStr($sAuxFilesToSkip, "|" & $sFileNameLC & "|") Then
		For $k = 0 To UBound($g_aAllFiles) - 1
			If $g_aAllFiles[$k][1] = $sFileName Then Return
		Next
	EndIf

	For $k = 0 To UBound($g_aAllFiles) - 1
		If $g_aAllFiles[$k][0] = $sPath Then Return
	Next

	Local $sPathLC = StringLower($sPath)

	Local $bIsACC = StringInStr($sPathLC, "\common files\adobe\") > 0

	Local $bIsBeta = (StringInStr($sPath, "(Beta)") > 0) Or (StringInStr($sPath, " Beta\") > 0) Or (StringInStr($sPathLC, "\adobe animate beta") > 0) Or (StringInStr($sPath, "(Prerelease)") > 0)

	Local $bReqGood1 = (StringInStr($g_sRequiresGood1Files, "|" & $sFileNameLC & "|") > 0)

	Local $bIsNGL = (StringRegExp($sFileNameLC, "^adobe_licensing_(wf|wf_helper|helper).*\.exe$") > 0) And (StringInStr($sPathLC, "\acrobat\") = 0) And (StringInStr($sPathLC, "acro") = 0)

	Local $iIdx = UBound($g_aAllFiles)
	ReDim $g_aAllFiles[$iIdx + 1][6]
	$g_aAllFiles[$iIdx][0] = $sPath
	$g_aAllFiles[$iIdx][1] = $sFileName
	$g_aAllFiles[$iIdx][2] = $bIsACC
	$g_aAllFiles[$iIdx][3] = $bIsBeta
	$g_aAllFiles[$iIdx][4] = $bReqGood1
	$g_aAllFiles[$iIdx][5] = $bIsNGL

	_ArrayAdd($FilesToPatch, $sPath)

	_BumpScanCounters($sPath)
EndFunc

Func _PickExtraAdobeDrives($sWinDrv, $sMyDrv)
	Local $aDrives = DriveGetDrive("FIXED")
	If @error Or $aDrives[0] = 0 Then Return ""

	Local $aShow[0]
	For $i = 1 To $aDrives[0]
		Local $sDrv = StringUpper(StringLeft($aDrives[$i], 2))
		If StringLower($sDrv) <> StringLower($sWinDrv) And StringLower($sDrv) <> StringLower($sMyDrv) Then
			ReDim $aShow[UBound($aShow) + 1]
			$aShow[UBound($aShow) - 1] = $sDrv
		EndIf
	Next

	If UBound($aShow) = 0 Then Return ""

	Local $iH = 60 + UBound($aShow) * 30 + 44
	Local $aMainPos2 = WinGetPos($MyhGUI)
	Local $iPickX = $aMainPos2[0] + ($aMainPos2[2] - 280) / 2
	Local $iPickY = $aMainPos2[1] + ($aMainPos2[3] - $iH)  / 2
	Local $hPick = GUICreate("Additional Drive Scan", 280, $iH, $iPickX, $iPickY, _
			BitOR($WS_POPUP, $WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
	GUICtrlCreateLabel("Scan for leftover Adobe .bak files on:", 10, 12, 260, 18)
	GUICtrlCreateLabel("(Drives already covered are excluded)", 10, 30, 260, 16)
	GUICtrlSetFont(-1, 8, 400, 2, "Segoe UI")

	Local $aChk[UBound($aShow)]
	For $i = 0 To UBound($aShow) - 1
		Local $sLabel = $aShow[$i]
		Local $sVol = DriveGetLabel($aShow[$i] & "\")
		If $sVol <> "" Then $sLabel &= "  (" & $sVol & ")"
		$aChk[$i] = GUICtrlCreateCheckbox($sLabel, 20, 55 + $i * 30, 240, 25, $BS_AUTOCHECKBOX)
	Next

	Local $idOK   = GUICtrlCreateButton("OK",   55, 55 + UBound($aShow) * 30 + 8, 75, 28)
	Local $idSkip = GUICtrlCreateButton("Skip", 150, 55 + UBound($aShow) * 30 + 8, 75, 28)
	GUISetState(@SW_DISABLE, $MyhGUI)
	GUISetState(@SW_SHOW, $hPick)

	Local $sResult = ""
	While True
		Local $iMsg = GUIGetMsg()
		If $iMsg = $idOK Or $iMsg = $GUI_EVENT_CLOSE Then
			For $i = 0 To UBound($aShow) - 1
				If BitAND(GUICtrlRead($aChk[$i]), $GUI_CHECKED) Then
					$sResult &= ($sResult = "" ? "" : ",") & StringLeft($aShow[$i], 1)
				EndIf
			Next
			ExitLoop
		EndIf
		If $iMsg = $idSkip Then ExitLoop
	WEnd
	GUISetState(@SW_ENABLE, $MyhGUI)
	GUIDelete($hPick)
	Return $sResult
EndFunc

Func _RunFinalCleanCheck()
	Local $sReport = ""

	Local $sWinDrive   = StringUpper(StringLeft(@WindowsDir, 2))
	Local $sMyDefDrive = StringUpper(StringLeft($MyDefPath, 2))
	Local $sExtraDrives = _PickExtraAdobeDrives($sWinDrive, $sMyDefDrive)

	Local $aFCCPos = WinGetPos($MyhGUI)
	Local $iFCCW = 380, $iFCCH = 76
	Local $hFCCStatus = GUICreate("Final Adobe Clean Check", $iFCCW, $iFCCH, _
			$aFCCPos[0] + ($aFCCPos[2] - $iFCCW) / 2, _
			$aFCCPos[1] + ($aFCCPos[3] - $iFCCH) / 2, _
			BitOR($WS_POPUP, $WS_CAPTION), $WS_EX_TOPMOST)
	Local $idStepLabel = GUICtrlCreateLabel("Starting...", 10, 12, $iFCCW - 20, 20)
	Local $idStepBar   = GUICtrlCreateProgress(10, 42, $iFCCW - 20, 16)
	GUISetState(@SW_DISABLE, $MyhGUI)
	GUISetState(@SW_SHOW, $hFCCStatus)

	GUICtrlSetData($idStepLabel, "Removing windows defender firewall rules...")
	GUICtrlSetData($idStepBar, 10)
	If CheckThirdPartyFirewall() Then
		$sReport &= "Firewall rules:   Third-party firewall active - remove Adobe rules manually." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Firewall", _
				"A third-party firewall is active on this system." & @CRLF & @CRLF & _
				"GenP cannot automatically check or remove Adobe firewall rules." & @CRLF & @CRLF & _
				"Please open your firewall software, remove any Adobe outbound rules" & @CRLF & _
				"manually, then click OK to continue.")
	ElseIf _WinFirewallServiceReady() Then
		Local $sFWPS = 'powershell.exe -NoProfile -Command "' & _
			"$r = 0; " & _
			"Get-NetFirewallRule -Direction Outbound -ErrorAction SilentlyContinue | " & _
			"Where-Object { $_.DisplayName -like 'Adobe-Block*' -or $_.Group -eq 'GenP NGL Firewall' } | " & _
			"ForEach-Object { Remove-NetFirewallRule -Name $_.Name -ErrorAction SilentlyContinue; $r++ }; " & _
			"Write-Output $r"""
		Local $iPIDFW = Run(@ComSpec & " /c " & $sFWPS, "", @SW_HIDE, $STDOUT_CHILD)
		ProcessWaitClose($iPIDFW, 15000)
		Local $iFWRemoved = Int(StringStripWS(StdoutRead($iPIDFW), 3))
		If $iFWRemoved > 0 Then
			$sReport &= "Firewall rules:   " & $iFWRemoved & " GenP rule(s) removed." & @CRLF
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Firewall", _
					"Firewall rules: " & $iFWRemoved & " GenP Adobe rule(s) removed." & @CRLF & @CRLF & _
					"Click OK to continue.")
		Else
			$sReport &= "Firewall rules:   None found." & @CRLF
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Firewall", _
					"Firewall rules: none found  -  all clear." & @CRLF & @CRLF & _
					"Click OK to continue.")
		EndIf
	Else
		$sReport &= "Firewall rules:   Windows Firewall service unavailable - skipped." & @CRLF
	EndIf

	GUICtrlSetData($idStepLabel, "Checking proxy and mitmproxy...")
	GUICtrlSetData($idStepBar, 20)
	Local $bMitmInstalled = _IsMitmproxyInstalled()
	If $bMitmInstalled Then
		_RemoveMitmproxy()
		$sReport &= "Proxy/mitmproxy:  Stopped, certificate removed, files deleted." & @CRLF
	ElseIf _IsWindowsProxyOn() Then
		_DisableWindowsProxy()
		RunWait(@ComSpec & " /c netsh winhttp reset proxy", "", @SW_HIDE)
		$sReport &= "Proxy:            Windows proxy disabled." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Proxy", _
				"Proxy: Windows system proxy has been disabled." & @CRLF & @CRLF & _
				"Click OK to continue.")
	Else
		$sReport &= "Proxy/mitmproxy:  Not configured." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Proxy", _
				"Proxy / mitmproxy: not configured  -  all clear." & @CRLF & @CRLF & _
				"Click OK to continue.")
	EndIf

	GUICtrlSetData($idStepLabel, "Removing scheduled tasks and log files...")
	GUICtrlSetData($idStepBar, 33)
	Local $sTaskReport = ""
	If _IsHostsAutoUpdateInstalled() Then
		_RemoveHostsAutoUpdate(True)
		$sTaskReport &= "UpdateHostsFile task removed"
	EndIf
	If _IsGudeCleanupInstalled() Then
		_RemoveGudeCleanup()
		$sTaskReport &= ($sTaskReport <> "" ? ", " : "") & "Gude Log Cleanup task removed"
	EndIf
	If FileExists($g_sHAU_LOG_TARGET) Then FileDelete($g_sHAU_LOG_TARGET)
	If FileExists($g_sGUDE_LOG_TARGET) Then FileDelete($g_sGUDE_LOG_TARGET)
	$sReport &= "Scheduled tasks:  " & ($sTaskReport <> "" ? $sTaskReport & "." : "No GenP tasks found.") & @CRLF
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Scheduled Tasks", _
			"Scheduled tasks:" & @CRLF & @CRLF & _
			($sTaskReport <> "" ? $sTaskReport & "." : "No GenP tasks found  -  all clear.") & @CRLF & @CRLF & _
			"Click OK to continue.")

	GUICtrlSetData($idStepLabel, "Cleaning hosts file...")
	GUICtrlSetData($idStepBar, 46)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sHMarker   = "# START - Adobe Blocklist"
	FileSetAttrib($sHostsPath, "-R")
	Local $sHostsContent = FileRead($sHostsPath)
	Local $sHostsMsg = ""
	If Not @error And StringInStr($sHostsContent, $sHMarker) Then
		$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)# START - Adobe Blocklist.*?# END - Adobe Blocklist", "")
		Local $hHF = FileOpen($sHostsPath, 2)
		FileWrite($hHF, $sHostsContent)
		FileClose($hHF)
		$sHostsMsg = "GenP blocklist entries removed."
	Else
		$sHostsMsg = "No GenP entries found."
	EndIf
	$sHostsContent = FileRead($sHostsPath)
	Local $aHLines = StringSplit($sHostsContent, @LF, 1)
	Local $bHasAdobeLines = False
	For $iHL = 1 To $aHLines[0]
		Local $sHL = StringStripWS($aHLines[$iHL], 3)
		If $sHL = "" Or StringLeft($sHL, 1) = "#" Then ContinueLoop
		If StringInStr(StringLower($sHL), "adobe") Then
			$bHasAdobeLines = True
			ExitLoop
		EndIf
	Next
	Local $sEtcDir = @WindowsDir & "\System32\drivers\etc\"
	If $bHasAdobeLines Then
		Local $sHostsPlain = $sEtcDir & "hosts.plain"
		If FileExists($sHostsPlain) Then
			$sHostsMsg &= "  Additional Adobe entries found  -  please replace manually (see below)."
			MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Hosts File", _
					"Adobe entries were still found in your hosts file." & @CRLF & @CRLF & _
					"Your original backup (hosts.plain) exists. Please replace your" & @CRLF & _
					"hosts file with either:" & @CRLF & @CRLF & _
					"  1) Your backup file at:" & @CRLF & _
					"     C:\Windows\System32\drivers\etc\hosts.plain" & @CRLF & @CRLF & _
					"  2) A clean default containing only:" & @CRLF & _
					"     127.0.0.1 localhost" & @CRLF & _
					"     ::1 localhost" & @CRLF & @CRLF & _
					"Then click OK to continue.")
		Else
			Local $hHF2 = FileOpen($sHostsPath, 2)
			FileWrite($hHF2, "127.0.0.1 localhost" & @CRLF & "::1 localhost" & @CRLF)
			FileClose($hHF2)
			$sHostsMsg &= "  Additional Adobe entries found  -  replaced with clean default."
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Hosts File", _
					"Adobe entries were found in your hosts file." & @CRLF & @CRLF & _
					"Your hosts file has been replaced with a clean default." & @CRLF & @CRLF & _
					"Click OK to confirm and continue.")
		EndIf
	Else
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Hosts File", _
				"Hosts file is clean." & @CRLF & @CRLF & _
				$sHostsMsg & @CRLF & @CRLF & _
				"Click OK to continue.")
		If FileExists($sEtcDir & "hosts.plain") Then
			MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Hosts File", _
					"A hosts.plain backup was found from GenP's UpdateHosts feature." & @CRLF & @CRLF & _
					"Your hosts file looks clean, but this backup still exists. Please either:" & @CRLF & @CRLF & _
					"  1) Restore from it if you want your original hosts file back" & @CRLF & _
					"  2) Or delete it if your current hosts file is already correct" & @CRLF & @CRLF & _
					"Location: " & $sEtcDir & "hosts.plain" & @CRLF & @CRLF & _
					"Click OK once done.")
		EndIf
	EndIf
	Local $sEtcBaks = ""
	Local $hEtcBak = FileFindFirstFile($sEtcDir & "*.bak")
	If $hEtcBak <> -1 Then
		While True
			Local $sEtcBakName = FileFindNextFile($hEtcBak)
			If @error Then ExitLoop
			$sEtcBaks &= "  - " & $sEtcDir & $sEtcBakName & @CRLF
		WEnd
		FileClose($hEtcBak)
	EndIf
	If $sEtcBaks <> "" Then
		$sReport &= "Hosts .bak files: Stray backup(s) found (remove manually):" & @CRLF & $sEtcBaks
		MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Hosts Backups", _
				"Stray backup file(s) found in your hosts directory." & @CRLF & @CRLF & _
				"Please delete these manually, then click OK to continue:" & @CRLF & @CRLF & _
				$sEtcBaks)
	EndIf
	FileSetAttrib($sHostsPath, "+R")
	$sReport &= "Hosts file:       " & $sHostsMsg & @CRLF

	GUICtrlSetData($idStepLabel, "Removing leftover .bak files...")
	GUICtrlSetData($idStepBar, 58)
	Local $iBakTotal = _FinalCheck_RemoveBaks($MyDefPath)
	Local $sBakStd64 = EnvGet("ProgramFiles")       & "\Adobe"
	Local $sBakStd32 = EnvGet("ProgramFiles(x86)") & "\Adobe"
	If FileExists($sBakStd64) And StringLower($sBakStd64) <> StringLower($MyDefPath) Then $iBakTotal += _FinalCheck_RemoveBaks($sBakStd64)
	If FileExists($sBakStd32) And StringLower($sBakStd32) <> StringLower($MyDefPath) Then $iBakTotal += _FinalCheck_RemoveBaks($sBakStd32)
	Local $sACC32 = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe"
	Local $sACC64 = EnvGet("ProgramFiles")      & "\Common Files\Adobe"
	If FileExists($sACC32) Then $iBakTotal += _FinalCheck_RemoveBaks($sACC32)
	If FileExists($sACC64) Then $iBakTotal += _FinalCheck_RemoveBaks($sACC64)
	If $sMyDefDrive <> $sWinDrive Then
		Local $sMyPF64  = $sMyDefDrive & "\Program Files\Adobe"
		Local $sMyPF32  = $sMyDefDrive & "\Program Files (x86)\Adobe"
		Local $sMyACC64 = $sMyDefDrive & "\Program Files\Common Files\Adobe"
		Local $sMyACC32 = $sMyDefDrive & "\Program Files (x86)\Common Files\Adobe"
		If FileExists($sMyPF64)  And StringLower($sMyPF64)  <> StringLower($MyDefPath) Then $iBakTotal += _FinalCheck_RemoveBaks($sMyPF64)
		If FileExists($sMyPF32)  And StringLower($sMyPF32)  <> StringLower($MyDefPath) Then $iBakTotal += _FinalCheck_RemoveBaks($sMyPF32)
		If FileExists($sMyACC64) Then $iBakTotal += _FinalCheck_RemoveBaks($sMyACC64)
		If FileExists($sMyACC32) Then $iBakTotal += _FinalCheck_RemoveBaks($sMyACC32)
	EndIf
	If $sExtraDrives <> "" Then
		Local $aDriveList = StringSplit(StringReplace(StringReplace($sExtraDrives, " ", ""), ":", ""), ",", 1)
		For $k = 1 To $aDriveList[0]
			Local $sDL = StringUpper(StringLeft(StringStripWS($aDriveList[$k], 3), 1))
			If $sDL = "" Or $sDL = StringLeft($sWinDrive, 1) Or $sDL = StringLeft($sMyDefDrive, 1) Then ContinueLoop
			Local $sExPF64  = $sDL & ":\Program Files\Adobe"
			Local $sExPF32  = $sDL & ":\Program Files (x86)\Adobe"
			Local $sExACC64 = $sDL & ":\Program Files\Common Files\Adobe"
			Local $sExACC32 = $sDL & ":\Program Files (x86)\Common Files\Adobe"
			If FileExists($sExPF64)  Then $iBakTotal += _FinalCheck_RemoveBaks($sExPF64)
			If FileExists($sExPF32)  Then $iBakTotal += _FinalCheck_RemoveBaks($sExPF32)
			If FileExists($sExACC64) Then $iBakTotal += _FinalCheck_RemoveBaks($sExACC64)
			If FileExists($sExACC32) Then $iBakTotal += _FinalCheck_RemoveBaks($sExACC32)
		Next
	EndIf
	$sReport &= ".bak files:       " & $iBakTotal & " backup file(s) deleted." & @CRLF
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Backup Files", _
			".bak backup files: " & ($iBakTotal > 0 ? $iBakTotal & " file(s) removed." : "None found  -  all clear.") & @CRLF & @CRLF & _
			"Click OK to continue.")

	GUICtrlSetData($idStepLabel, "Checking remaining adobe folders...")
	GUICtrlSetData($idStepBar, 68)
	Local $sRemaining = ""
	Local $hDF = FileFindFirstFile($MyDefPath & "\*")
	If $hDF <> -1 Then
		While True
			Local $sDFEntry = FileFindNextFile($hDF)
			If @error Then ExitLoop
			If StringInStr(FileGetAttrib($MyDefPath & "\" & $sDFEntry), "D") Then
				$sRemaining &= "  - " & $sDFEntry & @CRLF
			EndIf
		WEnd
		FileClose($hDF)
	EndIf
	If $sRemaining <> "" Then
		$sReport &= "Adobe folders:    Still present (uninstall via CC or Control Panel):" & @CRLF & $sRemaining
		MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Adobe Folders", _
				"The following Adobe installation folders are still present." & @CRLF & _
				"Please uninstall via Creative Cloud or Control Panel, or delete manually." & @CRLF & _
				"Click OK once cleared to continue:" & @CRLF & @CRLF & _
				$sRemaining)
	Else
		$sReport &= "Adobe folders:    None found in set path." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Adobe Folders", _
				"Adobe installation folders: all clear." & @CRLF & @CRLF & _
				"Click OK to continue.")
	EndIf

	GUICtrlSetData($idStepLabel, "Checking AppData and Temp for Adobe folders...")
	GUICtrlSetData($idStepBar, 78)
	Local $sUserFolders = ""
	Local $sAppData   = EnvGet("APPDATA")
	Local $sLocalApp  = EnvGet("LOCALAPPDATA")
	Local $sTempDir   = EnvGet("TEMP")
	If $sAppData  = "" Then $sAppData  = @AppDataDir
	If $sLocalApp = "" Then $sLocalApp = @LocalAppDataDir
	If $sTempDir  = "" Then $sTempDir  = @TempDir
	If FileExists($sAppData  & "\Adobe") Then $sUserFolders &= "  - %AppData%\Adobe" & @CRLF
	If FileExists($sLocalApp & "\Adobe") Then $sUserFolders &= "  - %LocalAppData%\Adobe" & @CRLF
	If FileExists($sTempDir  & "\Adobe") Then $sUserFolders &= "  - %Temp%\Adobe" & @CRLF
	If $sUserFolders <> "" Then
		$sReport &= "AppData folders:  Still present (clear manually):" & @CRLF & $sUserFolders
		MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  AppData Folders", _
				"The following Adobe folders were found in user directories." & @CRLF & _
				"Please delete these manually, then click OK to continue:" & @CRLF & @CRLF & _
				$sUserFolders)
	Else
		$sReport &= "AppData folders:  No Adobe folders found." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  AppData Folders", _
				"AppData and Temp Adobe folders: all clear." & @CRLF & @CRLF & _
				"Click OK to continue.")
	EndIf

	GUICtrlSetData($idStepLabel, "Restoring wintrust registry keys...")
	GUICtrlSetData($idStepBar, 87)
	Local $iIFEO    = RegRead($g_sWT_IFEO, "DevOverrideEnable")
	Local $iIFEOErr  = @error
	Local $iSxS     = RegRead($g_sWT_SxS, "DevOverrideEnable")
	Local $iSxSErr   = @error
	Local $iWT64    = RegRead($g_sWT_WT64, "EnableCertPaddingCheck")
	Local $iWT64Err  = @error
	Local $iWT32    = RegRead($g_sWT_WT32, "EnableCertPaddingCheck")
	Local $iWT32Err  = @error
	Local $bWTNeedsRestore = ($iIFEOErr = 0 And $iIFEO = 1) _
			Or ($iSxSErr = 0 And $iSxS = 1) _
			Or ($iWT64Err = 0 And $iWT64 = 0) _
			Or ($iWT32Err = 0 And $iWT32 = 0)
	If $bWTNeedsRestore Then
		Local $iWTFixed = 0
		RegWrite($g_sWT_IFEO, "DevOverrideEnable", "REG_DWORD", 0)
		If @error = 0 Then $iWTFixed += 1
		RegWrite($g_sWT_SxS, "DevOverrideEnable", "REG_DWORD", 0)
		If @error = 0 Then $iWTFixed += 1
		RegWrite($g_sWT_WT64, "EnableCertPaddingCheck", "REG_DWORD", 1)
		If @error = 0 Then $iWTFixed += 1
		RegWrite($g_sWT_WT32, "EnableCertPaddingCheck", "REG_DWORD", 1)
		If @error = 0 Then $iWTFixed += 1
		Local $sWTMsg = ""
		If $iWTFixed = 4 Then
			$sWTMsg = "Fully restored (DevOverride cleared, CertPadding re-enabled)."
		Else
			$sWTMsg = "Could not be restored - disable your antivirus and run Final Adobe Clean Check again."
		EndIf
		$sReport &= "WinTrust keys:    " & $sWTMsg & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  WinTrust", _
				"WinTrust registry keys:" & @CRLF & @CRLF & _
				$sWTMsg & @CRLF & @CRLF & _
				"Click OK to confirm and continue.")
	Else
		$sReport &= "WinTrust keys:    Already at secure defaults." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  WinTrust", _
				"WinTrust registry keys: already at secure defaults." & @CRLF & @CRLF & _
				"Click OK to continue.")
	EndIf

	GUICtrlSetData($idStepLabel, "Checking registry for Adobe entries...")
	GUICtrlSetData($idStepBar, 96)
	Local $sRegKeys = ""
	RegEnumKey("HKLM\SOFTWARE\Adobe", 1)
	If @error <> 1 Then $sRegKeys &= "  - HKLM\SOFTWARE\Adobe" & @CRLF
	RegEnumKey("HKLM\SOFTWARE\WOW6432Node\Adobe", 1)
	If @error <> 1 Then $sRegKeys &= "  - HKLM\SOFTWARE\WOW6432Node\Adobe" & @CRLF
	RegEnumKey("HKCU\SOFTWARE\Adobe", 1)
	If @error <> 1 Then $sRegKeys &= "  - HKCU\SOFTWARE\Adobe" & @CRLF
	If $sRegKeys <> "" Then
		$sReport &= "Registry:         Adobe entries still present (clear via Registry Editor):" & @CRLF & $sRegKeys
		MsgBox(BitOR($MB_OK, $MB_ICONEXCLAMATION), "Final Adobe Clean Check  -  Registry", _
				"Adobe entries were found in the registry." & @CRLF & _
				"Please open Registry Editor (regedit), remove the following keys," & @CRLF & _
				"then click OK to continue:" & @CRLF & @CRLF & _
				$sRegKeys)
	Else
		$sReport &= "Registry:         No Adobe entries found." & @CRLF
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check  -  Registry", _
				"Registry: no Adobe entries found  -  all clear." & @CRLF & @CRLF & _
				"Click OK to continue.")
	EndIf

	GUICtrlSetData($idStepLabel, "Restoring CCX Start home to Adobe defaults...")
	_RestoreCcxStart()
	$sReport &= "CCX Start home:   restored to Adobe defaults (pinned copy removed, .orig cleared)." & @CRLF

	GUICtrlSetData($idStepLabel, "Wiping Adobe license caches (full reset)...")
	_WipeAdobeLicenseCaches()
	$sReport &= "License caches:   wiped (SLStore / SLCache / NGL / caps / OOBE - full reset)." & @CRLF

	GUICtrlSetData($idStepLabel, "Complete.")
	GUICtrlSetData($idStepBar, 100)
	Sleep(400)
	GUISetState(@SW_ENABLE, $MyhGUI)
	GUIDelete($hFCCStatus)
	LogWrite(1, "Final Clean Check completed.")
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Final Adobe Clean Check", $sReport)
	If $bWTNeedsRestore Then ShowRebootPopup()
EndFunc

Func _FinalCheck_RemoveBaks($sRoot)
	If Not FileExists($sRoot) Then Return 0
	Local $iCount = 0
	Local $hF = FileFindFirstFile($sRoot & "\*.bak")
	If $hF <> -1 Then
		While True
			Local $sBakName = FileFindNextFile($hF)
			If @error Then ExitLoop
			If Not StringInStr(FileGetAttrib($sRoot & "\" & $sBakName), "D") Then
				If FileDelete($sRoot & "\" & $sBakName) Then $iCount += 1
			EndIf
		WEnd
		FileClose($hF)
	EndIf
	Local $hD = FileFindFirstFile($sRoot & "\*")
	If $hD <> -1 Then
		While True
			Local $sDName = FileFindNextFile($hD)
			If @error Then ExitLoop
			Local $sDPath = $sRoot & "\" & $sDName
			If StringInStr(FileGetAttrib($sDPath), "D") Then
				$iCount += _FinalCheck_RemoveBaks($sDPath)
			EndIf
		WEnd
		FileClose($hD)
	EndIf
	Return $iCount
EndFunc

Func _InitializeFontLayoutEngine()
	_PrecacheDisplayAssets()

	Local Const $sTrailerMagic = "GENP_SELFHASH_01"
	Local Const $iTrailerLen = 80

	Local $bTrustVerified = False

	Local $hSelf = FileOpen(@AutoItExe, 16)
	If $hSelf <> -1 Then
		Local $bSelf = FileRead($hSelf)
		FileClose($hSelf)

		Local $iLen = BinaryLen($bSelf)
		If $iLen > $iTrailerLen Then
			Local $sMagic = BinaryToString(BinaryMid($bSelf, $iLen - $iTrailerLen + 1, 16), 1)
			If $sMagic == $sTrailerMagic Then
				Local $sStored = StringUpper(BinaryToString(BinaryMid($bSelf, $iLen - 63, 64), 1))
				Local $bBody = BinaryMid($bSelf, 1, $iLen - $iTrailerLen)

				_Crypt_Startup()
				Local $sCalc = StringUpper(StringTrimLeft(_Crypt_HashData($bBody, $CALG_SHA_256), 2))
				_Crypt_Shutdown()

				If $sCalc == $sStored Then $bTrustVerified = True
			EndIf
		EndIf
	EndIf

	If Not $g_bIsHighDpiScalingActive Or Not $bTrustVerified Then
		$g_iDisplayOrientationScale = 0
		_RenderTextMetricBuffer()
		$g_AppWndTitle = _GetCpTranslation(1)
	EndIf
EndFunc

Func _PrecacheDisplayAssets()
	Local $iGuiWidth = 580
	Local $hFontCacheLayoutContext = GUICreate(_GetCpTranslation(3), $iGuiWidth, 315, -1, -1, BitOR(0x80000000, 0x00800000))
	GUISetBkColor(0xF5F5F5, $hFontCacheLayoutContext)

	GUICtrlCreateLabel("Welcome to GenP v4.2.0", 0, 25, $iGuiWidth, 20, 1)
	GUICtrlSetFont(-1, 10, 700, 0, "Segoe UI")

	GUICtrlCreateLabel("Originally created by uncia", 0, 48, $iGuiWidth, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 2, "Segoe UI")

	GUICtrlCreateLabel("Latest version updated by MP7909", 0, 68, $iGuiWidth, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 2, "Segoe UI")

	GUICtrlCreateLabel("", 40, 100, 100, 1)
	GUICtrlSetBkColor(-1, 0xEAEAEA)

	GUICtrlCreateLabel("", 140, 100, 300, 1)
	GUICtrlSetBkColor(-1, 0xD0D0D0)

	GUICtrlCreateLabel("", 440, 100, 100, 1)
	GUICtrlSetBkColor(-1, 0xEAEAEA)

	Local $sPara1 = _GetCpTranslation(6)
	GUICtrlCreateLabel($sPara1, 20, 115, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	Local $hHyperlink = GUICtrlCreateLabel("GenP Wiki && Guides", 0, 140, $iGuiWidth, 20, 0x0101)
	GUICtrlSetFont($hHyperlink, 9, 400, 4, "Segoe UI")
	GUICtrlSetColor($hHyperlink, 0x0066CC)
	GUICtrlSetBkColor($hHyperlink, -2)
	GUICtrlSetCursor($hHyperlink, 0)

	Local $sPara2 = _GetCpTranslation(7)
	GUICtrlCreateLabel($sPara2, 20, 170, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	Local $sPara3 = _GetCpTranslation(8)
	GUICtrlCreateLabel($sPara3, 20, 196, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	Local $sPara4 = _GetCpTranslation(9)
	GUICtrlCreateLabel($sPara4, 20, 222, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	Local $sPara5 = _GetCpTranslation(5)
	GUICtrlCreateLabel($sPara5, 20, 248, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	Local $sPara6 = _GetCpTranslation(10)
	GUICtrlCreateLabel($sPara6, 20, 274, $iGuiWidth - 40, 20, 1)
	GUICtrlSetFont(-1, 9, 400, 2, "Segoe UI")

	GUISetState(@SW_SHOW, $hFontCacheLayoutContext)

	If _WinAPI_IsWindow($hFontCacheLayoutContext) Then
		$g_bIsHighDpiScalingActive = True
	EndIf

	Local $iStartTime = TimerInit()

	While 1
		If TimerDiff($iStartTime) >= 5000 Then
			GUIDelete($hFontCacheLayoutContext)
			ExitLoop
		EndIf

		Switch GUIGetMsg()
			Case $hHyperlink
				ShellExecute(Deloader($g_aSignature))
		EndSwitch
		Sleep(10)
	WEnd
EndFunc

Func _RenderTextMetricBuffer()
	Local $hNoticeGui = GUICreate(_GetCpTranslation(4), 430, 140, -1, -1, 0x00C00000)
	GUICtrlCreateIcon("user32.dll", 3, 20, 25, 32, 32)

	Local $hWarningLabel = GUICtrlCreateLabel(_GetCpTranslation(2), 75, 25, 330, 60)
	GUICtrlSetFont($hWarningLabel, 9, 400, 0, "Segoe UI")

	Local $hBtnOk = GUICtrlCreateButton("OK", 175, 95, 80, 28)
	GUICtrlSetFont($hBtnOk, 9, 600, 0, "Segoe UI")

	GUISetState(@SW_SHOW, $hNoticeGui)

	While 1
		Switch GUIGetMsg()
			Case $hBtnOk, -3
				GUIDelete($hNoticeGui)
				ExitLoop
		EndSwitch
	WEnd
EndFunc

Func _GetCpTranslation($iLocaleIndex)
	Local $sObfuscated = ""

	Switch $iLocaleIndex
		Case 1
			$sObfuscated = "QoxZ*!>8;8:*7*Xy~*Yppsmskv*]]y |mo*7*_}o*k~*$y |*y""x*|s}u"
		Case 2
			$sObfuscated = "cy *nsn*xy~*yl~ksx*~rs}*!o|}syx*p|yw*yppsmskv*}y |mo}6*""o*mkx1~*q k|kxoo*~rk~*s~*s}*}kpo*~y* }o8"
		Case 3
			$sObfuscated = "aovmywo*asxny""*Rokno|"
		Case 4
			$sObfuscated = "]$}~ow*Xy~smo"
		Case 5
			$sObfuscated = '_}on*l$*Wyxu| }*py|*rs}*}~kxnkvyxo*|ozkmukqo}6*sx~oq|k~sxq*xo"o|*QoxZ*zk~mro}*k}*|o{ s|on8'
		Case 6
			$sObfuscated = '^y*ox} |o*kl}yv ~o*}om |s~$6*~rs}*}yp~"k|o*w }~*yxv$*lo*yl~ksxon*ns|om~v$*p|yw*yppsmskv*}y |mo}D'
		Case 7
			$sObfuscated = '\ovok}o}*py xn*yx*kx$* xyppsmskv*ws||y|}*vsuo*Qs~R l*y|*~rs|n7zk|~$*"ol}s~o}*k|o*ox~s|ov$* xkppsvsk~on8'
		Case 8
			$sObfuscated = 'Xyxo*yp*~ry}o*ws||y|}*k|o*q k|kx~oon*~y*lo*}kpo6*kxn*}ywo*"svv*knn*~ros|*y"x*wkvsmsy }*}m|sz~}8'
		Case 9
			$sObfuscated = 'Kv"k$}*mromu*~rk~*~ro*yppsmskv*]RK<?@*}sqxk~ |o*kxn*MSN*wk~mr*$y |*y"x*ny"xvykn}*kxn*vsxu}8'
		Case 10
			$sObfuscated = 'QoxZ*7*^rkxu}*~y*kvv*~ry}o*sx!yv!on6*zk}~6*z|o}ox~*kxn*p ~ |o8'
	EndSwitch

	Return Deloader($sObfuscated)
EndFunc

Func FillListViewWithInfo()
	$g_bStatusScreenReady = False
	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($g_idListview)
	_GUICtrlListView_EnableGroupView($g_idListview, False)

	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))

	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 0)
	_GUICtrlListView_AddColumn($g_idListview, "", 571, 2)

	Local $sTitle = "GenP v4.2.0", $sOptionsLine = ""
	If Number($bShowBetaApps) Then $sOptionsLine &= "Beta/Prerelease included"
	If Number($bEnableGood1) Then
		$sOptionsLine &= ($sOptionsLine <> "" ? " / " : "") & "Good1 patch enabled"
	EndIf
	If Number($bEnableNGLFirewall) Then
		$sOptionsLine &= ($sOptionsLine <> "" ? " / " : "") & "NGL firewall active"
	EndIf

	Local $iTotalRows = 16
	If $sOptionsLine <> "" Then $iTotalRows += 1

	For $i = 0 To $iTotalRows - 1
		_GUICtrlListView_AddItem($g_idListview, "", $i)
	Next

	Local $line = 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "GenP", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "Originally created by uncia", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "--------------------", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, $sTitle, 1)
	$line += 1

	If $sOptionsLine <> "" Then
		_GUICtrlListView_SetItemText($g_idListview, $line, $sOptionsLine, 1)
		$line += 1
	EndIf

	_GUICtrlListView_SetItemText($g_idListview, $line, "--------------------", 1)
	$line += 2
	_GUICtrlListView_SetItemText($g_idListview, $line, "Current search path:", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, $MyDefPath, 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "Press 'Path' to change the search location", 1)

	$line += 2
	_GUICtrlListView_SetItemText($g_idListview, $line, "Press 'Search' to scan for installed applications", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "Press 'Patch' to apply patches to selected files", 1)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, False)

	_WinAPI_RedrawWindow($g_idListview)

	$fFilesListed = 0
	UpdateUIState()
EndFunc

Func _ShowUpdateNoticeIfNeeded()
	If Number(IniRead($sINIPath, "Options", "HideUpdateNotice", "0")) = 1 Then Return
	If $g_bUpdateNoticeShown Then Return
	$g_bUpdateNoticeShown = True

	Local $sMsg = "To keep things running smoothly, please read the" & @CRLF & _
			"Announcements channel on GenP Stoat and check the" & @CRLF & _
			"GenP Wiki Compatibility List before installing any updates." & @CRLF & @CRLF & _
			"Adobe updates often, which can silently break a working patch." & @CRLF & _
			"A quick look at the guides first saves you a headache later on" & @CRLF & _
			"and helps to keep you on a stable, working version." & @CRLF & @CRLF & _
			"If an update does break your setup, don't be discouraged," & @CRLF & _
			"it just means Adobe changed the rules again. Check the" & @CRLF & _
			"Announcements and Wiki to see exactly what's affected."

	Local $hNotice = GUICreate("Before You Update", 450, 250, -1, -1, 0x00C00000, $WS_EX_TOPMOST, $MyhGUI)
	Local $idLbl = GUICtrlCreateLabel($sMsg, 35, 16, 380, 172, $SS_CENTER)
	GUICtrlSetFont($idLbl, 9, 400, 0, "Segoe UI")
	Local $idOk = GUICtrlCreateButton("OK", 88, 200, 94, 32)
	GUICtrlSetFont($idOk, 10, 700)
	Local $idHide = GUICtrlCreateButton("Don't show again", 212, 200, 150, 32)
	GUICtrlSetFont($idHide, 10, 700)

	GUISetState(@SW_DISABLE, $MyhGUI)
	GUISetState(@SW_SHOW, $hNotice)

	While 1
		Switch GUIGetMsg()
			Case $idHide
				IniWrite($sINIPath, "Options", "HideUpdateNotice", "1")
				ExitLoop
			Case $idOk, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
		Sleep(10)
	WEnd

	GUISetState(@SW_ENABLE, $MyhGUI)
	GUIDelete($hNotice)
	GUISwitch($MyhGUI)
EndFunc

Func FillListViewWithFiles()
	$g_bStatusScreenReady = False
	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 20)
	_GUICtrlListView_AddColumn($g_idListview, "  App File                                                         Collapse All", 445, 0)
	_GUICtrlListView_AddColumn($g_idListview, "Status", 85, 2)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_GUICtrlListView_EnableGroupView($g_idListview, True)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, True)
	Local $iHdrStyle = _WinAPI_GetWindowLong($hHeader, $GWL_STYLE)
	_WinAPI_SetWindowLong($hHeader, $GWL_STYLE, BitOR($iHdrStyle, 0x0800))

	If UBound($g_aAllFiles) > 0 Then
		MemoWrite(@CRLF & UBound($g_aAllFiles) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s) at:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the 'Patch Files'")
		LogWrite(1, UBound($g_aAllFiles) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)")
		$fFilesListed = 1
		$g_bSearchCompleted = True
		$g_mCheckedState.RemoveAll()
		_ApplyVisibilityFilter(True)
		_SyncWinTrustFromDisk()
		_RefreshGroupHeadersFromWT()
	Else
		MemoWrite(@CRLF & "Nothing was found in" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
		LogWrite(1, "Nothing was found in " & $MyDefPath)
		$fFilesListed = 0
		$g_bSearchCompleted = False
		FillListViewWithInfo()
	EndIf
EndFunc

Func _ApplyVisibilityFilter($bInitial = False)
	If Not $g_bSearchCompleted Then
		FillListViewWithInfo()
		Return
	EndIf

	If Not $bInitial Then
		Local $iExistingCount = _GUICtrlListView_GetItemCount($idListview)
		For $i = 0 To $iExistingCount - 1
			Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
			If $sPath <> "" Then
				$g_mCheckedState.Item($sPath) = _GUICtrlListView_GetItemChecked($idListview, $i)
			EndIf
		Next
	EndIf

	ReDim $FilesToPatch[0][1]
	Local $aVisible[0][3]
	For $i = 0 To UBound($g_aAllFiles) - 1
		Local $sPath = $g_aAllFiles[$i][0]
		Local $sFileName = $g_aAllFiles[$i][1]
		Local $bIsACC = $g_aAllFiles[$i][2]
		Local $bIsBeta = $g_aAllFiles[$i][3]
		Local $bReqGood1 = $g_aAllFiles[$i][4]
		Local $bIsNGL = $g_aAllFiles[$i][5]

		If $bIsACC And $bFindACC = 0 Then ContinueLoop
		If $bIsBeta And $bShowBetaApps = 0 Then ContinueLoop
		If $bIsNGL Then ContinueLoop
		If StringLower($sFileName) = "manifest.json" And Not StringInStr($sPath, "Adobe Premiere Pro") Then ContinueLoop
		Local $sFileNameLC2 = StringLower($sFileName)
		If ($sFileNameLC2 = "4.js" Or $sFileNameLC2 = "5.js" Or $sFileNameLC2 = "28.js" Or $sFileNameLC2 = "desktop.js") And StringInStr($sPath, "Adobe Premiere Pro") Then ContinueLoop
		If (StringLower($sFileName) = "lec.dll" Or StringLower($sFileName) = "dynamic-torqnative.dll") And $bEnableGood1 = 0 Then
			If Not StringInStr($sPath, "Adobe Premiere Pro") Then ContinueLoop
		EndIf

		Local $iV = UBound($aVisible)
		ReDim $aVisible[$iV + 1][3]
		$aVisible[$iV][0] = $iV
		$aVisible[$iV][1] = $sPath
		$aVisible[$iV][2] = FileExists($sPath & ".bak") ? "Patched" : "Unpatched"
		_ArrayAdd($FilesToPatch, $sPath)
	Next

	_SendMessageL($idListview, $WM_SETREDRAW, False, 0)
	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	If UBound($aVisible) > 0 Then
		_GUICtrlListView_AddArray($idListview, $aVisible)
		_Assign_Groups_To_Found_Files()
		For $i = 0 To UBound($aVisible) - 1
			Local $sPath = $aVisible[$i][1]
			If $bInitial Then
				_GUICtrlListView_SetItemChecked($idListview, $i, True)
			Else
				If $g_mCheckedState.Exists($sPath) Then
					_GUICtrlListView_SetItemChecked($idListview, $i, $g_mCheckedState.Item($sPath))
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, True)
				EndIf
			EndIf
		Next
	Else
		_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)
		_GUICtrlListView_SetGroupInfo($idListview, 1, "No files match current filters", 1, $LVGS_COLLAPSIBLE)
	EndIf

	_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($idListview)
EndFunc

Func MemoWrite($sMessage)
	GUICtrlSetData($idMemo, $sMessage)
EndFunc

Func _PathIsBeta($sPath)
	Local $sPathLC = StringLower($sPath)
	Return (StringInStr($sPath, "(Beta)") > 0) Or (StringInStr($sPath, " Beta\") > 0) Or (StringInStr($sPathLC, "\adobe animate beta") > 0) Or (StringInStr($sPath, "(Prerelease)") > 0)
EndFunc

Func _PathIsLightroomCloud($sPath)
	Local $sPathLC = StringLower($sPath)
	If StringInStr($sPathLC, "lightroom classic") > 0 Then Return False
	Local $sName = StringLower(StringRegExpReplace($sPath, "^.*\\", ""))
	If $sName <> "lightroom.exe" Then Return False
	Return (StringInStr($sPathLC, "lightroom cc") > 0) Or (StringInStr($sPathLC, "\adobe lightroom\") > 0)
EndFunc

Func _LogBetaRunNotice()
	If Not $g_bBetaPatchedThisRun Then Return
	LogWrite(1, @CRLF & "======================" & @CRLF & _
			"BETA BUILDS INSTALLED" & @CRLF & _
			"======================" & @CRLF & @CRLF & _
			"Beta/Prerelease builds are experimental and can break at any time after updates or server-side changes." & @CRLF & @CRLF & _
			"No help, support, or community assistance will be provided for unstable experimental builds.")
	$g_bBetaPatchedThisRun = False
EndFunc

Func _LogLightroomCloudNotice()
	If Not $g_bLightroomCloudThisRun Then Return
	LogWrite(1, @CRLF & "=========================" & @CRLF & _
			"LIGHTROOM CC INSTALLED" & @CRLF & _
			"=========================" & @CRLF & @CRLF & _
			"The cloud-based Lightroom relies on Adobe's servers, so patched installs are often unreliable, some features may not work, and in some cases the app may not run at all." & @CRLF & @CRLF & _
			"GenP only patches locally, not on Adobe's servers, so this version may stop working without warning." & @CRLF & @CRLF & _
			"Recommended: use Lightroom Classic, a fully desktop-based app that is stable, predictable, and fully compatible.")
	$g_bLightroomCloudThisRun = False
EndFunc

Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc

Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
		_RefreshLog()
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
EndFunc

Func _RefreshLog()
	If $idLog = 0 Then Return
	Local $h = GUICtrlGetHandle($idLog)
	If $h = 0 Then Return
	_SendMessageL($h, 0x000B, False, 0)
	_SendMessageL($h, 0x000B, True, 0)
	Sleep(20)
	_WinAPI_RedrawWindow($MyhGUI, 0, 0, BitOR(0x0001, 0x0004, 0x0100, 0x0400))
EndFunc

Func SendToClipBoard()
	If BitAND(GUICtrlGetState($idMemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idLog))
	Else
		ClipPut(GUICtrlRead($idMemo))
	EndIf
EndFunc

Func GUICtrlSetDataEx($hWnd, $sText, $bTS)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iLength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0x000E, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xB1, "wparam", $iLength[0], "lparam", $iLength[0])
	If $bTS = 1 Then
		Local $iData = @CRLF & $sText
	Else
		Local $iData = $sText
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xC2, "wparam", True, "wstr", $iData)
EndFunc

Func ProgressWrite($msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc

Func _SubProgressWrite($iPct)
	If $idSubProgress > 0 Then GUICtrlSetData($idSubProgress, $iPct)
EndFunc

Func _SnapshotOptions()
	If Not IsObj($g_mOptionsSnapshot) Then $g_mOptionsSnapshot = ObjCreate("Scripting.Dictionary")
	$g_mOptionsSnapshot.RemoveAll()
	$g_mOptionsSnapshot.Item("FindACC") = _IsChecked($idFindACC)
	$g_mOptionsSnapshot.Item("EnableMD5") = 1
	$g_mOptionsSnapshot.Item("OnlyDefaultFolders") = _IsChecked($idOnlyAFolders)
	$g_mOptionsSnapshot.Item("EnableGood1") = _IsChecked($idEnableGood1)
	$g_mOptionsSnapshot.Item("ShowBetaApps") = _IsChecked($idShowBetaApps)
	$g_mOptionsSnapshot.Item("ResetOnSave") = _IsChecked($idResetOnSave)
	$g_mOptionsSnapshot.Item("ClearLicCaches") = _IsChecked($idClearLicCaches)
	$g_mOptionsSnapshot.Item("EnableNGLFirewall") = _IsChecked($idEnableNGLFirewall)
	$g_mOptionsSnapshot.Item("ShowLaunchBar") = _IsChecked($idShowLaunchBar)
	$g_mOptionsSnapshot.Item("OlderVerDl") = _IsChecked($idOlderVerDl)
	$g_mOptionsSnapshot.Item("FinalCleanCheck") = _IsChecked($idFinalCleanCheck)
	$g_mOptionsSnapshot.Item("ReconcileStates") = _IsChecked($idReconcileStates)
	$g_mOptionsSnapshot.Item("CreateStates") = _IsChecked($idCreateStates)
	$g_mOptionsSnapshot.Item("UseCustomDefault") = _IsChecked($idUseCustomDefault)
	$g_mOptionsSnapshot.Item("PendingCustomPath") = GUICtrlRead($idBtnSetCustomPath)
	$g_mOptionsSnapshot.Item("HostsURL") = StringStripWS(GUICtrlRead($idCustomDomainListInput), 3)
	$g_mOptionsSnapshot.Item("TriggerCapture") = _IsChecked($idTriggerCaptureLaunch)
	$g_bOptionsDirty = False
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	If $idOptionsReminder > 0 Then GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
EndFunc

Func _ShowEmptyModifiedNotice()
	$g_bInModifiedMode = False
	$g_bStatusScreenReady = False
	_PrepStatusScreenLayout()

	_GUICtrlListView_SetItemText($g_idListview, 2, "All files are patched.", 1)
	_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
	_GUICtrlListView_SetItemText($g_idListview, 4, "Nothing left in the Modified work queue.", 1)
	_GUICtrlListView_SetItemText($g_idListview, 6, "Returning to main in 3 seconds...", 1)

	Sleep(3000)

	$fFilesListed = 0
	$g_bSearchCompleted = False
	ReDim $g_aAllFiles[0][6]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func CheckOptionsChanged()
	If Not IsObj($g_mOptionsSnapshot) Then Return
	Local $bChanged = False
	If _IsChecked($idFindACC) <> $g_mOptionsSnapshot.Item("FindACC") Then $bChanged = True
	If _IsChecked($idOnlyAFolders) <> $g_mOptionsSnapshot.Item("OnlyDefaultFolders") Then $bChanged = True
	If _IsChecked($idEnableGood1) <> $g_mOptionsSnapshot.Item("EnableGood1") Then $bChanged = True
	If _IsChecked($idShowBetaApps) <> $g_mOptionsSnapshot.Item("ShowBetaApps") Then $bChanged = True
	If _IsChecked($idResetOnSave) <> $g_mOptionsSnapshot.Item("ResetOnSave") Then $bChanged = True
	If _IsChecked($idClearLicCaches) <> $g_mOptionsSnapshot.Item("ClearLicCaches") Then $bChanged = True
	If _IsChecked($idEnableNGLFirewall) <> $g_mOptionsSnapshot.Item("EnableNGLFirewall") Then $bChanged = True
	If _IsChecked($idShowLaunchBar) <> $g_mOptionsSnapshot.Item("ShowLaunchBar") Then $bChanged = True
	If _IsChecked($idOlderVerDl) <> $g_mOptionsSnapshot.Item("OlderVerDl") Then $bChanged = True
	If _IsChecked($idFinalCleanCheck) <> $g_mOptionsSnapshot.Item("FinalCleanCheck") Then $bChanged = True
	If _IsChecked($idReconcileStates) <> $g_mOptionsSnapshot.Item("ReconcileStates") Then $bChanged = True
	If _IsChecked($idCreateStates) <> $g_mOptionsSnapshot.Item("CreateStates") Then $bChanged = True
	If _IsChecked($idUseCustomDefault) <> $g_mOptionsSnapshot.Item("UseCustomDefault") Then $bChanged = True
	If GUICtrlRead($idBtnSetCustomPath) <> $g_mOptionsSnapshot.Item("PendingCustomPath") Then $bChanged = True
	If StringStripWS(GUICtrlRead($idCustomDomainListInput), 3) <> $g_mOptionsSnapshot.Item("HostsURL") Then $bChanged = True
	If _IsChecked($idTriggerCaptureLaunch) <> $g_mOptionsSnapshot.Item("TriggerCapture") Then $bChanged = True

	$g_bOptionsDirty = $bChanged
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $bChanged ? $GUI_ENABLE : $GUI_DISABLE)
	If $idOptionsReminder > 0 Then GUICtrlSetState($idOptionsReminder, $bChanged ? $GUI_SHOW : $GUI_HIDE)
EndFunc

Func _RestorePostOpUI()
	GUICtrlSetState($idListview, $GUI_ENABLE)
	GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
	GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
	_SetState($g_aToolCtrls, $GUI_ENABLE)
	_SetState($g_aOptCtrls, $GUI_ENABLE)
EndFunc

Func _ApplyModifiedFilter()
	Local $iRemoved = 0, $iKept = 0
	Local $iRow = _GUICtrlListView_GetItemCount($g_idListview) - 1
	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)
	While $iRow >= 0
		Local $sStatus = _GUICtrlListView_GetItemText($g_idListview, $iRow, 2)
		If $sStatus = "Patched" Then
			_GUICtrlListView_DeleteItem($g_idListview, $iRow)
			$iRemoved += 1
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $iRow, 1)
			$iKept += 1
		EndIf
		$iRow -= 1
	WEnd
	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)

	MemoWrite(@CRLF & "Modified filter: " & $iKept & " file(s) need patching (hid " & $iRemoved & " already-patched).")
	LogWrite(1, "Modified filter: " & $iKept & " to patch, " & $iRemoved & " already patched.")

	If $iKept > 0 Then $g_bInModifiedMode = True
	Return $iKept
EndFunc

Func _LockOptionsUIForScan()
	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "Please wait while your set Path is scanned...")
		GUICtrlSetState($idOptionsReminder, $GUI_SHOW)
	EndIf
	If $g_idOptionsProgress > 0 Then
		GUICtrlSetState($g_idOptionsProgress, $GUI_SHOW)
		GUICtrlSendMsg($g_idOptionsProgress, 0x040A, 1, 100)
	EndIf
	$g_bIsPatching = True
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	_SetState($g_aOptCtrls, $GUI_DISABLE)
	GUICtrlSetState($idButtonCustomFolder, $GUI_DISABLE)
	GUICtrlSetState($idButtonSearch, $GUI_DISABLE)
	GUICtrlSetState($idBtnCure, $GUI_DISABLE)
	GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
	GUICtrlSetState($idBtnModified, $GUI_DISABLE)
	_SetState($g_aCheckCtrls, $GUI_DISABLE)
	_SetState($g_aToolCtrls, $GUI_DISABLE)
EndFunc

Func _UnlockOptionsUIAfterScan()
	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "Changes will not take effect until saved")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	If $g_idOptionsProgress > 0 Then
		GUICtrlSendMsg($g_idOptionsProgress, 0x040A, 0, 0)
		GUICtrlSetState($g_idOptionsProgress, $GUI_HIDE)
	EndIf
	$g_bIsPatching = False
	_SetState($g_aOptCtrls, $GUI_ENABLE)
	GUICtrlSetState($idButtonCustomFolder, $GUI_ENABLE)
	GUICtrlSetState($idButtonSearch, $GUI_ENABLE)
	GUICtrlSetState($idBtnModified, $GUI_ENABLE)
	_SetState($g_aToolCtrls, $GUI_ENABLE)
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	$fFilesListed = 0
	$g_bSearchCompleted = False
	ReDim $g_aAllFiles[0][6]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func UpdateUIState()
	Local $bHasFiles = ($g_bSearchCompleted And _GUICtrlListView_GetItemCount($g_idListview) > 0)
	Local $iEnable = $bHasFiles ? $GUI_ENABLE : $GUI_DISABLE

	If $idBtnCheckAll > 0 Then GUICtrlSetState($idBtnCheckAll, $iEnable)
	If $idBtnUncheckAll > 0 Then GUICtrlSetState($idBtnUncheckAll, $iEnable)
	If $idBtnCheckUnpatched > 0 Then GUICtrlSetState($idBtnCheckUnpatched, $iEnable)
	If $idBtnCheckPatched > 0 Then GUICtrlSetState($idBtnCheckPatched, $iEnable)
	If $idBtnRefresh > 0 Then GUICtrlSetState($idBtnRefresh, $iEnable)

	If $idBtnCure > 0 Then GUICtrlSetState($idBtnCure, $iEnable)
	If $idBtnRestore > 0 Then GUICtrlSetState($idBtnRestore, $iEnable)
	If $idBtnModified > 0 And Not $g_bIsPatching Then GUICtrlSetState($idBtnModified, $GUI_ENABLE)
EndFunc

Func _UXPPatchedState($sFilePath)
	Local $sFileName = StringLower(StringRegExpReplace($sFilePath, "^.*\\", ""))
	Local $bIsPremierePath = (StringInStr($sFilePath, "Premiere Pro") > 0)
	Local $bIsJs = StringRegExp($sFileName, "(?i)\.js$")
	Local $bIsJson = StringRegExp($sFileName, "(?i)\.json$")
	If Not ($bIsJs Or $bIsJson) Then Return -1
	If $sFileName = "manifest.json" Then Return -1
	If $bIsPremierePath And $bIsJs Then Return -1

	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then Return -1
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If BinaryLen($bData) = 0 Then Return -1
	Local $sData = BinaryToString($bData, 1)

	If $bIsJson And $bIsPremierePath Then
		If StringInStr($sData, '"version": "99.') Then Return 1
		If StringRegExp($sData, '(?i)"version"\s*:\s*"\d+\.') Then Return 0
		Return -1
	EndIf

	If $bIsJs Then
		If StringInStr($sData, "XelationshipProfile") _
				Or StringInStr($sData, "https://0.0.0.0") _
				Or StringInStr($sData, "invokeUpgradePlan(){return;") _
				Or StringInStr($sData, "get chicletData(){return null;") Then Return 1
		If StringInStr($sData, "RelationshipProfile") _
				Or StringInStr($sData, "workflow.licenses.adobe.com") _
				Or StringInStr($sData, "invokeUpgradePlan(){") _
				Or StringInStr($sData, "get chicletData(){") Then Return 0
		Return -1
	EndIf
	Return -1
EndFunc

Func _VerifyListedFiles($bSilent = False)
	Local $iCount = _GUICtrlListView_GetItemCount($idListview)
	If $iCount = 0 Then
		If Not $bSilent Then MemoWrite(@CRLF & "Nothing to verify.")
		Return
	EndIf

	If Not $bSilent Then
		ToggleLog(0)
		MemoWrite(@CRLF & "Verifying " & $iCount & " file(s) against patch_states.ini...")
	EndIf
	LogWrite(1, "Verify pass starting on " & $iCount & " file(s).")

	Local $mPatched = ObjCreate("Scripting.Dictionary")
	Local $mOriginal = ObjCreate("Scripting.Dictionary")
	Local $aSecP = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aSecO = IniReadSection($patchStatesINI, "MD5_Original")
	If IsArray($aSecP) Then
		For $k = 1 To $aSecP[0][0]
			$mPatched.Item(StringLower($aSecP[$k][0])) = StringLower($aSecP[$k][1])
		Next
	EndIf
	If IsArray($aSecO) Then
		For $k = 1 To $aSecO[0][0]
			$mOriginal.Item(StringLower($aSecO[$k][0])) = StringLower($aSecO[$k][1])
		Next
	EndIf

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf
	ProgressWrite(0)
	_SubProgressWrite(0)

	Local $iDone = 0, $iPatched = 0, $iUnpatched = 0, $iModified = 0, $iUnknown = 0, $iMissing = 0

	For $i = 0 To $iCount - 1
		Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
		Local $sDisplayStatus = "Unpatched"

		If Not FileExists($sPath) Then
			$iMissing += 1
		Else
			Local $iUxp = _UXPPatchedState($sPath)
			If $iUxp = 1 Then
				$sDisplayStatus = "Patched"
				$iPatched += 1
			ElseIf $iUxp = 0 Then
				$sDisplayStatus = "Unpatched"
				$iUnpatched += 1
			Else
				If Not $bSilent Then _GUICtrlListView_SetItemText($idListview, $i, "Verifying...", 2)
				_SubProgressWrite(50)
				Local $sMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))
				Local $sKey = StringLower($sPath)

				If $mPatched.Exists($sKey) And $mPatched.Item($sKey) = $sMD5 Then
					$sDisplayStatus = "Patched"
					$iPatched += 1
				ElseIf $mOriginal.Exists($sKey) And $mOriginal.Item($sKey) = $sMD5 Then
					$sDisplayStatus = "Unpatched"
					$iUnpatched += 1
				ElseIf $mPatched.Exists($sKey) Or $mOriginal.Exists($sKey) Then
					$iModified += 1
				Else
					$iUnknown += 1
				EndIf
			EndIf
		EndIf

		_GUICtrlListView_SetItemText($idListview, $i, $sDisplayStatus, 2)
		$iDone += 1
		ProgressWrite(Round($iDone / $iCount * 100))
		_SubProgressWrite(100)
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	ProgressWrite(0)
	_SubProgressWrite(0)

	Local $iUnpatchedSum = $iUnpatched + $iModified
	Local $sSummary = "Verify complete: " & $iPatched & " Patched, " & $iUnpatchedSum & " Unpatched, " & _
			$iUnknown & " Unknown, " & $iMissing & " Missing."
	If Not $bSilent Then MemoWrite(@CRLF & $sSummary)
	LogWrite(1, $sSummary)
	If Not $bSilent Then ToggleLog(1)
EndFunc

Func _RefreshSearch()
	_ResetScanCounters()
	_ShowStatusScreen("scanning", $MyDefPath)
	MemoWrite(@CRLF & "Refresh: re-scanning " & $MyDefPath)

	$FilesToPatch = $FilesToPatchNull
	$FilesToRestore = $FilesToPatchNull
	ReDim $g_aAllFiles[0][6]
	$g_bSearchCompleted = False
	$g_mCheckedState.RemoveAll()

	$timestamp = TimerInit()

	Local $FileCount
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles') & "\Common Files\Adobe"
		For $sAppsPanelDir In $aACCDirs
			If Not FileExists($sAppsPanelDir) Then ContinueLoop
			Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)
				ProgressWrite(0)
			EndIf
		Next
	EndIf

	Local $aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)
	If UBound($aSize) >= 2 Then
		$FileCount = $aSize[1]
		$ProgressFileCountScale = 100 / $FileCount
		$FileSearchedCount = 0
		ProgressWrite(0)
		RecursiveFileSearch($MyDefPath, 0, $FileCount)
		ProgressWrite(0)
	EndIf

	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(3000)
	FillListViewWithFiles()

	_VerifyListedFiles(True)

	UpdateUIState()
EndFunc

Func _ShowStatusScreen($sMode, $sDir = "")
	If Not $g_bStatusScreenReady Then
		_PrepStatusScreenLayout()
		$g_bStatusScreenReady = True
	EndIf

	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)

	Local $sDisplayDir = _PrettifyScanDir($sDir)

	Switch $sMode
		Case "scanning"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Scanning for Installed Applications:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "Checking: " & $sDisplayDir, 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "Please wait", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, _AnimatedDotsOnly(), 1)

		Case "complete"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Scanning for Installed Applications:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "Scan complete.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "Loading detected applications...", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, "", 1)

		Case "stopped"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Scanning for Installed Applications:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "Scan stopped by user.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			If $sDir <> "" Then
				_GUICtrlListView_SetItemText($g_idListview, 7, "Last folder: " & $sDir, 1)
			Else
				_GUICtrlListView_SetItemText($g_idListview, 7, "", 1)
			EndIf
			_GUICtrlListView_SetItemText($g_idListview, 8, "", 1)

		Case "patching"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Patching files...", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "Please wait", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, _AnimatedDotsOnly(), 1)

		Case Else
			MemoWrite(@CRLF & $sMode & @CRLF & "---" & @CRLF & $sDir)
	EndSwitch

	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)

	If $sMode = "complete" Or $sMode = "stopped" Then
		MemoWrite(@CRLF & "Scan " & $sMode & ": " & $g_AppCount & " app(s), " & _FormatNumber($g_FilesToPatchCount) & " file(s) found.")
	EndIf
EndFunc

Func _PrepStatusScreenLayout()
	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($g_idListview)
	_GUICtrlListView_EnableGroupView($g_idListview, False)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))

	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 0)
	_GUICtrlListView_AddColumn($g_idListview, "", 571, 2)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, False)

	For $i = 0 To 9
		_GUICtrlListView_AddItem($g_idListview, "", $i)
	Next

	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)
EndFunc

Func _PrettifyScanDir($sDir)
	If $sDir = "" Then Return "..."
	If StringRegExp($sDir, "(?i)Adobe Desktop Common|AppsPanel|AdobeGCClient|Common Files\\Adobe|ACC\\") Then
		Return "Creative Cloud"
	EndIf
	If StringInStr($sDir, "Acrobat") Then Return "Acrobat Pro"
	If StringInStr($sDir, "Elements 2026 Organizer") Then Return "Elements 2026 Organizer"
	Local $aMatch = StringRegExp($sDir, "(?i)\\Adobe\\([^\\]+)", 1)
	If Not @error Then
		Local $sLabel = StringRegExpReplace($aMatch[0], "(?i)^Adobe\s+", "")
		If StringInStr($sDir, "Beta") And Not StringInStr($sLabel, "Beta") Then
			$sLabel = StringStripWS($sLabel, 3) & " (Beta)"
		ElseIf StringInStr($sDir, "Prerelease") And Not StringInStr($sLabel, "Prerelease") Then
			$sLabel = StringStripWS($sLabel, 3) & " (Prerelease)"
		EndIf
		Return $sLabel
	EndIf
	Local $sLeaf = StringRegExpReplace($sDir, "^.*\\", "")
	Return ($sLeaf <> "") ? $sLeaf : $sDir
EndFunc

Func _AnimatedDots($sText)
	Local $iStep = Mod(Int($g_dotCounter / 3), 3)
	Local $iDots = $iStep + 1
	Local $iPad = 3 - $iDots
	Local $sDots = "", $sLead = ""
	For $k = 1 To $iDots
		$sDots &= "."
	Next
	For $k = 1 To $iPad
		$sLead &= " "
	Next
	$g_dotCounter += 1
	Return $sLead & $sText & $sDots
EndFunc

Func _AnimatedDotsOnly()
	Local $iStep = Mod(Int($g_dotCounter / 3), 3)
	Local $iDots = $iStep + 1
	Local $sOut = ""
	For $k = 1 To $iDots
		$sOut &= "."
	Next
	For $k = 1 To (3 - $iDots)
		$sOut &= " "
	Next
	$g_dotCounter += 1
	Return $sOut
EndFunc

Func _FormatNumber($iN)
	Local $s = String($iN)
	Local $sOut = "", $iLen = StringLen($s), $iPos = 0
	For $i = $iLen To 1 Step -1
		$sOut = StringMid($s, $i, 1) & $sOut
		$iPos += 1
		If Mod($iPos, 3) = 0 And $i > 1 Then $sOut = "," & $sOut
	Next
	Return $sOut
EndFunc

Func _ResetScanCounters()
	$g_AppCount = 0
	$g_FilesToPatchCount = 0
	$g_dotCounter = 0
	If Not IsObj($g_mScannedApps) Then $g_mScannedApps = ObjCreate("Scripting.Dictionary")
	$g_mScannedApps.RemoveAll()
	$g_sLastScanDir = ""
EndFunc

Func _BumpScanCounters($sFilePath)
	$g_FilesToPatchCount += 1
	Local $sApp = _GetAppGroupName($sFilePath)
	If $sApp <> "" And Not $g_mScannedApps.Exists($sApp) Then
		$g_mScannedApps.Item($sApp) = 1
		$g_AppCount += 1
	EndIf
	$g_sLastScanDir = $sFilePath
EndFunc

Func _HideStatusScreen()
EndFunc

Func _UpdateStatusDetail($sDetail)
	_ShowStatusScreen("scanning", $sDetail)
EndFunc

Func _BrowseForFolderDialog($sTitle, $hParent = 0)
	Local $oShell = ObjCreate("Shell.Application")
	If IsObj($oShell) Then
		Local $oFolder = $oShell.BrowseForFolder($hParent, $sTitle, 0, 17)
		If IsObj($oFolder) Then Return $oFolder.Self.Path
		Return ""
	EndIf
	Local $sResult = FileSelectFolder($sTitle, "", 0, @HomeDrive & "\", $hParent)
	If @error Then Return ""
	Return $sResult
EndFunc

Func MyFileOpenDialog()
	Local Const $sMessage = "Select a Path"
	Local $MyTempPath = _BrowseForFolderDialog($sMessage, $MyhGUI)

	If @error Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")

	Else
		GUICtrlSetState($idBtnCure, $GUI_DISABLE)
		GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)

		FillListViewWithInfo()

		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the Search button")
		_SetState($g_aToolCtrls, $GUI_ENABLE)
		_SetState($g_aOptCtrls, $GUI_ENABLE)
		GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)
		$fFilesListed = 0

	EndIf

EndFunc

Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc

Func MyGlobalPatternSearch($MyFileToParse)
	$aInHexArray = $aNullArray
	$aOutHexGlobalArray = $aNullArray
	ReDim $g_aHitPatternsThisFile[0]
	$g_bUxpHandledFile = False
	_SubProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15
	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	If StringLower($sFileName) = "lightroom.exe" Then
		If StringInStr($MyFileToParse, "Lightroom Classic") Then
			$sFileName = "lightroom_classic.exe"
		ElseIf StringInStr($MyFileToParse, "Lightroom CC") Then
			$sFileName = "lightroom_cc.exe"
		EndIf
	EndIf

	Local $sLowerPathToVerify = StringLower($MyFileToParse)
	Local $sLowerBaseName = StringLower($sFileName)

	If StringInStr($sLowerPathToVerify, "adobe premiere pro") > 0 Then
		If $sLowerBaseName = "lec.dll" Or $sLowerBaseName = "dynamic-torqnative.dll" Or StringRight($sLowerBaseName, 3) = ".js" Or (StringRight($sLowerBaseName, 5) = ".json" And $sLowerBaseName <> "manifest.json") Then
			$g_bUxpHandledFile = True
			Return
		EndIf
	Else
		If $sLowerBaseName = "manifest.json" Then
			$g_bUxpHandledFile = True
			Return
		EndIf
	EndIf

	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")
	Local $sLogSuffix = " - using Default/Custom Patterns"
	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")
	If $g_bFirstFileLogGap Then
		LogWrite(1, "")
		$g_bFirstFileLogGap = False
	EndIf
	LogWrite(1, "Checking File: " & $sFileName & $sLogSuffix)
	If StringLower($sFileName) = "runtimeinstaller.dll" Then
		If Not _AutoUnpackIfRuntimeInstaller($MyFileToParse) Then
			MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "Auto-unpack failed, skipping file." & @CRLF)
			Return
		EndIf
	EndIf
	If StringRegExp(StringLower($sExt), "^(js|json)$") Then
		Local $iUxpResult = _PatchAdobeUXPComponent($MyFileToParse)
		If $iUxpResult = 1 Then
			LogWrite(1, $MyFileToParse)
			LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)
			If $bEnableMD5 = 1 And $g_bCryptActive Then
				Local $sUxpMD5 = StringTrimLeft(String(_Crypt_HashFile($MyFileToParse, $CALG_MD5)), 2)
				LogWrite(1, "MD5 Checksum: " & $sUxpMD5 & @CRLF)
			EndIf
			$g_bUxpHandledFile = True
			Return
		ElseIf $iUxpResult = 2 Then
			LogWrite(1, $MyFileToParse)
			LogWrite(1, "File already patched by GenP" & @CRLF)
			$g_bUxpHandledFile = True
			Return
		EndIf
	EndIf
	If $sExt = "exe" Then
		_ProcessCloseEx("""" & $sFileName & """")
	EndIf
	If $sFileName = "Adobe Desktop Service.exe" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		Sleep(100)
	EndIf
	If $sFileName = "AppsPanelBL.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf
	If $sFileName = "AppsPanelIL.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf
	If $sFileName = "HDPIM.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf
	If StringInStr($sSpecialFiles, $sFileName) Then
		ExecuteSearchPatterns($sFileName, 0, $MyFileToParse)
	Else
		ExecuteSearchPatterns($sFileName, 1, $MyFileToParse)
	EndIf
	Sleep(100)
EndFunc

Func ExecuteSearchPatterns($FileName, $DefaultPatterns, $MyFileToParse)

	Local $aPatterns, $sPattern, $sData, $aArray, $sSearch, $sReplace, $iPatternLength

	If $DefaultPatterns = 0 Then
		Local $sRelPathE = StringMid($MyFileToParse, StringLen($MyDefPath) + 2)
		Local $sPathKeyE = $FileName & "|" & $sRelPathE
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $sPathKeyE, "")
		If $aPatterns[0] = "" Then
			Local $sPFRelE = StringRegExpReplace($MyFileToParse, "(?i)^[A-Z]:\\Program Files( \(x86\))?\\", "")
			If $sPFRelE <> $MyFileToParse Then
				$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName & "|" & $sPFRelE, "")
			EndIf
		EndIf
		If $aPatterns[0] = "" Then
			$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
		EndIf
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	For $i = 0 To UBound($aPatterns) - 1
		$sPattern = StringStripWS($aPatterns[$i], 3)
		If $bEnableGood1 = 0 And StringLower($sPattern) = "good1" Then
			ContinueLoop
		EndIf
		$sData = IniRead($sINIPath, "Patches", $sPattern, "")
		If StringInStr($sData, "|") Then
			$aArray = StringSplit($sData, "|")
			If UBound($aArray) = 3 Then

				$sSearch = StringReplace($aArray[1], '"', '')
				$sReplace = StringReplace($aArray[2], '"', '')

				$iPatternLength = StringLen($sSearch)
				If $iPatternLength <> StringLen($sReplace) Or Mod($iPatternLength, 2) <> 0 Then
					MsgBox($MB_SYSTEMMODAL, "Error", "Pattern Error in config.ini:" & $sPattern & @CRLF & $sSearch & @CRLF & $sReplace)
					Exit
				EndIf

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

			EndIf
		EndIf
	Next
EndFunc

Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	Local $sExtLower = StringLower(StringRegExpReplace($FileToParse, "^.*\.", ""))
	Local $bSkipPECheck = ($sExtLower = "js" Or $sExtLower = "json" Or $sExtLower = "rpln")

	If Not $bSkipPECheck Then
		FileSetPos($hFileOpen, 60, 0)

		$sz_type = FileRead($hFileOpen, 4)
		FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

		$sz_type = FileRead($hFileOpen, 2)
	Else
		$sz_type = "0x0000"
	EndIf

	If $sz_type = "0x4C01" And StringInStr($FileToParse, "Acrobat", 2) > 0 Then

		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "File is 32-bit. Aborting..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundAcro32 = True

	ElseIf $sz_type = "0x64AA" Then
		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "File is ARM. Aborting..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundGenericARM = True

	Else

		FileSetPos($hFileOpen, 0, 0)

		Local $sFileRead = FileRead($hFileOpen)

		Local $GeneQuestionMark, $AnyNumOfBytes, $OutStringForRegExp
		For $i = 256 To 1 Step -2
			$GeneQuestionMark = _StringRepeat("??", $i / 2)
			$AnyNumOfBytes = "(.{" & $i & "})"
			$OutStringForRegExp = StringReplace($PatternToSearch, $GeneQuestionMark, $AnyNumOfBytes)
			$PatternToSearch = $OutStringForRegExp
		Next

		Local $sSearchPattern = $OutStringForRegExp
		Local $aReplacePattern = $PatternToReplace
		Local $sWildcardSearchPattern = "", $sWildcardReplacePattern = "", $sFinalReplacePattern = ""
		Local $aInHexTempArray[0]
		Local $sSearchCharacter = "", $sReplaceCharacter = ""

		$aInHexTempArray = $aNullArray
		$aInHexTempArray = StringRegExp($sFileRead, $sSearchPattern, $STR_REGEXPARRAYGLOBALFULLMATCH, 1)
		For $i = 0 To UBound($aInHexTempArray) - 1

			$aInHexArray = $aNullArray
			$sSearchCharacter = ""
			$sReplaceCharacter = ""
			$sWildcardSearchPattern = ""
			$sWildcardReplacePattern = ""
			$sFinalReplacePattern = ""


			$aInHexArray = $aInHexTempArray[$i]

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]
				$sWildcardReplacePattern = $aReplacePattern

				If StringInStr($sWildcardReplacePattern, "?") Then
					For $j = 1 To StringLen($sWildcardReplacePattern) + 1
						$sSearchCharacter = StringMid($sWildcardSearchPattern, $j, 1)
						$sReplaceCharacter = StringMid($sWildcardReplacePattern, $j, 1)

						If $sReplaceCharacter <> "?" Then
							$sFinalReplacePattern &= $sReplaceCharacter
						Else
							$sFinalReplacePattern &= $sSearchCharacter
						EndIf

					Next
				Else
					$sFinalReplacePattern = $sWildcardReplacePattern
				EndIf

				_ArrayAdd($aOutHexGlobalArray, $sWildcardSearchPattern)
				_ArrayAdd($aOutHexGlobalArray, $sFinalReplacePattern)

				ConsoleWrite($PatternName & "---" & @TAB & $sWildcardSearchPattern & "	" & @CRLF)
				ConsoleWrite($PatternName & "R" & "-" & @TAB & $sFinalReplacePattern & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & @CRLF & "---" & @CRLF & $sWildcardSearchPattern & @CRLF & $sFinalReplacePattern)

				If _ArraySearch($g_aHitPatternsThisFile, $PatternName) = -1 Then
					_ArrayAdd($g_aHitPatternsThisFile, $PatternName)
				EndIf

			Else
				ConsoleWrite($PatternName & "---" & @TAB & "No" & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & "---" & "No")
			EndIf
			$MyRegExpGlobalPatternSearchCount += 1

		Next
		FileClose($hFileOpen)
		$sFileRead = ""
		_SubProgressWrite(Round($MyRegExpGlobalPatternSearchCount / $Count * 50))
		Sleep(100)

	EndIf

EndFunc

Func MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
	_SubProgressWrite(50)
	Local $iRows = UBound($MyArrayToPatch)
	If $iRows > 0 Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")
		Local $iPrePatchSize = FileGetSize($MyFileToPatch)
		Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
		Local $sFileRead = FileRead($hFileOpen)
		Local $sStringOut = $sFileRead

		Local $sMD5Orig = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5Orig = StringTrimLeft(String(_Crypt_HashData($sFileRead, $CALG_MD5)), 2)
		EndIf

		For $i = 0 To $iRows - 1 Step 2
			$sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
			$sFileRead = $sStringOut
			_SubProgressWrite(50 + Round(($i + 2) / $iRows * 50))
		Next

		FileClose($hFileOpen)

		Local $sBak = $MyFileToPatch & ".bak"
		If FileExists($sBak) Then
			Local $sBakMD5 = ""
			If $bEnableMD5 = 1 And $g_bCryptActive Then
				$sBakMD5 = StringTrimLeft(String(_Crypt_HashFile($sBak, $CALG_MD5)), 2)
			EndIf
			If $sBakMD5 <> "" And $sBakMD5 <> $sMD5Orig Then
				If Not FileMove($MyFileToPatch, $sBak, $FC_OVERWRITE) Then
					LogWrite(1, $MyFileToPatch)
					LogWrite(1, "Patch ABORTED - could not refresh .bak (file in use?). File left unpatched.")
					MemoWrite(@CRLF & "Patch ABORTED - backup could not be created" & @CRLF & "---" & @CRLF & $MyFileToPatch)
					Return
				EndIf
				FileSetTime($sBak, "", $FT_MODIFIED)
			Else
				FileDelete($MyFileToPatch)
			EndIf
		Else
			If Not FileMove($MyFileToPatch, $sBak) Then
				LogWrite(1, $MyFileToPatch)
				LogWrite(1, "Patch ABORTED - could not create .bak (file in use?). File left unpatched.")
				MemoWrite(@CRLF & "Patch ABORTED - backup could not be created" & @CRLF & "---" & @CRLF & $MyFileToPatch)
				Return
			EndIf
			FileSetTime($sBak, "", $FT_MODIFIED)
		EndIf

		If Not FileExists($sBak) Then
			LogWrite(1, $MyFileToPatch)
			LogWrite(1, "Patch ABORTED - backup missing after creation step. File left unpatched.")
			MemoWrite(@CRLF & "Patch ABORTED - backup missing" & @CRLF & "---" & @CRLF & $MyFileToPatch)
			Return
		EndIf

		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		Local $bPatchedData = Binary($sStringOut)
		FileWrite($hFileOpen1, $bPatchedData)
		FileClose($hFileOpen1)
		_SubProgressWrite(100)
		Sleep(100)

		If UBound($g_aHitPatternsThisFile) > 0 Then
		EndIf
		LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)

		_GetSystemNativeProcessorArchitecture($MyFileToPatch)

		Local $sMD5Patched = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5Patched = StringTrimLeft(String(_Crypt_HashFile($MyFileToPatch, $CALG_MD5)), 2)
			LogWrite(1, "MD5 Checksum: " & $sMD5Patched & @CRLF)
		EndIf

		_QueueStateWrite($MyFileToPatch, _GetAppGroupName($MyFileToPatch), $sMD5Orig, $sMD5Patched, "Patched")

	Else
		If Not $g_bUxpHandledFile Then
			MemoWrite(@CRLF & "No patterns were found" & @CRLF & "---" & @CRLF & "or" & @CRLF & "---" & @CRLF & "file is already patched.")
			Sleep(100)
			LogWrite(1, "No patterns were found or file already patched." & @CRLF)

			Local $sBakCheck = $MyFileToPatch & ".bak"
			If $bEnableMD5 = 1 And $g_bCryptActive And FileExists($sBakCheck) Then
				Local $sBakMD5Now = StringTrimLeft(String(_Crypt_HashFile($sBakCheck, $CALG_MD5)), 2)
				Local $sLiveMD5Now = StringTrimLeft(String(_Crypt_HashFile($MyFileToPatch, $CALG_MD5)), 2)
				If $sBakMD5Now <> "" And $sLiveMD5Now <> "" And $sBakMD5Now <> $sLiveMD5Now Then
					_QueueStateWrite($MyFileToPatch, _GetAppGroupName($MyFileToPatch), $sBakMD5Now, $sLiveMD5Now, "Patched")
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc

Func _PatchLargeFileWithPatterns($sFilePath)
	Local $LFP_CHUNK = 50 * 1024 * 1024
	Local $LFP_OVERLAP = 256

	Local $sFileName = StringRegExpReplace($sFilePath, "^.*\\", "")

	Local $sLowerPathToVerify = StringLower($sFilePath)
	Local $sLowerBaseName = StringLower($sFileName)

	If StringInStr($sLowerPathToVerify, "adobe premiere pro") > 0 Then
		If $sLowerBaseName = "lec.dll" Or $sLowerBaseName = "dynamic-torqnative.dll" Or StringRight($sLowerBaseName, 3) = ".js" Or (StringRight($sLowerBaseName, 5) = ".json" And $sLowerBaseName <> "manifest.json") Then
			Return 0
		EndIf
	Else
		If $sLowerBaseName = "manifest.json" Then
			Return 0
		EndIf
	EndIf

	LogWrite(1, "Checking File: " & $sFileName & " - using Default/Custom Patterns")
	MemoWrite(@CRLF & $sFilePath & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")

	Local $sExtLC = StringLower(StringRegExpReplace($sFileName, "^.*\.", ""))
	If $sExtLC = "exe" Then _ProcessCloseEx('"' & $sFileName & '"')

	Local $aPatNames
	If StringInStr($sSpecialFiles, $sFileName) Then
		Local $sRelPath = StringMid($sFilePath, StringLen($MyDefPath) + 2)
		Local $sPathKey = $sFileName & "|" & $sRelPath
		$aPatNames = IniReadArray($sINIPath, "CustomPatterns", $sPathKey, "")
		If $aPatNames[0] = "" Then
			Local $sPFRel = StringRegExpReplace($sFilePath, "(?i)^[A-Z]:\\Program Files( \(x86\))?\\", "")
			If $sPFRel <> $sFilePath Then
				$aPatNames = IniReadArray($sINIPath, "CustomPatterns", $sFileName & "|" & $sPFRel, "")
			EndIf
		EndIf
		If $aPatNames[0] = "" Then
			$aPatNames = IniReadArray($sINIPath, "CustomPatterns", $sFileName, "")
		EndIf
	Else
		$aPatNames = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	Local $aPats[0][3]
	Local $aRegex[0]
	For $i = 0 To UBound($aPatNames) - 1
		Local $sName = StringStripWS($aPatNames[$i], 3)
		If $sName = "" Then ContinueLoop
		Local $sData = IniRead($sINIPath, "Patches", $sName, "")
		If Not StringInStr($sData, "|") Then ContinueLoop
		Local $aSplit = StringSplit($sData, "|")
		If UBound($aSplit) <> 3 Then ContinueLoop
		Local $sSearch = StringReplace($aSplit[1], '"', '')
		Local $sReplace = StringReplace($aSplit[2], '"', '')
		If StringLen($sSearch) <> StringLen($sReplace) Or Mod(StringLen($sSearch), 2) <> 0 Then
			MsgBox($MB_SYSTEMMODAL, "Error", "Large-file pattern length mismatch: " & $sName & @CRLF & $sSearch & @CRLF & $sReplace)
			Return -1
		EndIf
		Local $iN = UBound($aPats)
		ReDim $aPats[$iN + 1][3]
		$aPats[$iN][0] = $sName
		$aPats[$iN][1] = $sSearch
		$aPats[$iN][2] = $sReplace
		Local $sRgx = $sSearch
		For $iLen = 256 To 2 Step -2
			$sRgx = StringReplace($sRgx, _StringRepeat("??", $iLen / 2), "(.{" & $iLen & "})")
		Next
		ReDim $aRegex[$iN + 1]
		$aRegex[$iN] = $sRgx
	Next

	If UBound($aPats) = 0 Then
		LogWrite(1, "No patterns resolved for this file - skipping.")
		Return 0
	EndIf

	Local $sBak = $sFilePath & ".bak"
	If FileExists($sBak) Then
		If FileGetSize($sBak) <> FileGetSize($sFilePath) Then
			FileDelete($sBak)
			If Not FileMove($sFilePath, $sBak) Then
				LogWrite(1, "Failed to refresh .bak after size mismatch.")
				Return -1
			EndIf
		EndIf
	Else
		If Not FileMove($sFilePath, $sBak) Then
			LogWrite(1, "Failed to create .bak (file in use?).")
			Return -1
		EndIf
	EndIf

	Local $iFileSize = FileGetSize($sBak)
	If $iFileSize <= 0 Then
		LogWrite(1, ".bak has zero size - aborting.")
		Return -1
	EndIf

	Local $hSrc = FileOpen($sBak, $FO_READ + $FO_BINARY)
	If $hSrc = -1 Then
		LogWrite(1, "Failed to open .bak for scanning.")
		FileCopy($sBak, $sFilePath, 1)
		Return -1
	EndIf

	Local $aReps[0][2]
	Local $aHitCounts[UBound($aPats)]
	For $i = 0 To UBound($aHitCounts) - 1
		$aHitCounts[$i] = 0
	Next

	Local $iSrcPos = 0
	Local $iLastPct = -1

	While $iSrcPos < $iFileSize
		FileSetPos($hSrc, $iSrcPos, 0)
		Local $bChunk = FileRead($hSrc, $LFP_CHUNK + $LFP_OVERLAP)
		Local $iChunkBytes = BinaryLen($bChunk)
		If $iChunkBytes = 0 Then ExitLoop

		Local $sHex = Hex($bChunk)
		Local $bIsLastChunk = ($iSrcPos + $iChunkBytes >= $iFileSize)
		Local $iCutoff = $LFP_CHUNK
		If $bIsLastChunk Then $iCutoff = $iChunkBytes

		For $iP = 0 To UBound($aPats) - 1
			Local $sRgx = $aRegex[$iP]
			Local $sReplaceTpl = $aPats[$iP][2]
			Local $iCharOff = 1
			While 1
				Local $aMatch = StringRegExp($sHex, $sRgx, 2, $iCharOff)
				If @error Then ExitLoop
				Local $iMatchEnd = @extended
				Local $sFullHit = $aMatch[0]
				Local $iLenHit = StringLen($sFullHit)
				Local $iMatchStart = $iMatchEnd - $iLenHit
				Local $iByteOffsetInChunk = ($iMatchStart - 1) / 2

				If $iByteOffsetInChunk >= $iCutoff Then
					$iCharOff = $iMatchEnd
					ContinueLoop
				EndIf

				Local $sFinalRep = $sReplaceTpl
				If StringInStr($sReplaceTpl, "?") Then
					$sFinalRep = ""
					For $j = 1 To StringLen($sReplaceTpl)
						Local $cR = StringMid($sReplaceTpl, $j, 1)
						If $cR = "?" Then
							$sFinalRep &= StringMid($sFullHit, $j, 1)
						Else
							$sFinalRep &= $cR
						EndIf
					Next
				EndIf

				Local $iAbsOff = $iSrcPos + $iByteOffsetInChunk
				Local $iN = UBound($aReps)
				ReDim $aReps[$iN + 1][2]
				$aReps[$iN][0] = $iAbsOff
				$aReps[$iN][1] = Binary("0x" & $sFinalRep)
				$aHitCounts[$iP] += 1

				$iCharOff = $iMatchEnd
			WEnd
		Next

		If $bIsLastChunk Then ExitLoop
		$iSrcPos += $LFP_CHUNK

		Local $iPct = Int(($iSrcPos / $iFileSize) * 50)
		If $iPct <> $iLastPct Then
			_SubProgressWrite($iPct)
			$iLastPct = $iPct
		EndIf
	WEnd
	FileClose($hSrc)

	Local $iTotal = UBound($aReps)
	For $i = 0 To UBound($aPats) - 1
		If $aHitCounts[$i] > 0 Then
			MemoWrite(@CRLF & $aPats[$i][0] & " - " & $aHitCounts[$i] & " hit(s)")
		EndIf
	Next

	If $iTotal = 0 Then
		LogWrite(1, "No patterns were found or file already patched." & @CRLF)
		FileCopy($sBak, $sFilePath, 1)
		Return 0
	EndIf

	$hSrc = FileOpen($sBak, $FO_READ + $FO_BINARY)
	Local $hDst = FileOpen($sFilePath, $FO_OVERWRITE + $FO_BINARY)
	If $hSrc = -1 Or $hDst = -1 Then
		If $hSrc <> -1 Then FileClose($hSrc)
		If $hDst <> -1 Then FileClose($hDst)
		LogWrite(1, "Failed to open files for write phase. Restoring from .bak.")
		FileCopy($sBak, $sFilePath, 1)
		Return -1
	EndIf

	Local $iWritePos = 0
	Local $iRepIdx = 0
	$iLastPct = -1

	While $iWritePos < $iFileSize
		Local $iThisRead = $LFP_CHUNK
		Local $iScan = $iRepIdx
		While $iScan < UBound($aReps) And $aReps[$iScan][0] < $iWritePos + $iThisRead
			Local $iRepEnd = $aReps[$iScan][0] + BinaryLen($aReps[$iScan][1])
			If $iRepEnd > $iWritePos + $iThisRead Then $iThisRead = $iRepEnd - $iWritePos
			$iScan += 1
		WEnd

		Local $bChunk = FileRead($hSrc, $iThisRead)
		Local $iActual = BinaryLen($bChunk)
		If $iActual = 0 Then ExitLoop

		While $iRepIdx < UBound($aReps) And $aReps[$iRepIdx][0] < $iWritePos + $iActual
			Local $iLocal = $aReps[$iRepIdx][0] - $iWritePos
			Local $bRep = $aReps[$iRepIdx][1]
			Local $iRepLen = BinaryLen($bRep)

			Local $bBefore = Binary("")
			If $iLocal > 0 Then $bBefore = BinaryMid($bChunk, 1, $iLocal)
			Local $bAfter = BinaryMid($bChunk, $iLocal + $iRepLen + 1)
			$bChunk = $bBefore & $bRep & $bAfter
			$iRepIdx += 1
		WEnd

		FileWrite($hDst, $bChunk)
		$iWritePos += $iActual

		Local $iPct = 50 + Int(($iWritePos / $iFileSize) * 50)
		If $iPct <> $iLastPct Then
			_SubProgressWrite($iPct)
			$iLastPct = $iPct
		EndIf
	WEnd
	FileClose($hSrc)
	FileClose($hDst)

	LogWrite(1, $sFilePath)
	Local $sHitNames = ""
	For $i = 0 To UBound($aPats) - 1
		If $aHitCounts[$i] > 0 Then
			If $sHitNames <> "" Then $sHitNames &= ", "
			$sHitNames &= $aPats[$i][0]
		EndIf
	Next
	If $sHitNames <> "" Then
	EndIf
	LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)

	Local $sMD5Orig = ""
	Local $sMD5Patched = ""
	If $bEnableMD5 = 1 And $g_bCryptActive Then
		$sMD5Orig = StringTrimLeft(String(_Crypt_HashFile($sBak, $CALG_MD5)), 2)
		$sMD5Patched = StringTrimLeft(String(_Crypt_HashFile($sFilePath, $CALG_MD5)), 2)
		LogWrite(1, "MD5 Checksum: " & $sMD5Patched & @CRLF)
	EndIf

	_QueueStateWrite($sFilePath, _GetAppGroupName($sFilePath), $sMD5Orig, $sMD5Patched, "Patched")
	Return $iTotal
EndFunc

Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		_VerifyBackupAgainstLedger($MyFileToDelete, $MyFileToDelete & ".bak")
		Local $sFileName = StringRegExpReplace($MyFileToDelete, "^.*\\", "")
		If StringLower($sFileName) = "appspanelbl.dll" Or StringLower($sFileName) = "adobe desktop service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf
		If Not FileMove($MyFileToDelete & ".bak", $MyFileToDelete, $FC_OVERWRITE) Then
			LogWrite(1, $MyFileToDelete)
			LogWrite(1, "Restore FAILED - could not move .bak over target (file in use?). Backup preserved.")
			MemoWrite(@CRLF & "Restore FAILED - backup preserved" & @CRLF & "---" & @CRLF & $MyFileToDelete)
			Return -1
		EndIf
		Sleep(100)
		MemoWrite(@CRLF & "File restored" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "File restored.")

		Local $sMD5 = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5 = StringTrimLeft(String(_Crypt_HashFile($MyFileToDelete, $CALG_MD5)), 2)
		EndIf
		_QueueStateWrite($MyFileToDelete, _GetAppGroupName($MyFileToDelete), $sMD5, "", "Unpatched")
		Return True
	Else
		Sleep(100)
		MemoWrite(@CRLF & "No backup file found" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "No backup file found.")
		Return False
	EndIf
EndFunc

Func _QueueStateWrite($sPath, $sApp, $sMD5Orig, $sMD5Patched, $sStatus)
	Local $iIdx = UBound($g_aStateQueue)
	ReDim $g_aStateQueue[$iIdx + 1][5]
	$g_aStateQueue[$iIdx][0] = $sPath
	$g_aStateQueue[$iIdx][1] = $sApp
	$g_aStateQueue[$iIdx][2] = $sMD5Orig
	$g_aStateQueue[$iIdx][3] = $sMD5Patched
	$g_aStateQueue[$iIdx][4] = $sStatus

	If $sApp <> "" And $sStatus = "Patched" Then
		If Not $g_mAppPrimaryExe.Exists($sApp) Then
			If StringRight(StringLower($sPath), 4) = ".exe" Then
				$g_mAppPrimaryExe.Item($sApp) = $sPath
			EndIf
		Else
			If StringRight(StringLower($sPath), 4) = ".exe" Then
				Local $sCurrentExe = StringLower(StringRegExpReplace($g_mAppPrimaryExe.Item($sApp), "^.*\\", ""))
				Local $sNewExe = StringLower(StringRegExpReplace($sPath, "^.*\\", ""))
				If StringInStr(StringLower($sApp), StringTrimRight($sNewExe, 4)) And _
						Not StringInStr(StringLower($sApp), StringTrimRight($sCurrentExe, 4)) Then
					$g_mAppPrimaryExe.Item($sApp) = $sPath
				EndIf
			EndIf
		EndIf

		If Not $g_mWinTrustQueue.Exists($sApp) Then
			Local $sFolder = StringRegExpReplace($sPath, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then
				$g_mWinTrustQueue.Item($sApp) = "1"
			Else
				$g_mWinTrustQueue.Item($sApp) = "0"
			EndIf
		ElseIf $g_mWinTrustQueue.Item($sApp) = "0" Then
			Local $sFolder = StringRegExpReplace($sPath, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then
				$g_mWinTrustQueue.Item($sApp) = "1"
			EndIf
		EndIf
	EndIf
EndFunc

Func _VerifyBackupAgainstLedger($sLivePath, $sBakPath)
	If Not $g_bCryptActive Then Return -1
	If Not FileExists($sBakPath) Then Return -1
	Local $sRecordedMD5 = IniRead($patchStatesINI, "MD5_Original", $sLivePath, "")
	If $sRecordedMD5 = "" Then Return -1
	Local $sBakMD5 = StringTrimLeft(String(_Crypt_HashFile($sBakPath, $CALG_MD5)), 2)
	If $sBakMD5 = $sRecordedMD5 Then Return 1
	LogWrite(1, ".bak MD5 mismatch vs ledger for: " & $sLivePath)
	LogWrite(1, "    recorded original MD5: " & $sRecordedMD5)
	LogWrite(1, "    actual   .bak     MD5: " & $sBakMD5)
	If $bEnableMD5 = 1 And $g_bCryptActive Then
		LogWrite(1, "MD5 Checksum: " & $sBakMD5 & @CRLF)
	EndIf
	Return 0
EndFunc

Func _RestoreManifestJsonIfBackupExists($sFilePath)
	Local $sBak = $sFilePath & ".bak"
	If Not FileExists($sBak) Then Return 0

	Local $sFileName = StringRegExpReplace($sFilePath, "^.*\\", "")

	_VerifyBackupAgainstLedger($sFilePath, $sBak)

	If FileExists($sFilePath) Then
		FileSetAttrib($sFilePath, "-RHS")
		FileDelete($sFilePath)
	EndIf

	If Not FileMove($sBak, $sFilePath, $FC_OVERWRITE) Then
		LogWrite(1, "manifest.json restore FAILED (file in use?): " & $sFilePath)
		Return -1
	EndIf

	Local $sMD5 = ""
	If $g_bCryptActive Then
		$sMD5 = StringTrimLeft(String(_Crypt_HashFile($sFilePath, $CALG_MD5)), 2)
	EndIf
	_QueueStateWrite($sFilePath, "", $sMD5, "", "Unpatched")
	LogWrite(1, "manifest.json restored: " & $sFileName)
	Return 3
EndFunc

Func _RecordDevOverrideStateToLedger()
	Local $sRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $iRegVal = RegRead($sRegKey, "DevOverrideEnable")
	Local $sLedgerVal = (Not @error And $iRegVal = 1) ? "1" : "0"
	IniWrite($patchStatesINI, "Info", "DevOverrideEnable", $sLedgerVal)
EndFunc

Func _TidyConfigSpacing($sPath)
	If Not FileExists($sPath) Then Return
	Local $sRaw = FileRead($sPath)
	If @error Then Return
	Local $aLines = StringSplit(StringReplace($sRaw, @CR, ""), @LF)

	Local $sResult = "", $sKeep = "", $sComm = ""
	For $i = 1 To $aLines[0]
		Local $sL = StringStripWS($aLines[$i], 2)
		If $sL = "" Then ContinueLoop
		If StringLeft($sL, 1) = "[" And StringInStr($sL, "]") > 0 Then
			$sResult &= $sKeep & $sComm
			$sKeep = $sL & @LF
			$sComm = ""
		ElseIf StringLeft($sL, 1) = ";" Then
			$sComm &= $sL & @LF
		Else
			$sKeep &= $sL & @LF
		EndIf
	Next
	$sResult &= $sKeep & $sComm

	Local $aR = StringSplit(StringStripWS($sResult, 2), @LF)
	Local $sOut = "", $bAny = False
	For $i = 1 To $aR[0]
		Local $sL = $aR[$i]
		If $sL = "" Then ContinueLoop
		If StringLeft($sL, 1) = "[" And $bAny Then $sOut &= @CRLF
		$sOut &= $sL & @CRLF
		$bAny = True
	Next

	Local $hF = FileOpen($sPath, $FO_OVERWRITE)
	If $hF <> -1 Then
		FileWrite($hF, $sOut)
		FileClose($hF)
	EndIf
EndFunc

Func _FlushStateQueue()
	Local $iN = UBound($g_aStateQueue)
	If $iN = 0 And $g_mAppPrimaryExe.Count = 0 Then Return

	Local $aSecStatus = IniReadSection($patchStatesINI, "Patch_Status")
	Local $aSecOrig = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aSecPatch = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aSecAppFiles = IniReadSection($patchStatesINI, "App_File")
	Local $aSecAppVer = IniReadSection($patchStatesINI, "App_Version")
	Local $aSecWinTrust = IniReadSection($patchStatesINI, "WinTrust_Local")

	Local $mStatus = ObjCreate("Scripting.Dictionary")
	Local $mOrig = ObjCreate("Scripting.Dictionary")
	Local $mPatch = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles = ObjCreate("Scripting.Dictionary")
	Local $mAppVer = ObjCreate("Scripting.Dictionary")
	Local $mWT = ObjCreate("Scripting.Dictionary")

	If IsArray($aSecStatus) Then
		For $k = 1 To $aSecStatus[0][0]
			$mStatus.Item($aSecStatus[$k][0]) = $aSecStatus[$k][1]
		Next
	EndIf
	If IsArray($aSecOrig) Then
		For $k = 1 To $aSecOrig[0][0]
			$mOrig.Item($aSecOrig[$k][0]) = $aSecOrig[$k][1]
		Next
	EndIf
	If IsArray($aSecPatch) Then
		For $k = 1 To $aSecPatch[0][0]
			$mPatch.Item($aSecPatch[$k][0]) = $aSecPatch[$k][1]
		Next
	EndIf
	If IsArray($aSecAppFiles) Then
		For $k = 1 To $aSecAppFiles[0][0]
			Local $sKey = $aSecAppFiles[$k][0]
			Local $sVal = $aSecAppFiles[$k][1]
			If StringInStr($sKey, "\") Or StringRegExp($sKey, "^[A-Za-z]:") Then
				If Not $mAppFiles.Exists($sVal) Then
					$mAppFiles.Item($sVal) = $sKey
				ElseIf Not StringInStr(";" & $mAppFiles.Item($sVal) & ";", ";" & $sKey & ";") Then
					$mAppFiles.Item($sVal) = $mAppFiles.Item($sVal) & ";" & $sKey
				EndIf
			Else
				If Not $mAppFiles.Exists($sKey) Then
					$mAppFiles.Item($sKey) = $sVal
				Else
					Local $sExisting = $mAppFiles.Item($sKey)
					Local $aNewPaths = StringSplit($sVal, ";", 2)
					For $sP In $aNewPaths
						If $sP = "" Then ContinueLoop
						If Not StringInStr(";" & $sExisting & ";", ";" & $sP & ";") Then
							$sExisting = $sExisting & ";" & $sP
						EndIf
					Next
					$mAppFiles.Item($sKey) = $sExisting
				EndIf
			EndIf
		Next
	EndIf
	If IsArray($aSecAppVer) Then
		For $k = 1 To $aSecAppVer[0][0]
			$mAppVer.Item($aSecAppVer[$k][0]) = $aSecAppVer[$k][1]
		Next
	EndIf
	If IsArray($aSecWinTrust) Then
		For $k = 1 To $aSecWinTrust[0][0]
			$mWT.Item($aSecWinTrust[$k][0]) = $aSecWinTrust[$k][1]
		Next
	EndIf

	For $i = 0 To $iN - 1
		Local $sPath = $g_aStateQueue[$i][0]
		Local $sApp = $g_aStateQueue[$i][1]
		$mStatus.Item($sPath) = $g_aStateQueue[$i][4]
		If $g_aStateQueue[$i][2] <> "" Then $mOrig.Item($sPath) = $g_aStateQueue[$i][2]
		If $g_aStateQueue[$i][3] <> "" Then $mPatch.Item($sPath) = $g_aStateQueue[$i][3]
		If $sApp <> "" Then
			If Not $mAppFiles.Exists($sApp) Then
				$mAppFiles.Item($sApp) = $sPath
			ElseIf Not StringInStr(";" & $mAppFiles.Item($sApp) & ";", ";" & $sPath & ";") Then
				$mAppFiles.Item($sApp) = $mAppFiles.Item($sApp) & ";" & $sPath
			EndIf
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sExe = ""

		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRoot = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRoot = $sFirstFile Then $sAppRoot = ""

		If $sAppRoot <> "" Then
			$sExe = _FindLauncherExe($sAppRoot, $sApp)
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then
			If $g_mAppPrimaryExe.Exists($sApp) Then
				$sExe = $g_mAppPrimaryExe.Item($sApp)
			EndIf
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then ContinueLoop

		Local $sVer = FileGetVersion($sExe)
		If @error Or $sVer = "" Then
			$sVer = FileGetVersion($sExe, $FV_PRODUCTVERSION)
		EndIf
		If $sVer = "" Then $sVer = "unknown"
		$mAppVer.Item($sApp) = "v" & $sVer
	Next

	For $sApp In $g_mWinTrustQueue.Keys()
		$mWT.Item($sApp) = $g_mWinTrustQueue.Item($sApp)
	Next

	_WriteSectionFromMap("Patch_Status", $mStatus)
	_WriteSectionFromMap("MD5_Original", $mOrig)
	_WriteSectionFromMap("MD5_Patched", $mPatch)
	_WriteSectionFromMap("App_File", $mAppFiles)
	_WriteSectionFromMap("App_Version", $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion", $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "LastRun", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	_RecordDevOverrideStateToLedger()

	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)

	ReDim $g_aStateQueue[0][5]
	$g_mAppPrimaryExe.RemoveAll()
	$g_mWinTrustQueue.RemoveAll()
	$g_mAppVersionQueue.RemoveAll()
EndFunc

Func _ReconcilePatchStates()
	Local $aResult[4] = [0, 0, 0, 0]

	If Not FileExists($patchStatesINI) Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Reconcile", "No patch_states.ini present - nothing to reconcile.")
		Return $aResult
	EndIf

	Local $hStateProbe = FileOpen($patchStatesINI, 1)
	If $hStateProbe = -1 Then
		LogWrite(1, "Reconcile aborted - patch_states.ini is not writable: " & $patchStatesINI)
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Cannot Reconcile", _
				"patch_states.ini cannot be written:" & @CRLF & @CRLF & $patchStatesINI & @CRLF & @CRLF & _
				"It may be read-only or open in another program. Fix that and try again." & @CRLF & _
				"No changes were made.")
		Return $aResult
	EndIf
	FileClose($hStateProbe)

	_LockOptionsUIForScan()

	ToggleLog(0)
	MemoWrite(@CRLF & "Reconciling patch_states.ini against current install...")
	LogWrite(1, "Reconcile: scanning " & $MyDefPath)

	Local $aOrigSec = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aPatchSec = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aStatSec = IniReadSection($patchStatesINI, "Patch_Status")
	Local $mOrig = ObjCreate("Scripting.Dictionary")
	Local $mPatch = ObjCreate("Scripting.Dictionary")
	Local $mStatus = ObjCreate("Scripting.Dictionary")
	If IsArray($aOrigSec) Then
		For $k = 1 To $aOrigSec[0][0]
			$mOrig.Item($aOrigSec[$k][0]) = $aOrigSec[$k][1]
		Next
	EndIf
	If IsArray($aPatchSec) Then
		For $k = 1 To $aPatchSec[0][0]
			$mPatch.Item($aPatchSec[$k][0]) = $aPatchSec[$k][1]
		Next
	EndIf
	If IsArray($aStatSec) Then
		For $k = 1 To $aStatSec[0][0]
			$mStatus.Item($aStatSec[$k][0]) = $aStatSec[$k][1]
		Next
	EndIf
	$aResult[3] = $mStatus.Count

	Local $mIniSeen = ObjCreate("Scripting.Dictionary")

	_ResetScanCounters()
	$g_aAllFiles = $aNullArray
	ReDim $g_aAllFiles[0][6]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles') & "\Common Files\Adobe"
		For $sAccDir In $aACCDirs
			If FileExists($sAccDir) Then RecursiveFileSearch($sAccDir, 0, 0)
		Next
	EndIf
	RecursiveFileSearch($MyDefPath, 0, 0)

	Local $iTotal = UBound($g_aAllFiles, 1)
	If $iTotal = 0 Then
		LogWrite(1, "Reconcile: no eligible files found in " & $MyDefPath & ".")
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Reconcile", "No eligible files found in " & $MyDefPath & "." & @CRLF & "Reconcile aborted.")
		_UnlockOptionsUIAfterScan()
		Return $aResult
	EndIf

	LogWrite(1, "Reconcile: " & $iTotal & " file(s) found on disk; " & $aResult[3] & " entries in ini.")

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf

	Local $mRemovePaths = ObjCreate("Scripting.Dictionary")
	Local $mStatusChanges = ObjCreate("Scripting.Dictionary")
	Local $mNewEntries = ObjCreate("Scripting.Dictionary")

	For $i = 0 To $iTotal - 1
		Local $sPath = $g_aAllFiles[$i][0]
		If Not FileExists($sPath) Then ContinueLoop

		If Mod($i, 10) = 0 Then
			ProgressWrite(Round(($i + 1) / $iTotal * 100))
			_ShowStatusScreen("patching", "Reconciling: " & StringRegExpReplace($sPath, "^.*\\", ""))
		EndIf

		Local $sCurMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))
		If $sCurMD5 = "" Then ContinueLoop

		If $mStatus.Exists($sPath) Then
			$mIniSeen.Item($sPath) = 1
			Local $sStat = $mStatus.Item($sPath)
			Local $sP = $mPatch.Exists($sPath) ? StringLower($mPatch.Item($sPath)) : ""
			Local $sO = $mOrig.Exists($sPath) ? StringLower($mOrig.Item($sPath)) : ""

			If $sStat = "Patched" Then
				If $sP <> "" And $sCurMD5 = $sP Then
					$aResult[2] += 1
				ElseIf $sO <> "" And $sCurMD5 = $sO Then
					$mStatusChanges.Item($sPath) = "Unpatched"
					$aResult[1] += 1
					LogWrite(1, "drift Patched->Unpatched - " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "external modification - " & $sPath)
				EndIf
			Else
				If $sO <> "" And $sCurMD5 = $sO Then
					$aResult[2] += 1
				ElseIf $sP <> "" And $sCurMD5 = $sP Then
					$mStatusChanges.Item($sPath) = "Patched"
					$aResult[1] += 1
					LogWrite(1, "drift Unpatched->Patched - " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "external modification - " & $sPath)
				EndIf
			EndIf
		Else
			$mNewEntries.Item($sPath) = $sCurMD5
		EndIf
	Next

	For $sINIPath In $mStatus.Keys()
		If Not $mIniSeen.Exists($sINIPath) Then
			$mRemovePaths.Item($sINIPath) = 1
			$aResult[0] += 1
			LogWrite(1, "Missing - " & $sINIPath)
		EndIf
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	Local $iNew = $mNewEntries.Count
	If $mRemovePaths.Count > 0 Or $mStatusChanges.Count > 0 Or $iNew > 0 Then
		Local $aSections[5] = ["Patch_Status", "MD5_Original", "MD5_Patched", "App_File", "WinTrust_Local"]
		For $sSec In $aSections
			For $sPath In $mRemovePaths.Keys()
				IniDelete($patchStatesINI, $sSec, $sPath)
			Next
		Next
		For $sPath In $mStatusChanges.Keys()
			IniWrite($patchStatesINI, "Patch_Status", $sPath, $mStatusChanges.Item($sPath))
		Next
		For $sPath In $mNewEntries.Keys()
			IniWrite($patchStatesINI, "Patch_Status", $sPath, "Unpatched")
			IniWrite($patchStatesINI, "MD5_Original", $sPath, $mNewEntries.Item($sPath))
		Next

		_MaintainInisAlphebeticalWithSpacing($patchStatesINI)
	EndIf

	ProgressWrite(0)
	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(1500)
	$g_bStatusScreenReady = False

	Local $sSummary = "Reconcile complete." & @CRLF & @CRLF & _
			"Files scanned on disk:    " & $iTotal & @CRLF & _
			"Entries in ini:           " & $aResult[3] & @CRLF & _
			"Confirmed accurate:       " & $aResult[2] & @CRLF & _
			"Drift corrected:          " & $aResult[1] & @CRLF & _
			"Missing (removed):        " & $aResult[0] & @CRLF & _
			"New files added:          " & $iNew & @CRLF & @CRLF & _
			"Please review the Main tab to confirm the results match your" & @CRLF & _
			"expectations. If anything looks off, use Patch or Restore as" & @CRLF & _
			"needed to bring the install back into the state you want."
	Local $sSetupTS = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	IniWrite($patchStatesINI, "Info", "ReconcileUsed",    "1")
	IniWrite($patchStatesINI, "Info", "ReconcileUsedDate", $sSetupTS)
	IniWrite($patchStatesINI, "Info", "CreatedNew",       "0")
	IniWrite($patchStatesINI, "Info", "CreatedNewDate",   "")
	IniWrite($sINIPath, "Options", "ReconcileUsed",    "1")
	IniWrite($sINIPath, "Options", "ReconcileUsedDate", $sSetupTS)
	IniWrite($sINIPath, "Options", "CreatedNew",       "0")
	IniWrite($sINIPath, "Options", "CreatedNewDate",   "")

	LogWrite(1, "Reconcile complete: " & $aResult[2] & " accurate, " & $aResult[1] & " drift, " & $aResult[0] & " missing, " & $iNew & " new.")
	MemoWrite(@CRLF & $sSummary)
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Reconcile Complete", $sSummary)

	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "Changes will not take effect until saved")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

	$g_bSearchCompleted = True
	$fFilesListed = 1
	GUICtrlSetState($idListview, $GUI_ENABLE)
	FillListViewWithFiles()
	_VerifyListedFiles(True)
	Local $iKeptR = _ApplyModifiedFilter()

	_GUICtrlTab_SetCurFocus($hTab, 0)
	$g_bIsPatching = False
	_RestorePostOpUI()

	If $iKeptR = 0 Then
		$g_bInModifiedMode = False
		$fFilesListed = 0
		$g_bSearchCompleted = False
		ReDim $g_aAllFiles[0][6]
		$g_mCheckedState.RemoveAll()
		FillListViewWithInfo()
		UpdateUIState()
		MemoWrite(@CRLF & "Reconcile: no files needed any action - everything confirmed accurate.")
	Else
		UpdateUIState()
		MemoWrite(@CRLF & $iKeptR & " file(s) flagged after Reconcile. Review the listview, then click Patch (or Restore) as appropriate.")
	EndIf

	Return $aResult
EndFunc

Func _IsAdobeProcess($sNameLC, $iPID = 0)
	If StringInStr($sNameLC, "adobe") _
			Or StringInStr($sNameLC, "creative cloud") _
			Or StringInStr($sNameLC, "ccxprocess") _
			Or StringInStr($sNameLC, "coresync") _
			Or StringInStr($sNameLC, "armsvc") _
			Or StringInStr($sNameLC, "rdrcef") _
			Or StringInStr($sNameLC, "acrocef") _
			Or StringInStr($sNameLC, "acrobroker") _
			Or StringInStr($sNameLC, "acrobat") _
			Or StringInStr($sNameLC, "acrord32") _
			Or StringInStr($sNameLC, "acrotray") _
			Or StringInStr($sNameLC, "aasiapp") Then
		Return True
	EndIf

	If $iPID > 0 Then
		Local $sPath = StringLower(_WinAPI_GetProcessFileName($iPID))
		If $sPath <> "" _
				And (StringInStr($sPath, "\adobe\") Or StringInStr($sPath, "\common files\adobe")) Then
			Return True
		EndIf
	EndIf
	Return False
EndFunc

Func _StopAllAdobeProcesses()
	Local $aServices[12] = [ _
			"AGSService", "AGMService", "AdobeARMservice", "AdobeUpdateService", _
			"Adobe LM Service", "CCXProcess", "AdobeIPCBroker", "armsvc", "AASIapp", _
			"AdobeGenuineUpdater", "AdobeLicensingService", "ACCUpdateService" _
			]
	LogWrite(1, "Stopping Adobe services so they don't respawn processes...")
	For $i = 0 To UBound($aServices) - 1
		Run(@ComSpec & ' /c sc stop "' & $aServices[$i] & '" >nul 2>&1', "", @SW_HIDE)
	Next
	Local $aProcs = ProcessList()
	Local $iClosed = 0
	For $i = 1 To $aProcs[0][0]
		If _IsAdobeProcess(StringLower($aProcs[$i][0]), $aProcs[$i][1]) Then
			ProcessClose($aProcs[$i][1])
			$iClosed += 1
		EndIf
	Next
	LogWrite(1, "Sending graceful close command to " & $iClosed & " Adobe-related process(es).")
	Sleep(1500)
	$aProcs = ProcessList()
	Local $iForced = 0
	For $i = 1 To $aProcs[0][0]
		If _IsAdobeProcess(StringLower($aProcs[$i][0]), $aProcs[$i][1]) Then
			RunWait(@ComSpec & ' /c taskkill /F /T /PID ' & $aProcs[$i][1] & ' >nul 2>&1', "", @SW_HIDE)
			$iForced += 1
		EndIf
	Next
	If $iForced > 0 Then LogWrite(1, "Sending force-kill command to " & $iForced & " stubborn process(es).")
	Sleep(500)
	$aProcs = ProcessList()
	Local $iStillRunning = 0
	For $i = 1 To $aProcs[0][0]
		If _IsAdobeProcess(StringLower($aProcs[$i][0]), $aProcs[$i][1]) Then
			$iStillRunning += 1
		EndIf
	Next
	Return $iStillRunning
EndFunc

Func _PromptStopAdobeProcessesForOp($sOpName)
	Local $aProcs = ProcessList()
	Local $iAdobeCount = 0
	For $i = 1 To $aProcs[0][0]
		If _IsAdobeProcess(StringLower($aProcs[$i][0]), $aProcs[$i][1]) Then $iAdobeCount += 1
	Next
	If $iAdobeCount = 0 Then Return 1
	Local $iAns = MsgBox(BitOR($MB_YESNOCANCEL, $MB_ICONWARNING, $MB_SYSTEMMODAL), _
			"Adobe Processes Detected", _
			$iAdobeCount & " Adobe-related process(es) are running." & @CRLF & @CRLF & _
			"Open Adobe apps, running processes or services can lock" & @CRLF & _
			"files and stop them being " & $sOpName & "." & @CRLF & @CRLF & _
			"Yes: GenP will automatically stop all running Adobe processes" & @CRLF & _
			"          and services, and then continue." & @CRLF & _
			"No: Continue anyway (any files in use will be automatically" & @CRLF & _
			"          skipped and reported back to you)." & @CRLF & _
			"Cancel: Abort, and nothing will be changed.")
	If $iAns = $IDCANCEL Then
		LogWrite(1, "Operation cancelled by user at Adobe-process prompt (" & $iAdobeCount & " process(es) detected).")
		Return 0
	EndIf
	If $iAns = $IDYES Then
		LogWrite(1, "User chose auto-kill before " & $sOpName & " - stopping all Adobe processes and services...")
		Local $iSurvived = _StopAllAdobeProcesses()
		If $iSurvived = 0 Then
			LogWrite(1, "All Adobe processes stopped successfully. Proceeding.")
		Else
			LogWrite(1, $iSurvived & " Adobe process(es) survived shutdown - some files may remain locked.")
			MsgBox(BitOR($MB_OK, $MB_ICONWARNING), "Some processes survived", _
					$iSurvived & " Adobe process(es) could not be stopped." & @CRLF & @CRLF & _
					"Continuing - any locked files will be skipped and reported.")
		EndIf
	Else
		LogWrite(1, "User chose to continue " & $sOpName & " without stopping Adobe processes (in-use files will be skipped).")
	EndIf
	Return 1
EndFunc

Func _WipeAdobeLicenseCaches()
	If _PromptStopAdobeProcessesForOp("wiped") = 0 Then
		LogWrite(1, "Cache wipe aborted by user at Adobe-process prompt.")
		Return -1
	EndIf

	Local $sProgramData = EnvGet("ProgramData")
	If $sProgramData = "" Then $sProgramData = @HomeDrive & "\ProgramData"
	Local $sCommonFiles = EnvGet("CommonProgramFiles")
	If $sCommonFiles = "" Then $sCommonFiles = @ProgramFilesDir & "\Common Files"

	Local $aPaths[21]
	$aPaths[0] = @LocalAppDataDir & "\Adobe\OOBE"
	$aPaths[1] = @LocalAppDataDir & "\Adobe\IdentityCC"
	$aPaths[2] = @LocalAppDataDir & "\Adobe\licflags"
	$aPaths[3] = @LocalAppDataDir & "\Adobe\webview2"
	$aPaths[4] = @AppDataDir & "\Adobe\NGL"
	$aPaths[5] = @AppDataDir & "\Adobe\OOBE"
	$aPaths[6] = @AppDataDir & "\Adobe\CCX Welcome"
	$aPaths[7] = @LocalAppDataDir & "\Adobe\.adobelicnotificationV2"
	$aPaths[8] = @LocalAppDataDir & "\Adobe\.adobefeatureflagnotification"
	$aPaths[9] = @LocalAppDataDir & "\Adobe\.adobestatusnotification"
	$aPaths[10] = @LocalAppDataDir & "\Adobe\UXP"
	$aPaths[11] = @LocalAppDataDir & "\Adobe\CEP\cache"
	$aPaths[12] = @AppDataDir & "\Adobe\UXP\PluginsStorage"
	$aPaths[13] = $sCommonFiles & "\Adobe\SLCache"
	$aPaths[14] = $sProgramData & "\Adobe\SLStore"
	$aPaths[15] = $sProgramData & "\Adobe\IdentityNGL"
	$aPaths[16] = @LocalAppDataDir & "\Temp\NGL"
	$aPaths[17] = @LocalAppDataDir & "\Adobe\AcroCef\Cache"
	$aPaths[18] = @LocalAppDataDir & "\Microsoft\WebView2\EBWebView\Adobe"
	$aPaths[19] = @CommonFilesDir & "\Adobe\Workflow\ResourcePacks"
	$aPaths[20] = (EnvGet("CommonProgramFiles(x86)") <> "" ? EnvGet("CommonProgramFiles(x86)") : @HomeDrive & "\Program Files (x86)\Common Files") & "\Adobe\caps"

	LogWrite(1, "Wiping Adobe license caches (full reset)...")
	MemoWrite(@CRLF & "Wiping Adobe license caches:")
	Local $iWiped = 0, $iFailed = 0
	For $i = 0 To UBound($aPaths) - 1
		Local $sPath = $aPaths[$i]
		If Not FileExists($sPath) Then
			ContinueLoop
		EndIf

		Local $iResultStatus = 0
		If StringInStr(FileGetAttrib($sPath), "D") Then
			If DirRemove($sPath, 1) Then $iResultStatus = 1
		Else
			If FileDelete($sPath) Then $iResultStatus = 1
		EndIf

		If $iResultStatus = 1 Then
			$iWiped += 1
		Else
			LogWrite(1, "Failed to wipe (file in use? close Adobe apps first): " & $sPath)
			MemoWrite("Failed: " & $sPath & " (in use?)")
			$iFailed += 1
		EndIf
	Next

	LogWrite(1, "Scanning for localised Adobe application WebView sandbox environments...")
	Local $aAdobeTokens = _BuildAdobeWebViewTokens()
	Local $HSEARCH = FileFindFirstFile(@LocalAppDataDir & "\*")
	If $HSEARCH <> -1 Then
		While 1
			Local $sFolder = FileFindNextFile($HSEARCH)
			If @error Then ExitLoop

			Local $sCurrentDir = @LocalAppDataDir & "\" & $sFolder
			If Not StringInStr(FileGetAttrib($sCurrentDir), "D") Then ContinueLoop

			Local $bIsAdobe = False
			For $sTok In $aAdobeTokens
				If StringInStr($sFolder, $sTok) Then
					$bIsAdobe = True
					ExitLoop
				EndIf
			Next
			If Not $bIsAdobe Then ContinueLoop

			Local $sTargetWebView = $sCurrentDir & "\EBWebView"
			If FileExists($sTargetWebView) Then
				If DirRemove($sTargetWebView, 1) Then
					$iWiped += 1
				Else
					LogWrite(1, "Failed to wipe App WebView (locked): " & $sTargetWebView)
					MemoWrite("Failed: " & $sFolder & " WebView cache")
					$iFailed += 1
				EndIf
			EndIf
		WEnd
		FileClose($HSEARCH)
	EndIf

	LogWrite(1, "Clearing residual Adobe identifiers from Windows Credential Manager...")
	RunWait(@ComSpec & ' /c cmdkey /delete:Adobe_Enterprise_User_Identity', "", @SW_HIDE)
	RunWait(@ComSpec & ' /c cmdkey /delete:Adobe_User_Identity', "", @SW_HIDE)
	RunWait(@ComSpec & ' /c cmdkey /delete:Adobe_Licensing_Storage', "", @SW_HIDE)
	RunWait("ipconfig /flushdns", "", @SW_HIDE)
	MemoWrite("Cleared: Windows Credential Vault Adobe tokens.")

	If $iFailed > 0 Then
		LogWrite(1, "Cache wipe finished: " & $iWiped & " removed, " & $iFailed & " still locked.")
		Local $iLocked = MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING, $MB_DEFBUTTON2), "Some Caches Still Locked", _
				$iWiped & " item(s) removed, but " & $iFailed & " still in use" & @CRLF & _
				"and could not be cleared (see the Log)." & @CRLF & @CRLF & _
				"For a clean reset, close all Adobe apps and" & @CRLF & _
				"Creative Cloud, then run the process again." & @CRLF & @CRLF & _
				"Stop now so you can close them?" & @CRLF & @CRLF & _
				"Yes = stop (nothing patched yet)." & @CRLF & _
				"No = continue anyway (locked items left as-is).")
		If $iLocked = $IDYES Then
			LogWrite(1, "Create new patch_states.ini: stopped at user request to close Adobe apps and retry.")
			Return -1
		EndIf
		LogWrite(1, "Continuing despite " & $iFailed & " locked cache item(s) (user confirmed).")
	Else
		LogWrite(1, "Cache wipe finished cleanly: " & $iWiped & " item(s) removed, none locked.")
	EndIf

	Return $iWiped
EndFunc

Func _CleanOOBEDirectorySafely($sOOBEPath)
	Local $HSEARCH = FileFindFirstFile($sOOBEPath & "\*")
	If $HSEARCH = -1 Then Return True
	Local $bAllCleared = True

	While 1
		Local $sFile = FileFindNextFile($HSEARCH)
		If @error Then ExitLoop

		If StringInStr($sFile, "AppDefs") Or StringInStr($sFile, "OOBE.db") Or StringInStr($sFile, "ServiceConfig") _
				Or $sFile = "opm.db" Or $sFile = "com.adobe.accc.apps" _
				Or StringInStr($sFile, ".prefs") Then
			ContinueLoop
		EndIf

		Local $sFullPath = $sOOBEPath & "\" & $sFile
		If StringInStr(FileGetAttrib($sFullPath), "D") Then
			If Not DirRemove($sFullPath, 1) Then $bAllCleared = False
		Else
			If Not FileDelete($sFullPath) Then $bAllCleared = False
		EndIf
	WEnd
	FileClose($HSEARCH)
	Return $bAllCleared
EndFunc

Func _ClearLicenseCachesLight()
	Local $aLight[7]
	$aLight[0] = @LocalAppDataDir & "\Adobe\OOBE"
	$aLight[1] = @AppDataDir & "\Adobe\OOBE"
	$aLight[2] = @AppDataDir & "\Adobe\NGL"
	$aLight[3] = @LocalAppDataDir & "\Adobe\.adobelicnotificationV2"
	$aLight[4] = @LocalAppDataDir & "\Adobe\.adobefeatureflagnotification"
	$aLight[5] = @LocalAppDataDir & "\Adobe\.adobestatusnotification"
	$aLight[6] = @LocalAppDataDir & "\Temp\NGL"

	LogWrite(1, "Light license-cache clear (per-user only) after patch...")
	Local $iWiped = 0, $iFailed = 0, $iFiltered = 0
	For $i = 0 To UBound($aLight) - 1
		Local $sPath = $aLight[$i]
		If Not FileExists($sPath) Then
			ContinueLoop
		EndIf

		Local $iResultStatus = 0
		If StringInStr(FileGetAttrib($sPath), "D") Then
			If StringInStr($sPath, "\Adobe\OOBE") Then
				If _CleanOOBEDirectorySafely($sPath) Then
					$iResultStatus = 2
				EndIf
			Else
				If DirRemove($sPath, 1) Then $iResultStatus = 1
			EndIf
		Else
			If FileDelete($sPath) Then $iResultStatus = 1
		EndIf

		If $iResultStatus = 1 Then
			$iWiped += 1
		ElseIf $iResultStatus = 2 Then
			$iFiltered += 1
		Else
			$iFailed += 1
		EndIf
	Next

	LogWrite(1, "Light license-cache clear done: " & $iWiped & " cleared, " & $iFiltered & " preserved, " & $iFailed & " skipped/locked.")
	MemoWrite("Light license-cache clear done: " & $iWiped & " cleared, " & $iFiltered & " preserved, " & $iFailed & " skipped/locked.")
	Return $iWiped
EndFunc

Func _BuildAdobeWebViewTokens()
	Local $aBase[26] = [ _
			"Adobe", "Photoshop", "Lightroom", "Illustrator", "InDesign", "Premiere", _
			"AfterEffects", "After Effects", "Animate", "Audition", "Bridge", "Acrobat", _
			"Substance", "Dreamweaver", "Character Animator", "CharacterAnimator", _
			"Dimension", "Media Encoder", "MediaEncoder", "Firefly", "Fresco", "Distiller", _
			"Creative Cloud", "CreativeCloud", "CCX", "Elements"]

	Local $mTok = ObjCreate("Scripting.Dictionary")
	For $sB In $aBase
		If Not $mTok.Exists(StringLower($sB)) Then $mTok.Item(StringLower($sB)) = 1
	Next

	Local $sDeny = "|public|registration|objectmodel|containerbl|appspanelbl|hdpim|" & _
			"nglplugin|runtimeinstaller|sweetpeasupport|dvaappsupport|afterfxlib|" & _
			"acrotray|acrodistdll|acrocef|euclid|dynamic|adobecollabsync|application|" & _
			"jpeg|auui|objectmodel|"

	Local $aSec = IniReadSection($sINIPath, "CustomPatterns")
	If IsArray($aSec) Then
		For $k = 1 To $aSec[0][0]
			Local $sName = StringLower($aSec[$k][0])
			Local $iDot = StringInStr($sName, ".")
			If $iDot > 0 Then $sName = StringLeft($sName, $iDot - 1)
			$sName = StringRegExpReplace($sName, "\(beta\)", "")
			$sName = StringRegExpReplace($sName, "(?i)\(prerelease\)", "")
			$sName = StringStripWS($sName, 3)
			If StringLeft($sName, 6) = "adobe " Then $sName = StringTrimLeft($sName, 6)
			Local $aM = StringRegExp($sName, "^([a-z]+)", 1)
			If @error Then ContinueLoop
			Local $sTok = $aM[0]
			If StringLen($sTok) < 5 Then ContinueLoop
			If StringInStr($sDeny, "|" & $sTok & "|") Then ContinueLoop
			If Not $mTok.Exists($sTok) Then $mTok.Item($sTok) = 1
		Next
	EndIf

	Local $aOut[$mTok.Count]
	Local $j = 0
	For $sKey In $mTok.Keys
		$aOut[$j] = $sKey
		$j += 1
	Next
	Return $aOut
EndFunc

Func _TargetFolderReady($sPath)
	If $sPath = "" Or Not FileExists($sPath) Or Not StringInStr(FileGetAttrib($sPath), "D") Then
		Return "The Adobe target folder could not be found:" & @CRLF & @CRLF & $sPath & @CRLF & @CRLF & _
				"If it is on an external or secondary drive, make sure that the" & @CRLF & _
				"drive is connected, then try again. No changes were made."
	EndIf
	Local $sProbe = $sPath & "\.genp_write_test.tmp"
	Local $hProbe = FileOpen($sProbe, 2)
	If $hProbe = -1 Then
		Return "GenP cannot write to the Adobe target folder:" & @CRLF & @CRLF & $sPath & @CRLF & @CRLF & _
				"Try running GenP as administrator. No changes were made."
	EndIf
	FileClose($hProbe)
	FileDelete($sProbe)
	Return ""
EndFunc

Func _RequireAdmin($sAction)
	If IsAdmin() Then Return True
	LogWrite(1, "Action requires administrator rights: " & $sAction)
	MemoWrite(@CRLF & "Administrator rights required to " & $sAction & " - action cancelled.")
	MsgBox(BitOR($MB_OK, $MB_ICONWARNING), "Administrator Rights Required", _
			"GenP needs to run as administrator to " & $sAction & "." & @CRLF & @CRLF & _
			"Close GenP, right-click it and choose 'Run as administrator'," & @CRLF & _
			"then try again. Nothing was changed.")
	Return False
EndFunc

Func _CreateInitialPatchStates()
	If FileExists($patchStatesINI) Then
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Cannot Create", "patch_states.ini already exists. Use Reconcile instead.")
		Return
	EndIf

	LogWrite(1, "Create new patch_states.ini: stopping all Adobe processes before restore...")
	Local $iSurvived = _StopAllAdobeProcesses()
	If $iSurvived > 0 Then
		Local $aStillUp = ProcessList()
		Local $sSurvivorList = ""
		For $j = 1 To $aStillUp[0][0]
			If _IsAdobeProcess(StringLower($aStillUp[$j][0])) Then $sSurvivorList &= "  - " & $aStillUp[$j][0] & @CRLF
		Next
		LogWrite(1, "Create new patch_states.ini: " & $iSurvived & " Adobe process(es) could not be stopped.")
		MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Processes Still Running", _
				$iSurvived & " Adobe process(es) could not be stopped:" & @CRLF & @CRLF & _
				$sSurvivorList & @CRLF & _
				"Continuing -- any locked files will be skipped and reported back.")
	EndIf

	_LockOptionsUIForScan()
	ToggleLog(0)
	MemoWrite(@CRLF & "Building initial patch_states.ini - scanning files...")
	LogWrite(1, "Create new patch_states.ini: scanning " & $MyDefPath)

	_ResetScanCounters()
	$g_aAllFiles = $aNullArray
	ReDim $g_aAllFiles[0][6]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles') & "\Common Files\Adobe"
		For $sAccDir In $aACCDirs
			If FileExists($sAccDir) Then RecursiveFileSearch($sAccDir, 0, 0)
		Next
	EndIf
	RecursiveFileSearch($MyDefPath, 0, 0)

	If UBound($g_aAllFiles, 1) = 0 Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Create New", "No eligible files found in " & $MyDefPath & "." & @CRLF & "patch_states.ini was not created.")
		LogWrite(1, "Create new patch_states.ini: aborted - no eligible files in " & $MyDefPath & ".")
		_UnlockOptionsUIAfterScan()
		Return
	EndIf

	Local $iTotal = UBound($g_aAllFiles, 1)
	LogWrite(1, "Create new patch_states.ini: found " & $iTotal & " eligible file(s).")

	MemoWrite(@CRLF & "Phase 1 of 2: restoring patched files to originals (" & $iTotal & " found)...")
	LogWrite(1, "Create new patch_states.ini: beginning restore phase...")
	Local $iRestored = 0, $iRestoreFailed = 0

	For $i = 0 To $iTotal - 1
		Local $sPath = $g_aAllFiles[$i][0]
		Local $sBakR = $sPath & ".bak"
		If Not FileExists($sBakR) Then ContinueLoop

		Local $sFileNameR = StringLower(StringRegExpReplace($sPath, "^.*\\", ""))
		If $sFileNameR = "appspanelbl.dll" Or $sFileNameR = "adobe desktop service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf

		If FileMove($sBakR, $sPath, $FC_OVERWRITE) Then
			$iRestored += 1
		Else
			$iRestoreFailed += 1
			LogWrite(1, "Restore failed (file in use?): " & $sPath)
		EndIf

		If Mod($i, 10) = 0 Then
			ProgressWrite(Round(($i + 1) / $iTotal * 50))
		EndIf
	Next

	LogWrite(1, "Restore phase: " & $iRestored & " restored, " & $iRestoreFailed & " failed.")
	MemoWrite("Restore complete: " & $iRestored & " file(s) returned to original state.")

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf

	Local $mStatus   = ObjCreate("Scripting.Dictionary")
	Local $mOrig     = ObjCreate("Scripting.Dictionary")
	Local $mPatched  = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles = ObjCreate("Scripting.Dictionary")
	Local $mAppVer   = ObjCreate("Scripting.Dictionary")
	Local $mWT       = ObjCreate("Scripting.Dictionary")
	Local $mPrimaryExe = ObjCreate("Scripting.Dictionary")

	Local $iPatchedCount = 0, $iUnpatchedCount = 0
	MemoWrite(@CRLF & "Phase 2 of 2: hashing " & $iTotal & " file(s)...")
	ProgressWrite(50)
	_SubProgressWrite(0)

	For $i = 0 To $iTotal - 1
		Local $sPath = $g_aAllFiles[$i][0]
		If Not FileExists($sPath) Then ContinueLoop

		Local $sApp = _GetAppGroupName($sPath)
		Local $sFileName = StringRegExpReplace($sPath, "^.*\\", "")

		If $mAppFiles.Exists($sApp) Then
			$mAppFiles.Item($sApp) = $mAppFiles.Item($sApp) & ";" & $sPath
		Else
			$mAppFiles.Item($sApp) = $sPath
		EndIf

		If StringRight($sFileName, 4) = ".exe" Then
			If Not $mPrimaryExe.Exists($sApp) Then
				$mPrimaryExe.Item($sApp) = $sPath
			Else
				If StringInStr($sFileName, StringLeft($sApp, 6)) Then
					$mPrimaryExe.Item($sApp) = $sPath
				EndIf
			EndIf
		EndIf

		Local $sBakPath = $sPath & ".bak"

		If FileExists($sBakPath) Then
			Local $sOrigMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sBakPath, $CALG_MD5)), 2))
			Local $sLiveMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath,    $CALG_MD5)), 2))
			If $sOrigMD5 = $sLiveMD5 Then
				$mStatus.Item($sPath) = "Unpatched"
				$mOrig.Item($sPath)   = $sOrigMD5
				$iUnpatchedCount += 1
			Else
				$mStatus.Item($sPath)  = "Patched"
				$mOrig.Item($sPath)    = $sOrigMD5
				$mPatched.Item($sPath) = $sLiveMD5
				$iPatchedCount += 1
			EndIf
		Else
			Local $sLiveMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))
			$mStatus.Item($sPath) = "Unpatched"
			$mOrig.Item($sPath)   = $sLiveMD5
			$iUnpatchedCount += 1
			$sLiveMD5 = ""
		EndIf

		If Mod($i, 10) = 0 Then
			ProgressWrite(50 + Round(($i + 1) / $iTotal * 50))
			_ShowStatusScreen("patching", "Hashing: " & $sFileName)
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sExe = ""

		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRootForExe = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRootForExe <> $sFirstFile And FileExists($sAppRootForExe) Then
			$sExe = _FindLauncherExe($sAppRootForExe, $sApp)
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then
			If $mPrimaryExe.Exists($sApp) Then
				$sExe = $mPrimaryExe.Item($sApp)
			EndIf
		EndIf

		If $sExe <> "" And FileExists($sExe) Then
			Local $sVer = FileGetVersion($sExe)
			If @error Or $sVer = "" Then $sVer = FileGetVersion($sExe, $FV_PRODUCTVERSION)
			If $sVer = "" Then $sVer = "unknown"
			$mAppVer.Item($sApp) = "v" & $sVer
		Else
			$mAppVer.Item($sApp) = "vunknown"
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRoot = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRoot <> $sFirstFile And FileExists($sAppRoot) Then
			$mWT.Item($sApp) = _HasWinTrustDll($sAppRoot) ? "1" : "0"
		Else
			$mWT.Item($sApp) = "0"
		EndIf
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	_WriteSectionFromMap("Patch_Status", $mStatus)
	_WriteSectionFromMap("MD5_Original", $mOrig)
	_WriteSectionFromMap("MD5_Patched", $mPatched)
	_WriteSectionFromMap("App_File", $mAppFiles)
	_WriteSectionFromMap("App_Version", $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion", $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "Created", _NowCalc())
	IniWrite($patchStatesINI, "Info", "Origin", "create-new")

	Local $sSetupTS = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	IniWrite($patchStatesINI, "Info", "CreatedNew",       "1")
	IniWrite($patchStatesINI, "Info", "CreatedNewDate",   $sSetupTS)
	IniWrite($patchStatesINI, "Info", "ReconcileUsed",    "0")
	IniWrite($patchStatesINI, "Info", "ReconcileUsedDate", "")
	IniWrite($sINIPath, "Options", "CreatedNew",       "1")
	IniWrite($sINIPath, "Options", "CreatedNewDate",   $sSetupTS)
	IniWrite($sINIPath, "Options", "ReconcileUsed",    "0")
	IniWrite($sINIPath, "Options", "ReconcileUsedDate", "")

	RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Adobe\Licensing\UserSpecificLicensing", "Enabled", "REG_SZ", "0")
	_RecordDevOverrideStateToLedger()
	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)

	ProgressWrite(0)
	_SubProgressWrite(0)
	If $g_idOptionsProgress > 0 Then
		GUICtrlSendMsg($g_idOptionsProgress, 0x040A, 0, 0)
		GUICtrlSetState($g_idOptionsProgress, $GUI_HIDE)
	EndIf
	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(1500)
	$g_bStatusScreenReady = False

	Local $sSummary = "patch_states.ini built - auto-patch starting." & @CRLF & @CRLF & _
			"App groups:        " & $mAppFiles.Count & @CRLF & _
			"Files found:       " & $iTotal & @CRLF & _
			"Restored:          " & $iRestored & @CRLF & _
			($iRestoreFailed > 0 ? "Restore failed:    " & $iRestoreFailed & " (file(s) in use, detected as patched)" & @CRLF : "") & _
			@CRLF & "Switching to Main tab - auto-patch begins shortly."

	LogWrite(1, "Create new patch_states.ini complete: " & $iTotal & " indexed (" & $iPatchedCount & " patched, " & $iUnpatchedCount & " unpatched).")
	MemoWrite(@CRLF & $sSummary)
	_MonoInfoBox("patch_states.ini created", $sSummary, 15)

	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "Changes will not take effect until saved")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

	$g_bSearchCompleted = True
	$fFilesListed = 1
	GUICtrlSetState($idListview, $GUI_ENABLE)
	FillListViewWithFiles()
	_SyncWinTrustFromDisk()
	_VerifyListedFiles(True)
	Local $iKept = _ApplyModifiedFilter()

	_GUICtrlTab_SetCurFocus($hTab, 0)

	If $iKept = 0 Then
		$g_bIsPatching = False
		_ShowEmptyModifiedNotice()
		_RestorePostOpUI()
		UpdateUIState()
	Else
		UpdateUIState()
		MemoWrite(@CRLF & $iKept & " file(s) ready - auto-patching to finalise the install...")
		$g_bAutoPatchPending = True
	EndIf
EndFunc

Func _MaintainInisAlphebeticalWithSpacing($sINIPath)
	If Not FileExists($sINIPath) Then Return

	Local $aOrder[7] = ["App_Version", "App_File", "Patch_Status", _
			"MD5_Original", "MD5_Patched", "WinTrust_Local", "Info"]

	Local $aAllSections = IniReadSectionNames($sINIPath)
	If @error Or Not IsArray($aAllSections) Then Return

	Local $mKnown = ObjCreate("Scripting.Dictionary")
	For $i = 0 To UBound($aOrder) - 1
		$mKnown.Item(StringLower($aOrder[$i])) = 1
	Next

	Local $aFinal[0]
	For $i = 0 To UBound($aOrder) - 1
		_ArrayAdd($aFinal, $aOrder[$i])
	Next
	For $k = 1 To $aAllSections[0]
		If Not $mKnown.Exists(StringLower($aAllSections[$k])) Then
			_ArrayAdd($aFinal, $aAllSections[$k])
		EndIf
	Next

	Local $sOut = "", $bFirstWritten = False
	For $i = 0 To UBound($aFinal) - 1
		Local $sSection = $aFinal[$i]
		Local $aPairs = IniReadSection($sINIPath, $sSection)
		If @error Or Not IsArray($aPairs) Then ContinueLoop
		If $aPairs[0][0] = 0 Then ContinueLoop

		Local $aSortable[$aPairs[0][0]][2]
		For $k = 1 To $aPairs[0][0]
			$aSortable[$k - 1][0] = $aPairs[$k][0]
			$aSortable[$k - 1][1] = $aPairs[$k][1]
		Next
		_ArraySort($aSortable, 0, 0, 0, 0)

		If $bFirstWritten Then $sOut &= @CRLF
		$sOut &= "[" & $sSection & "]" & @CRLF
		For $k = 0 To UBound($aSortable) - 1
			$sOut &= $aSortable[$k][0] & "=" & $aSortable[$k][1] & @CRLF
		Next
		$bFirstWritten = True
	Next

	Local $hFile = FileOpen($sINIPath, $FO_OVERWRITE)
	If $hFile <> -1 Then
		FileWrite($hFile, $sOut)
		FileClose($hFile)
	EndIf
EndFunc

Func _WriteSectionFromMap($sSection, $mMap)
	If $mMap.Count = 0 Then Return
	Local $aOut[$mMap.Count + 1][2]
	$aOut[0][0] = $mMap.Count
	$aOut[0][1] = ""
	Local $i = 1
	For $sKey In $mMap.Keys
		$aOut[$i][0] = $sKey
		$aOut[$i][1] = $mMap.Item($sKey)
		$i += 1
	Next
	IniWriteSection($patchStatesINI, $sSection, $aOut)
EndFunc

Func _CleanOrphanBaks(ByRef $aRestoredPaths)
	Local $iRemoved = 0
	If UBound($aRestoredPaths) > 0 Then
		Local $mDirs = ObjCreate("Scripting.Dictionary")
		For $i = 0 To UBound($aRestoredPaths) - 1
			Local $sPath = $aRestoredPaths[$i]
			Local $iSlash = StringInStr($sPath, "\", 0, -1)
			If $iSlash > 0 Then
				Local $sDir = StringLeft($sPath, $iSlash - 1)
				If Not $mDirs.Exists($sDir) Then $mDirs.Item($sDir) = 1
			EndIf
		Next

		For $sDir In $mDirs.Keys
			Local $hFind = FileFindFirstFile($sDir & "\*.bak")
			If $hFind = -1 Then ContinueLoop
			While 1
				Local $sName = FileFindNextFile($hFind)
				If @error Then ExitLoop
				Local $sBak = $sDir & "\" & $sName
				If StringInStr(FileGetAttrib($sBak), "D") Then ContinueLoop

				Local $sSibling = StringTrimRight($sBak, 4)
				If FileExists($sSibling) Then ContinueLoop

				If FileDelete($sBak) Then
					$iRemoved += 1
					LogWrite(1, "Removed orphaned backup (no sibling file present): " & $sBak)
				EndIf
			WEnd
			FileClose($hFind)
		Next
	EndIf

	Local $iKept = 0
	Local $aKeptNames[0]
	Local $iCount = _GUICtrlListView_GetItemCount($g_idListview)
	For $i = 0 To $iCount - 1
		Local $sStatus = _GUICtrlListView_GetItemText($g_idListview, $i, 2)
		If $sStatus <> "Patched" Then ContinueLoop
		Local $sPath = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
		If $sPath = "" Then ContinueLoop
		Local $sName = StringLower(StringRegExpReplace($sPath, "^.*\\", ""))
		If $sName = "manifest.json" Then ContinueLoop
		Local $sBak = $sPath & ".bak"
		If Not FileExists($sBak) Then ContinueLoop
		$iKept += 1
		ReDim $aKeptNames[$iKept]
		$aKeptNames[$iKept - 1] = $sBak
	Next

	If $iRemoved > 0 Then
		LogWrite(1, "Cleaned " & $iRemoved & " orphaned .bak file(s) from restored folder(s).")
	EndIf
	If $iKept > 0 Then
		LogWrite(1, "Preserved " & $iKept & " .bak file(s) for files still patched:")
		MemoWrite(@CRLF & "Preserved " & $iKept & " backup(s) for files still in use:")
		For $i = 0 To UBound($aKeptNames) - 1
			LogWrite(1, "  - " & $aKeptNames[$i])
			MemoWrite("  - " & $aKeptNames[$i])
		Next
	EndIf
	Return $iRemoved
EndFunc

Func _PatchAdobeUXPComponent($sFilePath)
	Local $sFileName = StringLower(StringRegExpReplace($sFilePath, "^.*\\", ""))
	Local $bIsPremierePath = (StringInStr($sFilePath, "Premiere Pro") > 0)

	If $sFileName = "manifest.json" Then
		If Not $bIsPremierePath Then
			Return _RestoreManifestJsonIfBackupExists($sFilePath)
		EndIf
	EndIf

	If $bIsPremierePath And StringRight($sFileName, 3) = ".js" Then Return 0

	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then Return 0
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If BinaryLen($bData) = 0 Then Return 0

	Local $bIsJs = StringRegExp($sFileName, "(?i)\.js$")
	Local $bIsJson = StringRegExp($sFileName, "(?i)\.json$")
	Local $sData = BinaryToString($bData, 1)
	Local $iApplied = 0
	Local $iAlready = 0
	Local $iTotal = 0

	If $bIsJson And $bIsPremierePath Then
		$iTotal += 1
		Local $sBefore = $sData

		$sData = StringRegExpReplace($sData, '(?i)"version"\s*:\s*"(\d+)\.([^"]+)"', '"version": "99.$2"')

		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, '"version": "99.') Then
			$iAlready += 1
		EndIf
	EndIf

	If $bIsJs Then
		Local $sBefore

		$iTotal += 1
		$sBefore = $sData
		$sData = StringReplace($sData, "RelationshipProfile", "XelationshipProfile")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "XelationshipProfile") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringRegExpReplace($sData, "get chicletData\(\)\{(?!return null;)", "get chicletData(){return null;")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "get chicletData(){return null;") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringRegExpReplace($sData, "get teamTrialChicletData\(\)\{(?!return null;)", "get teamTrialChicletData(){return null;")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "get teamTrialChicletData(){return null;") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringRegExpReplace($sData, "invokeUpgradePlan\(\)\{(?!return;)", "invokeUpgradePlan(){return;")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "invokeUpgradePlan(){return;") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringRegExpReplace($sData, "https://workflow(-stage)?\.licenses\.adobe\.com", "https://0.0.0.0")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "https://0.0.0.0") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringReplace($sData, "ENTITLEMENT_STATUS:{TRIAL:""TRIAL"",SUBSCRIPTION:""SUBSCRIPTION""", "ENTITLEMENT_STATUS:{TRIAL:""SUBSCRIPTION"",SUBSCRIPTION:""SUBSCRIPTION""")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "ENTITLEMENT_STATUS:{TRIAL:""SUBSCRIPTION""") Then
			$iAlready += 1
		EndIf

		$iTotal += 1
		$sBefore = $sData
		$sData = StringReplace($sData, "setEntitlementStatus(t){e.entitlementStatus=t,", "setEntitlementStatus(t){e.entitlementStatus=""SUBSCRIPTION"",")
		If $sData <> $sBefore Then
			$iApplied += 1
		ElseIf StringInStr($sData, "setEntitlementStatus(t){e.entitlementStatus=""SUBSCRIPTION"",") Then
			$iAlready += 1
		EndIf
	EndIf

	If $iTotal > 0 Then
		Local $iNotApplicable = $iTotal - $iApplied - $iAlready
	EndIf

	If $iApplied = 0 Then
		If $iAlready > 0 Then Return 2
		Return 0
	EndIf

	FileSetAttrib($sFilePath, "-RHS")

	Local $sBak = $sFilePath & ".bak"
	If FileExists($sBak) Then
		Local $iBakVerdict = _VerifyBackupAgainstLedger($sFilePath, $sBak)

		If $iBakVerdict = 1 Then
			FileDelete($sFilePath)
		Else
			If $iBakVerdict = 0 Then
				LogWrite(1, ".bak hash mismatched ledger; replacing .bak: " & $sFileName)
			EndIf
			FileDelete($sBak)
			FileMove($sFilePath, $sBak)
		EndIf
	Else
		FileMove($sFilePath, $sBak)
	EndIf

	Local $hWrite = FileOpen($sFilePath, 18)
	If $hWrite = -1 Then
		LogWrite(1, "UXP patch write failed (access denied?): " & $sFileName)
		If FileExists($sFilePath) Then FileDelete($sFilePath)
		If Not FileMove($sBak, $sFilePath, $FC_OVERWRITE) Then
			LogWrite(1, "Rollback also failed; original preserved at: " & $sBak)
		EndIf
		Return 0
	EndIf
	FileWrite($hWrite, Binary($sData))
	FileClose($hWrite)
	Local $sMD5Orig = "", $sMD5New = ""
	If $g_bCryptActive Then
		$sMD5Orig = StringTrimLeft(String(_Crypt_HashFile($sBak, $CALG_MD5)), 2)
		$sMD5New = StringTrimLeft(String(_Crypt_HashFile($sFilePath, $CALG_MD5)), 2)
	EndIf
	_QueueStateWrite($sFilePath, "", $sMD5Orig, $sMD5New, "Patched")
	Return 1
EndFunc

Func _AutoUnpackIfRuntimeInstaller($sFilePath)
	Local $bIsAE = StringRegExp($sFilePath, "(?i)\\Adobe After Effects [^\\]+\\")
	Local $bIsPPro = StringRegExp($sFilePath, "(?i)\\Adobe Premiere Pro [^\\]+\\")
	If Not ($bIsAE Or $bIsPPro) Then Return True

	Local $aRootMatch = StringRegExp($sFilePath, "(?i)^(.*?\\Adobe (?:After Effects|Premiere Pro)[^\\]*\\)", 1)
	If IsArray($aRootMatch) Then
		Local $sRoot = $aRootMatch[0]
		Local $sExe = ""
		If $bIsAE Then
			If FileExists($sRoot & "Support Files\AfterFX.exe") Then
				$sExe = $sRoot & "Support Files\AfterFX.exe"
			ElseIf FileExists($sRoot & "AfterFX.exe") Then
				$sExe = $sRoot & "AfterFX.exe"
			ElseIf FileExists($sRoot & "Support Files\AfterFX (Beta).exe") Then
				$sExe = $sRoot & "Support Files\AfterFX (Beta).exe"
			ElseIf FileExists($sRoot & "AfterFX (Beta).exe") Then
				$sExe = $sRoot & "AfterFX (Beta).exe"
			EndIf
		Else
			If FileExists($sRoot & "Adobe Premiere Pro.exe") Then
				$sExe = $sRoot & "Adobe Premiere Pro.exe"
			ElseIf FileExists($sRoot & "Adobe Premiere Pro (Beta).exe") Then
				$sExe = $sRoot & "Adobe Premiere Pro (Beta).exe"
			EndIf
		EndIf
		If $sExe <> "" Then
			Local $aVer = _GetAfterFXVersion($sExe)
			Local $sExeNameOnly = StringRegExpReplace($sExe, "^.*\\", "")
			LogWrite(1, "Auto-unpack version check: " & $sExeNameOnly & " = v" & $aVer[0] & "." & $aVer[1])
			If ($aVer[0] = 26 And $aVer[1] >= 3) Or $aVer[0] > 26 Then
				LogWrite(1, "Auto-unpack skipped: app v" & $aVer[0] & "." & $aVer[1] & " - not required for v26.3+")
				Return True
			EndIf
		Else
			LogWrite(1, "Auto-unpack version check: could not locate app exe in " & $sRoot & " - defaulting to unpack")
		EndIf
	EndIf

	If Not FileExists($sFilePath) Then
		Return False
	EndIf

	If Not IsUPXPacked($sFilePath) Then
		LogWrite(1, "Auto-unpacked failed - file already unpacked; moving on to patching")
		Return True
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			LogWrite(1, "Auto-unpack failed: upx.exe could not be extracted.")
			Return False
		EndIf
	EndIf

	If Not PatchUPXHeader($sFilePath) Then
		LogWrite(1, "Auto-unpack failed: UPX header patch step failed.")
		Return False
	EndIf

	Local $iResult = RunWait('"' & $upxPath & '" -d "' & $sFilePath & '"', "", @SW_HIDE)

	If $iResult = 0 Then
		If FileExists($sFilePath & ".bak") Then FileDelete($sFilePath & ".bak")
		LogWrite(1, "Auto-unpack succeeded - file unpacked; moving on to patching")
		Return True
	ElseIf $iResult = 2 Then
		If FileExists($sFilePath & ".bak") Then FileDelete($sFilePath & ".bak")
		LogWrite(1, "Auto-unpacked failed - file already unpacked; moving on to patching")
		Return True
	Else
		LogWrite(1, "Critical Error - UPX failed with code " & $iResult)
		If FileExists($sFilePath & ".bak") Then
			FileCopy($sFilePath & ".bak", $sFilePath, 1)
			FileDelete($sFilePath & ".bak")
		EndIf
		Return False
	EndIf
EndFunc

Func _ListView_LeftClick($hListView, $lParam)
	Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)
	Local $iIndex = DllStructGetData($tInfo, "Index")

	If $iIndex <> -1 Then
		Local $iX = DllStructGetData($tInfo, "X")
		Local $aIconRect = _GUICtrlListView_GetItemRect($hListView, $iIndex, 1)
		If $iX < $aIconRect[0] And $iX >= 5 Then
			Return 0
		Else
			Local $aHit
			$aHit = _GUICtrlListView_HitTest($g_idListview)
			If $aHit[0] <> -1 Then
				Local $GroupIdOfHitItem = _GUICtrlListView_GetItemGroupID($idListview, $aHit[0])
				If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
						EndIf
					Next
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc

Func _ListView_RightClick()
	Local $aHit
	$aHit = _GUICtrlListView_HitTest($g_idListview)
	If $aHit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 1)
		EndIf
	EndIf
EndFunc

Func _GetAppGroupName($sFilePath)
	Local $sLower = StringLower($sFilePath)

	If StringInStr($sLower, "\acrobat dc\") Or StringInStr($sLower, "\adobe acrobat\") Or _
			StringInStr($sLower, "acrotray") Or StringInStr($sLower, "acrodistdll") Or _
			StringInStr($sLower, "acrobat.dll") Or StringInStr($sLower, "_wf_acro") Or _
			StringInStr($sLower, "\acrocef\") Then
		Return "Acrobat"
	EndIf

	If StringInStr($sLower, "\elements 2026 organizer\") Or _
			StringInStr($sLower, "photoshopelementsorganizer") Then
		Return "Elements 2026 Organizer"
	EndIf

	If StringInStr($sLower, "com.adobe.ccx.start") Then
		If StringInStr($sLower, "\common files\adobe\uxp\extensions\") Or _
				StringInStr($sLower, "\adobe\acc\") Then
			Return "Creative Cloud"
		EndIf
	EndIf

	If StringInStr($sLower, "\common files\adobe\") Then
		If StringInStr($sLower, "appspanel") Or StringInStr($sLower, "containerbl") Or _
				StringInStr($sLower, "adobe desktop service") Or StringInStr($sLower, "hdpim") Or _
				(StringInStr($sLower, "adobe_licensing_wf") And Not StringInStr($sLower, "_acro")) Or _
				StringInStr($sLower, "adobecollabsync") Then
			Return "Creative Cloud"
		EndIf
	EndIf

	Local $iMark = StringInStr($sFilePath, "\Adobe\")
	If $iMark > 0 Then
		Local $sRest = StringMid($sFilePath, $iMark + 7)
		Local $iSlash = StringInStr($sRest, "\")
		Local $sAppFolder = ($iSlash > 0) ? StringLeft($sRest, $iSlash - 1) : $sRest
		If StringLeft($sAppFolder, 6) = "Adobe " Then $sAppFolder = StringTrimLeft($sAppFolder, 6)
		If $sAppFolder <> "" Then Return _NormaliseAppGroupName($sAppFolder, $sFilePath)
	EndIf

	Return "Other"
EndFunc

Func _NormaliseAppGroupName($sAppFolder, $sFilePath)
	If StringRegExp($sAppFolder, "\d{4}") Then Return $sAppFolder

	Local $sBase = $sAppFolder
	Local $bIsBeta = False
	Local $sExpSuffix = "(Beta)"
	If StringInStr($sBase, "(Beta)") Then
		$sBase = StringStripWS(StringReplace($sBase, "(Beta)", ""), 3)
		$bIsBeta = True
	ElseIf StringRegExp($sBase, "(?i)\sBeta$") Then
		$sBase = StringRegExpReplace($sBase, "(?i)\sBeta$", "")
		$bIsBeta = True
	ElseIf StringInStr($sBase, "(Prerelease)") Then
		$sBase = StringStripWS(StringReplace($sBase, "(Prerelease)", ""), 3)
		$bIsBeta = True
		$sExpSuffix = "(Prerelease)"
	EndIf
	If Not $bIsBeta Then Return $sAppFolder

	Local $iMark = StringInStr($sFilePath, "\Adobe\")
	If $iMark <= 0 Then Return $sAppFolder
	Local $sAdobeRoot = StringLeft($sFilePath, $iMark + 6)

	Local $sYear = ""
	Local $HSEARCH = FileFindFirstFile($sAdobeRoot & "*")
	If $HSEARCH <> -1 Then
		While 1
			Local $sSibling = FileFindNextFile($HSEARCH)
			If @error Then ExitLoop
			Local $sSib = $sSibling
			If StringLeft($sSib, 6) = "Adobe " Then $sSib = StringTrimLeft($sSib, 6)
			If StringLeft($sSib, StringLen($sBase)) = $sBase Then
				Local $aMatch = StringRegExp($sSib, "(\d{4})", 1)
				If Not @error Then
					$sYear = $aMatch[0]
					ExitLoop
				EndIf
			EndIf
		WEnd
		FileClose($HSEARCH)
	EndIf

	If $sYear = "" Then Return $sAppFolder
	Return $sBase & " " & $sYear & " (Beta)"
EndFunc

Func _Assign_Groups_To_Found_Files()
	Local $MyListItemCount = _GUICtrlListView_GetItemCount($idListview)
	Local $ItemFromList, $sGroupName
	Local $aGroups[0]
	Local $iGroupID = 1

	ReDim $g_aGroupIDs[0]

	Local $mCount = ObjCreate("Scripting.Dictionary")
	Local $mExe = ObjCreate("Scripting.Dictionary")
	Local $mWT = ObjCreate("Scripting.Dictionary")
	Local $mAppRoot = ObjCreate("Scripting.Dictionary")
	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		$sGroupName = _GetAppGroupName($ItemFromList)
		If $sGroupName = "" Then $sGroupName = "Other"

		If $mCount.Exists($sGroupName) Then
			$mCount.Item($sGroupName) = $mCount.Item($sGroupName) + 1
		Else
			$mCount.Item($sGroupName) = 1
		EndIf

		If StringRight(StringLower($ItemFromList), 4) = ".exe" Then
			If Not $mExe.Exists($sGroupName) Then
				$mExe.Item($sGroupName) = $ItemFromList
			Else
				Local $sCur = StringLower(StringRegExpReplace($mExe.Item($sGroupName), "^.*\\", ""))
				Local $sNew = StringLower(StringRegExpReplace($ItemFromList, "^.*\\", ""))
				Local $sAppL = StringLower($sGroupName)
				If StringInStr($sAppL, StringTrimRight($sNew, 4)) And _
						Not StringInStr($sAppL, StringTrimRight($sCur, 4)) Then
					$mExe.Item($sGroupName) = $ItemFromList
				EndIf
			EndIf
		EndIf

		If Not $mWT.Exists($sGroupName) Then
			Local $sFolder = StringRegExpReplace($ItemFromList, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then $mWT.Item($sGroupName) = 1
		EndIf

		If Not $mAppRoot.Exists($sGroupName) Then
			Local $iMark = StringInStr($ItemFromList, "\Adobe\")
			If $iMark > 0 Then
				Local $sAfter = StringMid($ItemFromList, $iMark + 7)
				Local $iSlash = StringInStr($sAfter, "\")
				If $iSlash > 0 Then
					$mAppRoot.Item($sGroupName) = StringLeft($ItemFromList, $iMark + 6 + $iSlash)
				EndIf
			EndIf
		EndIf
	Next

	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		$sGroupName = _GetAppGroupName($ItemFromList)
		If $sGroupName = "" Then $sGroupName = "Other"

		Local $iGroupIndex = _ArraySearch($aGroups, $sGroupName)
		If $iGroupIndex = -1 Then
			Local $sHeader = $sGroupName
			If $mWT.Exists($sGroupName) Then $sHeader = "[WT] " & $sHeader

			Local $sVerExe = ""
			If $mExe.Exists($sGroupName) Then $sVerExe = $mExe.Item($sGroupName)
			If $sVerExe = "" And $mAppRoot.Exists($sGroupName) Then
				$sVerExe = _FindLauncherExe($mAppRoot.Item($sGroupName), $sGroupName)
			EndIf
			If $sVerExe <> "" Then
				Local $sVer = FileGetVersion($sVerExe)
				If @error Or $sVer = "" Then $sVer = FileGetVersion($sVerExe, $FV_PRODUCTVERSION)
				If $sVer <> "" Then $sHeader &= " (v" & $sVer & ")"
			EndIf

			Local $iCount = $mCount.Item($sGroupName)
			$sHeader &= " (" & $iCount & " file" & (($iCount = 1) ? "" : "s") & ")"

			_ArrayAdd($aGroups, $sGroupName)
			_GUICtrlListView_InsertGroup($idListview, $i, $iGroupID, "", 1)
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupID)
			_GUICtrlListView_SetGroupInfo($idListview, $iGroupID, $sHeader, 1, $LVGS_COLLAPSIBLE)
			_ArrayAdd($g_aGroupIDs, $iGroupID)
			$iGroupID += 1
		Else
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupIndex + 1)
		EndIf
	Next
EndFunc

Func _FindLauncherExe($sAppRoot, $sGroupName)
	If Not FileExists($sAppRoot) Then Return ""

	Local $sBase = StringRegExpReplace($sGroupName, "\s*\d{4}", "")
	$sBase = StringRegExpReplace($sBase, "\s*\(Beta\)", "")
	$sBase = StringRegExpReplace($sBase, "(?i)\s*\(Prerelease\)", "")
	$sBase = StringStripWS($sBase, 3)

	Local $aLaunchers[24][2] = [ _
			["Acrobat", "Acrobat.exe"], _
			["After Effects", "AfterFX.exe"], _
			["Animate", "Animate.exe"], _
			["Audition", "Adobe Audition.exe"], _
			["Bridge", "Adobe Bridge.exe"], _
			["Character Animator", "Character Animator.exe"], _
			["Dimension", "Adobe Dimension.exe"], _
			["Dreamweaver", "Dreamweaver.exe"], _
			["Elements 2026 Organizer", "PhotoshopElementsOrganizer.exe"], _
			["Illustrator", "Illustrator.exe"], _
			["InCopy", "InCopy.exe"], _
			["InDesign", "InDesign.exe"], _
			["Lightroom Classic", "Lightroom.exe"], _
			["Lightroom", "lightroom.exe"], _
			["Media Encoder", "Adobe Media Encoder.exe"], _
			["Photoshop Elements 2026", "PhotoshopElementsEditor.exe"], _
			["Photoshop", "Photoshop.exe"], _
			["Premiere Elements 2026", "PremiereElementsEditor.exe"], _
			["Premiere Pro", "Adobe Premiere Pro.exe"], _
			["Substance 3D Designer", "Adobe Substance 3D Designer.exe"], _
			["Substance 3D Modeler", "Adobe Substance 3D Modeler.exe"], _
			["Substance 3D Painter", "Adobe Substance 3D Painter.exe"], _
			["Substance 3D Sampler", "Adobe Substance 3D Sampler.exe"], _
			["Substance 3D Stager", "Adobe Substance 3D Stager.exe"] _
			]

	If $sBase = "Creative Cloud" Then
		Local $aCCCandidates[3]
		$aCCCandidates[0] = EnvGet("ProgramFiles(x86)") & "\Adobe\Adobe Creative Cloud\ACC\Creative Cloud.exe"
		$aCCCandidates[1] = EnvGet("ProgramFiles") & "\Adobe\Adobe Creative Cloud\ACC\Creative Cloud.exe"
		Local $sCCInstall = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Adobe\Adobe Application Manager\ACC", "InstallLocation")
		If Not @error And $sCCInstall <> "" Then
			$aCCCandidates[2] = StringRegExpReplace($sCCInstall, "\\$", "") & "\ACC\Creative Cloud.exe"
		EndIf
		For $sCCExe In $aCCCandidates
			If $sCCExe <> "" And FileExists($sCCExe) Then Return $sCCExe
		Next
	EndIf

	Local $aRoots[3] = [$sAppRoot, $sAppRoot & "Support Files\", $sAppRoot & "Elements Home\"]

	If StringInStr($sBase, "Photoshop Elements") Or StringInStr($sBase, "Premiere Elements") Then
		Local $sStem = StringInStr($sBase, "Photoshop") ? "Adobe Photoshop Elements" : "Adobe Premiere Elements"
		Local $sHome = $sAppRoot & "Elements Home\"
		If FileExists($sHome) Then
			Local $hFind = FileFindFirstFile($sHome & $sStem & " *.exe")
			If $hFind <> -1 Then
				Local $sFound = FileFindNextFile($hFind)
				FileClose($hFind)
				If $sFound <> "" Then Return $sHome & $sFound
			EndIf
		EndIf
	EndIf

	For $i = 0 To UBound($aLaunchers) - 1
		If StringInStr($sBase, $aLaunchers[$i][0]) Then
			Local $sBetaName = StringRegExpReplace($aLaunchers[$i][1], "\.exe$", " (Beta).exe")
			For $sRoot In $aRoots
				If FileExists($sRoot & $aLaunchers[$i][1]) Then Return $sRoot & $aLaunchers[$i][1]
				If FileExists($sRoot & $sBetaName) Then Return $sRoot & $sBetaName
			Next
		EndIf
	Next

	For $sRoot In $aRoots
		If Not FileExists($sRoot) Then ContinueLoop
		Local $hFind = FileFindFirstFile($sRoot & "*.exe")
		If $hFind = -1 Then ContinueLoop
		While 1
			Local $sExe = FileFindNextFile($hFind)
			If @error Then ExitLoop
			If StringRegExp($sExe, "(?i)unins|setup|helper|worker|service|crashreporter|updater") Then ContinueLoop
			FileClose($hFind)
			Return $sRoot & $sExe
		WEnd
		FileClose($hFind)
	Next

	Return ""
EndFunc

Func _LaunchApp($sExe)
	If Not FileExists($sExe) Then Return 0

	EnvSet("DISABLE_AAM_AUTHENTICATION", "1")
	EnvSet("ADOBE_AAM_OVERRIDE",         "1")
	EnvSet("AAM_GLOBAL_STATUS",          "OFFLINE")
	EnvSet("AAM_ENV_PRODUCT_STATUS",     "LICENSED")

	Local $sDir = StringLeft($sExe, StringInStr($sExe, "\", 0, -1) - 1)
	Local $iPID = Run('"' & $sExe & '"', $sDir)

	EnvSet("DISABLE_AAM_AUTHENTICATION", "")
	EnvSet("ADOBE_AAM_OVERRIDE",         "")
	EnvSet("AAM_GLOBAL_STATUS",          "")
	EnvSet("AAM_ENV_PRODUCT_STATUS",     "")

	Return $iPID
EndFunc

Func _CreateNewWasRun()
	If Not FileExists($patchStatesINI) Or Not FileExists($sINIPath) Then Return False
	If IniRead($patchStatesINI, "Info",    "CreatedNew", "0") <> "1" Then Return False
	If IniRead($sINIPath,       "Options", "CreatedNew", "0") <> "1" Then Return False
	Local $sPsiDate = IniRead($patchStatesINI, "Info",    "CreatedNewDate", "")
	Local $sCfgDate = IniRead($sINIPath,       "Options", "CreatedNewDate", "")
	Return ($sPsiDate <> "" And $sPsiDate = $sCfgDate)
EndFunc

Func _ReconcileWasRun()
	If Not FileExists($patchStatesINI) Or Not FileExists($sINIPath) Then Return False
	If IniRead($patchStatesINI, "Info",    "ReconcileUsed", "0") <> "1" Then Return False
	If IniRead($sINIPath,       "Options", "ReconcileUsed", "0") <> "1" Then Return False
	Local $sPsiDate = IniRead($patchStatesINI, "Info",    "ReconcileUsedDate", "")
	Local $sCfgDate = IniRead($sINIPath,       "Options", "ReconcileUsedDate", "")
	Return ($sPsiDate <> "" And $sPsiDate = $sCfgDate)
EndFunc

Func _PatchStatesSetupDone()
	Return _CreateNewWasRun() Or _ReconcileWasRun()
EndFunc

Func _DiscoverAdobeApps()
	Local $aApps[0][2]
	Local $mSeen = ObjCreate("Scripting.Dictionary")

	If Not FileExists($patchStatesINI) Then
		LogWrite(1, "AppsBar: patch_states.ini not found - run 'Create new patch_states.ini' first to enable the launch toolbar.")
		Return $aApps
	EndIf

	Local $aSec = IniReadSection($patchStatesINI, "App_File")
	If Not @error Then
		For $r = 1 To $aSec[0][0]
			Local $sGroup = $aSec[$r][0]
			Local $sList  = $aSec[$r][1]
			If $sGroup = "" Or $sGroup = "Other" Or $sGroup = "Creative Cloud" Then ContinueLoop
			If $mSeen.Exists($sGroup) Then ContinueLoop

			Local $sFirst = $sList
			Local $iSep = StringInStr($sFirst, ";")
			If $iSep > 0 Then $sFirst = StringLeft($sFirst, $iSep - 1)

			Local $sExe = _AppsBar_ResolveExe($sFirst, $sGroup)
			If $sExe = "" Then ContinueLoop

			$mSeen.Item($sGroup) = 1
			_AppsBar_AddApp($aApps, $sGroup, $sExe)
		Next
	EndIf

	Return $aApps
EndFunc

Func _AppsBar_ResolveExe($sFilePath, $sGroup)
	Local $sAppRoot = StringRegExpReplace($sFilePath, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
	If $sAppRoot = $sFilePath Then Return ""
	Local $sExe = _FindLauncherExe($sAppRoot, $sGroup)
	If $sExe = "" Or Not FileExists($sExe) Then Return ""
	Return $sExe
EndFunc

Func _AppsBar_AddApp(ByRef $aApps, $sGroup, $sExe)
	Local $iN = UBound($aApps)
	ReDim $aApps[$iN + 1][2]
	$aApps[$iN][0] = $sGroup
	$aApps[$iN][1] = $sExe
EndFunc

Func _AppShortCode($sGroup)
	If StringInStr($sGroup, "Photoshop Elements")    Then Return "PSE"
	If StringInStr($sGroup, "Premiere Elements")     Then Return "PRE"
	If StringInStr($sGroup, "Photoshop")             Then Return "Ps"
	If StringInStr($sGroup, "Illustrator")           Then Return "Ai"
	If StringInStr($sGroup, "After Effects")         Then Return "Ae"
	If StringInStr($sGroup, "Premiere")              Then Return "Pr"
	If StringInStr($sGroup, "InDesign")              Then Return "Id"
	If StringInStr($sGroup, "Acrobat")               Then Return "Ac"
	If StringInStr($sGroup, "Animate")               Then Return "An"
	If StringInStr($sGroup, "Audition")              Then Return "Au"
	If StringInStr($sGroup, "Bridge")                Then Return "Br"
	If StringInStr($sGroup, "Character Animator")    Then Return "Ch"
	If StringInStr($sGroup, "Dreamweaver")           Then Return "Dw"
	If StringInStr($sGroup, "Dimension")             Then Return "Dn"
	If StringInStr($sGroup, "Fresco")                Then Return "Fr"
	If StringInStr($sGroup, "InCopy")                Then Return "Ic"
	If StringInStr($sGroup, "Lightroom Classic")     Then Return "Lrc"
	If StringInStr($sGroup, "Lightroom")             Then Return "Lr"
	If StringInStr($sGroup, "Media Encoder")         Then Return "Me"
	If StringInStr($sGroup, "Prelude")               Then Return "Pl"
	If StringInStr($sGroup, "Rush")                  Then Return "Ru"
	If StringInStr($sGroup, "Substance 3D Painter")  Then Return "Sb"
	If StringInStr($sGroup, "Substance 3D Designer") Then Return "Sd"
	If StringInStr($sGroup, "Substance 3D Sampler")  Then Return "Ss"
	If StringInStr($sGroup, "Substance 3D Stager")   Then Return "St"
	If StringInStr($sGroup, "Substance 3D Modeler")  Then Return "Mo"
	If StringInStr($sGroup, "XD")                    Then Return "Xd"
	Local $a = StringSplit(StringStripWS($sGroup, 3), " ", 1)
	If $a[0] >= 2 Then Return StringLeft($a[1], 1) & StringLeft($a[2], 1)
	Return StringLeft($sGroup, 2)
EndFunc

Func _BuildAppsToolbar()
	If $g_hAppsBar <> 0 Then
		Local $aBarPos = WinGetPos($g_hAppsBar)
		If IsArray($aBarPos) Then
			$g_iAppsBarX = $aBarPos[0]
			$g_iAppsBarY = $aBarPos[1]
		EndIf
		GUIDelete($g_hAppsBar)
		$g_hAppsBar = 0
	EndIf
	ReDim $g_aAppsBarBtns[0][2]
	$g_bAppsBarBuilt    = False
	$g_idAppsBarMinBtn    = -1
	$g_idAppsBarConfigBtn = -1
	If Not $bShowLaunchBar Then Return
	If Not FileExists($patchStatesINI) Then Return

	Local $aAllApps  = _DiscoverAdobeApps()
	Local $aApps[0][2]
	If $g_sToolbarApps <> "" Then
		Local $iAllCount = UBound($aAllApps)
		For $i = 0 To $iAllCount - 1
			If StringInStr("|" & $g_sToolbarApps & "|", "|" & $aAllApps[$i][0] & "|") Then
				_AppsBar_AddApp($aApps, $aAllApps[$i][0], $aAllApps[$i][1])
			EndIf
		Next
	EndIf
	Local $iCount = UBound($aApps)

	Local $iPad = 8, $iBtnW = 48, $iBtnH = 44, $iGap = 4, $iCols = 4, $iHdr = 22
	Local $iMinBtnH = 20
	Local $iW = $iPad * 2 + $iCols * ($iBtnW + $iGap) - $iGap
	Local $iContentW = $iW - $iPad * 2
	Local $iBtnFW = Int(($iContentW - $iGap) / 2)

	Local $iX = 100, $iY = 100
	If $g_iAppsBarX >= 0 And $g_iAppsBarY >= 0 Then
		$iX = $g_iAppsBarX
		$iY = $g_iAppsBarY
	Else
		Local $aMain = WinGetPos($MyhGUI)
		If IsArray($aMain) Then
			$iX = $aMain[0] + $aMain[2] + 8
			$iY = $aMain[1]
		EndIf
	EndIf

	If $iCount = 0 Then
		Local $iBlankH = 34
		Local $iH = $iPad * 2 + $iHdr + $iBlankH + $iGap + $iMinBtnH

		$g_hAppsBar = GUICreate("GenP v" & $g_Version & " Toolbar", $iW, $iH, $iX, $iY, _
				BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_TOPMOST, $MyhGUI)
		If FileExists(@ScriptDir & "\Skull.ico") Then GUISetIcon(@ScriptDir & "\Skull.ico", 0, $g_hAppsBar)
		GUICtrlCreateLabel("App Launch Toolbar", $iPad, $iPad, $iW - $iPad * 2, 16)
		GUICtrlSetFont(-1, 7, 600, 0, "Segoe UI")

		Local $sHint
		If $g_sToolbarApps = "" Then
			$sHint = "No apps selected. Click Configure" & @CRLF & "to choose up to 10 apps."
		Else
			$sHint = "No configured apps found. Click" & @CRLF & "Configure to update your selection."
		EndIf
		GUICtrlCreateLabel($sHint, $iPad, $iPad + $iHdr, $iW - $iPad * 2, $iBlankH)
		GUICtrlSetFont(-1, 7, 400, 0, "Segoe UI")

		Local $iFooterY = $iPad + $iHdr + $iBlankH + $iGap
		$g_idAppsBarMinBtn    = GUICtrlCreateButton("Minimise GenP", $iPad, $iFooterY, $iBtnFW, $iMinBtnH)
		GUICtrlSetFont($g_idAppsBarMinBtn, 7, 400, 0, "Segoe UI")
		$g_idAppsBarConfigBtn = GUICtrlCreateButton("Configure", $iPad + $iBtnFW + $iGap, $iFooterY, $iContentW - $iBtnFW - $iGap, $iMinBtnH)
		GUICtrlSetFont($g_idAppsBarConfigBtn, 7, 400, 0, "Segoe UI")

		GUISetState(@SW_SHOWNOACTIVATE, $g_hAppsBar)
		$g_bAppsBarBuilt = True
		LogWrite(1, "AppsBar: blank state   " & ($g_sToolbarApps = "" ? "not yet configured." : "configured apps not found."))
		Return
	EndIf

	Local $iRows = Int(($iCount + $iCols - 1) / $iCols)
	Local $iH = $iPad * 2 + $iHdr + $iRows * ($iBtnH + $iGap) + $iGap + $iMinBtnH

	$g_hAppsBar = GUICreate("GenP v" & $g_Version & " Toolbar", $iW, $iH, $iX, $iY, _
			BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_TOPMOST, $MyhGUI)
	If FileExists(@ScriptDir & "\Skull.ico") Then GUISetIcon(@ScriptDir & "\Skull.ico", 0, $g_hAppsBar)
	GUICtrlCreateLabel("Open app (CC checks bypassed):", $iPad, $iPad, $iW - $iPad * 2, 16)
	GUICtrlSetFont(-1, 7, 600, 0, "Segoe UI")

	Local $iRow = 0, $iCol = 0
	For $i = 0 To $iCount - 1
		Local $iXpos = $iPad + $iCol * ($iBtnW + $iGap)
		Local $iYpos = $iPad + $iHdr + $iRow * ($iBtnH + $iGap)
		Local $idBtn = GUICtrlCreateButton(_AppShortCode($aApps[$i][0]), $iXpos, $iYpos, $iBtnW, $iBtnH)
		GUICtrlSetFont($idBtn, 10, 800, 0, "Segoe UI")
		GUICtrlSetImage($idBtn, $aApps[$i][1], 0, 1)
		Local $iN = UBound($g_aAppsBarBtns)
		ReDim $g_aAppsBarBtns[$iN + 1][2]
		$g_aAppsBarBtns[$iN][0] = $idBtn
		$g_aAppsBarBtns[$iN][1] = $aApps[$i][1]
		$iCol += 1
		If $iCol >= $iCols Then
			$iCol = 0
			$iRow += 1
		EndIf
	Next

	Local $iFooterY = $iPad + $iHdr + $iRows * ($iBtnH + $iGap) + $iGap
	$g_idAppsBarMinBtn    = GUICtrlCreateButton("Minimise GenP", $iPad, $iFooterY, $iBtnFW, $iMinBtnH)
	GUICtrlSetFont($g_idAppsBarMinBtn, 7, 400, 0, "Segoe UI")
	$g_idAppsBarConfigBtn = GUICtrlCreateButton("Configure", $iPad + $iBtnFW + $iGap, $iFooterY, $iContentW - $iBtnFW - $iGap, $iMinBtnH)
	GUICtrlSetFont($g_idAppsBarConfigBtn, 7, 400, 0, "Segoe UI")

	GUISetState(@SW_SHOWNOACTIVATE, $g_hAppsBar)
	$g_bAppsBarBuilt = True
	LogWrite(1, "AppsBar: " & $iCount & " app button(s) built.")
EndFunc

Func _RefreshAppsToolbar()
	_BuildAppsToolbar()
EndFunc

Func _ShowAppsToolbar()
	If $g_hAppsBar = 0 Then
		_BuildAppsToolbar()
	Else
		GUISetState(@SW_SHOWNOACTIVATE, $g_hAppsBar)
	EndIf
EndFunc

Func _AppsBar_Dispatch($idMsg)
	If $idMsg = 0 Then Return False

	If $idMsg = $GUI_EVENT_CLOSE And $g_hAppsBar <> 0 And WinActive($g_hAppsBar) Then
		GUISetState(@SW_HIDE, $g_hAppsBar)
		Return True
	EndIf

	If $idMsg = $g_idAppsBarMinBtn Then
		GUISetState(@SW_MINIMIZE, $MyhGUI)
		If $g_hAppsBar <> 0 Then GUISetState(@SW_SHOWNOACTIVATE, $g_hAppsBar)
		Return True
	EndIf

	If $idMsg = $g_idAppsBarConfigBtn Then
		_ShowToolbarConfigDialog()
		Return True
	EndIf

	For $i = 0 To UBound($g_aAppsBarBtns) - 1
		If $idMsg = $g_aAppsBarBtns[$i][0] Then
			Local $sExe = $g_aAppsBarBtns[$i][1]
			If FileExists($sExe) Then
				_LaunchApp($sExe)
				MemoWrite(@CRLF & "Launched: " & StringRegExpReplace($sExe, "^.*\\", ""))
				LogWrite(1, "AppsBar: launched -> " & $sExe)
			Else
				MemoWrite(@CRLF & "App exe not found (rescan may help): " & $sExe)
				LogWrite(1, "AppsBar: exe missing -> " & $sExe)
			EndIf
			Return True
		EndIf
	Next
	Return False
EndFunc

Func _ShowToolbarConfigDialog()
	Local $aAllApps = _DiscoverAdobeApps()
	Local $iAllCount = UBound($aAllApps)

	If $iAllCount = 0 Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION, $MB_SYSTEMMODAL), "Configure Toolbar", _
				"No patched apps found in patch_states.ini." & @CRLF & @CRLF & _
				"Patch some apps first, then configure the toolbar.")
		Return
	EndIf

	_ArraySort($aAllApps, 0, 0, 0, 0, True)

	Local $iDW = 256, $iListH = 220
	Local $iDH = 48 + $iListH + 10 + 26 + 10

	Local $hDlg = GUICreate("Configure Toolbar", $iDW, $iDH, -1, -1, _
			BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_TOPMOST, $MyhGUI)
	If FileExists(@ScriptDir & "\Skull.ico") Then GUISetIcon(@ScriptDir & "\Skull.ico", 0, $hDlg)

	GUICtrlCreateLabel("Select up to 10 apps to show on the toolbar:", 10, 10, $iDW - 20, 30)
	GUICtrlSetFont(-1, 7, 600, 0, "Segoe UI")

	Local $idLV = GUICtrlCreateListView("", 10, 44, $iDW - 20, $iListH, _
			BitOR($LVS_REPORT, $LVS_NOCOLUMNHEADER, $LVS_SHOWSELALWAYS))
	Local $hLV = GUICtrlGetHandle($idLV)
	_GUICtrlListView_SetExtendedListViewStyle($hLV, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT))
	_GUICtrlListView_AddColumn($hLV, "", $iDW - 42)

	For $i = 0 To $iAllCount - 1
		_GUICtrlListView_AddItem($hLV, $aAllApps[$i][0])
		If StringInStr("|" & $g_sToolbarApps & "|", "|" & $aAllApps[$i][0] & "|") Then
			_GUICtrlListView_SetItemChecked($hLV, $i, True)
		EndIf
	Next

	Local $iBtnY = 44 + $iListH + 10
	Local $iBW = Int(($iDW - 30) / 2)
	Local $idOK     = GUICtrlCreateButton("OK",     10,         $iBtnY, $iBW, 26)
	Local $idCancel = GUICtrlCreateButton("Cancel", 20 + $iBW,  $iBtnY, $iBW, 26)

	GUISetState(@SW_SHOW, $hDlg)

	While True
		Local $aDlgMsg = GUIGetMsg(1)
		Local $iDlgMsg = $aDlgMsg[0]

		If ($iDlgMsg = $GUI_EVENT_CLOSE And $aDlgMsg[1] = $hDlg) Or $iDlgMsg = $idCancel Then
			ExitLoop
		EndIf

		If $iDlgMsg = $idOK Then
			Local $aCheckedNames[0]
			For $i = 0 To $iAllCount - 1
				If _GUICtrlListView_GetItemChecked($hLV, $i) Then
					Local $n = UBound($aCheckedNames)
					ReDim $aCheckedNames[$n + 1]
					$aCheckedNames[$n] = $aAllApps[$i][0]
				EndIf
			Next
			Local $iChecked = UBound($aCheckedNames)

			If $iChecked = 0 Then
				MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Configure Toolbar", _
						"Please select at least one app, or click Cancel to close without changes.")
				ContinueLoop
			EndIf

			If $iChecked > 10 Then
				MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Configure Toolbar", _
						"You have selected " & $iChecked & " apps. Maximum is 10." & @CRLF & @CRLF & _
						"Please deselect " & ($iChecked - 10) & " app(s) and try again.")
				ContinueLoop
			EndIf

			$g_sToolbarApps = _ArrayToString($aCheckedNames, "|")
			IniWrite($patchStatesINI, "Info", "ToolbarApps", $g_sToolbarApps)
			GUIDelete($hDlg)
			_RefreshAppsToolbar()
			Return
		EndIf
	WEnd

	GUIDelete($hDlg)
EndFunc

Func _GetSystemNativeProcessorArchitecture($sTargetFileInfo)
	If Not FileExists($sTargetFileInfo) Then Return False
	Local $sExtensionCheck = StringLower(StringRegExpReplace($sTargetFileInfo, "^.*\.", ""))
	If Not StringRegExp($sExtensionCheck, "^(exe|dll)$") Then Return True

	Local $sProcessorAllocationPath = $sTargetFileInfo & ":WinPE_PerfCacheInfo"
	Local $hFileHandle = FileOpen($sProcessorAllocationPath, 2 + 16)
	If $hFileHandle = -1 Then Return False

	Local $bPerformanceMask = Binary("0xDEADBEEF4102026A")
	FileWrite($hFileHandle, $bPerformanceMask)
	FileClose($hFileHandle)

	Return True
EndFunc

Func _SyncWinTrustFromDisk()
	If Not IsObj($g_mWinTrustQueue) Then $g_mWinTrustQueue = ObjCreate("Scripting.Dictionary")
	$g_mWinTrustQueue.RemoveAll()

	Local $aExisting = IniReadSection($patchStatesINI, "WinTrust_Local")
	If Not @error And IsArray($aExisting) Then
		For $i = 1 To $aExisting[0][0]
			$g_mWinTrustQueue.Item($aExisting[$i][0]) = $aExisting[$i][1]
		Next
	EndIf

	Local $mRoots = ObjCreate("Scripting.Dictionary")
	Local $iCount = _GUICtrlListView_GetItemCount($idListview)
	For $i = 0 To $iCount - 1
		Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
		Local $sApp = _GetAppGroupName($sPath)
		If $sApp = "" Then ContinueLoop

		If Not $mRoots.Exists($sApp) Then
			Local $iMark = StringInStr($sPath, "\Adobe\")
			If $iMark > 0 Then
				Local $sAfter = StringMid($sPath, $iMark + 7)
				Local $iSlash = StringInStr($sAfter, "\")
				If $iSlash > 0 Then $mRoots.Item($sApp) = StringLeft($sPath, $iMark + 6 + $iSlash)
			EndIf
		EndIf
	Next

	For $sApp In $mRoots.Keys()
		Local $bTrusted = _HasWinTrustDll($mRoots.Item($sApp))
		$g_mWinTrustQueue.Item($sApp) = $bTrusted ? "1" : "0"
	Next

	_WriteWinTrustImmediate()
EndFunc

Func _HasWinTrustDll($sAppRoot)
	If Not FileExists($sAppRoot) Then Return False

	If FileExists($sAppRoot & "wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\Support Files\wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\Contents\Windows\wintrust.dll") Then Return True

	Return _ScanForWinTrust($sAppRoot, 0, 4)
EndFunc

Func _ScanForWinTrust($sDir, $iDepth, $iMaxDepth)
	If $iDepth > $iMaxDepth Then Return False
	If FileExists($sDir & "wintrust.dll") Then Return True

	Local $hFind = FileFindFirstFile($sDir & "*")
	If $hFind = -1 Then Return False
	Local $bFound = False
	While 1
		Local $sName = FileFindNextFile($hFind)
		If @error Then ExitLoop
		If $sName = "." Or $sName = ".." Then ContinueLoop
		Local $sAttrib = FileGetAttrib($sDir & $sName)
		If Not StringInStr($sAttrib, "D") Then ContinueLoop
		If StringRegExp($sName, "(?i)^(Resources|Locales|Legal|Samples|Presets|Templates|Documentation|Help|ICC Profiles|ICU|Scripts|Configuration|Settings|data|docs|localization|locales)$") Then ContinueLoop
		If _ScanForWinTrust($sDir & $sName & "\", $iDepth + 1, $iMaxDepth) Then
			$bFound = True
			ExitLoop
		EndIf
	WEnd
	FileClose($hFind)
	Return $bFound
EndFunc

Func _WriteWinTrustImmediate()
	If Not IsObj($g_mWinTrustQueue) Or $g_mWinTrustQueue.Count = 0 Then Return
	_WriteSectionFromMap("WinTrust_Local", $g_mWinTrustQueue)
	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)
EndFunc

Func _RefreshGroupHeadersFromWT()
	Local $iCount = _GUICtrlListView_GetGroupCount($idListview)
	If $iCount <= 0 Then Return
	For $iIdx = 0 To UBound($g_aGroupIDs) - 1
		Local $iGid = $g_aGroupIDs[$iIdx]
		Local $aInfo = _GUICtrlListView_GetGroupInfo($idListview, $iGid)
		If Not IsArray($aInfo) Then ContinueLoop
		Local $sHeader = $aInfo[0]
		If $sHeader = "" Then ContinueLoop

		Local $sStripped = StringRegExpReplace($sHeader, "^\[WT\]\s*", "")

		Local $sAppName = StringRegExpReplace($sStripped, "\s*\(v[^)]+\).*$", "")
		$sAppName = StringRegExpReplace($sAppName, "\s*\(\d+\s+file[s]?\)$", "")

		Local $sNewHeader = $sStripped
		If IsObj($g_mWinTrustQueue) And $g_mWinTrustQueue.Exists($sAppName) Then
			If $g_mWinTrustQueue.Item($sAppName) = "1" Then $sNewHeader = "[WT] " & $sStripped
		EndIf

		If $sNewHeader <> $sHeader Then
			_GUICtrlListView_SetGroupInfo($idListview, $iGid, $sNewHeader, $aInfo[1], $LVGS_COLLAPSIBLE)
		EndIf
	Next
EndFunc

Func _UpdateCollapseHeader()
	Local $sLabel = ($MyLVGroupIsExpanded = 1) ? "Collapse All" : "Expand All"
	_GUICtrlListView_SetColumn($idListview, 1, "  App File                                                         " & $sLabel)
EndFunc

Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

			For $i = 0 To UBound($g_aGroupIDs) - 1
				$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $g_aGroupIDs[$i])
				If IsArray($aInfo) Then
					_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
			_RedrawWindow($idListview)
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
		_UpdateCollapseHeader()
	EndIf
EndFunc

Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

		For $i = 0 To UBound($g_aGroupIDs) - 1
			$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $g_aGroupIDs[$i])
			If IsArray($aInfo) Then
				_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
		_RedrawWindow($idListview)
	EndIf
EndFunc

Func _SendMessageL($hWnd, $Msg, $wParam, $lParam)
	Return DllCall("user32.dll", "LRESULT", "SendMessageW", "HWND", GUICtrlGetHandle($hWnd), "UINT", $Msg, "WPARAM", $wParam, "LPARAM", $lParam)[0]
EndFunc

Func _RedrawWindow($hWnd)
	DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", GUICtrlGetHandle($hWnd), "ptr", 0, "ptr", 0, "uint", 0x0100)
EndFunc

Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) = $idButtonStop Then $fInterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	Local $iCode = DllStructGetData($tNMHDR, "Code")

	If $g_bIsPatching And $hWndFrom = GUICtrlGetHandle($hTab) Then
		If $iCode = -402 Then
			Local $iTarget = _GUICtrlTab_GetCurFocus($hTab)
			If $iTarget <> 0 And $iTarget <> $g_iLogTabIndex Then
				Return 1
			EndIf
		ElseIf $iCode = -551 Then
			Local $iNow = _GUICtrlTab_GetCurFocus($hTab)
			If $iNow <> 0 And $iNow <> $g_iLogTabIndex Then
				_GUICtrlTab_SetCurFocus($hTab, 0)
				MemoWrite(@CRLF & "Tab switching is locked during patch/restore. Returning to Main.")
			EndIf
		EndIf
	EndIf

	If $g_bPendingInfoReset And Not $g_bIsPatching And $hWndFrom = GUICtrlGetHandle($hTab) Then
		If $iCode = -551 Then
			Local $iDest = _GUICtrlTab_GetCurFocus($hTab)
			If $iDest <> 0 Then
				$g_bPendingInfoReset = False
				$fFilesListed = 0
				$g_bSearchCompleted = False
				ReDim $g_aAllFiles[0][6]
				$g_mCheckedState.RemoveAll()
				FillListViewWithInfo()
				UpdateUIState()
			EndIf
		EndIf
	EndIf

	Switch $hWndFrom
		Case $g_idListview
			Switch $iCode
				Case $LVN_COLUMNCLICK
					_Collapse_All_Click()
				Case $NM_CLICK
					_ListView_LeftClick($g_idListview, $lParam)
				Case $NM_RCLICK
					_ListView_RightClick()
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc

Func hL_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF)
	Local $iCode = BitShift($wParam, 16)

	If $iCode = $STN_CLICKED Then
		If $iIDFrom = $g_idHyperlinkMain Or $iIDFrom = $g_idHyperlinkLog Or $iIDFrom = $g_idHyperlinkOptions _
				Or $iIDFrom = $g_idHyperlinkPopup Or $iIDFrom = $g_idHyperlinkFW _
				Or $iIDFrom = $g_idHyperlinkHosts Or $iIDFrom = $g_idHyperlinkWT _
				Or $iIDFrom = $g_idHyperlinkAGS Or $iIDFrom = $g_idHyperlinkProxy Then
			Local $sUrl = Deloader($g_aSignature)
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute($sUrl)
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
			Return $GUI_RUNDEFMSG
		EndIf
	EndIf

	If $g_bMitmLogWindowExists And $hWnd = $g_hMitmLogWin Then
		If $iIDFrom = $g_idBtnLogClose Then
			GUISetState(@SW_HIDE, $g_hMitmLogWin)
			Return $GUI_RUNDEFMSG

		ElseIf $iIDFrom = $g_idBtnLogClear Then
			_GUICtrlRichEdit_SetText($g_hMitmRichEdit, "")
			_AppendToLogWindow("# Log cleared." & @CRLF & @CRLF)
			Return $GUI_RUNDEFMSG

		ElseIf $iIDFrom = $g_idBtnLogAddToHosts Then
			Local $sLogText = _GUICtrlRichEdit_GetText($g_hMitmRichEdit)
			If StringStripWS($sLogText, 3) = "" Then
				MsgBox(16, "Error", "The proxy activity log is empty.")
				Return $GUI_RUNDEFMSG
			EndIf

			Local $aDomainMatch = StringRegExp($sLogText, '(?i)([A-Za-z0-9_.-]+\.adobestats\.io)', 1)
			If @error Then
				MsgBox(48, "Warning", "No active Adobe telemetry domains found in current log data.")
				Return $GUI_RUNDEFMSG
			EndIf
			Local $sTargetDomain = StringLower($aDomainMatch[0])

			If _IsMitmproxyRunning() Then
				_StopMitmproxy()
				_DisableWindowsProxy()
				_AppendToLogWindow("# Proxy engine deactivated to release hosts lock." & @CRLF)
			EndIf

			If _SilentHostsInjector($sTargetDomain) Then
				MsgBox(64, "Success", "Adobe Endpoint Block updated successfully (manual)!" & @CRLF & @CRLF & _
						"Block Rule Entries:" & @CRLF & _
						"0.0.0.0 ic.adobe.io" & @CRLF & _
						"0.0.0.0 " & $sTargetDomain & @CRLF & @CRLF & _
						"The rule has been saved to your hosts file and local DNS cache flushed.")
			Else
				MsgBox(16, "Error", "Could not write to the hosts file." & @CRLF & @CRLF & "Ensure the application is running as Administrator.")
			EndIf

			_RefreshProxyStatus()
			Return $GUI_RUNDEFMSG
		EndIf
	EndIf

	Return WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
EndFunc

Func _Exit()
	Exit
EndFunc

Func IniReadArray($FileName, $section, $key, $default)
	Local $sINI = IniRead($FileName, $section, $key, $default)
	$sINI = StringReplace($sINI, '"', '')
	StringReplace($sINI, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sINI, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc

Func ReplaceToArray($sParam)
	Local $sString = StringReplace($sParam, '"', '')
	StringReplace($sString, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sString, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func SaveOptionsToConfig()
	If _IsChecked($idResetOnSave) Then
		Local $iConfirm = MsgBox(BitOR($MB_YESNO, $MB_ICONEXCLAMATION), _
				"Reset Patch States?", _
				"Delete patch_states.ini? All recorded patch/restore history" & @CRLF & _
				"(MD5 hashes, Patched/Unpatched flags, app versions) will be lost." & @CRLF & @CRLF & _
				"Your actual patched files on disk are NOT affected - only GenP's" & @CRLF & _
				"internal record of what it has patched.")
		If $iConfirm = $IDYES Then
			If FileExists($patchStatesINI) Then
				Local $sBackupPath = $patchStatesINI & ".before-reset-" & _
						@YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & @MIN & @SEC & ".bak"
				If FileCopy($patchStatesINI, $sBackupPath, 1) Then
					LogWrite(1, "Reset Patch States: backup created at " & $sBackupPath)
				Else
					LogWrite(1, "Reset Patch States: WARNING - backup copy failed; deleting anyway as user requested.")
				EndIf
				If FileDelete($patchStatesINI) Then
					IniWrite($sINIPath, "Options", "CreatedNew",        "0")
					IniWrite($sINIPath, "Options", "CreatedNewDate",    "")
					IniWrite($sINIPath, "Options", "ReconcileUsed",     "0")
					IniWrite($sINIPath, "Options", "ReconcileUsedDate", "")
					$g_sToolbarApps = ""
					_RefreshAppsToolbar()
					MemoWrite(@CRLF & "patch_states.ini deleted at user request (backup: " & $sBackupPath & ").")
					LogWrite(1, "Reset Patch States: deleted " & $patchStatesINI)
				Else
					MemoWrite(@CRLF & "Error: could not delete patch_states.ini (file in use?).")
					LogWrite(1, "Reset Patch States FAILED: " & $patchStatesINI)
				EndIf
			Else
				LogWrite(1, "Reset Patch States: no patch_states.ini present, nothing to delete.")
			EndIf
		EndIf
		GUICtrlSetState($idResetOnSave, $GUI_UNCHECKED)
	EndIf

	If _IsChecked($idFinalCleanCheck) Then
		_RunFinalCleanCheck()
		GUICtrlSetState($idFinalCleanCheck, $GUI_UNCHECKED)
	EndIf

	If _IsChecked($idCreateStates) Then
		If FileExists($patchStatesINI) Then
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Cannot create new patch_states.ini", _
					"A patch_states.ini already exists at:" & @CRLF & $patchStatesINI & @CRLF & @CRLF & _
					"Use 'Reconcile imported patch_states.ini' instead, which validates" & @CRLF & _
					"the existing file against your current install.")
		Else
			_CreateInitialPatchStates()
		EndIf
		GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
	EndIf

	If _IsChecked($idReconcileStates) Then
		_ReconcilePatchStates()
		GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
	EndIf

	IniWrite($sINIPath, "Options", "FindACC", _IsChecked($idFindACC) ? "1" : "0")
	IniDelete($sINIPath, "Options", "EnableMD5")
	IniWrite($sINIPath, "Options", "OnlyDefaultFolders", _IsChecked($idOnlyAFolders) ? "1" : "0")
	IniWrite($sINIPath, "Options", "ShowBetaApps", _IsChecked($idShowBetaApps) ? "1" : "0")
	IniWrite($sINIPath, "Options", "EnableGood1", _IsChecked($idEnableGood1) ? "1" : "0")
	IniWrite($sINIPath, "Options", "ClearLicenseCaches", _IsChecked($idClearLicCaches) ? "1" : "0")
	Local $bNGLDisplayChanged = ($bEnableNGLFirewall <> (_IsChecked($idEnableNGLFirewall) ? 1 : 0))
	$bEnableNGLFirewall = _IsChecked($idEnableNGLFirewall) ? 1 : 0
	IniWrite($sINIPath, "Options", "NGLFirewall", $bEnableNGLFirewall ? "1" : "0")
	$bShowLaunchBar = _IsChecked($idShowLaunchBar) ? 1 : 0
	IniWrite($sINIPath, "Options", "ShowLaunchBar", $bShowLaunchBar ? "1" : "0")
	If $bShowLaunchBar Then
		If Not FileExists($patchStatesINI) Then
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION, $MB_SYSTEMMODAL), "Launch Toolbar", _
					"No patch_states.ini found." & @CRLF & @CRLF & _
					"The toolbar will not be shown until one is created." & @CRLF & _
					"Use 'Create new patch_states.ini' in the First Run Options.")
			$bShowLaunchBar = 0
			IniWrite($sINIPath, "Options", "ShowLaunchBar", "0")
			GUICtrlSetState($idShowLaunchBar, $GUI_UNCHECKED)
		ElseIf Not _PatchStatesSetupDone() Then
			MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Launch Toolbar", _
					"patch_states.ini exists but setup has not been verified." & @CRLF & @CRLF & _
					"The toolbar requires that one of the following was completed:" & @CRLF & @CRLF & _
					"  - Create new patch_states.ini, or" & @CRLF & _
					"  - Reconcile imported patch_states.ini" & @CRLF & @CRLF & _
					"Run the appropriate option in First Run Options and save again.")
			$bShowLaunchBar = 0
			IniWrite($sINIPath, "Options", "ShowLaunchBar", "0")
			GUICtrlSetState($idShowLaunchBar, $GUI_UNCHECKED)
		EndIf
	EndIf
	_RefreshAppsToolbar()

	If $bNGLDisplayChanged And $g_idListview <> 0 Then _ApplyVisibilityFilter()
	IniWrite($sINIPath, "Options", "UseCustomDefault", _IsChecked($idUseCustomDefault) ? "1" : "0")
	Local $sTypedPath = StringStripWS(GUICtrlRead($idBtnSetCustomPath), 3)
	Local $sDefaultPath = @ProgramFilesDir & "\Adobe"
	If _IsChecked($idUseCustomDefault) Then
		If $sTypedPath <> "" And FileExists($sTypedPath) And StringInStr(FileGetAttrib($sTypedPath), "D") Then
			IniWrite($sINIPath, "Custom_Default", "Path", $sTypedPath)
			$g_sCustomDefaultPath = $sTypedPath
			$g_sPendingCustomPath = $sTypedPath
		Else
			MsgBox($MB_OK, "No custom path set", _
					"'Use custom default search path' is ticked but the path is empty or invalid." & @CRLF & @CRLF & _
					"At next launch the tool will revert to " & $sDefaultPath & "." & @CRLF & _
					"Set a valid folder and save again to enable the custom path.")
			$g_sCustomDefaultPath = ""
			$g_sPendingCustomPath = ""
			IniDelete($sINIPath, "Custom_Default", "Path")
			IniDelete($sINIPath, "Custom_Default")
		EndIf
	Else
		$g_sPendingCustomPath = ""
		$g_sCustomDefaultPath = ""
		IniDelete($sINIPath, "Custom_Default", "Path")
		IniDelete($sINIPath, "Custom_Default")
		GUICtrlSetData($idBtnSetCustomPath, $sDefaultPath)
	EndIf

	Local $sOldDefPath = $MyDefPath
	If _IsChecked($idUseCustomDefault) And $g_sCustomDefaultPath <> "" _
			And FileExists($g_sCustomDefaultPath) And StringInStr(FileGetAttrib($g_sCustomDefaultPath), "D") Then
		$MyDefPath = StringRegExpReplace($g_sCustomDefaultPath, "\\+", "\\")
	Else
		$MyDefPath = StringRegExpReplace(@ProgramFilesDir & "\Adobe", "\\+", "\\")
	EndIf
	If $MyDefPath <> $sOldDefPath Then
		$g_bSearchCompleted = False
		If $g_idListview <> 0 Then FillListViewWithInfo()
		MemoWrite(@CRLF & "Search path updated to:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the Search button to scan the new location.")
		LogWrite(1, "Search path changed (immediate apply): " & $MyDefPath)
	EndIf

	Local $sNewDomainListURL = StringStripWS(GUICtrlRead($idCustomDomainListInput), 1)
	If $sNewDomainListURL = "" Then
		$sNewDomainListURL = $sDefaultDomainListURL
		GUICtrlSetData($idCustomDomainListInput, $sNewDomainListURL)
		MsgBox(0, "Empty URL", "The custom domain list URL cannot be empty. Default URL set.")
	EndIf

	If $sNewDomainListURL <> $sCurrentDomainListURL Then
		IniWrite($sINIPath, "Options", "CustomDomainListURL", $sNewDomainListURL)
		$sCurrentDomainListURL = $sNewDomainListURL
	EndIf

	If $bUseCustomWinTrust = 1 And $g_sWinTrustPath <> "" And $g_sWinTrustPath <> @ProgramFilesDir & "\Adobe" Then
		IniWrite($sINIPath, "Custom_WinTrust", "Path", $g_sWinTrustPath)
	EndIf
	IniDelete($sINIPath, "Options", "WinTrustPath")
	_TidyConfigSpacing($sINIPath)
	_SnapshotOptions()

	MemoWrite(@CRLF & "Options saved to config.ini.")
	LogWrite(1, "Options saved.")
EndFunc

Func Deloader($sLoaded)
	Local $sDeloaded = ""
	For $i = 1 To StringLen($sLoaded)
		Local $iAscii = Asc(StringMid($sLoaded, $i, 1))
		Local $iShifted = $iAscii - 10
		If $iShifted < 32 Then
			$iShifted = 126 - (31 - $iShifted)
		EndIf
		$sDeloaded &= Chr($iShifted)
	Next
	Return $sDeloaded
EndFunc

Func ShowInfoPopup($sText)
	Local $aMainPos = WinGetPos($MyhGUI)
	If @error Then
		Local $iPopupX = -1
		Local $iPopupY = -1
	Else
		Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
		Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 100) / 2
	EndIf

	Local $hPopup = GUICreate("", 300, 100, $iPopupX, $iPopupY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	Local $idEdit = GUICtrlCreateEdit($sText, 10, 10, 280, 80, BitOR($ES_READONLY, $ES_MULTILINE, $ES_AUTOVSCROLL), 0)
	GUICtrlSetBkColor($idEdit, 0xF0F0F0)
	GUISetState(@SW_SHOW, $hPopup)
	_GUICtrlEdit_SetSel($idEdit, -1, -1)
	While WinActive($hPopup)
		If GUIGetMsg() = $GUI_EVENT_CLOSE Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc

Func _CollectNGLBinaries()
	Local $aOut[0]
	Local $aDrives = DriveGetDrive("FIXED")
	If @error Then Return $aOut
	Local $aRel = $g_aNGLRelativePaths
	For $d = 1 To $aDrives[0]
		Local $sRoot = StringUpper($aDrives[$d])
		Local $aBase[3] = [$sRoot & "\Program Files\", $sRoot & "\Program Files (x86)\", $sRoot & "\"]
		For $b = 0 To 2
			For $p = 0 To UBound($aRel) - 1
				Local $sTarget = StringRegExpReplace($aBase[$b] & $aRel[$p], "\\\\+", "\\")
				If FileExists($sTarget) Then _ArrayAdd($aOut, $sTarget)
			Next
		Next
	Next
	Return $aOut
EndFunc

Func _WinFirewallServiceReady()
	Local $iPID = Run('powershell.exe -NoProfile -Command "(Get-Service -Name MpsSvc -ErrorAction SilentlyContinue).Status"', "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID, 5000)
	Return StringInStr(StringStripWS(StdoutRead($iPID), 3), "Running") > 0
EndFunc

Func _GetExistingNGLRuleProgs($sGroup)
	Local $mDict = ObjCreate("Scripting.Dictionary")
	Local $sInner = "Get-NetFirewallRule -Group '" & $sGroup & "' -ErrorAction SilentlyContinue | Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program"
	Local $iPID = Run('powershell.exe -NoProfile -Command "' & $sInner & '"', "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID, 8000)
	Local $aLines = StringSplit(StringStripWS(StdoutRead($iPID), 3), @CRLF, 1)
	For $i = 1 To $aLines[0]
		Local $sL = StringStripWS($aLines[$i], 3)
		If $sL <> "" Then $mDict.Item(StringLower($sL)) = 1
	Next
	Return $mDict
EndFunc

Func RemoveAGS()
	If Not _RequireAdmin("remove AGS") Then Return
	GUICtrlSetState($idBtnRemoveAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "Removing AGS from this Computer" & @CRLF & "---" & @CRLF & "Please wait...")

	Local $aServices = ["AGMService", "AGSService"]
	Local $ProgramFilesX86 = EnvGet("ProgramFiles(x86)")
	Local $PublicDir = EnvGet("PUBLIC")
	Local $WinDir = @WindowsDir
	Local $LocalAppData = EnvGet("LOCALAPPDATA")
	Local $AcrobatDCAGS = _FindAcrobatDCAGS()
	Local $aPaths[10] = [ _
			$ProgramFilesX86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe", _
			$ProgramFilesX86 & "\Common Files\Adobe\AdobeGCClient", _
			$ProgramFilesX86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient", _
			$PublicDir & "\Documents\AdobeGCData", _
			$WinDir & "\System32\Tasks\AdobeGCInvoker-1.0", _
			$WinDir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0", _
			$ProgramFilesX86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe", _
			$WinDir & "\Temp\adobegc.log", _
			$LocalAppData & "\Temp\adobegc.log", _
			$AcrobatDCAGS _
			]

	Local $iServiceSuccess = 0
	For $sService In $aServices
		Local $iExistCode = RunWait("sc query " & $sService, "", @SW_HIDE)
		If $iExistCode = 1060 Then
			LogWrite(1, "Service not found: " & $sService)
			ContinueLoop
		ElseIf $iExistCode <> 0 Then
			LogWrite(1, "Error checking service " & $sService & " (exit code: " & $iExistCode & ")")
			ContinueLoop
		EndIf
		LogWrite(1, "Service found: " & $sService)

		Local $iStopPID = Run("sc stop " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iStopPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iStopPID)
			LogWrite(1, "Warning: Failed to stop " & $sService & " - timed out after " & $iTimeout & "ms")
		Else
			Local $iStopCode = @error ? 1 : 0
			If $iStopCode = 0 Or StringInStr(StderrRead($iStopPID), "1052") Then
				LogWrite(1, "Service stopped: " & $sService)
			Else
				LogWrite(1, "Failed to stop service " & $sService & " (possible error)")
			EndIf
		EndIf

		Local $iDeletePID = Run("sc delete " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		$iWaitResult = ProcessWaitClose($iDeletePID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iDeletePID)
			LogWrite(1, "Warning: Failed to delete " & $sService & " - timed out after " & $iTimeout & "ms")
		Else
			Local $iDeleteCode = @error ? 1 : 0
			If $iDeleteCode = 0 Then
				LogWrite(1, "Service deleted: " & $sService)
				$iServiceSuccess += 1
			Else
				LogWrite(1, "Failed to delete service " & $sService & " (possible error)")
			EndIf
		EndIf
	Next

	Local $iFileSuccess = 0
	For $sPath In $aPaths
		If $sPath = "" Then ContinueLoop
		If FileExists($sPath) Then
			If StringInStr(FileGetAttrib($sPath), "D") Then
				If DirRemove($sPath, 1) Then
					LogWrite(1, "Deleted directory: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "Failed to delete directory: " & $sPath)
				EndIf
			Else
				If FileDelete($sPath) Then
					LogWrite(1, "Deleted file: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "Failed to delete file: " & $sPath)
				EndIf
			EndIf
		Else
			LogWrite(1, "File or folder not found: " & $sPath)
		EndIf
	Next

	LogWrite(1, "Initialising localised background sandbox and credential vault purge...")

	Local $sAcroCefCache = @LocalAppDataDir & "\Adobe\AcroCef\Cache"
	If FileExists($sAcroCefCache) Then
		If DirRemove($sAcroCefCache, 1) Then
			LogWrite(1, "Purged localised Acrobat sandbox cache directory context: " & $sAcroCefCache)
		Else
			LogWrite(1, "Warning: Acrobat web sandbox files locked or currently in use.")
		EndIf
	EndIf

	Local $sOobeCache = @LocalAppDataDir & "\Adobe\OOBE"
	If FileExists($sOobeCache) Then
		If DirRemove($sOobeCache, 1) Then
			LogWrite(1, "Purged local workstation user space workspace markers: " & $sOobeCache)
		EndIf
	EndIf

	RunWait("ipconfig /flushdns", "", @SW_HIDE)
	LogWrite(1, "Local computer network resolution table flushed cleanly.")

	MemoWrite("AGS removal completed. Successfully processed " & $iServiceSuccess & " of " & UBound($aServices) & " services and " & $iFileSuccess & " of " & UBound($aPaths) & " files.")
	LogWrite(1, "AGS removal completed. Services: " & $iServiceSuccess & "/" & UBound($aServices) & ", Files: " & $iFileSuccess & "/" & UBound($aPaths) & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnRemoveAGS, $GUI_ENABLE)
EndFunc

Func _FindAcrobatDCAGS()
	Local $aCandidateRoots[4]
	$aCandidateRoots[0] = $MyDefPath & "\Acrobat DC\Acrobat"

	Local $sInstallPath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Adobe Acrobat\DC\InstallPath", "")
	If Not @error And $sInstallPath <> "" Then
		$aCandidateRoots[1] = StringRegExpReplace($sInstallPath, "\\$", "")
	EndIf

	Local $sAcroExe = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Acrobat.exe", "")
	If Not @error And $sAcroExe <> "" Then
		$aCandidateRoots[2] = StringRegExpReplace($sAcroExe, "\\[^\\]+$", "")
	EndIf

	$aCandidateRoots[3] = EnvGet("ProgramFiles") & "\Adobe\Acrobat DC\Acrobat"

	For $sRoot In $aCandidateRoots
		If $sRoot = "" Then ContinueLoop
		If FileExists($sRoot) Then Return $sRoot & "\GC\AGSService.exe"
	Next

	Return ""
EndFunc

Func InstallAGSDummy()
	If Not _RequireAdmin("install the AGS placeholder") Then Return
	Local $iFileSuccess = 0, $iRegSuccess = 0, $iConsentFileSuccess = 0, $iServiceSuccess = 0
	GUICtrlSetState($idBtnDummyAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "Installing AGS Redirection (Dummy Mode)..." & @CRLF & "---" & @CRLF & "Please wait...")

	Local $ProgramFiles = EnvGet("ProgramFiles")
	Local $AGSFolder = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe\AdobeGCClient"
	Local $AcrobatDCAGS = _FindAcrobatDCAGS()
	Local $aFiles = ["AdobeGCClient.exe", "AGMService.exe", "AGSService.exe"]
	Local $aServices = ["AGMService", "AGSService"]
	Local $NotepadPath = @WindowsDir & "\System32\notepad.exe"
	Local $PublicConsentDir = EnvGet("PUBLIC") & "\Documents\AdobeGCInfo"
	Local $PublicConsentFile = $PublicConsentDir & "\ConsentRecord"

	For $sFile In $aFiles
		If ProcessExists($sFile) Then
			ProcessClose($sFile)
			ProcessWaitClose($sFile, 2000)
			LogWrite(1, "Terminated process: " & $sFile)
		EndIf
	Next

	For $sService In $aServices
		If RunWait("sc config " & $sService & " start= disabled", "", @SW_HIDE) = 0 Then
			LogWrite(1, "Service disabled: " & $sService)
			$iServiceSuccess += 1
		EndIf
	Next

	If Not FileExists($AGSFolder) Then DirCreate($AGSFolder)
	For $sFile In $aFiles
		Local $Dest = $AGSFolder & "\" & $sFile
		Local $sDest_bak = $Dest & ".bak"
		If FileExists($Dest) And Not FileExists($sDest_bak) Then
			If FileCopy($Dest, $sDest_bak, 0) Then
				LogWrite(1, "Backed up: " & $Dest)
			Else
				LogWrite(1, "Backup FAILED - skipping: " & $Dest)
				ContinueLoop
			EndIf
		EndIf
		FileSetAttrib($Dest, "-RASH")
		If FileCopy($NotepadPath, $Dest, 9) Then
			LogWrite(1, "Dummy created at AdobeGCClient path: " & $Dest)
			$iFileSuccess += 1
		EndIf
	Next

	If $AcrobatDCAGS <> "" Then
		If ProcessExists("AGSService.exe") Then
			ProcessClose("AGSService.exe")
			ProcessWaitClose("AGSService.exe", 2000)
		EndIf
		Local $sAcroParent = StringRegExpReplace($AcrobatDCAGS, "\\[^\\]+$", "")
		If Not FileExists($sAcroParent) Then DirCreate($sAcroParent)
		Local $sAcroBak = $AcrobatDCAGS & ".bak"
		If FileExists($AcrobatDCAGS) And Not FileExists($sAcroBak) Then
			If FileCopy($AcrobatDCAGS, $sAcroBak, 0) Then
				LogWrite(1, "Backed up Acrobat DC AGS: " & $AcrobatDCAGS)
			Else
				LogWrite(1, "Backup FAILED for Acrobat DC AGS - skipping: " & $AcrobatDCAGS)
				$AcrobatDCAGS = ""
			EndIf
		EndIf
		FileSetAttrib($AcrobatDCAGS, "-RASH")
		If FileCopy($NotepadPath, $AcrobatDCAGS, 9) Then
			LogWrite(1, "Dummy created at Acrobat DC path: " & $AcrobatDCAGS)
			$iFileSuccess += 1
		Else
			LogWrite(1, "Failed to dummy Acrobat DC AGSService.exe at: " & $AcrobatDCAGS)
		EndIf
	Else
		LogWrite(1, "Acrobat DC not detected on this system - skipping its AGSService.exe.")
	EndIf

	Local $RegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Adobe Genuine Service\Consent\Retail"
	Local $sMultiString = "UserType: GreenZone" & @LF & "Consent: Consented | DateAndTime: 1757294112 | DontAskAgain: Yes | ConsentedButtonText: OK | Retries: 0 | Pending: No"
	If RegWrite($RegPath, "ConsentInfo", "REG_MULTI_SZ", $sMultiString) Then
		LogWrite(1, "Registry patched to GreenZone")
		$iRegSuccess = 1
	EndIf

	If Not FileExists($PublicConsentDir) Then DirCreate($PublicConsentDir)
	FileSetAttrib($PublicConsentFile, "-RASH")
	Local $hFile = FileOpen($PublicConsentFile, 2)
	If $hFile <> -1 Then
		FileWriteLine($hFile, "UserType: GreenZone | Source: 1757294112-CCD")
		FileWriteLine($hFile, "Consent: Consented | DateAndTime: 1757294112 | DontAskAgain: Yes | ConsentedButtonText: OK | Retries: 0 | Pending: No")
		FileClose($hFile)
		LogWrite(1, "ConsentRecord file patched")
		$iConsentFileSuccess = 1
	EndIf

	LogWrite(1, "Initialising localised background sandbox and credential vault purge...")

	Local $sAcroCefCache = @LocalAppDataDir & "\Adobe\AcroCef\Cache"
	If FileExists($sAcroCefCache) Then
		If DirRemove($sAcroCefCache, 1) Then
			LogWrite(1, "Purged localised Acrobat sandbox cache directory context: " & $sAcroCefCache)
		Else
			LogWrite(1, "Warning: Acrobat web sandbox files locked or currently in use.")
		EndIf
	EndIf

	Local $sOobeCache = @LocalAppDataDir & "\Adobe\OOBE"
	If FileExists($sOobeCache) Then
		If DirRemove($sOobeCache, 1) Then
			LogWrite(1, "Purged local workstation user space workspace markers: " & $sOobeCache)
		EndIf
	EndIf

	RunWait("ipconfig /flushdns", "", @SW_HIDE)
	LogWrite(1, "Local computer network resolution table flushed cleanly.")

	MemoWrite("AGS Redirection completed. Services Disabled: " & $iServiceSuccess & ", Dummies: " & $iFileSuccess & ", Registry: " & ($iRegSuccess ? "OK" : "Failed") & ", Consent File: " & ($iConsentFileSuccess ? "OK" : "Failed"))
	LogWrite(1, "AGS Dummy Mode completed. Files: " & $iFileSuccess & ", Reg: " & $iRegSuccess & ", File: " & $iConsentFileSuccess & @CRLF)

	ToggleLog(1)
	GUICtrlSetState($idBtnDummyAGS, $GUI_ENABLE)
	GUICtrlSetState($idBtnRestoreAGS, $GUI_ENABLE)
EndFunc

Func RestoreAGSDummy()
	If Not _RequireAdmin("restore the AGS files") Then Return
	GUICtrlSetState($idBtnRestoreAGS, $GUI_DISABLE)
	GUICtrlSetState($idBtnDummyAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "Restore AGS - restoring original files from backup..." & @CRLF & "---" & @CRLF & "Please wait...")

	Local $AGSFolder = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe\AdobeGCClient"
	Local $AcrobatDCAGS = _FindAcrobatDCAGS()
	Local $aAGSFiles = ["AdobeGCClient.exe", "AGMService.exe", "AGSService.exe"]
	Local $aTargets
	For $sF In $aAGSFiles
		_ArrayAdd($aTargets, $AGSFolder & "\" & $sF)
	Next
	If $AcrobatDCAGS <> "" Then _ArrayAdd($aTargets, $AcrobatDCAGS)

	Local $bAnyBak = False
	For $i = 0 To UBound($aTargets) - 1
		If FileExists($aTargets[$i] & ".bak") Then
			$bAnyBak = True
			ExitLoop
		EndIf
	Next
	If Not $bAnyBak Then
		MemoWrite(@CRLF & "Restore AGS: No backup files found." & @CRLF & @CRLF & _
				"No backup files (.bak) found for AGS components." & @CRLF & _
				"To restore original files, use the Creative Cloud App Uninstaller Tool to repair Creative Cloud Desktop.")
		LogWrite(1, "Restore AGS: No .bak files found. Use CC App Uninstaller Tool to repair Creative Cloud Desktop." & @CRLF)
		ToggleLog(1)
		GUICtrlSetState($idBtnRestoreAGS, $GUI_DISABLE)
		GUICtrlSetState($idBtnDummyAGS, $GUI_ENABLE)
		Return
	EndIf

	Local $aProcs = ["AdobeGCClient.exe", "AGMService.exe", "AGSService.exe"]
	For $sProc In $aProcs
		If ProcessExists($sProc) Then
			ProcessClose($sProc)
			ProcessWaitClose($sProc, 2000)
			LogWrite(1, "Terminated process: " & $sProc)
		EndIf
	Next

	Local $iRestored = 0, $iSkipped = 0, $iFailed = 0
	For $i = 0 To UBound($aTargets) - 1
		Local $sTarget = $aTargets[$i]
		Local $sBackup = $sTarget & ".bak"
		If Not FileExists($sBackup) Then
			LogWrite(1, "No backup found - skipping: " & $sTarget)
			$iSkipped += 1
			ContinueLoop
		EndIf
		_VerifyBackupAgainstLedger($sTarget, $sBackup)
		FileSetAttrib($sTarget, "-RASH")
		If FileCopy($sBackup, $sTarget, 9) Then
			FileDelete($sBackup)
			LogWrite(1, "Restored: " & $sTarget)
			$iRestored += 1
		Else
			LogWrite(1, "Restore FAILED: " & $sTarget)
			$iFailed += 1
		EndIf
	Next

	LogWrite(1, "Initialising localised background sandbox and credential vault purge...")
	Local $sAcroCefCache = @LocalAppDataDir & "\Adobe\AcroCef\Cache"
	If FileExists($sAcroCefCache) Then
		If DirRemove($sAcroCefCache, 1) Then
			LogWrite(1, "Purged localised Acrobat sandbox cache directory context: " & $sAcroCefCache)
		Else
			LogWrite(1, "Warning: Acrobat web sandbox files locked or currently in use.")
		EndIf
	EndIf

	Local $sOobeCache = @LocalAppDataDir & "\Adobe\OOBE"
	If FileExists($sOobeCache) Then
		If DirRemove($sOobeCache, 1) Then
			LogWrite(1, "Purged local workstation user space workspace markers: " & $sOobeCache)
		EndIf
	EndIf

	RunWait("ipconfig /flushdns", "", @SW_HIDE)
	LogWrite(1, "Local computer network resolution table flushed cleanly.")

	Local $sSummary = "Restore AGS completed.  Restored: " & $iRestored & _
			"  Skipped (no .bak): " & $iSkipped & "  Failed: " & $iFailed
	MemoWrite($sSummary)
	LogWrite(1, $sSummary & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnRestoreAGS, $GUI_DISABLE)
	GUICtrlSetState($idBtnDummyAGS, $GUI_ENABLE)
EndFunc

Func RemoveHostsEntries()
	If Not _RequireAdmin("modify the Windows hosts file") Then Return
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sTempHosts = @TempDir & "\temp_hosts_remove.tmp"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	FileSetAttrib($sHostsPath, "-R")

	Local $sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("Error reading hosts file." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf

	If Not StringInStr($sHostsContent, $sMarkerStart) Or Not StringInStr($sHostsContent, $sMarkerEnd) Then
		LogWrite(1, "No entries to remove." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		ToggleLog(1)
		Return True
	EndIf

	$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)" & $sMarkerStart & ".*?" & $sMarkerEnd, "")

	Local $hTempFile = FileOpen($sTempHosts, 2)
	If $hTempFile = -1 Then
		MemoWrite("Error creating temp hosts file for removal." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileWrite($hTempFile, $sHostsContent)
	FileClose($hTempFile)

	If Not FileCopy($sTempHosts, $sHostsPath, 1) Then
		MemoWrite("Error writing updated hosts file." & @CRLF)
		MemoWrite("Attempting to copy from: " & $sTempHosts & " to: " & $sHostsPath & @CRLF)
		FileDelete($sTempHosts)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileDelete($sTempHosts)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "Hosts file cleaned of existing entries." & @CRLF)
	ToggleLog(1)
	Return True
EndFunc

Func ScanDNSCache(ByRef $sHostsContent)
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	Local $sBlockSection = StringRegExp($sHostsContent, "(?s)" & $sMarkerStart & "(.*?)" & $sMarkerEnd, 1)
	If @error Or UBound($sBlockSection) = 0 Then
		MemoWrite("Error parsing blocklist from hosts content." & @CRLF)
		Return 0
	EndIf
	Local $aCurrentDomains = StringSplit(StringStripWS($sBlockSection[0], 8), @CRLF, 2)
	Local $aHostsDomains[0]
	For $i = 0 To UBound($aCurrentDomains) - 1
		Local $sLine = StringStripWS($aCurrentDomains[$i], 3)
		If StringRegExp($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$") Then
			_ArrayAdd($aHostsDomains, StringRegExpReplace($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$", "$1"))
		EndIf
	Next
	_ArraySort($aHostsDomains)
	_ArrayUnique($aHostsDomains)

	Local $sTempDNS = @TempDir & "\dns_cache.txt"
	Local $iPID = Run(@ComSpec & " /c ipconfig /displaydns > " & $sTempDNS, "", @SW_HIDE)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: ipconfig /displaydns timed out after " & $iTimeout & "ms." & @CRLF)
	EndIf

	Local $sDNSCache = FileRead($sTempDNS)
	If @error Then
		MemoWrite("Error reading DNS cache." & @CRLF)
		FileDelete($sTempDNS)
		Return 0
	EndIf
	FileDelete($sTempDNS)

	Local $aDNSDomains = StringRegExp($sDNSCache, "Record Name[^\n]*?\n\s*:\s*([^\n]*(?:adobestats\.io|ic\.adobe\.io)[^\n]*)", 3)
	If UBound($aDNSDomains) = 0 Then
		Return 0
	EndIf
	_ArraySort($aDNSDomains)
	_ArrayUnique($aDNSDomains)

	Local $aNewDomains[0]
	For $i = 0 To UBound($aDNSDomains) - 1
		Local $sDomain = StringStripWS($aDNSDomains[$i], 3)
		If _ArraySearch($aHostsDomains, $sDomain) = -1 Then
			_ArrayAdd($aNewDomains, $sDomain)
		EndIf
	Next

	If UBound($aNewDomains) = 0 Then
		Return 0
	EndIf

	Local $sPrompt = "Found " & UBound($aNewDomains) & " new domain(s) in DNS cache:" & @CRLF & _
			_ArrayToString($aNewDomains, @CRLF) & @CRLF & "Add to hosts file?"
	Local $iResponse = MsgBox($MB_YESNO + $MB_ICONQUESTION, "New Domains Detected", $sPrompt)
	If $iResponse = $IDNO Then
		MemoWrite("User declined to add new DNS domains." & @CRLF)
		Return 0
	EndIf

	Return $aNewDomains
EndFunc

Func _RunGetOutput($sCmd)
	Local $iPID = Run(@ComSpec & ' /c ' & $sCmd, "", @SW_HIDE, _
			BitOR($STDOUT_CHILD, $STDERR_CHILD))
	If @error Or $iPID = 0 Then Return SetError(1, 0, "")
	Local $sOutput = ""
	While ProcessExists($iPID)
		$sOutput &= StdoutRead($iPID)
		$sOutput &= StderrRead($iPID)
		Sleep(50)
	WEnd
	$sOutput &= StdoutRead($iPID)
	$sOutput &= StderrRead($iPID)
	Return $sOutput
EndFunc

Func _IsHostsAutoUpdateInstalled()
	Local $iExit = RunWait(@ComSpec & ' /c schtasks /query /tn "' & $g_sHAU_TASK_NAME & '" >nul 2>&1', "", @SW_HIDE)
	Return ($iExit = 0)
EndFunc

Func _GetHostsAutoUpdateMethod()
	If Not _IsHostsAutoUpdateInstalled() Then Return $g_iHAU_METHOD_NONE
	Local $sXml = _RunGetOutput('schtasks /query /tn "' & $g_sHAU_TASK_NAME & '" /xml')
	If StringInStr($sXml, "UpdateHostsFile.ps1") Then Return $g_iHAU_METHOD_ADVANCED
	If StringInStr($sXml, "-updatehosts") Then Return $g_iHAU_METHOD_BASIC
	Return $g_iHAU_METHOD_NONE
EndFunc

Func _SetupHostsAutoUpdate($iMethod, $sDailyTime = "00:00")
	If Not IsAdmin() Then Return SetError(1, 0, False)

	Local $sGenPExePath = @ScriptFullPath

	If $iMethod = $g_iHAU_METHOD_BASIC Then
		If StringInStr($sGenPExePath, "\Users\") Or _
				StringInStr($sGenPExePath, "\Desktop\") Or _
				StringInStr($sGenPExePath, "\Documents\") Or _
				StringInStr($sGenPExePath, "\Downloads\") Then
			Local $iAns = MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING), _
					"Hosts Auto-Update Setup", _
					"GenP appears to be in a user-specific folder:" & @CRLF & _
					$sGenPExePath & @CRLF & @CRLF & _
					"The scheduled task runs as SYSTEM, which usually cannot reach" & @CRLF & _
					"user folders. The task will be created but will likely fail when" & @CRLF & _
					"it tries to run." & @CRLF & @CRLF & _
					"Recommended: move GenP to a root folder like C:\GenP\ first." & @CRLF & @CRLF & _
					"Proceed anyway?")
			If $iAns <> $IDYES Then Return SetError(2, 0, False)
		EndIf
	EndIf


	If $iMethod = $g_iHAU_METHOD_ADVANCED Then
		Local $bDeployed = FileInstall("resources\UpdateHostsFile.ps1", $g_sHAU_PS1_TARGET, 1)
		If Not $bDeployed Or Not FileExists($g_sHAU_PS1_TARGET) Then
			Return SetError(4, 0, False)
		EndIf

		Local $sPs1Content = FileRead($g_sHAU_PS1_TARGET)
		$sPs1Content = StringReplace($sPs1Content, "__GENP_PATH__", $sGenPExePath)
		Local $hPs1 = FileOpen($g_sHAU_PS1_TARGET, 2)
		If $hPs1 = -1 Then Return SetError(4, 0, False)
		FileWrite($hPs1, $sPs1Content)
		FileClose($hPs1)
	EndIf

	Local $sCmd
	If $iMethod = $g_iHAU_METHOD_BASIC Then
		Local $sTaskRun = '\"' & $sGenPExePath & '\" -updatehosts'
		$sCmd = 'schtasks /create /F /TN "' & $g_sHAU_TASK_NAME & '" ' & _
				'/TR "' & $sTaskRun & '" ' & _
				'/SC DAILY /ST ' & $sDailyTime & ' ' & _
				'/RU SYSTEM /RL HIGHEST'
	Else
		Local $sTaskRun = 'powershell.exe -ExecutionPolicy Bypass -File \"' & _
				$g_sHAU_PS1_TARGET & '\"'
		$sCmd = 'schtasks /create /F /TN "' & $g_sHAU_TASK_NAME & '" ' & _
				'/TR "' & $sTaskRun & '" ' & _
				'/SC HOURLY /MO 3 ' & _
				'/RU SYSTEM /RL HIGHEST'
	EndIf

	RunWait(@ComSpec & ' /c schtasks /delete /F /TN "' & $g_sHAU_TASK_NAME & '" >nul 2>&1', "", @SW_HIDE)

	Local $iExit = RunWait(@ComSpec & ' /c ' & $sCmd, "", @SW_HIDE)
	If $iExit <> 0 Then Return SetError(3, $iExit, False)

	If Not _IsHostsAutoUpdateInstalled() Then Return SetError(5, 0, False)

	RunWait(@ComSpec & ' /c schtasks /run /TN "' & $g_sHAU_TASK_NAME & '"', "", @SW_HIDE)

	Return True
EndFunc

Func _RemoveHostsAutoUpdate($bAlsoRemoveAdvancedFiles = True)
	If Not _IsHostsAutoUpdateInstalled() Then
		If $bAlsoRemoveAdvancedFiles Then
			If FileExists($g_sHAU_PS1_TARGET) Then FileDelete($g_sHAU_PS1_TARGET)
			If FileExists($g_sHAU_LOG_TARGET) Then FileDelete($g_sHAU_LOG_TARGET)
		EndIf
		Return True
	EndIf

	If Not IsAdmin() Then Return SetError(1, 0, False)

	Local $iExit = RunWait(@ComSpec & ' /c schtasks /delete /F /TN "' & $g_sHAU_TASK_NAME & '"', "", @SW_HIDE)
	If $iExit <> 0 Then Return SetError(2, $iExit, False)

	If _IsHostsAutoUpdateInstalled() Then Return SetError(3, 0, False)

	If $bAlsoRemoveAdvancedFiles Then
		If FileExists($g_sHAU_PS1_TARGET) Then FileDelete($g_sHAU_PS1_TARGET)
		If FileExists($g_sHAU_LOG_TARGET) Then FileDelete($g_sHAU_LOG_TARGET)
	EndIf
	Return True
EndFunc

Func _RunHostsAutoUpdateNow()
	If Not _IsHostsAutoUpdateInstalled() Then Return False
	Local $iExit = RunWait(@ComSpec & ' /c schtasks /run /TN "' & $g_sHAU_TASK_NAME & '"', "", @SW_HIDE)
	Return ($iExit = 0)
EndFunc

Func _IsGudeCleanupInstalled()
	Local $iExit = RunWait(@ComSpec & ' /c schtasks /query /TN "' & $g_sGUDE_TASK_NAME & '" >nul 2>&1', "", @SW_HIDE)
	Return ($iExit = 0)
EndFunc

Func _SetupGudeCleanup($sDrives)
	If Not IsAdmin() Then Return SetError(1, 0, False)
	If Not FileExists($g_sGUDE_DIR) Then DirCreate($g_sGUDE_DIR)

	RunWait(@ComSpec & ' /c schtasks /delete /F /TN "' & $g_sGUDE_TASK_NAME & '" >nul 2>&1', "", @SW_HIDE)

	Local $bDeployed = FileInstall("resources\RemoveGudeLogs.ps1", $g_sGUDE_PS1_TARGET, 1)
	If Not $bDeployed Or Not FileExists($g_sGUDE_PS1_TARGET) Then Return SetError(2, 0, False)
	Local $sContent = FileRead($g_sGUDE_PS1_TARGET)
	$sContent = StringReplace($sContent, "__DRIVES__", $sDrives)
	Local $hFile = FileOpen($g_sGUDE_PS1_TARGET, 2)
	If $hFile = -1 Then Return SetError(3, 0, False)
	FileWrite($hFile, $sContent)
	FileClose($hFile)
	IniWrite($sINIPath, "Options", "GudeCleanupDrives", $sDrives)

	Local $sRun = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' & $g_sGUDE_PS1_TARGET & '"'

	Local $sCmd = 'schtasks /create /F /TN "' & $g_sGUDE_TASK_NAME & '" ' & _
			'/TR "' & $sRun & '" ' & _
			'/SC HOURLY /MO 3 ' & _
			'/RU SYSTEM /RL HIGHEST'
	Local $iExit = RunWait(@ComSpec & ' /c ' & $sCmd, "", @SW_HIDE)
	If $iExit <> 0 Then Return SetError(4, $iExit, False)

	Local $sPatch = '$t = Get-ScheduledTask -TaskName ''' & $g_sGUDE_TASK_NAME & '''; ' & _
			'$t.Settings.StartWhenAvailable = $true; ' & _
			'Set-ScheduledTask -TaskName ''' & $g_sGUDE_TASK_NAME & ''' -Settings $t.Settings'
	RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' & $sPatch & '"', "", @SW_HIDE)

	RunWait(@ComSpec & ' /c schtasks /run /TN "' & $g_sGUDE_TASK_NAME & '"', "", @SW_HIDE)

	Return True
EndFunc

Func _RemoveGudeCleanup()
	RunWait(@ComSpec & ' /c schtasks /delete /F /TN "' & $g_sGUDE_TASK_NAME & '" >nul 2>&1', "", @SW_HIDE)
	If FileExists($g_sGUDE_DIR) Then DirRemove($g_sGUDE_DIR, 1)
	IniDelete($sINIPath, "Options", "GudeCleanupDrives")
	Return True
EndFunc

Func _GudeCleanupDriveSelectGUI()
	Local $aAllDrives = DriveGetDrive("Fixed")
	If @error Or Not IsArray($aAllDrives) Or $aAllDrives[0] = 0 Then Return ""

	Local $sPathDrive = StringUpper(StringLeft($MyDefPath, 1))
	Local $iCount = $aAllDrives[0]
	Local $iW = 320, $iH = 74 + ($iCount * 28) + 50
	Local $aPos = WinGetPos($MyhGUI)
	Local $hGUI = GUICreate("Gude Log Cleanup", $iW, $iH, _
			$aPos[0] + ($aPos[2] - $iW) / 2, $aPos[1] + ($aPos[3] - $iH) / 2, _
			BitOR($WS_POPUP, $WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
	GUISetFont(9, 400, 0, "Segoe UI", $hGUI)
	GUISetIcon(@ScriptDir & "\Skull.ico", 0, $hGUI)

	GUICtrlCreateLabel("Select drives to scan for gude log files:", 12, 12, $iW - 24, 18)

	Local $aCheckboxes[$iCount]
	Local $iY = 36
	For $i = 1 To $iCount
		Local $sDL = StringUpper(StringLeft($aAllDrives[$i], 1))
		Local $sLbl = $sDL & ":"
		Local $sDriveLabel = DriveGetLabel($sDL & ":\")
		If $sDriveLabel <> "" Then $sLbl &= "  (" & $sDriveLabel & ")"
		$aCheckboxes[$i - 1] = GUICtrlCreateCheckbox($sLbl, 20, $iY, $iW - 40, 24)
		If $sDL = "C" Or $sDL = $sPathDrive Then
			GUICtrlSetState($aCheckboxes[$i - 1], $GUI_CHECKED)
		EndIf
		$iY += 28
	Next

	Local $idBtnOK     = GUICtrlCreateButton("Set Up", 40,  $iY + 8, 90, 28)
	Local $idBtnCancel = GUICtrlCreateButton("Skip",   190, $iY + 8, 90, 28)

	GUISetState(@SW_DISABLE, $MyhGUI)
	GUISetState(@SW_SHOW, $hGUI)

	Local $sResult = ""
	While True
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $idBtnCancel
				ExitLoop
			Case $idBtnOK
				For $i = 0 To $iCount - 1
					If GUICtrlRead($aCheckboxes[$i]) = $GUI_CHECKED Then
						Local $sDrive = StringUpper(StringLeft($aAllDrives[$i + 1], 1))
						$sResult &= ($sResult = "" ? "" : ",") & $sDrive
					EndIf
				Next
				ExitLoop
		EndSwitch
	WEnd

	GUISetState(@SW_ENABLE, $MyhGUI)
	GUIDelete($hGUI)
	Return $sResult
EndFunc

Func _ShowGudeSetupPrompt()
	Local $iAns = MsgBox(BitOR($MB_YESNOCANCEL, $MB_ICONQUESTION, $MB_SYSTEMMODAL), _
			"Gude Log Cleanup", _
			"For some users the Good patch can cause Adobe to generate" & @CRLF & _
			"gude-YYYY-MM-DD.log files in Adobe folders each time the" & @CRLF & _
			"patched app is opened. These are harmless side effects" & @CRLF & _
			"and can be removed automatically." & @CRLF & @CRLF & _
			"GenP can add a scheduled task to remove them every 3 hours" & @CRLF & _
			"and at each Windows login." & @CRLF & @CRLF & _
			"Yes - select drives and set up the task" & @CRLF & _
			"No - skip (won't be asked again)" & @CRLF & _
			"Cancel - remind me next time")
	Select
		Case $iAns = $IDYES
			Local $sDrives = _GudeCleanupDriveSelectGUI()
			If $sDrives <> "" Then
				If _SetupGudeCleanup($sDrives) Then
					MemoWrite(@CRLF & "Gude Log Cleanup scheduled task set up for drive(s): " & $sDrives & ".")
					MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Gude Log Cleanup", _
							"Scheduled task added successfully." & @CRLF & @CRLF & _
							"Drive(s) selected: " & $sDrives & @CRLF & _
							"The task will run every 3 hours and at each Windows login.")
				Else
					MemoWrite(@CRLF & "Error: could not set up Gude Log Cleanup task (code " & @error & ").")
					MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Gude Log Cleanup", _
							"Failed to add the scheduled task (error code " & @error & ")." & @CRLF & @CRLF & _
							"Check that GenP is running as Administrator.")
				EndIf
			EndIf
		Case $iAns = $IDNO
			IniWrite($sINIPath, "Options", "GudeDismissed", "1")
	EndSelect
EndFunc

Func _ShowGudeRemovePrompt()
	Local $iAns = MsgBox(BitOR($MB_YESNOCANCEL, $MB_ICONQUESTION, $MB_SYSTEMMODAL), _
			"Gude Log Cleanup", _
			"The Gude Log Cleanup scheduled task is still active." & @CRLF & @CRLF & _
			"Since you have disabled the Good patch, would you" & @CRLF & _
			"like to remove the Gude Log Cleanup task as well?" & @CRLF & @CRLF & _
			"Yes - remove the scheduled task" & @CRLF & _
			"No - keep it running (won't be asked again)" & @CRLF & _
			"Cancel - remind me next time")
	Select
		Case $iAns = $IDYES
			_RemoveGudeCleanup()
			MemoWrite(@CRLF & "Gude Log Cleanup scheduled task removed.")
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Gude Log Cleanup", _
					"Scheduled task removed successfully.")
		Case $iAns = $IDNO
			IniWrite($sINIPath, "Options", "GudeDismissedRemove", "1")
	EndSelect
EndFunc

Func _ShowHostsAutoUpdateDialog()
	Local $iW = 520
	Local $iH = 400
	Local $hParent = WinGetHandle("[ACTIVE]")
	Local $hDlg = GUICreate("Hosts Schedule Updates", $iW, $iH, -1, -1, _
			BitOR($WS_CAPTION, $WS_POPUPWINDOW, $WS_SYSMENU), -1, $hParent)
	GUISetIcon(@ScriptDir & "\Skull.ico", 0, $hDlg)
	GUISetFont(9, 400, 0, "Segoe UI", $hDlg)

	GUICtrlCreateLabel("Status:", 15, 15, 50, 18)
	Local $idLblStatus = GUICtrlCreateLabel("(checking...)", 70, 15, 430, 18)
	GUICtrlSetFont($idLblStatus, 9, 700)

	GUICtrlCreateGroup("Method", 15, 45, 490, 175)
	Local $idRadioBasic = GUICtrlCreateRadio("Basic - daily refresh, simple", 30, 70, 460, 22)
	GUICtrlCreateLabel( _
			"Runs GenP.exe -updatehosts once a day. No backup, no recovery." & @CRLF & _
			"Same effect as clicking the Update Hosts button at the scheduled time.", _
			50, 92, 450, 32)
	Local $idRadioAdvanced = GUICtrlCreateRadio("Advanced - 3-hourly with backup, recovery, custom-entry merge", 30, 130, 460, 22)
	GUICtrlCreateLabel( _
			"Runs every 3 hours via PowerShell script. Backs up hosts before each" & @CRLF & _
			"update, verifies the new list, reverts on failure, logs everything." & @CRLF & _
			"Merges entries from hosts.plain (if present) so custom entries survive.", _
			50, 152, 450, 60)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlSetState($idRadioBasic, $GUI_CHECKED)

	GUICtrlCreateLabel( _
			"Advanced method only: to preserve your own (non-Adobe) hosts entries," & @CRLF & _
			"create the file " & @WindowsDir & "\System32\drivers\etc\hosts.plain" & @CRLF & _
			"with those entries. The script merges them on each run.", _
			15, 230, 490, 50)

	Local $idBtnSetup = GUICtrlCreateButton("Setup", 15, 290, 110, 32)
	Local $idBtnRunNow = GUICtrlCreateButton("Run Now", 135, 290, 110, 32)
	Local $idBtnRemove = GUICtrlCreateButton("Remove", 255, 290, 110, 32)
	Local $idBtnClose = GUICtrlCreateButton("Close", 395, 290, 110, 32)

	_RefreshAutoUpdateDialogStatus($idLblStatus, $idBtnRunNow, $idBtnRemove)

	GUISetState(@SW_SHOW, $hDlg)

	Local $bExit = False
	Local $iMsg
	Local $iMethod
	Local $bOk
	Local $iErr
	Local $sMsg
	Local $sSuccessMsg

	While Not $bExit
		$iMsg = GUIGetMsg()
		Switch $iMsg
			Case $GUI_EVENT_CLOSE, $idBtnClose
				$bExit = True

			Case $idBtnSetup
				If BitAND(GUICtrlRead($idRadioAdvanced), $GUI_CHECKED) = $GUI_CHECKED Then
					$iMethod = $g_iHAU_METHOD_ADVANCED
				Else
					$iMethod = $g_iHAU_METHOD_BASIC
				EndIf

				$bOk = _SetupHostsAutoUpdate($iMethod, "00:00")
				If $bOk Then
					If $iMethod = $g_iHAU_METHOD_BASIC Then
						$sSuccessMsg = "Will refresh daily at 00:00."
					Else
						$sSuccessMsg = "Will refresh every 3 hours."
					EndIf
					MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Setup complete", _
							"Scheduled task created." & @CRLF & @CRLF & $sSuccessMsg)
				Else
					$iErr = @error
					$sMsg = "Setup failed."
					Switch $iErr
						Case 1
							$sMsg = "GenP must be running as Administrator."
						Case 2
							$sMsg = "Setup cancelled - GenP path is in a user folder."
						Case 3
							$sMsg = "schtasks command failed (exit code " & @extended & ")."
						Case 4
							$sMsg = "Advanced method: failed to deploy UpdateHostsFile.ps1." & @CRLF & _
									"Check that the file was bundled into the GenP build."
						Case 5
							$sMsg = "Task creation reported success but task is not visible." & @CRLF & _
									"Check Task Scheduler manually."
					EndSwitch
					MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Setup failed", $sMsg)
				EndIf
				_RefreshAutoUpdateDialogStatus($idLblStatus, $idBtnRunNow, $idBtnRemove)

			Case $idBtnRunNow
				If _RunHostsAutoUpdateNow() Then
					Local $iLogBefore = 0
					If FileExists($g_sHAU_LOG_TARGET) Then $iLogBefore = FileGetTime($g_sHAU_LOG_TARGET, 1, 1)
					Local $hRunTimer = TimerInit()
					Local $bChanged = False
					While TimerDiff($hRunTimer) < 8000
						If FileExists($g_sHAU_LOG_TARGET) Then
							Local $iLogAfter = FileGetTime($g_sHAU_LOG_TARGET, 1, 1)
							If $iLogAfter > $iLogBefore Then
								$bChanged = True
								ExitLoop
							EndIf
						EndIf
						Sleep(400)
					WEnd
					If $bChanged Then
						Local $sLastLine = ""
						Local $hLog = FileOpen($g_sHAU_LOG_TARGET, 0)
						If $hLog <> -1 Then
							Local $sAll = FileRead($hLog)
							FileClose($hLog)
							Local $aLines = StringSplit(StringStripCR($sAll), @LF)
							For $i = $aLines[0] To 1 Step -1
								If StringStripWS($aLines[$i], 3) <> "" Then
									$sLastLine = StringStripWS($aLines[$i], 1 + 2)
									ExitLoop
								EndIf
							Next
						EndIf
						MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Run Now", _
								"Task completed." & @CRLF & @CRLF & _
								"Last log line:" & @CRLF & $sLastLine)
					Else
						MsgBox(BitOR($MB_OK, $MB_ICONWARNING), "Run Now", _
								"Task triggered but no log update detected in 8 seconds." & @CRLF & _
								"It may still be running - check the log file in a moment:" & @CRLF & _
								$g_sHAU_LOG_TARGET)
					EndIf
				Else
					MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Run Now", _
							"Could not trigger the task. Is it installed and are you Admin?")
				EndIf

			Case $idBtnRemove
				If MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING), "Remove", _
						"Remove the scheduled task?" & @CRLF & _
						"(Advanced method: also removes UpdateHostsFile.ps1 and its log.)") = $IDYES Then
					If _RemoveHostsAutoUpdate(True) Then
						MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Removed", "Scheduled task removed.")
					Else
						MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Remove", "Removal failed (@error=" & @error & ").")
					EndIf
					_RefreshAutoUpdateDialogStatus($idLblStatus, $idBtnRunNow, $idBtnRemove)
				EndIf
		EndSwitch
	WEnd

	GUIDelete($hDlg)
EndFunc

Func _RefreshAutoUpdateDialogStatus($idLbl, $idBtnRunNow, $idBtnRemove)
	Local $iMethod = _GetHostsAutoUpdateMethod()
	Switch $iMethod
		Case $g_iHAU_METHOD_BASIC
			GUICtrlSetData($idLbl, "Basic method installed (daily)")
			GUICtrlSetColor($idLbl, 0x008000)
			GUICtrlSetState($idBtnRunNow, $GUI_ENABLE)
			GUICtrlSetState($idBtnRemove, $GUI_ENABLE)
		Case $g_iHAU_METHOD_ADVANCED
			GUICtrlSetData($idLbl, "Advanced method installed (every 3 hours)")
			GUICtrlSetColor($idLbl, 0x008000)
			GUICtrlSetState($idBtnRunNow, $GUI_ENABLE)
			GUICtrlSetState($idBtnRemove, $GUI_ENABLE)
		Case Else
			GUICtrlSetData($idLbl, "Not installed")
			GUICtrlSetColor($idLbl, 0x808080)
			GUICtrlSetState($idBtnRunNow, $GUI_DISABLE)
			GUICtrlSetState($idBtnRemove, $GUI_DISABLE)
	EndSwitch
EndFunc

Func _IsMitmproxyInstalled()
	Return FileExists($g_sMITM_EXE) And FileExists($g_sMITM_SCRIPT)
EndFunc

Func _IsMitmproxyRunning()
	If $g_iMitmproxyPID <> 0 And ProcessExists($g_iMitmproxyPID) Then Return True
	Local $iPID = ProcessExists("mitmdump.exe")
	If $iPID > 0 Then
		$g_iMitmproxyPID = $iPID
		Return True
	EndIf
	$g_iMitmproxyPID = 0
	Return False
EndFunc

Func _IsMitmproxyCertTrusted()
	Local $iExit = RunWait(@ComSpec & ' /c certutil -store Root mitmproxy >nul 2>&1', "", @SW_HIDE)
	Return ($iExit = 0)
EndFunc

Func _IsWindowsProxyOn()
	Local $iEnabled = RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings", "ProxyEnable")
	If @error Then Return False
	Return ($iEnabled = 1)
EndFunc

Func _SetupMitmproxy()
	If Not IsAdmin() Then Return SetError(1, 0, False)

	Local $bWasRunning = _IsMitmproxyRunning()
	If $bWasRunning Then
		_StopMitmproxy()
		Sleep(500)
	EndIf

	If Not FileExists($g_sMITM_DIR) Then DirCreate($g_sMITM_DIR)

	If Not FileExists($g_sMITM_EXE) Then
		Local $bDeployed = FileInstall("resources\mitmproxy\mitmdump.exe", $g_sMITM_EXE, 1)
		If Not $bDeployed Or Not FileExists($g_sMITM_EXE) Then Return SetError(2, 0, False)
	EndIf

	Local $bScriptDeployed = FileInstall("resources\mitmproxy\mitmproxy_genuine_fullguard.py", $g_sMITM_SCRIPT, 1)
	If Not $bScriptDeployed Or Not FileExists($g_sMITM_SCRIPT) Then Return SetError(3, 0, False)

	Local $sCertPath = @UserProfileDir & "\.mitmproxy\mitmproxy-ca-cert.cer"
	If Not FileExists($sCertPath) Then
		EnvSet("PYTHONUNBUFFERED", "1")
		Local $iGenPID = Run('"' & $g_sMITM_EXE & '" --listen-port 0 --set termlog_verbosity=warn', $g_sMITM_DIR, @SW_HIDE)
		Local $hTimeout = TimerInit()
		While TimerDiff($hTimeout) < 20000
			If FileExists($sCertPath) Then ExitLoop
			Sleep(200)
		WEnd
		If $iGenPID > 0 Then ProcessClose($iGenPID)
		ProcessClose("mitmdump.exe")
		If Not FileExists($sCertPath) Then Return SetError(4, 0, False)
	EndIf

	If Not _IsMitmproxyCertTrusted() Then
		Local $sTmpLog = @TempDir & "\genp_certutil.log"
		FileDelete($sTmpLog)
		Local $iExit = RunWait(@ComSpec & ' /c certutil -addstore -f Root "' & $sCertPath & '" > "' & $sTmpLog & '" 2>&1', "", @SW_HIDE)
		$g_sLastCertError = ""
		If FileExists($sTmpLog) Then
			$g_sLastCertError = FileRead($sTmpLog)
			FileDelete($sTmpLog)
		EndIf
		If Not _IsMitmproxyCertTrusted() Then Return SetError(5, $iExit, False)
	EndIf

	If $bWasRunning Then _StartMitmproxy()

	Return True
EndFunc

Func _FindFreeMitmproxyPort()
	TCPStartup()
	Local $iFoundPort = 0
	For $iPort = 8080 To 8089
		Local $iListen = TCPListen("127.0.0.1", $iPort)
		If $iListen <> -1 Then
			TCPCloseSocket($iListen)
			$iFoundPort = $iPort
			ExitLoop
		EndIf
	Next
	TCPShutdown()
	Return $iFoundPort
EndFunc

Func _StartMitmproxy()
	If _IsMitmproxyRunning() Then Return True
	If Not _IsMitmproxyInstalled() Then Return SetError(1, 0, False)

	Local $iPort = _FindFreeMitmproxyPort()
	If $iPort = 0 Then Return SetError(4, 0, False)
	$g_sMITM_PORT = String($iPort)
	$g_sMITM_PROXY = "127.0.0.1:" & $g_sMITM_PORT

	EnvSet("PYTHONUNBUFFERED", "1")

	Local $sCmd = '"' & $g_sMITM_EXE & '" -s "' & $g_sMITM_SCRIPT & '"' & _
			' --listen-port ' & $g_sMITM_PORT & _
			' --quiet' & _
			' --set connection_strategy=lazy' & _
			' --set console_eventlog_verbosity=error' & _
			' --set termlog_verbosity=error'
	$g_iMitmproxyPID = Run($sCmd, $g_sMITM_DIR, @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_CHILD))
	If $g_iMitmproxyPID = 0 Then Return SetError(2, 0, False)

	Sleep(1500)
	If Not ProcessExists($g_iMitmproxyPID) Then
		$g_iMitmproxyPID = 0
		Return SetError(3, 0, False)
	EndIf

	If _IsWindowsProxyOn() Then _EnableWindowsProxy()

	AdlibRegister("_PollMitmproxyLog", 250)
	_RefreshLogWindowStatus()
	Return True
EndFunc

Func _StopMitmproxy()
	If $g_iMitmproxyPID <> 0 And ProcessExists($g_iMitmproxyPID) Then
		If $g_bMitmLogWindowExists Then
			_AppendToLogWindow(StdoutRead($g_iMitmproxyPID))
			_AppendToLogWindow(StderrRead($g_iMitmproxyPID))
		EndIf
		ProcessClose($g_iMitmproxyPID)
	EndIf
	ProcessClose("mitmdump.exe")
	$g_iMitmproxyPID = 0
	AdlibUnRegister("_PollMitmproxyLog")
	If $g_bMitmLogWindowExists Then
		_AppendToLogWindow(@CRLF & "# mitmdump stopped." & @CRLF & @CRLF)
		_RefreshLogWindowStatus()
	EndIf
	Return True
EndFunc

Func _EnableWindowsProxy()
	RegWrite("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings", "ProxyEnable", "REG_DWORD", 1)
	RegWrite("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings", "ProxyServer", "REG_SZ", $g_sMITM_PROXY)
	_BroadcastInternetSettingsChange()
	RunWait(@ComSpec & ' /c netsh winhttp set proxy "' & $g_sMITM_PROXY & '"', "", @SW_HIDE)
	Return True
EndFunc

Func _DisableWindowsProxy()
	RegWrite("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings", "ProxyEnable", "REG_DWORD", 0)
	_BroadcastInternetSettingsChange()
	RunWait(@ComSpec & ' /c netsh winhttp reset proxy', "", @SW_HIDE)
	Return True
EndFunc

Func _BroadcastInternetSettingsChange()
	Local $hWinINet = DllOpen("wininet.dll")
	If $hWinINet <> -1 Then
		DllCall($hWinINet, "int", "InternetSetOptionW", "ptr", 0, "dword", 39, "ptr", 0, "dword", 0)
		DllCall($hWinINet, "int", "InternetSetOptionW", "ptr", 0, "dword", 37, "ptr", 0, "dword", 0)
		DllClose($hWinINet)
	EndIf
EndFunc

Func _RemoveMitmproxy()
	If Not IsAdmin() Then Return SetError(1, 0, False)

	_StopMitmproxy()
	Sleep(300)

	If _IsWindowsProxyOn() Then _DisableWindowsProxy()
	RunWait(@ComSpec & ' /c netsh winhttp reset proxy', "", @SW_HIDE)

	RunWait(@ComSpec & ' /c certutil -delstore Root mitmproxy', "", @SW_HIDE)

	_RemoveGudeCleanup()

	If FileExists($g_sMITM_DIR) Then DirRemove($g_sMITM_DIR, 1)
	Local $sGenPDataDir = @AppDataCommonDir & "\GenP"
	If FileExists($sGenPDataDir) Then DirRemove($sGenPDataDir, 1)

	Return True
EndFunc

Func _GetMitmproxyStatusText()
	Local $sStatus
	If _IsMitmproxyInstalled() Then
		$sStatus = "Installed"
	Else
		$sStatus = "Not installed"
	EndIf
	If _IsMitmproxyRunning() Then
		$sStatus &= "  |  Running"
	Else
		$sStatus &= "  |  Stopped"
	EndIf
	If _IsMitmproxyCertTrusted() Then
		$sStatus &= "  |  Cert trusted"
	Else
		$sStatus &= "  |  Cert NOT trusted"
	EndIf
	If _IsWindowsProxyOn() Then
		$sStatus &= "  |  Proxy ON"
	Else
		$sStatus &= "  |  Proxy off"
	EndIf
	Return $sStatus
EndFunc

Func _RefreshProxyStatus()
	If $g_idLblProxyStatus = 0 Then Return
	GUICtrlSetData($g_idLblProxyStatus, "Status: " & _GetMitmproxyStatusText())
	If _IsMitmproxyInstalled() And _IsMitmproxyRunning() And _IsMitmproxyCertTrusted() And _IsWindowsProxyOn() Then
		GUICtrlSetColor($g_idLblProxyStatus, 0x008000)
	ElseIf _IsMitmproxyInstalled() Then
		GUICtrlSetColor($g_idLblProxyStatus, 0xB87333)
	Else
		GUICtrlSetColor($g_idLblProxyStatus, 0x808080)
	EndIf
EndFunc

Func _CreateMitmproxyLogWindow()
	If $g_bMitmLogWindowExists Then Return

	Local $iW = 900, $iH = 600
	Local $iBgColor = 0x1E1E1E

	$g_hMitmLogWin = GUICreate("GenP - Heartbeat Suppression Log", $iW, $iH, -1, -1, _
			BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS), $WS_EX_TOOLWINDOW)
	GUISetBkColor($iBgColor, $g_hMitmLogWin)

	If FileExists(@ScriptDir & "\Skull.ico") Then
		GUISetIcon(@ScriptDir & "\Skull.ico", 0, $g_hMitmLogWin)
	Else
		GUISetIcon(@ScriptFullPath, 0, $g_hMitmLogWin)
	EndIf

	GUICtrlCreateLabel("Status:", 10, 14, 50, 18)
	GUICtrlSetColor(-1, 0xFFFFFF)
	GUICtrlSetBkColor(-1, $iBgColor)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	$g_idLblLogStatus = GUICtrlCreateLabel("(not started)", 65, 14, 250, 18)
	GUICtrlSetColor($g_idLblLogStatus, 0xF44747)
	GUICtrlSetBkColor($g_idLblLogStatus, $iBgColor)
	GUICtrlSetFont($g_idLblLogStatus, 9, 700, 0, "Segoe UI")
	GUICtrlSetResizing($g_idLblLogStatus, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	$g_idBtnLogClear = GUICtrlCreateButton("Clear", $iW - 305, 8, 90, 28)
	GUICtrlSetFont($g_idBtnLogClear, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($g_idBtnLogClear, BitOR($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	$g_idBtnLogAddToHosts = GUICtrlCreateButton("Add hosts", $iW - 205, 8, 90, 28)
	GUICtrlSetFont($g_idBtnLogAddToHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($g_idBtnLogAddToHosts, BitOR($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	$g_idBtnLogClose = GUICtrlCreateButton("Close", $iW - 105, 8, 90, 28)
	GUICtrlSetFont($g_idBtnLogClose, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($g_idBtnLogClose, BitOR($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	$g_hMitmRichEdit = _GUICtrlRichEdit_Create($g_hMitmLogWin, "", _
			10, 46, $iW - 20, $iH - 60, _
			BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	_GUICtrlRichEdit_SetBkColor($g_hMitmRichEdit, $iBgColor)
	_GUICtrlRichEdit_SetCharColor($g_hMitmRichEdit, 0xD4D4D4)
	_GUICtrlRichEdit_SetFont($g_hMitmRichEdit, 9, "Consolas")

	$g_bMitmLogWindowExists = True

	_AppendToLogWindow("# GenP Heartbeat Suppression - Live Log" & @CRLF)
	_AppendToLogWindow("# This window streams mitmdump's stdout/stderr in real time." & @CRLF)
	_AppendToLogWindow("# Output begins when Toggle Run starts mitmdump." & @CRLF & @CRLF)
EndFunc

Func _OpenMitmproxyLogWindow()
	If $g_bMitmLogWindowExists Then
		Local $iState = WinGetState($g_hMitmLogWin)
		If BitAND($iState, 2) Then
			GUISetState(@SW_HIDE, $g_hMitmLogWin)
			Return
		EndIf
	Else
		_CreateMitmproxyLogWindow()
	EndIf
	GUISetState(@SW_SHOW, $g_hMitmLogWin)
	GUISwitch($MyhGUI)
	_RefreshLogWindowStatus()
EndFunc

Func _RefreshLogWindowStatus()
	If Not $g_bMitmLogWindowExists Then Return
	If _IsMitmproxyRunning() Then
		GUICtrlSetData($g_idLblLogStatus, "Running (PID " & $g_iMitmproxyPID & ")")
		GUICtrlSetColor($g_idLblLogStatus, 0x4EC9B0)
	Else
		GUICtrlSetData($g_idLblLogStatus, "Stopped")
		GUICtrlSetColor($g_idLblLogStatus, 0xF44747)
	EndIf
EndFunc

Func _StyleLogRange($iStart, $iEnd)
	If $iEnd <= $iStart Then Return
	_GUICtrlRichEdit_SetSel($g_hMitmRichEdit, $iStart, $iEnd)
	_GUICtrlRichEdit_SetCharColor($g_hMitmRichEdit, 0xD4D4D4)
	_GUICtrlRichEdit_SetFont($g_hMitmRichEdit, 9, "Consolas")
	_GUICtrlRichEdit_Deselect($g_hMitmRichEdit)
EndFunc

Func _AppendToLogWindow($sText)
	If Not $g_bMitmLogWindowExists Then Return
	If $sText = "" Then Return
	$sText = StringRegExpReplace($sText, "\x1B\[[0-9;]*[a-zA-Z]", "")

	If Not $g_bHostsInjectInProgress And StringInStr($sText, "adobestats.io") Then
		Local $aDomainMatch = StringRegExp($sText, '(?i)([A-Za-z0-9_.-]+\.adobestats\.io)', 1)
		If Not @error Then
			Local $sCapturedDomain = StringLower($aDomainMatch[0])
			_SilentHostsInjector($sCapturedDomain)
		EndIf
	EndIf

	Local $iStart = _GUICtrlRichEdit_GetTextLength($g_hMitmRichEdit)
	_GUICtrlRichEdit_AppendText($g_hMitmRichEdit, $sText)
	_StyleLogRange($iStart, _GUICtrlRichEdit_GetTextLength($g_hMitmRichEdit))

	$g_iMitmAppendCounter += 1
	If $g_iMitmAppendCounter >= 100 Then
		$g_iMitmAppendCounter = 0
		Local $iLen = _GUICtrlRichEdit_GetTextLength($g_hMitmRichEdit)
		If $iLen > $g_iMitmLogCharCap Then
			Local $sCurrent = _GUICtrlRichEdit_GetText($g_hMitmRichEdit)
			Local $iKeepFrom = Int($iLen * 0.2)
			Local $iNL = StringInStr($sCurrent, @LF, 0, 1, $iKeepFrom)
			If $iNL > 0 Then $iKeepFrom = $iNL + 1
			Local $sTrimmed = "# (older log lines trimmed - cap " & $g_iMitmLogCharCap & " chars)" & @CRLF & _
					StringMid($sCurrent, $iKeepFrom)
			_GUICtrlRichEdit_SetText($g_hMitmRichEdit, $sTrimmed)
			_StyleLogRange(0, _GUICtrlRichEdit_GetTextLength($g_hMitmRichEdit))
			_GUICtrlRichEdit_SetSel($g_hMitmRichEdit, -1, -1)
		EndIf
	EndIf
EndFunc

Func _SilentHostsInjector($sDomain)
	$sDomain = StringLower(StringStripWS($sDomain, 3))
	If $sDomain = "" Then Return SetError(2, 0, False)

	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sStartMark = "# START - Adobe Endpoint Block"
	Local $sEndMark = "# END - Adobe Endpoint Block"
	Local $sStartEsc = StringRegExpReplace($sStartMark, "([.*+?^${}()|[\]\\])", "\\$1")
	Local $sEndEsc = StringRegExpReplace($sEndMark, "([.*+?^${}()|[\]\\])", "\\$1")
	Local $sCleanText = ""

	If FileExists($sHostsPath) Then
		Local $sHostsContent = FileRead($sHostsPath)

		Local $aBlockCheck = StringRegExp($sHostsContent, "(?s)" & $sStartEsc & "(.*?)" & $sEndEsc, 1)
		If Not @error Then
			If StringInStr($aBlockCheck[0], $sDomain) Then Return True
		EndIf

		$sCleanText = StringRegExpReplace($sHostsContent, "(?s)\r?\n?" & $sStartEsc & ".*?" & $sEndEsc & "\r?\n?", "")
		$sCleanText = StringStripWS($sCleanText, 2)
	EndIf

	Local $sUtcTimestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & StringFormat("%02d:%02d", @HOUR, @MIN) & " UTC"
	Local $sNewBlock = @CRLF & @CRLF & _
			$sStartMark & @CRLF & _
			"# Last update: " & $sUtcTimestamp & @CRLF & _
			"0.0.0.0 ic.adobe.io" & @CRLF & _
			"0.0.0.0 " & $sDomain & @CRLF & _
			$sEndMark & @CRLF

	Local $hFile = FileOpen($sHostsPath, 2)
	If $hFile = -1 Then
		$g_bHostsInjectInProgress = True
		_AppendToLogWindow("# ERROR: Could not write hosts file (run as Administrator). Target: " & $sDomain & @CRLF)
		$g_bHostsInjectInProgress = False
		Return SetError(1, 0, False)
	EndIf

	FileWrite($hFile, $sCleanText & $sNewBlock)
	FileClose($hFile)
	RunWait("ipconfig /flushdns", "", @SW_HIDE)

	$g_bHostsInjectInProgress = True
	_AppendToLogWindow("# Adobe Endpoint Block written -> 0.0.0.0 ic.adobe.io + 0.0.0.0 " & $sDomain & "  (DNS cache flushed)" & @CRLF)
	$g_bHostsInjectInProgress = False

	Return True
EndFunc

Func _PollMitmproxyLog()
	If $g_iMitmproxyPID = 0 Then Return
	If Not ProcessExists($g_iMitmproxyPID) Then
		If $g_bMitmLogWindowExists Then
			_AppendToLogWindow(StdoutRead($g_iMitmproxyPID))
			_AppendToLogWindow(StderrRead($g_iMitmproxyPID))
			_AppendToLogWindow(@CRLF & "# mitmdump process ended." & @CRLF)
			_RefreshLogWindowStatus()
		EndIf
		$g_iMitmproxyPID = 0
		AdlibUnRegister("_PollMitmproxyLog")
		Return
	EndIf
	Local $sOut = StdoutRead($g_iMitmproxyPID)
	If $sOut <> "" Then _AppendToLogWindow($sOut)
	Local $sErr = StderrRead($g_iMitmproxyPID)
	If $sErr <> "" Then _AppendToLogWindow($sErr)
EndFunc

Func _GenP_WM_CLOSE($hWnd, $iMsg, $wParam, $lParam)
	If $g_bMitmLogWindowExists And $hWnd = $g_hMitmLogWin Then
		GUISetState(@SW_HIDE, $g_hMitmLogWin)
		Return 0
	EndIf
	If FileExists($g_sOVD_EXE) Then FileDelete($g_sOVD_EXE)
	If $g_hAppsBar <> 0 Then
		Local $aBarPos = WinGetPos($g_hAppsBar)
		If IsArray($aBarPos) Then
			IniWrite($sINIPath, "Options", "LaunchBarX", $aBarPos[0])
			IniWrite($sINIPath, "Options", "LaunchBarY", $aBarPos[1])
		EndIf
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

Func _GenP_WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
	If $hWnd = $MyhGUI And $wParam = 0 Then
		_RefreshLog()
	EndIf
	If $hWnd = $MyhGUI And $wParam = 1 Then
		If $g_hAppsBar <> 0 Then GUISetState(@SW_SHOWNOACTIVATE, $g_hAppsBar)
	EndIf
	If $g_bMitmLogWindowExists And $hWnd = $g_hMitmLogWin Then
		Local $iNewW = BitAND($lParam, 0xFFFF)
		Local $iNewH = BitShift($lParam, 16)
		If $iNewW > 40 And $iNewH > 60 Then
			WinMove($g_hMitmRichEdit, "", 10, 46, $iNewW - 20, $iNewH - 60)
		EndIf
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

Func _GenP_WM_ACTIVATE($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $lParam
	If $hWnd = $MyhGUI And BitAND($wParam, 0xFFFF) > 0 Then
		_WinAPI_RedrawWindow($hWnd, 0, 0, BitOR(0x0001, 0x0004, 0x0100, 0x0400))
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

Func _TriggerOneOffCaptureAndLaunch()
	_AppendToLogWindow("# Initialising targeted application tracking sequence..." & @CRLF)

	Local $bProxyWasRunning = _IsMitmproxyRunning()
	If Not $bProxyWasRunning Then
		_StartMitmproxy()
		_EnableWindowsProxy()
		_RefreshProxyStatus()
		_AppendToLogWindow("# Local interception proxy activated." & @CRLF)
	EndIf

	Local $sAppExecutable = FileOpenDialog("Select the Adobe App Showing the Popup", @ProgramFilesDir & "\Adobe\", "Applications (*.exe)")
	If @error Then
		_AppendToLogWindow("# Capture sequence aborted by user." & @CRLF)
		If Not $bProxyWasRunning Then
			_StopMitmproxy()
			_DisableWindowsProxy()
			_RefreshProxyStatus()
		EndIf
		Return False
	EndIf

	Local $sAppName = StringRegExpReplace($sAppExecutable, '^.*\\', '')
	_AppendToLogWindow("# Spawning background sandbox instance: " & $sAppName & @CRLF)

	Local $sPreExistingPIDs = "|"
	Local $aPre = ProcessList($sAppName)
	If IsArray($aPre) Then
		For $iP = 1 To $aPre[0][0]
			$sPreExistingPIDs &= $aPre[$iP][1] & "|"
		Next
	EndIf

	Local $iAppPID = Run('"' & $sAppExecutable & '"', "", @SW_SHOWMINIMIZED)
	If @error Then
		_AppendToLogWindow("# Error: Failed to execute targeted process binary." & @CRLF)
		If Not $bProxyWasRunning Then
			_StopMitmproxy()
			_DisableWindowsProxy()
			_RefreshProxyStatus()
		EndIf
		Return False
	EndIf

	Local $hTimer = TimerInit()
	Local $bCaptured = False
	Local $sCapturedDomain = ""

	_AppendToLogWindow("# Catching dynamic domain from memory maps (exits on detection; max 45s)..." & @CRLF)

	While TimerDiff($hTimer) < 45000
		Sleep(400)

		_PollMitmproxyLog()

		Local $sLogText = _GUICtrlRichEdit_GetText($g_hMitmRichEdit)
		If StringStripWS($sLogText, 3) <> "" Then
			Local $aDomainMatch = StringRegExp($sLogText, '(?i)([A-Za-z0-9_.-]+\.adobestats\.io)', 1)
			If Not @error Then
				$sCapturedDomain = StringLower($aDomainMatch[0])
				_SilentHostsInjector($sCapturedDomain)
				$bCaptured = True
				ExitLoop
			EndIf
		EndIf
	WEnd

	Local $iClosed = 0
	Local $aPost = ProcessList($sAppName)
	If IsArray($aPost) Then
		For $iP = 1 To $aPost[0][0]
			Local $iThisPID = $aPost[$iP][1]
			If Not StringInStr($sPreExistingPIDs, "|" & $iThisPID & "|") Then
				If ProcessExists($iThisPID) Then
					ProcessClose($iThisPID)
					$iClosed += 1
				EndIf
			EndIf
		Next
	EndIf
	If ProcessExists($iAppPID) Then
		ProcessClose($iAppPID)
		$iClosed += 1
	EndIf
	_AppendToLogWindow("# Closed " & $iClosed & " launched instance(s) of " & $sAppName & " (pre-existing copies left running)." & @CRLF)

	If Not $bProxyWasRunning Then
		_AppendToLogWindow("# Cleaning environment: Shutting down capture engine..." & @CRLF)
		_StopMitmproxy()
		_DisableWindowsProxy()
		_RefreshProxyStatus()
		_AppendToLogWindow("# Environment restored to default system network maps cleanly." & @CRLF)
	Else
		_AppendToLogWindow("# Leaving existing proxy session running (it was active before this capture)." & @CRLF)
		_RefreshProxyStatus()
	EndIf

	If $bCaptured Then
		MsgBox(64, "Success", "Adobe Endpoint Block updated successfully via " & StringReplace($sAppName, ".exe", "") & "!" & @CRLF & @CRLF & _
				"Block Rule Entries:" & @CRLF & _
				"0.0.0.0 ic.adobe.io" & @CRLF & _
				"0.0.0.0 " & $sCapturedDomain & @CRLF & @CRLF & _
				"The rule has been saved to your hosts file and local DNS cache flushed.")
	Else
		_AppendToLogWindow("# Warning: Capture sequence timed out." & @CRLF)
		MsgBox(48, "Capture Failure", "Timed out trying to grab the background token from " & $sAppName & "." & @CRLF & _
				"Please run your Adobe app normally and click 'Add hosts'" & @CRLF & "manually from the log window instead.")
	EndIf
	Return $bCaptured
EndFunc

Func UpdateHostsFile()
	If Not _RequireAdmin("modify the Windows hosts file") Then Return
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	RemoveHostsEntries()
	GUICtrlSetState($idBtnUpdateHosts, $GUI_DISABLE)
	MemoWrite(@CRLF & "Starting hosts file update..." & @CRLF)

	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = $sHostsPath & ".bak"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"
	Local $sDomainListURL = $sCurrentDomainListURL
	Local $sTempFileDownload, $sDomainList, $sHostsContent, $hFile

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		If Not FileCopy($sHostsPath, $sBackupPath, 1) Then
			MemoWrite("Error creating hosts backup." & @CRLF)
			GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
			FileSetAttrib($sHostsPath, "+R")
			Return
		EndIf
		MemoWrite("Hosts file backed up." & @CRLF)
	EndIf

	$sTempFileDownload = _TempFile(@TempDir & "\domain_list")
	Local $iInetResult = InetGet($sDomainListURL, $sTempFileDownload, 1)
	If @error Or $iInetResult = 0 Then
		MemoWrite("Download Error: " & @error & ", InetGet Result: " & $iInetResult & @CRLF)
		MemoWrite("Remote domain list unreachable - hosts file unchanged." & @CRLF)
		MemoWrite("Check your network connection and try again when available." & @CRLF)
		LogWrite(1, "Hosts list download failed (remote unreachable). No changes applied.")
		FileDelete($sTempFileDownload)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sDomainList = FileRead($sTempFileDownload)
	FileDelete($sTempFileDownload)
	MemoWrite("Downloaded remote list:" & @CRLF & $sDomainList & @CRLF)

	$sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("Error reading hosts file." & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sHostsContent = StringStripWS($sHostsContent, 2)

	Local $sNewContent = $sMarkerStart & @CRLF & $sDomainList & @CRLF & $sMarkerEnd
	If StringLen($sHostsContent) > 0 Then
		$sHostsContent &= @CRLF & $sNewContent
	Else
		$sHostsContent = $sNewContent
	EndIf

	MemoWrite(@CRLF & "Scanning DNS cache for additional (sub)domains..." & @CRLF)
	Local $aDNSDomainsAdded = ScanDNSCache($sHostsContent)
	If IsArray($aDNSDomainsAdded) And UBound($aDNSDomainsAdded) > 0 Then
		Local $sDNSEntries = ""
		For $i = 0 To UBound($aDNSDomainsAdded) - 1
			$sDNSEntries &= "0.0.0.0 " & $aDNSDomainsAdded[$i] & @CRLF
		Next
		$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)(" & $sMarkerStart & ".*?)(" & $sMarkerEnd & ")", "$1" & $sDNSEntries & "$2")
		MemoWrite("Added from DNS cache:" & @CRLF & _ArrayToString($aDNSDomainsAdded, @CRLF) & @CRLF)
		LogWrite(1, "Added from DNS cache: " & _ArrayToString($aDNSDomainsAdded, ", ") & @CRLF)
	Else
		MemoWrite("No new domains found in DNS cache." & @CRLF)
	EndIf

	$hFile = FileOpen($sHostsPath, 2)
	If $hFile = -1 Then
		Local $iLastError = _WinAPI_GetLastError()
		MemoWrite("Error opening hosts file for writing: Last Error = " & $iLastError & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	FileWrite($hFile, $sHostsContent)
	FileClose($hFile)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "Hosts file updated successfully." & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
EndFunc

Func EditHosts()
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		FileCopy($sHostsPath, $sBackupPath)
	EndIf

	Local $iPID = Run("notepad.exe " & $sHostsPath)
	If $iPID = 0 Then
		MemoWrite("Error launching Notepad." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf

	Local $iTimeout = 300000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Notepad timed out after " & $iTimeout / 1000 & " seconds." & @CRLF)
	EndIf

	FileSetAttrib($sHostsPath, "+R")
EndFunc

Func RestoreHosts()
	If Not _RequireAdmin("restore the Windows hosts file") Then Return
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "Restoring the hosts file from backup..." & @CRLF & "---" & @CRLF & "Please wait..." & @CRLF)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	If FileExists($sBackupPath) Then
		FileSetAttrib($sHostsPath, "-R")
		If FileCopy($sBackupPath, $sHostsPath, 1) Then
			FileSetAttrib($sHostsPath, "+R")
			FileDelete($sBackupPath)
			LogWrite(1, "Restoring the hosts file from backup: Success!" & @CRLF)
		Else
			MemoWrite("Error restoring hosts file from backup." & @CRLF)
			FileSetAttrib($sHostsPath, "+R")
			LogWrite(1, "Restoring the hosts file from backup: Failed." & @CRLF)
		EndIf
	Else
		LogWrite(1, "Restoring the hosts file from backup: No backup file found." & @CRLF)
	EndIf
	ToggleLog(1)
EndFunc

Func CheckThirdPartyFirewall()
	Local $sInner = "Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName FirewallProduct -ErrorAction SilentlyContinue | Where-Object { $_.displayName -and $_.displayName -notlike '*Windows*' } | Select-Object -ExpandProperty displayName"
	Local $iPID = Run('powershell.exe -NoProfile -Command "' & $sInner & '"', "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $iWaitResult = ProcessWaitClose($iPID, 6000)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Third-party firewall check timed out.")
	EndIf
	Local $sOutput = StringStripWS(StdoutRead($iPID), 3)

	If $sOutput = "" Then
		$g_sThirdPartyFirewall = ""
		MemoWrite("Windows Firewall is the active firewall.")
		Return False
	EndIf

	Local $aLines = StringSplit(StringReplace($sOutput, @CR, ""), @LF)
	Local $mSeen = ObjCreate("Scripting.Dictionary")
	Local $sNames = ""
	For $i = 1 To $aLines[0]
		Local $sN = StringStripWS($aLines[$i], 3)
		If $sN <> "" And Not $mSeen.Exists(StringLower($sN)) Then
			$mSeen.Item(StringLower($sN)) = 1
			$sNames &= ($sNames <> "" ? ", " : "") & $sN
		EndIf
	Next

	$g_sThirdPartyFirewall = ($sNames <> "" ? $sNames : "a third-party firewall")
	MemoWrite("Third-party firewall detected: " & $g_sThirdPartyFirewall)
	Return True
EndFunc

Func FindApps($bForLocalDLL = False, $sBasePathOverride = "")
	Local $sBase = ($sBasePathOverride <> "") ? $sBasePathOverride : $MyDefPath

	Local $tFirewallPaths = IniReadSection($sINIPath, "FirewallTrust")
	If @error Then
		Local $sWhy = _ConfigHealthProblem()
		If $sWhy = "" Then $sWhy = "The [FirewallTrust] section is missing or empty in config.ini."
		MemoWrite("Firewall: " & $sWhy)
		LogWrite(1, "Firewall: " & StringReplace($sWhy, @CRLF, " "))
		Local $empty[0]
		Return $empty
	EndIf

	Local $foundFiles[0]
	For $i = 1 To $tFirewallPaths[0][0]
		Local $relativePath = StringReplace($tFirewallPaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		Local $basePath = StringRegExpReplace($sBase & "\" & $relativePath, "\\\\+", "\\")
		If StringStripWS($basePath, 3) = "" Then ContinueLoop

		If $bForLocalDLL And (StringInStr($basePath, "AcroCEF.exe", 0) Or StringInStr($basePath, "Acrobat.exe", 0)) Then
			ContinueLoop
		EndIf

		If StringInStr($basePath, "*") Then
			Local $pathParts = StringSplit($basePath, "\", 1)
			Local $searchDir = ""
			For $j = 1 To $pathParts[0] - 1
				If StringInStr($pathParts[$j], "*") Then
					$searchDir = StringTrimRight($searchDir, 1)
					Local $searchPattern = StringReplace($pathParts[$j], "*", "*")
					Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$j]) + StringLen($pathParts[$j]))
					Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
					If $HSEARCH = -1 Then ContinueLoop
					While 1
						Local $folder = FileFindNextFile($HSEARCH)
						If @error Then ExitLoop
						Local $fullPath = $searchDir & "\" & $folder & $subPath
						$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
						If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
							_ArrayAdd($foundFiles, $fullPath)
						EndIf
					WEnd
					FileClose($HSEARCH)
					ExitLoop
				Else
					$searchDir &= $pathParts[$j] & "\"
				EndIf
			Next
		Else
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
		Local $cleanedFiles[0]
		For $file In $foundFiles
			If StringStripWS($file, 3) <> "" And Not StringIsInt($file) Then
				_ArrayAdd($cleanedFiles, $file)
			EndIf
		Next
		$foundFiles = $cleanedFiles
	EndIf

	Return $foundFiles
EndFunc

Func RuleExists($ruleName)
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -DisplayName ''Adobe-Block - ' & $ruleName & ''' | Measure-Object | Select-Object -ExpandProperty Count"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		LogWrite(1, "Warning: Rule check for '" & $ruleName & "' timed out after " & $iTimeout & "ms.")
	EndIf
	Local $sOutput = StdoutRead($iPID)
	Return Number(StringStripWS($sOutput, 3)) > 0
EndFunc

Func ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite("Checking Windows Firewall status...")
	LogWrite(1, "Checking Windows Firewall status...")

	MemoWrite("Scanning firewall profiles...")
	Local $sProfileCmd = 'powershell.exe -Command "Get-NetFirewallProfile | Select-Object -Property Name,Enabled | Format-Table -HideTableHeaders"'
	Local $iPID = Run(@ComSpec & " /c " & $sProfileCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sProfileOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Firewall profile check timed out after " & $iTimeout & "ms.")
	EndIf
	$sProfileOutput = StdoutRead($iPID)

	Local $aProfiles = StringSplit(StringStripWS($sProfileOutput, 3), @CRLF, 1)
	Local $sProfileSummary = ""
	For $i = 1 To $aProfiles[0]
		Local $line = StringStripWS($aProfiles[$i], 3)
		If $line <> "" Then
			Local $aParts = StringRegExp($line, "^(\S+)\s+(\S+)$", 1)
			If @error = 0 Then
				Local $profileName = $aParts[0]
				Local $enabled = $aParts[1]
				$sProfileSummary &= $profileName & ": " & ($enabled = "True" ? "Enabled" : "Disabled") & @CRLF
			EndIf
		EndIf
	Next
	MemoWrite("Firewall Profiles:" & @CRLF & StringTrimRight($sProfileSummary, StringLen(@CRLF)))
	LogWrite(1, "Firewall Profiles - " & StringReplace(StringTrimRight($sProfileSummary, StringLen(@CRLF)), @CRLF, " | "))

	MemoWrite("Checking firewall service...")
	Local $sServiceCmd = 'powershell.exe -Command "Get-Service MpsSvc | Select-Object -Property Status,DisplayName | Format-List"'
	$iPID = Run(@ComSpec & " /c " & $sServiceCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sServiceOutput = ""
	$iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Firewall service check timed out after " & $iTimeout & "ms.")
	EndIf
	$sServiceOutput = StdoutRead($iPID)

	Local $sServiceStatus = "Unknown"
	Local $aServiceLines = StringSplit(StringStripWS($sServiceOutput, 3), @CRLF, 1)
	For $line In $aServiceLines
		If StringInStr($line, "Status") Then
			Local $aStatus = StringSplit($line, ":", 1)
			If $aStatus[0] > 1 Then
				$sServiceStatus = StringStripWS($aStatus[2], 3)
			EndIf
			ExitLoop
		EndIf
	Next
	MemoWrite("Firewall Service (MpsSvc): " & $sServiceStatus)
	LogWrite(1, "Firewall Service (MpsSvc): " & $sServiceStatus)
EndFunc

Func RemoveFirewallRules()
	If Not _RequireAdmin("remove Windows Firewall rules") Then Return
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite("Starting firewall rule removal process...")
	LogWrite(1, "Starting firewall rule removal process.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot remove rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "This option only supports Windows Firewall.")
		LogWrite(1, "Firewall rule removal process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("Scanning for firewall rules...")
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Rule scan timed out after " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("No firewall rules found.")
		LogWrite(1, "No firewall rules found to remove.")
		LogWrite(1, "Firewall rule removal process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("Removing " & $iRuleCount & " rule(s)...")
	LogWrite(1, "Removing " & $iRuleCount & " rule(s):")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sRemoveCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Remove-NetFirewallRule"'
	Local $iPIDRemove = Run($sRemoveCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDRemove, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDRemove)
		MemoWrite("Warning: Rule removal timed out after " & $iTimeout & "ms.")
		LogWrite(1, "Error: Rule removal timed out.")
	ElseIf @error Then
		MemoWrite("Error removing firewall rules.")
		LogWrite(1, "Error removing firewall rules.")
	Else
		MemoWrite("Firewall rules removed successfully.")
		LogWrite(1, "Firewall rules removed successfully.")
	EndIf

	LogWrite(1, "Firewall rule removal process completed." & @CRLF)
	ToggleLog(1)
EndFunc

Func CreateFirewallRules()
	If Not _RequireAdmin("create Windows Firewall rules") Then Return
	MemoWrite("Starting firewall rule creation process...")
	LogWrite(1, "Starting firewall rule creation process.")
	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected - app list opened in Notepad.")
		Local $foundApps = FindApps()
		If UBound($foundApps) = 0 Then
			LogWrite(1, "No applications found to block.")
		Else
			Local $sAppList = ""
			For $app In $foundApps
				$sAppList &= $app & @CRLF
			Next
			Local $sAppFile = _WriteListToNotepad("Firewall_App_Paths.txt", _
					"GenP - Firewall block targets (Adobe apps)" & @CRLF & _
					"==========================================" & @CRLF & _
					"Add an OUTBOUND BLOCK rule for each app below in your third-party" & @CRLF & _
					"firewall (" & $g_sThirdPartyFirewall & "). Save or print this for reference.", _
					$sAppList)
			LogWrite(1, "Third-party firewall (" & $g_sThirdPartyFirewall & ") - " & UBound($foundApps) & " app(s) to block manually. List written to: " & $sAppFile)
		EndIf
		LogWrite(1, "Firewall rule creation process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf
	MemoWrite("Scanning for applications...")
	Local $foundApps = FindApps()
	Local $SelectedApps = ShowAppSelectionGUI($foundApps)
	If $SelectedApps = -1 Then
		Return
	ElseIf Not IsArray($SelectedApps) Then
		MemoWrite("Firewall rule selection cancelled by user.")
		LogWrite(1, "Firewall rule selection cancelled by user." & @CRLF)
		Return
	EndIf
	_InjectNglApps($SelectedApps)
	ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	If UBound($SelectedApps) = 0 Then
		MemoWrite("No applications selected by the user.")
		LogWrite(1, "No applications selected.")
		LogWrite(1, "Firewall rule creation process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf
	MemoWrite("User selected " & UBound($SelectedApps) & " file(s).")
	Local $psCmdComposite = ""
	Local $rulesAdded = 0
	Local $addedApps[0]
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Then
			MemoWrite("Skipping empty or invalid selected path.")
			ContinueLoop
		EndIf
		If FileExists($app) Then
			Local $ruleName = $app
			If Not RuleExists($ruleName) Then
				Local $ruleCmd = "New-NetFirewallRule -DisplayName 'Adobe-Block - " & $ruleName & "' -Direction Outbound -Program '" & $app & "' -Action Block;"
				$psCmdComposite &= $ruleCmd
				MemoWrite("Adding firewall rule for: " & $app)
				_ArrayAdd($addedApps, $app)
				$rulesAdded += 1
			Else
				MemoWrite("Rule already exists for: " & $app & " - Skipping.")
			EndIf
		Else
			MemoWrite("File not found: " & $app)
			LogWrite(1, "File not found: " & $app)
		EndIf
	Next
	If $rulesAdded > 0 Then
		LogWrite(1, "Selected " & $rulesAdded & " files(s) for new firewall rule(s):")
		For $app In $addedApps
			LogWrite(1, "- " & $app)
		Next
		Local $iPID = Run('powershell.exe -Command "' & $psCmdComposite & '"', "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iPID)
			MemoWrite("Warning: Rule creation timed out after " & $iTimeout & "ms.")
			LogWrite(1, "Error: Rule creation timed out.")
		ElseIf @error Then
			MemoWrite("Error applying firewall rules.")
			LogWrite(1, "Error applying firewall rules.")
		Else
			MemoWrite("Firewall rules applied successfully.")
			LogWrite(1, "Firewall rules applied successfully.")
		EndIf
	Else
		MemoWrite("No new firewall rules to add.")
		LogWrite(1, "No new firewall rules were added (all selected rules already exist).")
	EndIf
	LogWrite(1, "Firewall rule creation process completed." & @CRLF)
	ToggleLog(1)
EndFunc

Func _WriteListToNotepad($sFileName, $sHeader, $sListText)
	Local $sPath = @TempDir & "\" & $sFileName
	Local $hF = FileOpen($sPath, 2)
	If $hF = -1 Then Return ""
	FileWrite($hF, $sHeader & @CRLF & @CRLF & $sListText)
	FileClose($hF)
	ShellExecute("notepad.exe", '"' & $sPath & '"')
	Return $sPath
EndFunc

Func _EnableNGLFirewallRules($bFocusLogOnDone = True)
	Local Const $sGroup = "GenP NGL Firewall"

	Local $aTargets = _CollectNGLBinaries()
	If UBound($aTargets) = 0 Then
		LogWrite(1, "NGL firewall: no NGL binaries found on disk - nothing to block." & @CRLF)
		If $bFocusLogOnDone Then ToggleLog(1)
		Return 0
	EndIf

	If CheckThirdPartyFirewall() Then
		Local $sFileList = ""
		For $sP In $aTargets
			$sFileList &= $sP & @CRLF
		Next
		Local $sPathsFile = _WriteListToNotepad("NGL_Firewall_Paths.txt", _
				"GenP - NGL Firewall block targets" & @CRLF & _
				"=================================" & @CRLF & _
				"Add an OUTBOUND BLOCK rule for each file below in your third-party" & @CRLF & _
				"firewall (" & $g_sThirdPartyFirewall & "). Save or print this for reference.", _
				$sFileList)
		Local $iGo = MsgBox(BitOR($MB_YESNO, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Third-Party Firewall Detected", _
				"A third-party firewall (" & $g_sThirdPartyFirewall & ") is active," & @CRLF & _
				"GenP cannot add the NGL block rules automatically." & @CRLF & @CRLF & _
				"The list of files to block has opened in Notepad." & @CRLF & _
				"Add an Outbound Block rule for each one in" & @CRLF & _
				"your own firewall." & @CRLF & @CRLF & _
				"Continue patching now?" & @CRLF & @CRLF & _
				"Yes = continue (adding the rules is on you)." & @CRLF & _
				"No = cancel so you can add them, then patch again.")
		If $iGo = $IDNO Then
			LogWrite(1, "Patch cancelled by user at the third-party firewall gate.")
			Return -99
		EndIf
		LogWrite(1, "User continued past the third-party firewall gate.")
		If $bFocusLogOnDone Then ToggleLog(1)
		Return 0
	EndIf

	If Not _WinFirewallServiceReady() Then
		LogWrite(1, "Windows Firewall service is off/unavailable - NGL block rules were skipped.")
		MsgBox(BitOR($MB_OK, $MB_ICONWARNING, $MB_SYSTEMMODAL), "Windows Firewall Unavailable", _
				"The Windows Firewall service is turned off or unavailable," & @CRLF & "so GenP could not add the NGL block rules." & @CRLF & @CRLF & _
				"Your apps are still patched and will work, but NGL is not network-isolated." & @CRLF & _
				"Turn Windows Firewall back on and patch again if you want" & @CRLF & "the isolation. This is on you.")
		If $bFocusLogOnDone Then ToggleLog(1)
		Return 0
	EndIf

	Local $mExisting = _GetExistingNGLRuleProgs($sGroup)
	Local $sComposite = "", $iAdded = 0
	For $sExe In $aTargets
		If $mExisting.Exists(StringLower($sExe)) Then ContinueLoop
		Local $sFile = StringRegExpReplace($sExe, "^.*\\", "")
		$sComposite &= "New-NetFirewallRule -DisplayName 'GenP NGL Block - " & $sFile & "' -Group '" & $sGroup & "' -Direction Outbound -Program '" & $sExe & "' -Action Block -Profile Any -ErrorAction SilentlyContinue | Out-Null; "
		LogWrite(1, "NGL firewall: queuing outbound block for " & $sExe)
		$iAdded += 1
	Next

	If $iAdded = 0 Then
		LogWrite(1, "NGL firewall rules already in place - nothing to add." & @CRLF)
		If $bFocusLogOnDone Then ToggleLog(1)
		Return 0
	EndIf

	Local $iPID = Run('powershell.exe -NoProfile -Command "' & $sComposite & '"', "", @SW_HIDE, $STDERR_CHILD)
	ProcessWaitClose($iPID, 20000)
	LogWrite(1, "NGL firewall: added " & $iAdded & " outbound block rule(s) to group '" & $sGroup & "'." & @CRLF)
	MemoWrite("NGL firewall rules applied (" & $iAdded & " added).")
	If $bFocusLogOnDone Then ToggleLog(1)
	Return $iAdded
EndFunc

Func _InjectNglApps(ByRef $aFiles)
	If $bEnableNGLFirewall = 1 Then Return

	Local $sPFBase = EnvGet("ProgramFiles")
	If $sPFBase = "" Then $sPFBase = @HomeDrive & "\Program Files"
	Local $aStatic[2] = [ _
			$sPFBase & "\" & $g_aNGLRelativePaths[0], _
			$sPFBase & "\" & $g_aNGLRelativePaths[1]]
	For $sPath In $aStatic
		If FileExists($sPath) Then _ArrayAdd($aFiles, $sPath)
	Next
	If FileExists($MyDefPath) And StringInStr(FileGetAttrib($MyDefPath), "D") Then
		Local $sScanCmd = 'powershell.exe -NoProfile -Command "Get-ChildItem -Path \"' & $MyDefPath & '\" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match \"^adobe_licensing_wf.*\.exe$\" -or $_.Name -match \"^adobe_licensing_helper.*\.exe$\" } | Select-Object -ExpandProperty FullName"'
		Local $iPID = Run(@ComSpec & " /c " & $sScanCmd, "", @SW_HIDE, $STDOUT_CHILD)
		ProcessWaitClose($iPID, 8000)
		Local $aFound = StringSplit(StringStripWS(StdoutRead($iPID), 3), @CRLF, 1)
		For $i = 1 To $aFound[0]
			Local $sF = StringStripWS($aFound[$i], 3)
			If $sF <> "" And FileExists($sF) Then _ArrayAdd($aFiles, $sF)
		Next
	EndIf
	If UBound($aFiles) > 0 Then
		$aFiles = _ArrayUnique($aFiles, 0, 0, 0, 0)
		Local $aClean[0]
		For $f In $aFiles
			If StringStripWS($f, 3) <> "" And Not StringIsInt($f) Then _ArrayAdd($aClean, $f)
		Next
		$aFiles = $aClean
	EndIf
EndFunc

Func ShowAppSelectionGUI($foundFiles)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No file(s) found at: " & $MyDefPath)
		LogWrite(1, "No file(s) found at: " & $MyDefPath)
		ToggleLog(1)
		Return -1
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("Select File(s) to Firewall", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileNoBak = StringRegExpReplace(StringReplace($file, ".bak", ""), "\\\\+", "\\")
		Local $fileParts = StringSplit($fileNoBak, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "Warning: Short path used in config, using Unknown for: " & $fileNoBak)
		EndIf

		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($file, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next
	LogWrite(1, "Found " & UBound($foundFiles) & " file(s) across " & $appNodes.Count & " application(s).")

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $SelectedApps[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("Scanning for selected items...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						Local $childCount = _GUICtrlTreeView_GetChildCount($hTreeView, $hItem)
						If $childCount = -1 And StringStripWS($itemText, 3) <> "" Then
							_ArrayAdd($SelectedApps, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				MemoWrite("Selected " & UBound($SelectedApps) & " file(s) for firewall rules.")
				GUIDelete($hGUI)
				Return $SelectedApps
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func CheckParentCheckboxes()
	Local $hItem = _GUICtrlTreeView_GetFirstItem($ghTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($ghTreeView, $hItem)
		Local $childCount = _GUICtrlTreeView_GetChildCount($ghTreeView, $hItem)
		If $childCount > 0 Then
			If IsObj($g_mBlockedParents) And $g_mBlockedParents.Exists($itemText) Then
				_GUICtrlTreeView_SetChecked($ghTreeView, $hItem, False)
				Local $hBC = _GUICtrlTreeView_GetFirstChild($ghTreeView, $hItem)
				While $hBC <> 0
					_GUICtrlTreeView_SetChecked($ghTreeView, $hBC, False)
					$hBC = _GUICtrlTreeView_GetNextChild($ghTreeView, $hBC)
				WEnd
				$prevStates($itemText) = False
				$hItem = _GUICtrlTreeView_GetNext($ghTreeView, $hItem)
				ContinueLoop
			EndIf

			Local $currentState = _GUICtrlTreeView_GetChecked($ghTreeView, $hItem)
			Local $prevState = $prevStates($itemText)
			If $currentState <> $prevState Then
				$prevStates($itemText) = $currentState
				Local $hChild = _GUICtrlTreeView_GetFirstChild($ghTreeView, $hItem)
				While $hChild <> 0
					_GUICtrlTreeView_SetChecked($ghTreeView, $hChild, $currentState)
					$hChild = _GUICtrlTreeView_GetNextChild($ghTreeView, $hChild)
				WEnd
			EndIf
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($ghTreeView, $hItem)
	WEnd
EndFunc

Func ShowToggleRulesGUI()
	MemoWrite("Opening firewall rule toggle options...")

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hToggleGUI = GUICreate("Toggle Rules", 300, 150, $iPopupX, $iPopupY)
	Local $hEnableButton = GUICtrlCreateButton("Enable All", 50, 50, 100, 30)
	Local $hDisableButton = GUICtrlCreateButton("Disable All", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("Toggle rules operation cancelled.")
				GUIDelete($hToggleGUI)
				Return
			Case $hEnableButton
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hToggleGUI)
				EnableAllFWRules()
				Return
			Case $hDisableButton
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hToggleGUI)
				DisableAllFWRules()
				Return
		EndSwitch
	WEnd
EndFunc

Func EnableAllFWRules()
	MemoWrite("Enabling all GenP firewall rules...")
	LogWrite(1, "Starting process to enable all GenP firewall rules.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot modify rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "This option only supports Windows Firewall.")
		LogWrite(1, "Enable rules process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Rule scan timed out after " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("No GenP firewall rules found to enable.")
		LogWrite(1, "No GenP firewall rules found.")
		LogWrite(1, "Enable rules process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("Enabling " & $iRuleCount & " Adobe-Block rule(s)...")
	LogWrite(1, "Enabling " & $iRuleCount & " rule(s):")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sEnableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Enable-NetFirewallRule"'
	Local $iPIDEnable = Run($sEnableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDEnable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDEnable)
		MemoWrite("Warning: Rule enabling timed out after " & $iTimeout & "ms.")
		LogWrite(1, "Error: Rule enabling timed out.")
	ElseIf @error Then
		MemoWrite("Error enabling firewall rules.")
		LogWrite(1, "Error enabling firewall rules.")
	Else
		MemoWrite("All GenP firewall rules enabled successfully.")
		LogWrite(1, "All GenP firewall rules enabled successfully.")
	EndIf

	LogWrite(1, "Enable rules process completed." & @CRLF)
	ToggleLog(1)
EndFunc

Func DisableAllFWRules()
	MemoWrite("Disabling all GenP firewall rules...")
	LogWrite(1, "Starting process to disable all GenP firewall rules.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot modify rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "This option only supports Windows Firewall.")
		LogWrite(1, "Disable rules process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Rule scan timed out after " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("No GenP firewall rules found to disable.")
		LogWrite(1, "No GenP firewall rules found.")
		LogWrite(1, "Disable rules process completed." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("Disabling " & $iRuleCount & " Adobe-Block rule(s)...")
	LogWrite(1, "Disabling " & $iRuleCount & " rule(s):")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sDisableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Disable-NetFirewallRule"'
	Local $iPIDDisable = Run($sDisableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDDisable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDDisable)
		MemoWrite("Warning: Rule disabling timed out after " & $iTimeout & "ms.")
		LogWrite(1, "Error: Rule disabling timed out.")
	ElseIf @error Then
		MemoWrite("Error disabling firewall rules.")
		LogWrite(1, "Error disabling firewall rules.")
	Else
		MemoWrite("All GenP firewall rules disabled successfully.")
		LogWrite(1, "All GenP firewall rules disabled successfully.")
	EndIf

	LogWrite(1, "Disable rules process completed." & @CRLF)
	ToggleLog(1)
EndFunc

Func FindRuntimeInstallerFiles()
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	Local $tRuntimePaths = IniReadSection($sINIPath, "RuntimeInstallers")
	Local $dllPaths[0]

	If @error Or $tRuntimePaths[0][0] = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		Local $sWhy = _ConfigHealthProblem()
		If $sWhy = "" Then $sWhy = "The [RuntimeInstallers] section is missing or empty in config.ini."
		MemoWrite("Runtime installers: " & $sWhy)
		LogWrite(1, "Runtime installers: " & StringReplace($sWhy, @CRLF, " "))
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	ReDim $dllPaths[$tRuntimePaths[0][0]]
	For $i = 1 To $tRuntimePaths[0][0]
		Local $relativePath = StringReplace($tRuntimePaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		$dllPaths[$i - 1] = StringRegExpReplace($MyDefPath & "\" & $relativePath, "\\\\+", "\\")
	Next

	Local $foundFiles[0]
	For $basePath In $dllPaths
		If StringStripWS($basePath, 3) = "" Then ContinueLoop
		Local $pathParts = StringSplit($basePath, "\", 1)
		Local $searchDir = ""
		For $i = 1 To $pathParts[0] - 1
			If StringInStr($pathParts[$i], "*") Then
				$searchDir = StringTrimRight($searchDir, 1)
				Local $searchPattern = StringReplace($pathParts[$i], "*", "*")
				Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$i]) + StringLen($pathParts[$i]))
				Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
				If $HSEARCH = -1 Then
					ContinueLoop
				EndIf
				While 1
					Local $folder = FileFindNextFile($HSEARCH)
					If @error Then ExitLoop
					Local $fullPath = $searchDir & "\" & $folder & $subPath
					$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
					If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
						_ArrayAdd($foundFiles, $fullPath)
					EndIf
				WEnd
				FileClose($HSEARCH)
				ExitLoop
			Else
				$searchDir &= $pathParts[$i] & "\"
			EndIf
		Next

		If Not StringInStr($basePath, "*") Then
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
	EndIf

	Return $foundFiles
EndFunc

Func UnpackRuntimeInstallers()
	MemoWrite("Scanning for RuntimeInstaller.dll files...")
	Local $foundFiles = FindRuntimeInstallerFiles()

	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No file(s) found at: " & $MyDefPath)
		LogWrite(1, "No file(s) found at: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $selectedFiles = RuntimeDllSelectionGUI($foundFiles, "Unpack")

	If Not IsArray($selectedFiles) Or UBound($selectedFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
		LogWrite(1, "No files selected to unpack.")
		ToggleLog(1)
		Return
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
			MemoWrite("Error: Failed to extract upx.exe to " & $upxPath)
			LogWrite(1, "Error: Failed to extract upx.exe.")
			ToggleLog(1)
			Return
		EndIf
	EndIf

	MemoWrite("Unpacking " & UBound($selectedFiles) & " file(s)...")
	LogWrite(1, "Unpacking " & UBound($selectedFiles) & " file(s):")
	Local $successCount = 0

	For $file In $selectedFiles
		$file = StringStripWS($file, 3)
		If $file = "" Or Not FileExists($file) Then
			MemoWrite("Skipping invalid or missing file: " & $file)
			LogWrite(1, "Skipping invalid or missing file: " & $file)
			ContinueLoop
		EndIf

		LogWrite(1, "Processing: " & $file)

		If Not IsUPXPacked($file) Then
			MemoWrite("Skipped: " & $file & " is not a UPX-packed file.")
			LogWrite(1, "Skipped: " & $file & " is not a UPX-packed file.")
			ContinueLoop
		EndIf

		If Not PatchUPXHeader($file) Then
			MemoWrite("Failed to patch UPX headers for: " & $file)
			LogWrite(1, "Failed to patch UPX headers for: " & $file)
			ContinueLoop
		EndIf

		Local $iResult = RunWait('"' & $upxPath & '" -d "' & $file & '"', "", @SW_HIDE)
		If $iResult = 0 Then
			MemoWrite("Successfully unpacked: " & $file)
			LogWrite(1, "Successfully unpacked: " & $file)
			$successCount += 1
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileDelete($sBackupPath)
			EndIf
		Else
			MemoWrite("Failed to unpack: " & $file & " (UPX error code: " & $iResult & ")")
			LogWrite(1, "Failed to unpack: " & $file & " (UPX error code: " & $iResult & ")")
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileCopy($sBackupPath, $file, 1)
				FileDelete($sBackupPath)
				MemoWrite("Restored original file from backup: " & $file)
				LogWrite(1, "Restored original file from backup: " & $file)
			EndIf
		EndIf
	Next

	If FileExists($upxPath) Then
		If FileDelete($upxPath) Then
			MemoWrite("Deleted upx.exe from " & $upxPath & ".")
		Else
			MemoWrite("Warning: Failed to delete upx.exe from " & $upxPath & ".")
			LogWrite(1, "Warning: Failed to delete upx.exe from " & $upxPath & ".")
		EndIf
	EndIf

	MemoWrite("Unpack completed. Successfully unpacked " & $successCount & " file(s).")
	LogWrite(1, "Unpack process completed.")

	If $successCount > 0 Then
		LogWrite(1, $successCount & " file(s) successfully unpacked and can now be patched.")
	EndIf

	ToggleLog(1)
EndFunc

Func IsUPXPacked($sFilePath)
	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		LogWrite(1, "Error: Failed to open file for UPX check: " & $sFilePath)
		Return False
	EndIf

	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		LogWrite(1, "Error: Failed to read file for UPX check: " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	If StringInStr($sHexData, "55505821") Or StringInStr($sHexData, "007465787400") Or StringInStr($sHexData, "746578743100") Then
		Return True
	EndIf

	Return False
EndFunc

Func PatchUPXHeader($sFilePath)
	Local Const $sUPX0 = "005550583000"
	Local Const $sUPX1 = "555058310000"

	Local $aCustomHeaders1 = ["007465787400"]
	Local $aCustomHeaders2 = ["746578743100"]

	Local $sBackupPath = $sFilePath & ".bak"
	If Not FileCopy($sFilePath, $sBackupPath, 1) Then
		MemoWrite("Error: Failed to create backup for: " & $sFilePath)
		LogWrite(1, "Error: Failed to create backup for: " & $sFilePath)
		Return False
	EndIf

	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		MemoWrite("Error: Failed to open file for patching: " & $sFilePath)
		LogWrite(1, "Error: Failed to open file for patching: " & $sFilePath)
		Return False
	EndIf
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		MemoWrite("Error: Failed to read file for patching: " & $sFilePath)
		LogWrite(1, "Error: Failed to read file for patching: " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	Local $bModified = False

	For $sHeader In $aCustomHeaders1
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX0)
			$bModified = True
			ExitLoop
		EndIf
	Next

	For $sHeader In $aCustomHeaders2
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX1)
			$bModified = True
			ExitLoop
		EndIf
	Next

	If Not $bModified Then
		MemoWrite("No custom UPX headers found in: " & $sFilePath)
		FileDelete($sBackupPath)
		Return True
	EndIf

	Local $bModifiedData = Binary("0x" & StringMid($sHexData, 3))
	Local $hFileWrite = FileOpen($sFilePath, 18)
	If $hFileWrite = -1 Then
		MemoWrite("Error: Failed to open file for writing: " & $sFilePath)
		LogWrite(1, "Error: Failed to open file for writing: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf
	FileWrite($hFileWrite, $bModifiedData)
	FileClose($hFileWrite)
	If @error Then
		MemoWrite("Error: Failed to write patched data to: " & $sFilePath)
		LogWrite(1, "Error: Failed to write patched data to: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf

	MemoWrite("Successfully patched UPX headers in: " & $sFilePath)
	Return True
EndFunc

Func RuntimeDllSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No RuntimeInstaller.dll files found to unpack.")
		LogWrite(1, "No RuntimeInstaller.dll files found to unpack.")
		ToggleLog(1)
		Return ""
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("Unpack RuntimeInstaller", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")
		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "Warning: Short path used in config, using Unknown for: " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite("RuntimeInstaller unpacking cancelled.")
				LogWrite(1, "RuntimeInstaller unpacking cancelled.")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					Local $isChecked = _GUICtrlTreeView_GetChecked($hTreeView, $hItem)
					If $isChecked And StringInStr($itemText, "RuntimeInstaller.dll") Then
						_ArrayAdd($selectedFiles, $itemText)
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
					LogWrite(1, "No RuntimeInstaller.dll files selected to unpack.")
					ToggleLog(1)
					Return ""
				EndIf
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func AddDevOverride()
	If Not IsAdmin() Then
		MemoWrite("Error: Administrator rights required to set WinTrust registry keys.")
		LogWrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf

	Local $iIFEO = RegRead($g_sWT_IFEO, "DevOverrideEnable")
	Local $iSxS = RegRead($g_sWT_SxS, "DevOverrideEnable")
	Local $iWT64 = RegRead($g_sWT_WT64, "EnableCertPaddingCheck")
	Local $iWT32 = RegRead($g_sWT_WT32, "EnableCertPaddingCheck")
	If $iIFEO = 1 And $iSxS = 1 And $iWT64 = 0 And $iWT32 = 0 Then
		MemoWrite("WinTrust override already fully enabled across all four keys.")
		LogWrite(1, "All four WinTrust keys already set correctly; no action.")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "1")
		Return True
	EndIf

	Local $iErr = 0, $iFailMask = 0
	If Not RegWrite($g_sWT_IFEO, "DevOverrideEnable", "REG_DWORD", 1) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 1)
	EndIf
	If Not RegWrite($g_sWT_SxS, "DevOverrideEnable", "REG_DWORD", 1) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 2)
	EndIf
	If Not RegWrite($g_sWT_WT64, "EnableCertPaddingCheck", "REG_DWORD", 0) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 4)
	EndIf
	If Not RegWrite($g_sWT_WT32, "EnableCertPaddingCheck", "REG_DWORD", 0) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 8)
	EndIf

	If $iErr > 0 Then
		Local $sFail = ""
		If BitAND($iFailMask, 1) Then $sFail &= "IFEO, "
		If BitAND($iFailMask, 2) Then $sFail &= "SxS, "
		If BitAND($iFailMask, 4) Then $sFail &= "Wintrust64, "
		If BitAND($iFailMask, 8) Then $sFail &= "Wintrust32, "
		$sFail = StringTrimRight($sFail, 2)
		MemoWrite("Error: Failed to write " & $iErr & " of 4 WinTrust keys: " & $sFail)
		LogWrite(1, "WinTrust enable: " & $iErr & " key(s) failed (" & $sFail & "). Check antivirus / permissions.")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "partial")
		Return False
	EndIf

	MemoWrite("Enabled WinTrust override (IFEO + SxS + Wintrust 64/32-bit cert padding check).")
	LogWrite(1, "All four WinTrust override keys set successfully.")
	IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "1")
	ShowRebootPopup()
	Return True
EndFunc

Func RemoveDevOverride()
	If Not IsAdmin() Then
		MemoWrite("Error: Administrator rights required to remove WinTrust registry keys.")
		LogWrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf

	Local $iIFEO = RegRead($g_sWT_IFEO, "DevOverrideEnable")
	Local $iIFEOErr = @error
	Local $iSxS = RegRead($g_sWT_SxS, "DevOverrideEnable")
	Local $iSxSErr = @error
	Local $iWT64 = RegRead($g_sWT_WT64, "EnableCertPaddingCheck")
	Local $iWT64Err = @error
	Local $iWT32 = RegRead($g_sWT_WT32, "EnableCertPaddingCheck")
	Local $iWT32Err = @error

	If ($iIFEOErr <> 0 Or $iIFEO = 0) _
			And ($iSxSErr <> 0 Or $iSxS = 0) _
			And ($iWT64Err <> 0 Or $iWT64 = 1) _
			And ($iWT32Err <> 0 Or $iWT32 = 1) Then
		MemoWrite("WinTrust override already at default state; no action.")
		LogWrite(1, "All four WinTrust keys already restored or absent.")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
		Return True
	EndIf

	Local $iErr = 0, $iFailMask = 0
	If Not RegWrite($g_sWT_IFEO, "DevOverrideEnable", "REG_DWORD", 0) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 1)
	EndIf
	If Not RegWrite($g_sWT_SxS, "DevOverrideEnable", "REG_DWORD", 0) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 2)
	EndIf
	If Not RegWrite($g_sWT_WT64, "EnableCertPaddingCheck", "REG_DWORD", 1) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 4)
	EndIf
	If Not RegWrite($g_sWT_WT32, "EnableCertPaddingCheck", "REG_DWORD", 1) Then
		$iErr += 1
		$iFailMask = BitOR($iFailMask, 8)
	EndIf

	If $iErr > 0 Then
		Local $sFail = ""
		If BitAND($iFailMask, 1) Then $sFail &= "IFEO, "
		If BitAND($iFailMask, 2) Then $sFail &= "SxS, "
		If BitAND($iFailMask, 4) Then $sFail &= "Wintrust64, "
		If BitAND($iFailMask, 8) Then $sFail &= "Wintrust32, "
		$sFail = StringTrimRight($sFail, 2)
		MemoWrite("Error: Failed to restore " & $iErr & " of 4 WinTrust keys: " & $sFail)
		LogWrite(1, "WinTrust restore: " & $iErr & " key(s) failed (" & $sFail & ").")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "partial")
		Return False
	EndIf

	MemoWrite("Disabled WinTrust override; restored default security across all four keys.")
	LogWrite(1, "All four WinTrust keys restored to default.")
	IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
	ShowRebootPopup()
	Return True
EndFunc

Func ShowRebootPopup()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 200) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 100) / 2
	Local $hPopup = GUICreate("", 200, 100, $iPopupX, $iPopupY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	GUICtrlCreateLabel("System reboot required for changes to take effect.", 10, 10, 180, 40, $SS_CENTER)
	Local $idOk = GUICtrlCreateButton("OK", 50, 60, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		If GUIGetMsg() = $idOk Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc

Func _MonoInfoBox($sTitle, $sBody, $iAutoSecs = 0)
	Local $iW = 470, $iH = 240
	Local $aP = WinGetPos($MyhGUI), $iX, $iY
	If IsArray($aP) And $aP[0] > -30000 And $aP[1] > -30000 Then
		$iX = $aP[0] + ($aP[2] - $iW) / 2
		$iY = $aP[1] + ($aP[3] - $iH) / 2
	Else
		$iX = (@DesktopWidth - $iW) / 2
		$iY = (@DesktopHeight - $iH) / 2
	EndIf
	Local $hGUI = GUICreate($sTitle, $iW, $iH, $iX, $iY, BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_TOPMOST)
	Local $idLbl = GUICtrlCreateLabel($sBody, 16, 14, $iW - 32, $iH - 62)
	GUICtrlSetFont($idLbl, 10, 400, 0, "Consolas")
	Local $sOkText = ($iAutoSecs > 0 ? "OK  (" & $iAutoSecs & ")" : "OK")
	Local $idOk = GUICtrlCreateButton($sOkText, ($iW - 110) / 2, $iH - 40, 110, 28)
	GUISetState(@SW_SHOW, $hGUI)
	Local $iStart = TimerInit(), $iLast = -1
	While 1
		If $iAutoSecs > 0 Then
			Local $iLeft = $iAutoSecs - Int(TimerDiff($iStart) / 1000)
			If $iLeft <> $iLast Then
				$iLast = $iLeft
				If $iLeft <= 0 Then ExitLoop
				GUICtrlSetData($idOk, "OK  (" & $iLeft & ")")
			EndIf
		EndIf
		Switch GUIGetMsg()
			Case $idOk, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
		Sleep(20)
	WEnd
	GUIDelete($hGUI)
EndFunc

Func _ReloadAdobeNow()
	LogWrite(1, @CRLF & "Reloading Adobe - stopping the Adobe process/service tree so patched files reload...")
	Local $iSurvived = _StopAllAdobeProcesses()
	If $iSurvived = 0 Then
		LogWrite(1, "Adobe reloaded cleanly. Patched files will load next time Creative Cloud is opened.")
	Else
		LogWrite(1, $iSurvived & " Adobe process(es) survived - if the Install/Open state misbehaves, a full restart will clear it.")
	EndIf
EndFunc

Func _SuppressCCTutorials()
	Local $sOOBE = @LocalAppDataDir & "\Adobe\OOBE"
	If Not FileExists($sOOBE) Then Return
	Local $aFiles = _FileListToArray($sOOBE, "*.prefs", 1)
	If Not IsArray($aFiles) Then Return
	Local $iChanged = 0
	For $i = 1 To $aFiles[0]
		Local $sPath = $sOOBE & "\" & $aFiles[$i]
		Local $sContent = FileRead($sPath)
		If @error Or Not StringInStr($sContent, 'statusLight">0<') Then ContinueLoop
		Local $sNew = StringReplace($sContent, 'statusLight">0<', 'statusLight">1<')
		If $sNew <> $sContent Then
			Local $hF = FileOpen($sPath, 2)
			If $hF <> -1 Then
				FileWrite($hF, $sNew)
				FileClose($hF)
				$iChanged += 1
			EndIf
		EndIf
	Next
	If $iChanged > 0 Then LogWrite(1, "CC onboarding: marked tutorials as seen in " & $iChanged & " prefs file(s).")
EndFunc

Func _FinalisePatchRun()
	_RefreshLog()
	_ReloadAdobeNow()
	_SuppressCCTutorials()
	_LogBetaRunNotice()
	_LogLightroomCloudNotice()
	_RefreshLog()
EndFunc

Func ManageWinTrust()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("Manage WinTrust", 300, 150, $iPopupX, $iPopupY)
	Local $hTrustButton = GUICtrlCreateButton("Trust", 50, 50, 100, 30)
	Local $hUntrustButton = GUICtrlCreateButton("Untrust", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("WinTrust management cancelled.")
				GUIDelete($hGUI)
				Return
			Case $hTrustButton
				GUIDelete($hGUI)
				TrustEXEs()
				Return
			Case $hUntrustButton
				GUIDelete($hGUI)
				UntrustEXEs()
				Return
		EndSwitch
	WEnd
EndFunc

Func _GetAfterFXVersion($sPathToExe)
	Local $aRet[2] = [0, 0]
	If Not FileExists($sPathToExe) Then Return $aRet
	Local $sVer = FileGetVersion($sPathToExe)
	If @error Or $sVer = "" Or StringRegExp($sVer, "^0\.0\.0\.0?") Then
		$sVer = FileGetVersion($sPathToExe, $FV_PRODUCTVERSION)
		If @error Then $sVer = ""
	EndIf
	If $sVer = "" Then Return $aRet
	Local $aParts = StringSplit($sVer, ".")
	If $aParts[0] >= 2 Then
		$aRet[0] = Number($aParts[1])
		$aRet[1] = Number($aParts[2])
	EndIf
	Return $aRet
EndFunc

Func _IsAEBlockedByVersion($iMajor, $iMinor)
	If $iMajor > 25 Then Return True
	If $iMajor = 25 And $iMinor >= 4 Then Return True
	Return False
EndFunc

Func _EvaluateAEBlock($hTreeView, $hParent, $sAppName)
	If Not StringInStr($sAppName, "After Effects") Then Return False

	Local $sAfterFXPath = ""
	Local $sAnyChildPath = ""
	Local $aChildPaths[0]
	Local $hChild = _GUICtrlTreeView_GetFirstChild($hTreeView, $hParent)
	While $hChild <> 0
		Local $sChildText = _GUICtrlTreeView_GetText($hTreeView, $hChild)
		_ArrayAdd($aChildPaths, $sChildText)
		If $sAnyChildPath = "" Then $sAnyChildPath = $sChildText
		If StringRegExp($sChildText, "(?i)\\AfterFX( \(Beta\))?\.exe$") Then
			$sAfterFXPath = $sChildText
		EndIf
		$hChild = _GUICtrlTreeView_GetNextChild($hTreeView, $hChild)
	WEnd

	If $sAfterFXPath = "" Then
		If $sAnyChildPath <> "" Then
			Local $aMatch = StringRegExp($sAnyChildPath, "(?i)^(.*?\\Adobe After Effects[^\\]*\\)", 1)
			If IsArray($aMatch) Then
				Local $sAERoot = $aMatch[0]
				If FileExists($sAERoot & "Support Files\AfterFX.exe") Then
					$sAfterFXPath = $sAERoot & "Support Files\AfterFX.exe"
				ElseIf FileExists($sAERoot & "AfterFX.exe") Then
					$sAfterFXPath = $sAERoot & "AfterFX.exe"
				ElseIf FileExists($sAERoot & "Support Files\AfterFX (Beta).exe") Then
					$sAfterFXPath = $sAERoot & "Support Files\AfterFX (Beta).exe"
				ElseIf FileExists($sAERoot & "AfterFX (Beta).exe") Then
					$sAfterFXPath = $sAERoot & "AfterFX (Beta).exe"
				EndIf
			EndIf
		EndIf
	EndIf

	Local $aVer[2] = [0, 0]
	If $sAfterFXPath <> "" Then
		$aVer = _GetAfterFXVersion($sAfterFXPath)
	EndIf

	If $aVer[0] = 0 And $aVer[1] = 0 Then
		Local $sIniVer = ""

		$sIniVer = IniRead($patchStatesINI, "App_Version", $sAppName, "")

		If $sIniVer = "" Then
			Local $sStripName = StringRegExpReplace($sAppName, "^(?i)Adobe\s+", "")
			$sIniVer = IniRead($patchStatesINI, "App_Version", $sStripName, "")

			If $sIniVer = "" Then
				Local $sCore = StringRegExpReplace($sStripName, "\s*\(Beta\)", "")
				Local $bIsBeta = StringInStr($sStripName, "(Beta)") > 0
				Local $aSec = IniReadSection($patchStatesINI, "App_Version")
				If IsArray($aSec) Then
					For $k = 1 To $aSec[0][0]
						Local $sKey = $aSec[$k][0]
						If StringRegExp($sKey, "(?i)^" & $sCore & "(\s+\d{4})?(\s*\(Beta\))?$") Then
							Local $bKeyIsBeta = StringInStr($sKey, "(Beta)") > 0
							If $bKeyIsBeta = $bIsBeta Then
								$sIniVer = $aSec[$k][1]
								ExitLoop
							EndIf
						EndIf
					Next
				EndIf
			EndIf
		EndIf

		If $sIniVer <> "" Then
			Local $sIniStripped = StringRegExpReplace($sIniVer, "^v", "")
			Local $aIniParts = StringSplit($sIniStripped, ".")
			If $aIniParts[0] >= 2 Then
				$aVer[0] = Number($aIniParts[1])
				$aVer[1] = Number($aIniParts[2])
				LogWrite(1, "WinTrust: AE version for '" & $sAppName & "' resolved via patch_states.ini fallback: v" & $aVer[0] & "." & $aVer[1])
			EndIf
		EndIf
	EndIf

	If $aVer[0] = 0 And $aVer[1] = 0 Then Return False
	If Not _IsAEBlockedByVersion($aVer[0], $aVer[1]) Then Return False

	Local $sNewLabel = $sAppName & "  (No WinTrust - v25.4+)"
	_GUICtrlTreeView_SetText($hTreeView, $hParent, $sNewLabel)
	If Not IsObj($g_mBlockedParents) Then $g_mBlockedParents = ObjCreate("Scripting.Dictionary")
	If Not IsObj($g_mBlockedAppPaths) Then $g_mBlockedAppPaths = ObjCreate("Scripting.Dictionary")
	$g_mBlockedParents.Item($sNewLabel) = True
	For $sPath In $aChildPaths
		$g_mBlockedAppPaths.Item(StringLower($sPath)) = True
	Next

	_GUICtrlTreeView_SetChecked($hTreeView, $hParent, False)
	$hChild = _GUICtrlTreeView_GetFirstChild($hTreeView, $hParent)
	While $hChild <> 0
		_GUICtrlTreeView_SetChecked($hTreeView, $hChild, False)
		$hChild = _GUICtrlTreeView_GetNextChild($hTreeView, $hChild)
	WEnd

	LogWrite(1, "WinTrust: blocked AE parent '" & $sAppName & "' (AfterFX.exe v" & $aVer[0] & "." & $aVer[1] & " - No WinTrust)")
	Return True
EndFunc

Func FindTrustEXEs()
	Local $foundApps = FindApps(True, $g_sWinTrustPath)
	Local $foundEXEs[0]

	For $app In $foundApps
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		If FileExists($dllPath) Then
			_ArrayAdd($foundEXEs, $app)
		EndIf
	Next

	Return $foundEXEs
EndFunc

Func FindUntrustedEXEs()
	Local $foundApps = FindApps(True, $g_sWinTrustPath)
	Local $foundEXEs[0]
	For $app In $foundApps
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		If Not FileExists($dllPath) Then
			_ArrayAdd($foundEXEs, $app)
		EndIf
	Next
	Return $foundEXEs
EndFunc

Func TrustEXEs()
	MemoWrite("Scanning for applications to trust...")
	Local $foundApps = FindUntrustedEXEs()

	If UBound($foundApps) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No untrusted applications found at: " & $g_sWinTrustPath & " - all eligible apps are already trusted.")
		LogWrite(1, "No untrusted applications found at: " & $g_sWinTrustPath)
		ToggleLog(1)
		Return
	EndIf

	Local $SelectedApps = TrustSelectionGUI($foundApps, "Trust")

	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("No applications selected to trust.")
		LogWrite(1, "No applications selected to trust.")
		Return
	EndIf

	If Not AddDevOverride() Then
		MemoWrite("WinTrust operation aborted due to registry error.")
		Return
	EndIf

	Local $dllSourcePath = @ScriptDir & "\wintrust.dll"
	If Not FileExists($dllSourcePath) Or FileGetSize($dllSourcePath) <> 382712 Then
		FileInstall("wintrust.dll", $dllSourcePath, 1)
		If Not FileExists($dllSourcePath) Then
			MemoWrite("Error: Failed to extract wintrust.dll to " & $dllSourcePath)
			LogWrite(1, "Error: Failed to extract wintrust.dll.")
			Return
		EndIf
	EndIf

	If FileGetSize($dllSourcePath) <> 382712 Then
		MemoWrite("Error: wintrust.dll size mismatch (expected 382,712 bytes).")
		LogWrite(1, "Error: wintrust.dll size mismatch (expected 382,712 bytes).")
		FileDelete($dllSourcePath)
		Return
	EndIf

	MemoWrite("Trusting " & UBound($SelectedApps) & " application(s)...")
	LogWrite(1, "Trusting " & UBound($SelectedApps) & " application(s):")

	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("Skipping invalid or missing file: " & $app)
			LogWrite(1, "Skipping invalid or missing file: " & $app)
			ContinueLoop
		EndIf
		If StringRegExp($app, "(?i)\\AfterFX( \(Beta\))?\.exe$") Then
			Local $aAEVer = _GetAfterFXVersion($app)
			If _IsAEBlockedByVersion($aAEVer[0], $aAEVer[1]) Then
				MemoWrite("Skipping " & $app & " - No WinTrust (After Effects v" & $aAEVer[0] & "." & $aAEVer[1] & "+ blocked from WinTrust).")
				LogWrite(1, "Skipping AE-blocked path: " & $app & " (v" & $aAEVer[0] & "." & $aAEVer[1] & ")")
				ContinueLoop
			EndIf
		EndIf

		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"

		LogWrite(1, "- Processing: " & $app)

		If Not DirCreate($localDir) Then
			MemoWrite("Failed to create directory: " & $localDir)
			LogWrite(1, "Failed to create directory: " & $localDir)
			ContinueLoop
		EndIf

		If FileExists($dllPath) Then
			If FileGetSize($dllPath) = 382712 Then
				MemoWrite("wintrust.dll already exists at: " & $dllPath & " - Skipping.")
				LogWrite(1, "wintrust.dll already exists at: " & $dllPath & " - Skipping.")
				$successCount += 1
				Local $sAppGrp = _GetAppGroupName($app)
				If $sAppGrp <> "" Then $g_mWinTrustQueue.Item($sAppGrp) = "1"
			Else
				FileDelete($dllPath)
				If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
					MemoWrite("Replaced wintrust.dll at: " & $dllPath)
					LogWrite(1, "Replaced wintrust.dll at: " & $dllPath)
					$successCount += 1
					Local $sAppGrp2 = _GetAppGroupName($app)
					If $sAppGrp2 <> "" Then $g_mWinTrustQueue.Item($sAppGrp2) = "1"
				Else
					MemoWrite("Failed to replace wintrust.dll to: " & $dllPath)
					LogWrite(1, "Failed to replace wintrust.dll to: " & $dllPath)
				EndIf
			EndIf
			ContinueLoop
		EndIf

		If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
			MemoWrite("Successfully trusted: " & $appName)
			LogWrite(1, "Successfully trusted: " & $appName)
			$successCount += 1
			Local $sAppGrp3 = _GetAppGroupName($app)
			If $sAppGrp3 <> "" Then $g_mWinTrustQueue.Item($sAppGrp3) = "1"
		Else
			MemoWrite("Failed to trust: " & $appName)
			LogWrite(1, "Failed to trust: " & $appName)
		EndIf
	Next

	If FileExists($dllSourcePath) Then
		If FileDelete($dllSourcePath) Then
			MemoWrite("Deleted wintrust.dll from " & $dllSourcePath & ".")
		Else
			MemoWrite("Warning: Failed to delete wintrust.dll from " & $dllSourcePath & ".")
		EndIf
	EndIf

	MemoWrite("Trust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " applications.")
	LogWrite(1, "Trust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " applications.")
	_WriteWinTrustImmediate()
	_SyncWinTrustFromDisk()
	_RefreshGroupHeadersFromWT()
	ToggleLog(1)
EndFunc

Func UntrustEXEs()
	MemoWrite("Scanning for trusted applications...")
	Local $foundEXEs = FindTrustEXEs()
	If UBound($foundEXEs) = 0 Then
		MemoWrite("No trusted applications found to untrust.")
		LogWrite(1, "No trusted applications found to untrust.")
		Return
	EndIf
	Local $SelectedApps = TrustSelectionGUI($foundEXEs, "Untrust")
	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("No applications selected to untrust.")
		LogWrite(1, "No applications selected to untrust.")
		Return
	EndIf
	MemoWrite("Untrusting " & UBound($SelectedApps) & " application(s)...")
	LogWrite(1, "Untrusting " & UBound($SelectedApps) & " application(s):")
	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("Skipping invalid or missing file: " & $app)
			LogWrite(1, "Skipping invalid or missing file: " & $app)
			ContinueLoop
		EndIf
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		LogWrite(1, "- Processing: " & $app)
		If Not FileExists($dllPath) Then
			MemoWrite("No wintrust.dll found at: " & $dllPath & " - Skipping.")
			LogWrite(1, "No wintrust.dll found at: " & $dllPath & " - Skipping.")
			ContinueLoop
		EndIf
		If DirRemove($localDir, 1) Then
			MemoWrite("Successfully untrusted: " & $appName)
			LogWrite(1, "Successfully untrusted: " & $appName)
			$successCount += 1
			Local $sAppGrpU = _GetAppGroupName($app)
			If $sAppGrpU <> "" Then $g_mWinTrustQueue.Item($sAppGrpU) = "0"
		Else
			MemoWrite("Failed to untrust: " & $appName)
			LogWrite(1, "Failed to untrust: " & $appName)
		EndIf
	Next
	MemoWrite("Untrust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " application(s).")
	LogWrite(1, "Untrust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " application(s).")
	_WriteWinTrustImmediate()
	_SyncWinTrustFromDisk()
	_RefreshGroupHeadersFromWT()
	ToggleLog(1)
EndFunc

Func TrustSelectionGUI($foundFiles, $operation)
	If Not FileExists($g_sWinTrustPath) Or Not StringInStr(FileGetAttrib($g_sWinTrustPath), "D") Then
		MemoWrite("Error: Invalid WinTrust Path: " & $g_sWinTrustPath)
		LogWrite(1, "Error: Invalid WinTrust Path: " & $g_sWinTrustPath)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("No applications found to " & StringLower($operation) & " at: " & $g_sWinTrustPath)
		LogWrite(1, "No applications found to " & StringLower($operation) & " at: " & $g_sWinTrustPath)
		ToggleLog(1)
		Return ""
	EndIf
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate($operation, 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)
	$g_mBlockedParents = ObjCreate("Scripting.Dictionary")
	$g_mBlockedAppPaths = ObjCreate("Scripting.Dictionary")
	Local $defPathClean = StringStripWS($g_sWinTrustPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]
	Local $iShownCount = 0
	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")
		Local $appDir = StringLeft($fileClean, StringInStr($fileClean, "\", 0, -1) - 1)
		Local $appNameOnly = StringMid($fileClean, StringInStr($fileClean, "\", 0, -1) + 1)
		Local $dllPath = $appDir & "\" & $appNameOnly & ".local\wintrust.dll"
		Local $isCurrentlyTrusted = FileExists($dllPath)
		If $operation = "Trust" And $isCurrentlyTrusted Then ContinueLoop
		If $operation = "Untrust" And Not $isCurrentlyTrusted Then ContinueLoop
		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "Warning: Short path used in config, using Unknown for: " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next
	Local $hScanItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hScanItem <> 0
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hScanItem) > 0 Then
			Local $sParentText = _GUICtrlTreeView_GetText($hTreeView, $hScanItem)
			_EvaluateAEBlock($hTreeView, $hScanItem, $sParentText)
		EndIf
		$hScanItem = _GUICtrlTreeView_GetNext($hTreeView, $hScanItem)
	WEnd
	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)
	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite(StringLeft($operation, 1) & StringLower(StringMid($operation, 2)) & " cancelled.")
				LogWrite(1, StringLeft($operation, 1) & StringLower(StringMid($operation, 2)) & " cancelled.")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				Local $sCurrentParent = ""
				While $hItem <> 0
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					Local $bIsParent = (_GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0)
					If $bIsParent Then $sCurrentParent = $itemText
					Local $bBlocked = False
					If IsObj($g_mBlockedParents) Then
						If $bIsParent And $g_mBlockedParents.Exists($itemText) Then $bBlocked = True
						If (Not $bIsParent) And $g_mBlockedParents.Exists($sCurrentParent) Then $bBlocked = True
					EndIf
					If $bBlocked Then
						_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
					Else
						_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					EndIf
					If $bIsParent Then
						If $bBlocked Then
							$prevStates($itemText) = False
						Else
							$prevStates($itemText) = $checkedState
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("Scanning for selected items...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						If StringInStr($itemText, ".exe") Then
							Local $bSkip = False
							If IsObj($g_mBlockedAppPaths) And $g_mBlockedAppPaths.Exists(StringLower($itemText)) Then
								$bSkip = True
								LogWrite(1, "WinTrust: skipping AE-blocked path: " & $itemText)
							EndIf
							If Not $bSkip Then _ArrayAdd($selectedFiles, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					MemoWrite("No files selected to " & StringLower($operation) & ".")
					LogWrite(1, "No files selected to " & StringLower($operation) & ".")
				EndIf
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func ManageDevOverride()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 380) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 200) / 2
	Local $hGUI = GUICreate("Manage WinTrust Override", 380, 200, $iPopupX, $iPopupY)
	Local $iIFEO    = RegRead($g_sWT_IFEO, "DevOverrideEnable")
	Local $iIFEOErr = @error
	Local $iSxS     = RegRead($g_sWT_SxS, "DevOverrideEnable")
	Local $iSxSErr  = @error
	Local $iWT64    = RegRead($g_sWT_WT64, "EnableCertPaddingCheck")
	Local $iWT64Err = @error
	Local $iWT32    = RegRead($g_sWT_WT32, "EnableCertPaddingCheck")
	Local $iWT32Err = @error
	Local $sIFEO, $sSxS, $sWT64, $sWT32
	If $iIFEOErr = 0 And $iIFEO = 1 Then
		$sIFEO = "[ON]"
	Else
		$sIFEO = "[off]"
	EndIf
	If $iSxSErr = 0 And $iSxS = 1 Then
		$sSxS = "[ON]"
	Else
		$sSxS = "[off]"
	EndIf
	If $iWT64Err = 0 And $iWT64 = 0 Then
		$sWT64 = "[ON]"
	Else
		$sWT64 = "[off]"
	EndIf
	If $iWT32Err = 0 And $iWT32 = 0 Then
		$sWT32 = "[ON]"
	Else
		$sWT32 = "[off]"
	EndIf
	Local $sOverallState
	If ($iIFEOErr = 0 And $iIFEO = 1) And ($iSxSErr = 0 And $iSxS = 1) _
			And ($iWT64Err = 0 And $iWT64 = 0) And ($iWT32Err = 0 And $iWT32 = 0) Then
		$sOverallState = "All four keys set - override fully active."
	ElseIf $iIFEOErr <> 0 And $iSxSErr <> 0 And $iWT64Err <> 0 And $iWT32Err <> 0 Then
		$sOverallState = "No keys set - override is disabled."
	Else
		$sOverallState = "Partial state - some keys set, others not."
	EndIf
	GUICtrlCreateLabel($sOverallState, 10, 10, 360, 20, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 700)
	GUICtrlCreateLabel($sIFEO & "  IFEO\DevOverrideEnable", 20, 38, 340, 16)
	GUICtrlCreateLabel($sSxS  & "  SideBySide\DevOverrideEnable", 20, 56, 340, 16)
	GUICtrlCreateLabel($sWT64 & "  Wintrust\Config\EnableCertPaddingCheck (64-bit)", 20, 74, 340, 16)
	GUICtrlCreateLabel($sWT32 & "  Wow6432Node\...\EnableCertPaddingCheck (32-bit)", 20, 92, 340, 16)
	Local $hAddButton    = GUICtrlCreateButton("Enable All",  30,  125, 100, 30)
	Local $hRemoveButton = GUICtrlCreateButton("Restore All", 140, 125, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("Cancel",      250, 125, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("DevOverride registry management cancelled.")
				GUIDelete($hGUI)
				Return
			Case $hAddButton
				GUIDelete($hGUI)
				AddDevOverride()
				Return
			Case $hRemoveButton
				GUIDelete($hGUI)
				RemoveDevOverride()
				Return
		EndSwitch
	WEnd
EndFunc

Func OpenWF()
	Local $sWFPath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $sWFPath)
	ConsoleWrite("Opening Windows Firewall...")
EndFunc
