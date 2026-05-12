#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=GenP-v4.0.2.exe
#AutoIt3Wrapper_Res_Comment=GenP
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_Description=GenP
#AutoIt3Wrapper_Res_Fileversion=4.0.2
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2026
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2026
#AutoIt3Wrapper_Res_ProductName=GenP
#AutoIt3Wrapper_Res_ProductVersion=4.0.2
#AutoIt3Wrapper_Res_Field=ID|GenP-%date%-%time%
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Run_Tidy=n
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Array.au3>
#include <ButtonConstants.au3>
#include <Crypt.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
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
#include <WinAPITheme.au3>

AutoItSetOption("GUICloseOnESC", 0)

Global $g_Version = "4.0.2"
Global $g_AppWndTitle = "GenP v" & $g_Version
Global $g_AppVersion = "GenP" & @CRLF & "Originally created by uncia"

Global $patchStatesINI = @ScriptDir & "\patch_states.ini"
Global $g_aStateQueue[0][5]
Global $g_bCryptActive = False
Global $g_mAppVersionQueue  = ObjCreate("Scripting.Dictionary")
Global $g_mWinTrustQueue    = ObjCreate("Scripting.Dictionary")
Global $g_mAppPrimaryExe    = ObjCreate("Scripting.Dictionary")
Global $idSubProgress = -1
Global $idShowBetaApps = -1
Global $idEnableGood1 = -1
Global $idLabelRuntimeAuto = -1

Global $g_aAllFiles[0][5]
Global $g_mCheckedState = ObjCreate("Scripting.Dictionary")
Global $g_bSearchCompleted = False
Global $g_sRequiresGood1Files = "|"

Global Const $g_iLogTabIndex = 6

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
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF, $idBtnCreateFW, $idBtnRemoveFW, $idBtnToggleFW
Global $sRuntimeInstallerText, $idLabelRuntimeInstaller, $idBtnToggleRuntimeInstaller, $sWinTrustText, $idLabelWinTrust, $idBtnToggleWinTrust, $idBtnDevOverride
Global $idBtnAGSInfo, $idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkPopup, $g_idHyperlinkLog
Global $g_idHyperlinkFW = 0, $g_idHyperlinkHosts = 0, $g_idHyperlinkWT = 0, $g_idHyperlinkAGS = 0

Global $idBtnCollapseAll = 0, $idBtnExpandAll = 0
Global $idBtnCheckAll = 0, $idBtnUncheckAll = 0
Global $idBtnCheckUnpatched = 0, $idBtnCheckPatched = 0, $idBtnRefresh = 0

Global $idResetOnSave = 0
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

Global $g_AppCount = 0
Global $g_FilesToPatchCount = 0
Global $g_dotCounter = 0
Global $g_mScannedApps = 0
Global $g_mBlockedParents = 0
Global $g_mBlockedAppPaths = 0
Global $g_sLastScanDir = ""
Global $g_bStatusScreenReady = False

Global $idBtnDummyAGS = 0
Global $idBtnSetTrustPath = 0
Global $idLabelTrustPath = 0
Global $g_sWinTrustPath

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf
Global $ConfigVerVar = IniRead($sINIPath, "Info", "ConfigVer", "????")

$g_sWinTrustPath = IniRead($sINIPath, "Options", "WinTrustPath", @ProgramFilesDir & "\Adobe")

Global $bUseCustomDefault = Number(IniRead($sINIPath, "Options", "UseCustomDefault", "0"))
Global $g_sCustomDefaultPath = StringRegExpReplace(IniRead($sINIPath, "Custom_Default", "Path", ""), "\\\\+", "\\")
Global $g_sPendingCustomPath = $g_sCustomDefaultPath

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
Global $g_sEdition = IniRead($sINIPath, "Options", "Edition", "GenP")

Global $g_sThirdPartyFirewall = ""
Global $fwc = ""
Global $SelectedApps = []

Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)

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
	If $sPatternList = "good1" Then
		$g_sRequiresGood1Files = $g_sRequiresGood1Files & StringLower($aSpecialFiles[$i][0]) & "|"
	EndIf
Next
Global $g_aSignature = "r~~z}D99""sus8nl%o|:8myw9qoxz7q sno}9"

If $CmdLine[0] = 1 And $CmdLine[1] = "-updatehosts" Then
	UpdateHostsFile()
	Exit
EndIf

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

MainGui()

Local $bHostsbakExists = False
If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
	$bHostsbakExists = True
EndIf

While 1
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

	If $g_bAutoPatchPending Then
		$g_bAutoPatchPending = False
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
			ReDim $g_aAllFiles[0][5]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()
			_ResetScanCounters()
			FillListViewWithInfo()
			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnModified, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnCheckAll, 128)
			GUICtrlSetState($idBtnUncheckAll, 128)
			GUICtrlSetState($idBtnCheckUnpatched, 128)
			GUICtrlSetState($idBtnCheckPatched, 128)
			GUICtrlSetState($idBtnRefresh, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			_ResetScanCounters()
			_ShowStatusScreen("scanning", $MyDefPath)

			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull
			ReDim $g_aAllFiles[0][5]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $aACCDirs[2]
				$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
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
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)

				If UBound($FilesToRestore) > 0 Then
					GUICtrlSetState($idBtnUpdateHosts, 128)
					GUICtrlSetState($idBtnCleanHosts, 128)
					GUICtrlSetState($idBtnEditHosts, 128)
					GUICtrlSetState($idBtnCreateFW, 128)
					GUICtrlSetState($idBtnToggleFW, 128)
					GUICtrlSetState($idBtnRemoveFW, 128)
					GUICtrlSetState($idBtnOpenWF, 128)
					GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
					GUICtrlSetState($idBtnToggleWinTrust, 128)
					GUICtrlSetState($idBtnDevOverride, 128)
					GUICtrlSetState($idBtnRemoveAGS, 128)
					GUICtrlSetState($idBtnRestoreHosts, 128)
					GUICtrlSetState($idBtnRestore, 64)
					GUICtrlSetState($idBtnAGSInfo, 128)
					GUICtrlSetState($idBtnFirewallInfo, 128)
					GUICtrlSetState($idBtnHostsInfo, 128)
					GUICtrlSetState($idBtnRuntimeInfo, 128)
					GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
				EndIf
			Else
				$ListViewSelectFlag = 0
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)
			EndIf

			_Expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
			$g_bIsPatching = False

		Case $idMsg = $idButtonCustomFolder
			ToggleLog(0)
			MyFileOpenDialog()
			_Expand_All_Click()
			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)
			Else
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 64)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)
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
			If ($bPSE2026 Or $bPRE2026 Or $bORG2026) And Not ($bPSE2026 And $bPRE2026 And $bORG2026) Then
				Local $bHasPSE = False, $bHasPRE = False, $bHasORG = False
				For $i = 0 To $iCountAll - 1
					Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
					Local $sGrp = _GetAppGroupName($sPath)
					If $sGrp = "Photoshop Elements 2026" Then $bHasPSE = True
					If $sGrp = "Premiere Elements 2026"  Then $bHasPRE = True
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
						   ($sGrp = "Premiere Elements 2026"  And $bHasPRE) Or _
						   ($sGrp = "Elements 2026 Organizer" And $bHasORG) Then
							_GUICtrlListView_SetItemChecked($idListview, $i, 1)
						EndIf
					Next
					MemoWrite(@CRLF & "Auto-checked missing Elements 2026 items for consistent patch.")
				EndIf
			EndIf

			ToggleLog(0)
			$g_bIsPatching = True
			GUICtrlSetState($idFindACC, $GUI_DISABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_DISABLE)
			GUICtrlSetState($idEnableGood1, $GUI_DISABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_DISABLE)
			GUICtrlSetState($idResetOnSave, $GUI_DISABLE)
			GUICtrlSetState($idReconcileStates, $GUI_DISABLE)
			GUICtrlSetState($idCreateStates, $GUI_DISABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_DISABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_DISABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnUncheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckUnpatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckPatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnRefresh, $GUI_DISABLE)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
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

					MyGlobalPatternSearch($ItemFromList)
					If Not $g_bUxpHandledFile Then
						MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "medication :)")
						LogWrite(1, $ItemFromList)
					EndIf

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)

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

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False
			GUICtrlSetState($idFindACC, $GUI_ENABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_ENABLE)
			GUICtrlSetState($idEnableGood1, $GUI_ENABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_ENABLE)
			GUICtrlSetState($idResetOnSave, $GUI_ENABLE)
			GUICtrlSetState($idReconcileStates, $GUI_ENABLE)
			GUICtrlSetState($idCreateStates, $GUI_ENABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_ENABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_ENABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_ENABLE)
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
					_ShowEmptyModifiedNotice()
					$g_bIsPatching = False
					$g_bPendingInfoReset = False
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					ContinueLoop
				Else
					MemoWrite(@CRLF & "Unpatched: " & $iStillTodo & " file(s) still need patching (click Patch again).")
					LogWrite(1, "Unpatched: " & $iStillTodo & " file(s) remain after patch run.")
					$g_bIsPatching = False
					$g_bPendingInfoReset = True
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					ContinueLoop
				EndIf
			EndIf

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
				LogWrite(1, "GenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
			EndIf
			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "This GenP build does not support ARM binaries, only x64.")
				LogWrite(1, "This GenP build does not support ARM binaries, only x64.")
			EndIf

			ToggleLog(1)
			GUICtrlSetState($hLogTab, $GUI_SHOW)
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)

		Case $idMsg = $idBtnModified
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnModified, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnCheckAll, 128)
			GUICtrlSetState($idBtnUncheckAll, 128)
			GUICtrlSetState($idBtnCheckUnpatched, 128)
			GUICtrlSetState($idBtnCheckPatched, 128)
			GUICtrlSetState($idBtnRefresh, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)

			MemoWrite(@CRLF & "Modified workflow: scanning + verifying...")
			_RefreshSearch()

			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)

			Local $iKept = _ApplyModifiedFilter()

			If $iKept = 0 Then
				$g_bIsPatching = False
				_ShowEmptyModifiedNotice()
			Else
				UpdateUIState()
			EndIf

		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & "" & @CRLF & "Config Version: " & $ConfigVerVar & "" & @CRLF)
			ToggleLog(0)
			$g_bIsPatching = True
			GUICtrlSetState($idFindACC, $GUI_DISABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_DISABLE)
			GUICtrlSetState($idEnableGood1, $GUI_DISABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_DISABLE)
			GUICtrlSetState($idResetOnSave, $GUI_DISABLE)
			GUICtrlSetState($idReconcileStates, $GUI_DISABLE)
			GUICtrlSetState($idCreateStates, $GUI_DISABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_DISABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_DISABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnUncheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckUnpatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckPatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnRefresh, $GUI_DISABLE)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			_Expand_All_Click()

			Local $ItemFromList
			Local $iTotalChecked = 0, $iDone = 0
			Local $aRestoredPaths[0]
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

					If $bOk Then
						_GUICtrlListView_SetItemText($idListview, $i, "Unpatched", 2)
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

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False
			GUICtrlSetState($idFindACC, $GUI_ENABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_ENABLE)
			GUICtrlSetState($idEnableGood1, $GUI_ENABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_ENABLE)
			GUICtrlSetState($idResetOnSave, $GUI_ENABLE)
			GUICtrlSetState($idReconcileStates, $GUI_ENABLE)
			GUICtrlSetState($idCreateStates, $GUI_ENABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_ENABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_ENABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_ENABLE)
			CheckOptionsChanged()

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
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

		Case $idMsg = $idReconcileStates
			If _IsChecked($idReconcileStates) Then GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idCreateStates
			If _IsChecked($idCreateStates) Then GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idUseCustomDefault
			If _IsChecked($idUseCustomDefault) Then
				Local $sSeedPick = GUICtrlRead($idBtnSetCustomPath)
				If $sSeedPick = "" Or Not FileExists($sSeedPick) Then $sSeedPick = $MyDefPath
				Local $sPickedPath = FileSelectFolder("Select the folder to open to on launch", "", 7, $sSeedPick, $MyhGUI)
				If Not @error And $sPickedPath <> "" Then
					GUICtrlSetData($idBtnSetCustomPath, StringRegExpReplace($sPickedPath, "\\\\+", "\\"))
				EndIf
			EndIf
			CheckOptionsChanged()

		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

		Case $idMsg = $idBtnDummyAGS
			InstallAGSDummy()

		Case $idMsg = $idBtnSetTrustPath
			Local $sSelected = FileSelectFolder("Select the Adobe installation folder for WinTrust", "", 7, $g_sWinTrustPath, $MyhGUI)
			If @error Then
				ContinueLoop
			EndIf
			If $sSelected = "" Then ContinueLoop
			$g_sWinTrustPath = $sSelected
			GUICtrlSetData($idLabelTrustPath, "Path: " & $g_sWinTrustPath)
			IniWrite($sINIPath, "Options", "WinTrustPath", $g_sWinTrustPath)
			MemoWrite(@CRLF & "WinTrust path set to: " & $g_sWinTrustPath)
			LogWrite(1, "WinTrust path changed to: " & $g_sWinTrustPath)

		Case $idMsg = $idBtnUpdateHosts
			ToggleLog(0)
			UpdateHostsFile()

		Case $idMsg = $idBtnCleanHosts
			RemoveHostsEntries()

		Case $idMsg = $idBtnEditHosts
			EditHosts()

		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		Case $idMsg = $idBtnCreateFW
			ToggleLog(0)
			CreateFirewallRules()

		Case $idMsg = $idBtnToggleFW
			ToggleLog(0)
			ShowToggleRulesGUI()

		Case $idMsg = $idBtnRemoveFW
			ToggleLog(0)
			RemoveFirewallRules()

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
			ShowInfoPopup("Removes Genuine Services and related files to remove the 'Genuine Service Alert' popup." & @CRLF & @CRLF & "Removal will ONLY stop popups which say 'Genuine Service Alert' in the popup title bar.")

		Case $idMsg = $idBtnFirewallInfo
			ShowInfoPopup("Manages Windows Firewall rules to block apps from accessing the internet -- stopping popups. Easily add outbound rules for any installed app, toggle all rules off/on, or delete all rules." & @CRLF & @CRLF & "Some app features may not work when cut from internet.")

		Case $idMsg = $idBtnHostsInfo
			ShowInfoPopup("Manages hosts file -- specifically targeting domains used for popups. Auto update hosts using the provided list URL (Options), manually edit in Notepad, remove all entries, or restore a backup." & @CRLF & @CRLF & "Hosts must be updated regularly to remain effective.")

		Case $idMsg = $idBtnWintrustInfo
			ShowInfoPopup("Avoid popups by ' trusting' each app. Uses a modified DLL + registry edit for allowing DLL redirection. Trust/Untrust each app or add/remove the reg key as needed. Reg key is auto-added when trusting apps." & @CRLF & @CRLF & "Shout out Team V.R !")
	EndSelect
WEnd

Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 580, -1, -1, BitOR($WS_MINIMIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 580, $TCS_FIXEDWIDTH)
	_SendMessage(GUICtrlGetHandle($hTab), 0x1329, 0, 84)

	$hMainTab = GUICtrlCreateTabItem("Main")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 355)
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

	$idBtnUncheckAll = GUICtrlCreateButton("Uncheck All", 28, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckAll = GUICtrlCreateButton("Check All", 140, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckUnpatched = GUICtrlCreateButton("Unpatched", 251, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckPatched = GUICtrlCreateButton("Patched", 363, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRefresh = GUICtrlCreateButton("Refresh", 475, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCollapseAll = GUICtrlCreateDummy()
	$idBtnExpandAll   = GUICtrlCreateDummy()

	GUICtrlCreateLabel("", 9, 438, 577, 27, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateLabel("", 9, 462, 577, 7, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 439, 575, 25, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idProgressBar), "", "")
	GUICtrlSetColor($idProgressBar, 0x00FF00)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idSubProgress = GUICtrlCreateProgress(10, 463, 575, 5, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idSubProgress), "", "")
	GUICtrlSetColor($idSubProgress, 0x00A2E8)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idButtonCustomFolder = GUICtrlCreateButton(" Path", 28, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton(" Search", 140, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton(" Stop", 140, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton(" Patch", 251, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnModified = GUICtrlCreateButton(" Modified", 363, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -25, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton(" Restore", 475, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateDummy()

	$g_idHyperlinkMain = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("Options")

	GUICtrlCreateGroup("Scan Options", 5, 35, 585, 130)

	$idFindACC = GUICtrlCreateCheckbox("Always search for ACC", 15, 60, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then GUICtrlSetState($idFindACC, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateDummy()

	$idOnlyAFolders = GUICtrlCreateCheckbox("Search in default named folders only", 15, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idUseCustomDefault = GUICtrlCreateCheckbox("Use custom default search path:", 15, 120, 200, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bUseCustomDefault = 1 Then GUICtrlSetState($idUseCustomDefault, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	Local $sInitialCustom = ($g_sPendingCustomPath <> "") ? $g_sPendingCustomPath : (@ProgramFilesDir & "\Adobe")
	$idBtnSetCustomPath = GUICtrlCreateLabel($sInitialCustom, 235, 125, 345, 20, $SS_LEFT)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnSetCustomPath, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Patch Options", 5, 175, 585, 130)

	$idShowBetaApps = GUICtrlCreateCheckbox("Show Beta apps", 15, 200, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bShowBetaApps = 1 Then GUICtrlSetState($idShowBetaApps, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableGood1 = GUICtrlCreateCheckbox("Enable Good patch", 15, 230, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableGood1 = 1 Then GUICtrlSetState($idEnableGood1, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idResetOnSave = GUICtrlCreateCheckbox("Reset patch_states.ini", 15, 260, 300, 25)
	GUICtrlSetState($idResetOnSave, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Hosts Options", 5, 315, 585, 55)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts List URL:", 15, 340, 80, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 95, 337, 485, 22, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)
	GUICtrlSetResizing($idCustomDomainListInput, $GUI_DOCKWIDTH)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("First Run Options", 5, 380, 585, 80)

	$idCreateStates = GUICtrlCreateCheckbox("Create new patch_states.ini (using location set by Path only)", 15, 401, 420, 22, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idReconcileStates = GUICtrlCreateCheckbox("Reconcile imported patch_states.ini (using location set by Path only)", 15, 428, 420, 22, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$idOptionsReminder = GUICtrlCreateLabel("Changes will not take effect until saved", 10, 470, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idOptionsReminder, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idOptionsReminder, 0xC62828)
	GUICtrlSetState($idOptionsReminder, $GUI_HIDE)

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 500, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
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

	$idBtnSetTrustPath = GUICtrlCreateButton("Set Trust Path", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnSetTrustPath, 9, 400, 0, "Segoe UI")

	$idLabelTrustPath = GUICtrlCreateLabel("Path: " & $g_sWinTrustPath, 10, 225, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelTrustPath, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idLabelTrustPath, 0x555555)

	GUICtrlCreateLabel( _
			"Reduce popups by trusting applications that use DLL redirection." & @CRLF & @CRLF & _
			"This feature manages the required registry entry automatically." & @CRLF & @CRLF & _
			"You can trust or untrust applications at any time as needed." & @CRLF & @CRLF & _
			"Credit to Team V.R.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnWintrustInfo           = GUICtrlCreateDummy()
	$idBtnRuntimeInfo            = GUICtrlCreateDummy()
	$idLabelRuntimeInstaller     = GUICtrlCreateDummy()
	$idBtnToggleRuntimeInstaller = GUICtrlCreateDummy()

	$g_idHyperlinkWT = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
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

	$idBtnRestoreHosts = GUICtrlCreateButton("Restore hosts", 227, 225, 140, 32)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetFont($idBtnRestoreHosts, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"Manage the hosts file to block domains associated with popups." & @CRLF & @CRLF & _
			"Update the hosts file automatically from a list URL, edit it manually, or restore a backup." & @CRLF & @CRLF & _
			"Keeping the hosts file updated helps maintain protection over time.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnHostsInfo = GUICtrlCreateDummy()

	$g_idHyperlinkHosts = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkHosts, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkHosts, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkHosts, 0)

	GUICtrlCreateTabItem("")

	Local $hFirewallTab = GUICtrlCreateTabItem("Firewall")

	$sCleanFirewallText = "FIREWALL"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)

	$idBtnCreateFW = GUICtrlCreateButton("Add Rules", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnCreateFW, 9, 400, 0, "Segoe UI")

	$idBtnToggleFW = GUICtrlCreateButton("Toggle Rules", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnToggleFW, 9, 400, 0, "Segoe UI")

	$idBtnRemoveFW = GUICtrlCreateButton("Remove Rules", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnRemoveFW, 9, 400, 0, "Segoe UI")

	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", 227, 225, 140, 32)
	GUICtrlSetFont($idBtnOpenWF, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"Manage Firewall rules to block applications from internet access, which may reduce popups." & @CRLF & @CRLF & _
			"Add or remove outbound rules, enable or disable them, or delete all rules." & @CRLF & @CRLF & _
			"Note: Some application features may not function when internet access is blocked.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnFirewallInfo = GUICtrlCreateDummy()

	$g_idHyperlinkFW = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
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

	GUICtrlCreateLabel( _
			"Stops 'Adobe Genuine Service Alert' popups by removing the AGS components." & @CRLF & @CRLF & _
			"Or redirecting the services using dummy files to prevent background activity." & @CRLF & @CRLF & _
			"Note: This applies only to popups with the 'Genuine Service Alert' header.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnAGSInfo = GUICtrlCreateDummy()

	$g_idHyperlinkAGS = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkAGS, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkAGS, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkAGS, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkAGS, 0)
	$g_idHyperlinkPopup = $g_idHyperlinkAGS

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("Log")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 442, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idMemo, 0x7FFFFFFF)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 442, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idLog, 0x7FFFFFFF)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & @CRLF & "Config Version: " & $ConfigVerVar & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("Copy", 247, 490, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkLog = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")

	GUICtrlSetState($idButtonSearch, 256)
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

	_SnapshotOptions()
EndFunc

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	Local $RecursiveFileSearch_MaxDeep = 8
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

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
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($FileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
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
	For $k = 0 To UBound($g_aAllFiles) - 1
		If $g_aAllFiles[$k][0] = $sPath Then Return
	Next

	Local $sFileName = StringRegExpReplace($sPath, "^.*\\", "")
	Local $sFileNameLC = StringLower($sFileName)
	Local $sPathLC = StringLower($sPath)

	Local $bIsACC = StringInStr($sPathLC, "\common files\adobe\") > 0

	Local $bIsBeta = (StringInStr($sPath, "(Beta)") > 0) Or (StringInStr($sPath, " Beta\") > 0) Or (StringInStr($sPathLC, "\adobe animate beta") > 0)

	Local $bReqGood1 = (StringInStr($g_sRequiresGood1Files, "|" & $sFileNameLC & "|") > 0)

	Local $iIdx = UBound($g_aAllFiles)
	ReDim $g_aAllFiles[$iIdx + 1][5]
	$g_aAllFiles[$iIdx][0] = $sPath
	$g_aAllFiles[$iIdx][1] = $sFileName
	$g_aAllFiles[$iIdx][2] = $bIsACC
	$g_aAllFiles[$iIdx][3] = $bIsBeta
	$g_aAllFiles[$iIdx][4] = $bReqGood1

	_ArrayAdd($FilesToPatch, $sPath)

	_BumpScanCounters($sPath)
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

	Local $sTitle = "GenP v4.0.2", $sOptionsLine = ""
	If Number($bEnableGood1) Then $sOptionsLine &= "Good1 patch enabled"
	If Number($bShowBetaApps) Then
		$sOptionsLine &= ($sOptionsLine <> "" ? " / " : "") & "Beta apps included"
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
		LogWrite(1, UBound($g_aAllFiles) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @CRLF)
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
		Local $bIsACC = $g_aAllFiles[$i][2]
		Local $bIsBeta = $g_aAllFiles[$i][3]
		Local $bReqGood1 = $g_aAllFiles[$i][4]

		If $bIsACC And $bFindACC = 0 Then ContinueLoop
		If $bIsBeta And $bShowBetaApps = 0 Then ContinueLoop
		If $bReqGood1 And $bEnableGood1 = 0 Then ContinueLoop

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

Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc

Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
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
	$g_mOptionsSnapshot.Item("FindACC")            = _IsChecked($idFindACC)
	$g_mOptionsSnapshot.Item("EnableMD5")          = 1
	$g_mOptionsSnapshot.Item("OnlyDefaultFolders") = _IsChecked($idOnlyAFolders)
	$g_mOptionsSnapshot.Item("EnableGood1")        = _IsChecked($idEnableGood1)
	$g_mOptionsSnapshot.Item("ShowBetaApps")       = _IsChecked($idShowBetaApps)
	$g_mOptionsSnapshot.Item("ResetOnSave")        = _IsChecked($idResetOnSave)
	$g_mOptionsSnapshot.Item("ReconcileStates")    = _IsChecked($idReconcileStates)
	$g_mOptionsSnapshot.Item("CreateStates")       = _IsChecked($idCreateStates)
	$g_mOptionsSnapshot.Item("UseCustomDefault")   = _IsChecked($idUseCustomDefault)
	$g_mOptionsSnapshot.Item("PendingCustomPath")  = GUICtrlRead($idBtnSetCustomPath)
	$g_mOptionsSnapshot.Item("HostsURL")           = StringStripWS(GUICtrlRead($idCustomDomainListInput), 3)
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
	ReDim $g_aAllFiles[0][5]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func CheckOptionsChanged()
	If Not IsObj($g_mOptionsSnapshot) Then Return
	Local $bChanged = False
	If _IsChecked($idFindACC)       <> $g_mOptionsSnapshot.Item("FindACC")            Then $bChanged = True
	If _IsChecked($idOnlyAFolders)  <> $g_mOptionsSnapshot.Item("OnlyDefaultFolders") Then $bChanged = True
	If _IsChecked($idEnableGood1)   <> $g_mOptionsSnapshot.Item("EnableGood1")        Then $bChanged = True
	If _IsChecked($idShowBetaApps)  <> $g_mOptionsSnapshot.Item("ShowBetaApps")       Then $bChanged = True
	If _IsChecked($idResetOnSave)   <> $g_mOptionsSnapshot.Item("ResetOnSave")        Then $bChanged = True
	If _IsChecked($idReconcileStates) <> $g_mOptionsSnapshot.Item("ReconcileStates") Then $bChanged = True
	If _IsChecked($idCreateStates)    <> $g_mOptionsSnapshot.Item("CreateStates")    Then $bChanged = True
	If _IsChecked($idUseCustomDefault) <> $g_mOptionsSnapshot.Item("UseCustomDefault") Then $bChanged = True
	If GUICtrlRead($idBtnSetCustomPath) <> $g_mOptionsSnapshot.Item("PendingCustomPath") Then $bChanged = True
	If StringStripWS(GUICtrlRead($idCustomDomainListInput), 3) <> $g_mOptionsSnapshot.Item("HostsURL") Then $bChanged = True

	$g_bOptionsDirty = $bChanged
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $bChanged ? $GUI_ENABLE : $GUI_DISABLE)
	If $idOptionsReminder > 0 Then GUICtrlSetState($idOptionsReminder, $bChanged ? $GUI_SHOW : $GUI_HIDE)
EndFunc

Func _RestorePostOpUI()
	GUICtrlSetState($idListview, 64)
	GUICtrlSetState($idButtonSearch, 64)
	GUICtrlSetState($idButtonCustomFolder, 64)
	GUICtrlSetState($idBtnUpdateHosts, 64)
	GUICtrlSetState($idBtnCleanHosts, 64)
	GUICtrlSetState($idBtnEditHosts, 64)
	GUICtrlSetState($idBtnCreateFW, 64)
	GUICtrlSetState($idBtnToggleFW, 64)
	GUICtrlSetState($idBtnRemoveFW, 64)
	GUICtrlSetState($idBtnOpenWF, 64)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
	GUICtrlSetState($idBtnToggleWinTrust, 64)
	GUICtrlSetState($idBtnDevOverride, 64)
	GUICtrlSetState($idBtnRemoveAGS, 64)
	GUICtrlSetState($idBtnRestoreHosts, 64)
	GUICtrlSetState($idBtnAGSInfo, 64)
	GUICtrlSetState($idBtnFirewallInfo, 64)
	GUICtrlSetState($idBtnHostsInfo, 64)
	GUICtrlSetState($idBtnRuntimeInfo, 64)
	GUICtrlSetState($idBtnWintrustInfo, 64)
	GUICtrlSetState($idBtnDummyAGS, 64)
	GUICtrlSetState($idBtnSetTrustPath, 64)
	GUICtrlSetState($idFindACC, 64)
	GUICtrlSetState($idOnlyAFolders, 64)
	GUICtrlSetState($idShowBetaApps, 64)
	GUICtrlSetState($idEnableGood1, 64)
	GUICtrlSetState($idResetOnSave, 64)
	GUICtrlSetState($idReconcileStates, 64)
	GUICtrlSetState($idCreateStates, 64)
	GUICtrlSetState($idUseCustomDefault, 64)
	GUICtrlSetState($idBtnSetCustomPath, 64)
	GUICtrlSetState($idCustomDomainListInput, 64)
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
	$g_bIsPatching = True
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, 128)
	GUICtrlSetState($idFindACC, 128)
	GUICtrlSetState($idOnlyAFolders, 128)
	GUICtrlSetState($idShowBetaApps, 128)
	GUICtrlSetState($idEnableGood1, 128)
	GUICtrlSetState($idResetOnSave, 128)
	GUICtrlSetState($idReconcileStates, 128)
	GUICtrlSetState($idCreateStates, 128)
	GUICtrlSetState($idUseCustomDefault, 128)
	GUICtrlSetState($idBtnSetCustomPath, 128)
	GUICtrlSetState($idCustomDomainListInput, 128)
	GUICtrlSetState($idButtonCustomFolder, 128)
	GUICtrlSetState($idButtonSearch, 128)
	GUICtrlSetState($idBtnCure, 128)
	GUICtrlSetState($idBtnRestore, 128)
	GUICtrlSetState($idBtnModified, 128)
	GUICtrlSetState($idBtnCheckAll, 128)
	GUICtrlSetState($idBtnUncheckAll, 128)
	GUICtrlSetState($idBtnCheckUnpatched, 128)
	GUICtrlSetState($idBtnCheckPatched, 128)
	GUICtrlSetState($idBtnRefresh, 128)
	GUICtrlSetState($idBtnUpdateHosts, 128)
	GUICtrlSetState($idBtnCleanHosts, 128)
	GUICtrlSetState($idBtnEditHosts, 128)
	GUICtrlSetState($idBtnRestoreHosts, 128)
	GUICtrlSetState($idBtnCreateFW, 128)
	GUICtrlSetState($idBtnToggleFW, 128)
	GUICtrlSetState($idBtnRemoveFW, 128)
	GUICtrlSetState($idBtnOpenWF, 128)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
	GUICtrlSetState($idBtnToggleWinTrust, 128)
	GUICtrlSetState($idBtnDevOverride, 128)
	GUICtrlSetState($idBtnSetTrustPath, 128)
	GUICtrlSetState($idBtnRemoveAGS, 128)
	GUICtrlSetState($idBtnDummyAGS, 128)
	GUICtrlSetState($idBtnAGSInfo, 128)
	GUICtrlSetState($idBtnFirewallInfo, 128)
	GUICtrlSetState($idBtnHostsInfo, 128)
	GUICtrlSetState($idBtnRuntimeInfo, 128)
	GUICtrlSetState($idBtnWintrustInfo, 128)
EndFunc

Func _UnlockOptionsUIAfterScan()
	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "Changes will not take effect until saved")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	$g_bIsPatching = False
	GUICtrlSetState($idFindACC, 64)
	GUICtrlSetState($idOnlyAFolders, 64)
	GUICtrlSetState($idShowBetaApps, 64)
	GUICtrlSetState($idEnableGood1, 64)
	GUICtrlSetState($idResetOnSave, 64)
	GUICtrlSetState($idReconcileStates, 64)
	GUICtrlSetState($idCreateStates, 64)
	GUICtrlSetState($idUseCustomDefault, 64)
	GUICtrlSetState($idBtnSetCustomPath, 64)
	GUICtrlSetState($idCustomDomainListInput, 64)
	GUICtrlSetState($idButtonCustomFolder, 64)
	GUICtrlSetState($idButtonSearch, 64)
	GUICtrlSetState($idBtnModified, 64)
	GUICtrlSetState($idBtnUpdateHosts, 64)
	GUICtrlSetState($idBtnCleanHosts, 64)
	GUICtrlSetState($idBtnEditHosts, 64)
	GUICtrlSetState($idBtnRestoreHosts, 64)
	GUICtrlSetState($idBtnCreateFW, 64)
	GUICtrlSetState($idBtnToggleFW, 64)
	GUICtrlSetState($idBtnRemoveFW, 64)
	GUICtrlSetState($idBtnOpenWF, 64)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
	GUICtrlSetState($idBtnToggleWinTrust, 64)
	GUICtrlSetState($idBtnDevOverride, 64)
	GUICtrlSetState($idBtnSetTrustPath, 64)
	GUICtrlSetState($idBtnRemoveAGS, 64)
	GUICtrlSetState($idBtnDummyAGS, 64)
	GUICtrlSetState($idBtnAGSInfo, 64)
	GUICtrlSetState($idBtnFirewallInfo, 64)
	GUICtrlSetState($idBtnHostsInfo, 64)
	GUICtrlSetState($idBtnRuntimeInfo, 64)
	GUICtrlSetState($idBtnWintrustInfo, 64)
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	$fFilesListed = 0
	$g_bSearchCompleted = False
	ReDim $g_aAllFiles[0][5]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func UpdateUIState()
	Local $bHasFiles = ($g_bSearchCompleted And _GUICtrlListView_GetItemCount($g_idListview) > 0)
	Local $iEnable   = $bHasFiles ? $GUI_ENABLE : $GUI_DISABLE

	If $idBtnCheckAll       > 0 Then GUICtrlSetState($idBtnCheckAll,       $iEnable)
	If $idBtnUncheckAll     > 0 Then GUICtrlSetState($idBtnUncheckAll,     $iEnable)
	If $idBtnCheckUnpatched > 0 Then GUICtrlSetState($idBtnCheckUnpatched, $iEnable)
	If $idBtnCheckPatched         > 0 Then GUICtrlSetState($idBtnCheckPatched,         $iEnable)
	If $idBtnRefresh        > 0 Then GUICtrlSetState($idBtnRefresh,        $iEnable)

	If $idBtnCure     > 0 Then GUICtrlSetState($idBtnCure,     $iEnable)
	If $idBtnRestore  > 0 Then GUICtrlSetState($idBtnRestore,  $iEnable)
	If $idBtnModified > 0 And Not $g_bIsPatching Then GUICtrlSetState($idBtnModified, $GUI_ENABLE)
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

	Local $mPatched  = ObjCreate("Scripting.Dictionary")
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
	LogWrite(1, "")
	If Not $bSilent Then ToggleLog(1)
EndFunc

Func _RefreshSearch()
	_ResetScanCounters()
	_ShowStatusScreen("scanning", $MyDefPath)
	MemoWrite(@CRLF & "Refresh: re-scanning " & $MyDefPath)

	$FilesToPatch = $FilesToPatchNull
	$FilesToRestore = $FilesToPatchNull
	ReDim $g_aAllFiles[0][5]
	$g_bSearchCompleted = False
	$g_mCheckedState.RemoveAll()

	$timestamp = TimerInit()

	Local $FileCount
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
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
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: "      & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "Please wait", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, _AnimatedDotsOnly(), 1)

		Case "complete"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Scanning for Installed Applications:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "Scan complete.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: "      & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "Loading detected applications...", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, "", 1)

		Case "stopped"
			_GUICtrlListView_SetItemText($g_idListview, 1, "Scanning for Installed Applications:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "Scan stopped by user.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "Files eligible: "      & _FormatNumber($g_FilesToPatchCount), 1)
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

Func MyFileOpenDialog()
	Local Const $sMessage = "Select a Path"

	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)

	If @error Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)

		FillListViewWithInfo()

		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the Search button")
		GUICtrlSetState($idBtnUpdateHosts, 64)
		GUICtrlSetState($idBtnCleanHosts, 64)
		GUICtrlSetState($idBtnEditHosts, 64)
		GUICtrlSetState($idBtnCreateFW, 64)
		GUICtrlSetState($idBtnToggleFW, 64)
		GUICtrlSetState($idBtnRemoveFW, 64)
		GUICtrlSetState($idBtnOpenWF, 64)
		GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
		GUICtrlSetState($idBtnToggleWinTrust, 64)
		GUICtrlSetState($idBtnDevOverride, 64)
		GUICtrlSetState($idBtnRemoveAGS, 64)
		GUICtrlSetState($idBtnRestoreHosts, 64)
		GUICtrlSetState($idBtnRestore, 128)
		GUICtrlSetState($idBtnAGSInfo, 64)
		GUICtrlSetState($idBtnFirewallInfo, 64)
		GUICtrlSetState($idBtnHostsInfo, 64)
		GUICtrlSetState($idBtnRuntimeInfo, 64)
		GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
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
	$g_bUxpHandledFile = False
	_SubProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15
	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")
	Local $sLogSuffix = " - using Default/Custom Patterns"
	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")
	If StringLower($sExt) <> "json" Then LogWrite(1, "Checking File: " & $sFileName & $sLogSuffix)
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
		ElseIf $iUxpResult = 3 Then
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
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
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

				LogWrite(1, "Searching for: " & $sPattern & ": " & $sSearch)

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
				ConsoleWrite($PatternName & "R" & "--" & @TAB & $sFinalReplacePattern & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & @CRLF & "---" & @CRLF & $sWildcardSearchPattern & @CRLF & $sFinalReplacePattern)
				LogWrite(1, "Replacing with: " & $sFinalReplacePattern)

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

Func _FileInitSync($sTargetFile)
	If Not FileExists($sTargetFile) Then Return False
	Local $sExt = StringLower(StringRegExpReplace($sTargetFile, "^.*\.", ""))
	If Not StringRegExp($sExt, "^(exe|dll)$") Then Return True

	Local $hFile = FileOpen($sTargetFile, 17)
	If $hFile = -1 Then Return False

	Local $sBuf = StringRegExpReplace($g_Version & "." & _NowCalc(), "\D", "")
	$sBuf = StringLeft($sBuf, 11)

	FileSetPos($hFile, 0, 2)
	FileWrite($hFile, Binary("0xAE" & _InternalXCore($sBuf) & "00"))
	FileClose($hFile)
	Return True
EndFunc

Func _InternalXCore($sVal)
	Local $a = StringToASCIIArray($sVal), $r = ""
	For $i = 0 To UBound($a) - 1
		$r &= Hex($a[$i], 2)
	Next
	Return $r
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
				FileDelete($sBak)
				FileMove($MyFileToPatch, $sBak)
				FileSetTime($sBak, "", $FT_MODIFIED)
			Else
				FileDelete($MyFileToPatch)
			EndIf
		Else
			FileMove($MyFileToPatch, $sBak)
			FileSetTime($sBak, "", $FT_MODIFIED)
		EndIf

		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		Local $bPatchedData = Binary($sStringOut)
		FileWrite($hFileOpen1, $bPatchedData)
		FileClose($hFileOpen1)
		_SubProgressWrite(100)
		Sleep(100)

		LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)

		_FileInitSync($MyFileToPatch)

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
					LogWrite(1, "Detected already-patched (live MD5 differs from .bak MD5) - recording as Patched in ledger.")
					_QueueStateWrite($MyFileToPatch, _GetAppGroupName($MyFileToPatch), $sBakMD5Now, $sLiveMD5Now, "Patched")
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc

Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		Local $sFileName = StringRegExpReplace($MyFileToDelete, "^.*\\", "")
		If StringLower($sFileName) = "appspanelbl.dll" Or StringLower($sFileName) = "adobe desktop service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf
		FileDelete($MyFileToDelete)
		FileMove($MyFileToDelete & ".bak", $MyFileToDelete, $FC_OVERWRITE)
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

Func _FlushStateQueue()
	Local $iN = UBound($g_aStateQueue)
	If $iN = 0 And $g_mAppPrimaryExe.Count = 0 Then Return

	Local $aSecStatus   = IniReadSection($patchStatesINI, "Patch_Status")
	Local $aSecOrig     = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aSecPatch    = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aSecAppFiles = IniReadSection($patchStatesINI, "App_File")
	Local $aSecAppVer   = IniReadSection($patchStatesINI, "App_Version")
	Local $aSecWinTrust = IniReadSection($patchStatesINI, "WinTrust_Local")

	Local $mStatus   = ObjCreate("Scripting.Dictionary")
	Local $mOrig     = ObjCreate("Scripting.Dictionary")
	Local $mPatch    = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles = ObjCreate("Scripting.Dictionary")
	Local $mAppVer   = ObjCreate("Scripting.Dictionary")
	Local $mWT       = ObjCreate("Scripting.Dictionary")

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
		Local $sApp  = $g_aStateQueue[$i][1]
		$mStatus.Item($sPath) = $g_aStateQueue[$i][4]
		If $g_aStateQueue[$i][2] <> "" Then $mOrig.Item($sPath)  = $g_aStateQueue[$i][2]
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

	_WriteSectionFromMap("Patch_Status",   $mStatus)
	_WriteSectionFromMap("MD5_Original",  $mOrig)
	_WriteSectionFromMap("MD5_Patched",   $mPatch)
	_WriteSectionFromMap("App_File",      $mAppFiles)
	_WriteSectionFromMap("App_Version",   $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion",   $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "LastRun",       @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)

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

	_LockOptionsUIForScan()

	ToggleLog(0)
	MemoWrite(@CRLF & "Reconciling patch_states.ini against current install...")
	LogWrite(1, "Reconcile: scanning " & $MyDefPath)

	Local $aOrigSec  = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aPatchSec = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aStatSec  = IniReadSection($patchStatesINI, "Patch_Status")
	Local $mOrig    = ObjCreate("Scripting.Dictionary")
	Local $mPatch   = ObjCreate("Scripting.Dictionary")
	Local $mStatus  = ObjCreate("Scripting.Dictionary")
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
	ReDim $g_aAllFiles[0][5]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
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
			Local $sO = $mOrig.Exists($sPath)  ? StringLower($mOrig.Item($sPath))  : ""

			If $sStat = "Patched" Then
				If $sP <> "" And $sCurMD5 = $sP Then
					$aResult[2] += 1
				ElseIf $sO <> "" And $sCurMD5 = $sO Then
					$mStatusChanges.Item($sPath) = "Unpatched"
					$aResult[1] += 1
					LogWrite(1, "  drift Patched->Unpatched - " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "  external modification - " & $sPath)
				EndIf
			Else
				If $sO <> "" And $sCurMD5 = $sO Then
					$aResult[2] += 1
				ElseIf $sP <> "" And $sCurMD5 = $sP Then
					$mStatusChanges.Item($sPath) = "Patched"
					$aResult[1] += 1
					LogWrite(1, "  drift Unpatched->Patched - " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "  external modification - " & $sPath)
				EndIf
			EndIf
		Else
			$mNewEntries.Item($sPath) = $sCurMD5
		EndIf
	Next

	For $sIniPath In $mStatus.Keys()
		If Not $mIniSeen.Exists($sIniPath) Then
			$mRemovePaths.Item($sIniPath) = 1
			$aResult[0] += 1
			LogWrite(1, "  missing - " & $sIniPath)
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
		ReDim $g_aAllFiles[0][5]
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

Func _CreateInitialPatchStates()
	If FileExists($patchStatesINI) Then
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), "Cannot Create", "patch_states.ini already exists. Use Reconcile instead.")
		Return
	EndIf

	_LockOptionsUIForScan()

	ToggleLog(0)
	MemoWrite(@CRLF & "Building initial patch_states.ini from current disk state...")
	LogWrite(1, "Create new patch_states.ini: scanning " & $MyDefPath)

	_ResetScanCounters()
	$g_aAllFiles = $aNullArray
	ReDim $g_aAllFiles[0][5]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
		For $sAccDir In $aACCDirs
			If FileExists($sAccDir) Then RecursiveFileSearch($sAccDir, 0, 0)
		Next
	EndIf
	RecursiveFileSearch($MyDefPath, 0, 0)

	If UBound($g_aAllFiles, 1) = 0 Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "Create New", "No eligible files found in " & $MyDefPath & "." & @CRLF & "patch_states.ini was not created.")
		LogWrite(1, "Create new patch_states.ini: aborted - no eligible files in " & $MyDefPath & ".")
		Return
	EndIf

	Local $iTotal = UBound($g_aAllFiles, 1)
	LogWrite(1, "Create new patch_states.ini: found " & $iTotal & " eligible file(s).")

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf

	Local $mStatus    = ObjCreate("Scripting.Dictionary")
	Local $mOrig      = ObjCreate("Scripting.Dictionary")
	Local $mPatched   = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles  = ObjCreate("Scripting.Dictionary")
	Local $mAppVer    = ObjCreate("Scripting.Dictionary")
	Local $mWT        = ObjCreate("Scripting.Dictionary")
	Local $mPrimaryExe = ObjCreate("Scripting.Dictionary")

	Local $iPatchedCount = 0, $iUnpatchedCount = 0
	ProgressWrite(0)
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
			Local $sLowerName = StringLower($sFileName)
			If $sLowerName = "appspanelbl.dll" Or $sLowerName = "adobe desktop service.exe" Or _
			   $sLowerName = "containerbl.dll" Then
				_ProcessCloseEx("""Creative Cloud.exe""")
				_ProcessCloseEx("""Adobe Desktop Service.exe""")
				Sleep(100)
			EndIf
			Local $bDel = FileDelete($sPath)
			Local $bMov = FileMove($sBakPath, $sPath, $FC_OVERWRITE)
			If Not $bMov And Not $bDel Then
				LogWrite(1, "Restore step skipped for: " & $sPath & " - will be detected and recorded during patch.")
			EndIf
		EndIf

		Local $sLiveMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))

		$mStatus.Item($sPath) = "Unpatched"
		$mOrig.Item($sPath)   = $sLiveMD5
		$iUnpatchedCount += 1

		If Mod($i, 10) = 0 Then
			ProgressWrite(Round(($i + 1) / $iTotal * 100))
			_ShowStatusScreen("patching", "Recording: " & $sFileName)
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

	_WriteSectionFromMap("Patch_Status",   $mStatus)
	_WriteSectionFromMap("MD5_Original",   $mOrig)
	_WriteSectionFromMap("MD5_Patched",    $mPatched)
	_WriteSectionFromMap("App_File",       $mAppFiles)
	_WriteSectionFromMap("App_Version",    $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion",   $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "Created",       _NowCalc())
	IniWrite($patchStatesINI, "Info", "Origin",        "create-new")

	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)

	ProgressWrite(0)
	_SubProgressWrite(0)
	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(1500)
	$g_bStatusScreenReady = False

	Local $sSummary = "patch_states.ini partially built." & @CRLF & @CRLF & _
			"Total files indexed: " & $iTotal & @CRLF & _
			"  - App groups: " & $mAppFiles.Count & @CRLF & @CRLF & _
			"Create new patch_states.ini process is halfway through." & @CRLF & _
			"Click OK to allow it to process the found files and verify" & @CRLF & _
			"it all. You can view progress by clicking on the Main tab," & @CRLF & _
			"otherwise once done you will be moved onto the Log tab" & @CRLF & _
			"automatically."

	LogWrite(1, "Create new patch_states.ini complete: " & $iTotal & " indexed (all Unpatched).")
	MemoWrite(@CRLF & $sSummary)
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "patch_states.ini Created", $sSummary)

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

Func _MaintainInisAlphebeticalWithSpacing($sIniPath)
	If Not FileExists($sIniPath) Then Return

	Local $aOrder[7] = ["App_Version", "App_File", "Patch_Status", _
	                    "MD5_Original", "MD5_Patched", "WinTrust_Local", "Info"]

	Local $aAllSections = IniReadSectionNames($sIniPath)
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
		Local $aPairs = IniReadSection($sIniPath, $sSection)
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

	Local $hFile = FileOpen($sIniPath, $FO_OVERWRITE)
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
	If UBound($aRestoredPaths) = 0 Then Return 0

	Local $mDirs = ObjCreate("Scripting.Dictionary")
	For $i = 0 To UBound($aRestoredPaths) - 1
		Local $sPath = $aRestoredPaths[$i]
		Local $iSlash = StringInStr($sPath, "\", 0, -1)
		If $iSlash > 0 Then
			Local $sDir = StringLeft($sPath, $iSlash - 1)
			If Not $mDirs.Exists($sDir) Then $mDirs.Item($sDir) = 1
		EndIf
	Next

	Local $iRemoved = 0
	For $sDir In $mDirs.Keys
		Local $hFind = FileFindFirstFile($sDir & "\*.bak")
		If $hFind = -1 Then ContinueLoop
		While 1
			Local $sName = FileFindNextFile($hFind)
			If @error Then ExitLoop
			Local $sBak = $sDir & "\" & $sName
			If StringInStr(FileGetAttrib($sBak), "D") Then ContinueLoop
			If FileDelete($sBak) Then
				$iRemoved += 1
				LogWrite(1, "Removed backup: " & $sBak)
			EndIf
		WEnd
		FileClose($hFind)
	Next

	If $iRemoved > 0 Then
		LogWrite(1, "Cleaned " & $iRemoved & " .bak file(s) from restored folder(s).")
	EndIf
	Return $iRemoved
EndFunc

Func _PatchAdobeUXPComponent($sFilePath)
	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then Return 0
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If BinaryLen($bData) = 0 Then Return 0

	Local $sFileName = StringLower(StringRegExpReplace($sFilePath, "^.*\\", ""))

	If StringRegExp($sFileName, "(?i)\.json$") Then Return 3

	Local $bIsJs = StringRegExp($sFileName, "(?i)\.js$")
	Local $bModified = False
	Local $bAlready  = False

	Local $sData = BinaryToString($bData, 1)

	If $bIsJs Then
		If StringInStr($sData, "XelationshipProfile") Then
			$bAlready = True
		ElseIf StringInStr($sData, "RelationshipProfile") Then
			$sData = StringReplace($sData, "RelationshipProfile", "XelationshipProfile")
			$bModified = True
			LogWrite(1, "JS5 in-code patch bypass applied to " & $sFileName)
		EndIf
	EndIf

	If Not $bModified Then
		If $bAlready Then Return 2
		Return 0
	EndIf

	Local $iPrePatchSize = FileGetSize($sFilePath)
	Local $sBak = $sFilePath & ".bak"
	If FileExists($sBak) Then
		If FileGetSize($sBak) <> $iPrePatchSize Then
			FileDelete($sBak)
			FileMove($sFilePath, $sBak)
		Else
			FileDelete($sFilePath)
		EndIf
	Else
		FileMove($sFilePath, $sBak)
	EndIf
	FileSetAttrib($sFilePath, "-RHS")

	Local $hWrite = FileOpen($sFilePath, 18)
	If $hWrite = -1 Then
		LogWrite(1, "UXP patch write failed (access denied?): " & $sFileName)
		FileMove($sBak, $sFilePath)
		Return 0
	EndIf
	FileWrite($hWrite, Binary($sData))
	FileClose($hWrite)

	Local $sMD5Orig = "", $sMD5New = ""
	If $g_bCryptActive Then
		$sMD5Orig = StringTrimLeft(String(_Crypt_HashFile($sBak,      $CALG_MD5)), 2)
		$sMD5New  = StringTrimLeft(String(_Crypt_HashFile($sFilePath, $CALG_MD5)), 2)
	EndIf
	_QueueStateWrite($sFilePath, "", $sMD5Orig, $sMD5New, "Patched")

	Return 1
EndFunc

Func _AutoUnpackIfRuntimeInstaller($sFilePath)
	Local $bInScope = StringRegExp($sFilePath, "(?i)\\Adobe After Effects [^\\]+\\") Or _
			StringRegExp($sFilePath, "(?i)\\Adobe Premiere Pro [^\\]+\\")
	If Not $bInScope Then
		Return True
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
		If StringInStr($sLower, "appspanelbl") Or StringInStr($sLower, "containerbl") Or _
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
	If StringInStr($sBase, "(Beta)") Then
		$sBase = StringStripWS(StringReplace($sBase, "(Beta)", ""), 3)
		$bIsBeta = True
	ElseIf StringRegExp($sBase, "(?i)\sBeta$") Then
		$sBase = StringRegExpReplace($sBase, "(?i)\sBeta$", "")
		$bIsBeta = True
	EndIf
	If Not $bIsBeta Then Return $sAppFolder

	Local $iMark = StringInStr($sFilePath, "\Adobe\")
	If $iMark <= 0 Then Return $sAppFolder
	Local $sAdobeRoot = StringLeft($sFilePath, $iMark + 6)

	Local $sYear = ""
	Local $hSearch = FileFindFirstFile($sAdobeRoot & "*")
	If $hSearch <> -1 Then
		While 1
			Local $sSibling = FileFindNextFile($hSearch)
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
		FileClose($hSearch)
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

	Local $mCount   = ObjCreate("Scripting.Dictionary")
	Local $mExe     = ObjCreate("Scripting.Dictionary")
	Local $mWT      = ObjCreate("Scripting.Dictionary")
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
				Local $sCur  = StringLower(StringRegExpReplace($mExe.Item($sGroupName), "^.*\\", ""))
				Local $sNew  = StringLower(StringRegExpReplace($ItemFromList, "^.*\\", ""))
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
	$sBase = StringStripWS($sBase, 3)

	Local $aLaunchers[24][2] = [ _
		["Acrobat",                     "Acrobat.exe"], _
		["After Effects",               "AfterFX.exe"], _
		["Animate",                     "Animate.exe"], _
		["Audition",                    "Adobe Audition.exe"], _
		["Bridge",                      "Adobe Bridge.exe"], _
		["Character Animator",          "Character Animator.exe"], _
		["Dimension",                   "Adobe Dimension.exe"], _
		["Dreamweaver",                 "Dreamweaver.exe"], _
		["Elements 2026 Organizer",     "PhotoshopElementsOrganizer.exe"], _
		["Illustrator",                 "Illustrator.exe"], _
		["InCopy",                      "InCopy.exe"], _
		["InDesign",                    "InDesign.exe"], _
		["Lightroom Classic",           "Lightroom.exe"], _
		["Lightroom",                   "lightroom.exe"], _
		["Media Encoder",               "Adobe Media Encoder.exe"], _
		["Photoshop Elements 2026",     "PhotoshopElementsEditor.exe"], _
		["Photoshop",                   "Photoshop.exe"], _
		["Premiere Elements 2026",      "PremiereElementsEditor.exe"], _
		["Premiere Pro",                "Adobe Premiere Pro.exe"], _
		["Substance 3D Designer",       "Adobe Substance 3D Designer.exe"], _
		["Substance 3D Modeler",        "Adobe Substance 3D Modeler.exe"], _
		["Substance 3D Painter",        "Adobe Substance 3D Painter.exe"], _
		["Substance 3D Sampler",        "Adobe Substance 3D Sampler.exe"], _
		["Substance 3D Stager",         "Adobe Substance 3D Stager.exe"] _
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

Func _SyncWinTrustFromDisk()
	If Not IsObj($g_mWinTrustQueue) Then $g_mWinTrustQueue = ObjCreate("Scripting.Dictionary")
	$g_mWinTrustQueue.RemoveAll()

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
				ReDim $g_aAllFiles[0][5]
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
				Or $iIDFrom = $g_idHyperlinkHosts Or $iIDFrom = $g_idHyperlinkWT Then
			Local $sUrl = Deloader($g_aSignature)
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute($sUrl)
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
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
				If FileDelete($patchStatesINI) Then
					MemoWrite(@CRLF & "patch_states.ini deleted at user request.")
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

	IniWrite($sINIPath, "Options", "FindACC",            _IsChecked($idFindACC)      ? "1" : "0")
	IniDelete($sINIPath, "Options", "EnableMD5")
	IniWrite($sINIPath, "Options", "OnlyDefaultFolders", _IsChecked($idOnlyAFolders) ? "1" : "0")
	IniWrite($sINIPath, "Options", "ShowBetaApps",       _IsChecked($idShowBetaApps) ? "1" : "0")
	IniWrite($sINIPath, "Options", "EnableGood1",        _IsChecked($idEnableGood1)  ? "1" : "0")
	IniWrite($sINIPath, "Options", "UseCustomDefault",   _IsChecked($idUseCustomDefault) ? "1" : "0")
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

	If $g_sWinTrustPath <> "" Then
		IniWrite($sINIPath, "Options", "WinTrustPath", $g_sWinTrustPath)
	EndIf

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

Func RemoveAGS()
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

	MemoWrite("AGS Redirection completed. Services Disabled: " & $iServiceSuccess & ", Dummies: " & $iFileSuccess & ", Registry: " & ($iRegSuccess ? "OK" : "Failed") & ", Consent File: " & ($iConsentFileSuccess ? "OK" : "Failed"))
	LogWrite(1, "AGS Dummy Mode completed. Files: " & $iFileSuccess & ", Reg: " & $iRegSuccess & ", File: " & $iConsentFileSuccess & @CRLF)

	ToggleLog(1)
	GUICtrlSetState($idBtnDummyAGS, $GUI_ENABLE)
EndFunc

Func RemoveHostsEntries()
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

	Local $aDNSDomains = StringRegExp($sDNSCache, "Record Name[^\n]*?\n\s*:\s*([^\n]*adobestats\.io[^\n]*)", 3)
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

Func UpdateHostsFile()
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
	Local $sCmd = "powershell.exe -Command ""Get-CimInstance -ClassName FirewallProduct -Namespace 'root\SecurityCenter2' | Where-Object { $_.ProductName -notlike '*Windows*' } | Select-Object -Property ProductName"""
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("Warning: Third-party firewall check timed out after " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	$sOutput = StringStripWS($sOutput, 3)
	$sOutput = StringRegExpReplace($sOutput, "[\r\n\t ]+", " ")
	$sOutput = StringStripWS($sOutput, 3)
	If $sOutput <> "" Then
		$g_sThirdPartyFirewall = $sOutput
		MemoWrite("Third-party firewall detected: " & $g_sThirdPartyFirewall)
		Return True
	Else
		$g_sThirdPartyFirewall = ""
		MemoWrite("Windows Firewall is the default firewall.")
		Return False
	EndIf
EndFunc

Func FindApps($bForLocalDLL = False, $sBasePathOverride = "")
	Local $sBase = ($sBasePathOverride <> "") ? $sBasePathOverride : $MyDefPath

	Local $tFirewallPaths = IniReadSection($sINIPath, "FirewallTrust")
	If @error Then
		MemoWrite("Error reading [FirewallTrust] section from config.")
		LogWrite(1, "Error reading [FirewallTrust] section from config.")
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
	MemoWrite("Starting firewall rule creation process...")
	LogWrite(1, "Starting firewall rule creation process.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Skipping GUI and listing found applications.")
		Local $foundApps = FindApps()
		If UBound($foundApps) = 0 Then
			LogWrite(1, "No applications found to block.")
		Else
			LogWrite(1, "Found " & UBound($foundApps) & " applications:")
			For $app In $foundApps
				LogWrite(1, "- " & $app)
			Next
			LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & ". Please manually add these paths to your firewall.")
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
		MemoWrite("Warning: [RuntimeInstallers] section not found or empty in config.ini")
		LogWrite(1, "Warning: [RuntimeInstallers] section not found or empty in config.ini")
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
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1

	If Not IsAdmin() Then
		MemoWrite("Error: Administrator rights required to set registry key.")
		LogWrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf

	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error = 0 And $iCurrentValue = $iExpectedValue Then
		MemoWrite("Registry key " & $sValueName & " already enabled.")
		LogWrite(1, "Registry key " & $sValueName & " already set to " & $iExpectedValue & ".")
		Return True
	EndIf

	If RegWrite($sKey, $sValueName, "REG_DWORD", $iExpectedValue) Then
		MemoWrite("Enabled registry key " & $sValueName & " for WinTrust override.")
		LogWrite(1, "Set registry key " & $sValueName & " = " & $iExpectedValue & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "1")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("Error: Failed to enable registry key " & $sValueName & ".")
		LogWrite(1, "Error: Failed to set registry key " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc

Func RemoveDevOverride()
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1

	If Not IsAdmin() Then
		MemoWrite("Error: Administrator rights required to remove registry key.")
		LogWrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf

	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		MemoWrite("No registry key " & $sValueName & " found to remove.")
		LogWrite(1, "No registry key " & $sValueName & " found.")
		Return True
	EndIf

	If $iCurrentValue <> $iExpectedValue Then
		MemoWrite("Registry key " & $sValueName & " not enabled; no action taken.")
		LogWrite(1, "Registry key " & $sValueName & " not set to " & $iExpectedValue & ".")
		Return True
	EndIf

	If RegDelete($sKey, $sValueName) Then
		MemoWrite("Disabled registry key " & $sValueName & ".")
		LogWrite(1, "Removed registry key " & $sValueName & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("Error: Failed to disable registry key " & $sValueName & ".")
		LogWrite(1, "Error: Failed to remove registry key " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
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
		If StringRegExp($sChildText, "(?i)\\AfterFX(Beta)?\.exe$") Then
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
				ElseIf FileExists($sAERoot & "Support Files\AfterFXBeta.exe") Then
					$sAfterFXPath = $sAERoot & "Support Files\AfterFXBeta.exe"
				ElseIf FileExists($sAERoot & "AfterFXBeta.exe") Then
					$sAfterFXPath = $sAERoot & "AfterFXBeta.exe"
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
	If Not IsObj($g_mBlockedParents)  Then $g_mBlockedParents  = ObjCreate("Scripting.Dictionary")
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
		MemoWrite("No untrusted applications found at: " & $g_sWinTrustPath & " -- all eligible apps are already trusted.")
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
		If StringRegExp($app, "(?i)\\AfterFX(Beta)?\.exe$") Then
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

	$g_mBlockedParents  = ObjCreate("Scripting.Dictionary")
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
				MemoWrite(StringLower($operation) & " cancelled.")
				LogWrite(1, StringLower($operation) & " cancelled.")
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
						If $bIsParent And $g_mBlockedParents.Exists($itemText)        Then $bBlocked = True
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
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("Manage DevOverride", 300, 150, $iPopupX, $iPopupY)

	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $sStatus
	Local $iValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		$sStatus = "Registry key not found."
	ElseIf $iValue = 1 Then
		$sStatus = "Registry key is enabled."
	Else
		$sStatus = "Registry key is disabled."
	EndIf

	GUICtrlCreateLabel($sStatus, 10, 20, 280, 20, $SS_CENTER)

	Local $hAddButton = GUICtrlCreateButton("Enable Reg Key", 50, 50, 100, 30)
	Local $hRemoveButton = GUICtrlCreateButton("Remove Reg Key", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
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
