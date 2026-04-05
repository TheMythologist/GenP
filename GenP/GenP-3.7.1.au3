#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=GenP-v3.7.1.exe
#AutoIt3Wrapper_Res_Comment=GenP
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_Description=GenP
#AutoIt3Wrapper_Res_Fileversion=3.7.1.0
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2025
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2025
#AutoIt3Wrapper_Res_ProductName=GenP
#AutoIt3Wrapper_Res_ProductVersion=3.7.1
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

AutoItSetOption("GUICloseOnESC", 0)

Global $g_Version = "3.7.1 - CGP"
Global $g_AppWndTitle = "GenP v" & $g_Version
Global $g_AppVersion = "CGP Community Edition" & @CRLF & "Originally created by uncia"

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
Global $idBtnUpdateHosts, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAFolders, $idBtnSaveOptions, $idCustomDomainListLabel, $idCustomDomainListInput
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF, $idBtnCreateFW, $idBtnRemoveFW, $idBtnToggleFW
Global $sRuntimeInstallerText, $idLabelRuntimeInstaller, $idBtnToggleRuntimeInstaller, $sWinTrustText, $idLabelWinTrust, $idBtnToggleWinTrust, $idBtnDevOverride
Global $idBtnAGSInfo, $idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkPopup, $g_idHyperlinkLog

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf
Global $ConfigVerVar = IniRead($sINIPath, "Info", "ConfigVer", "????")

Global $MyDefPath = StringRegExpReplace(IniRead($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe"), "\\\\+", "\\")
If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	IniWrite($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe")
	$MyDefPath = StringRegExpReplace(@ProgramFilesDir & "\Adobe", "\\\\+", "\\")
EndIf

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = IniRead($sINIPath, "Options", "EnableMD5", "1")
Global $bOnlyAFolders = IniRead($sINIPath, "Options", "OnlyDefaultFolders", "1")

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
Next
Global $g_aSignature = "r~~z}D99qox8zk|kwy|o8}"
;MsgBox(0, "", $sSpecialFiles)

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

	$idMsg = GUIGetMsg()

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
			$ListViewSelectFlag = 0   ; Set Flag to Deselected State
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

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
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
			;Search through all files and folders in directory and fill ListView
			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_AddItem($idListview, "", 0)
			_GUICtrlListView_AddItem($idListview, "", 1)
			_GUICtrlListView_AddItem($idListview, "", 2)
			_GUICtrlListView_AddItem($idListview, "", 2)

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 1, "Preparing...", 1)
			_GUICtrlListView_AddSubItem($idListview, 2, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 3, "Be patient, please.", 1)
			_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 3, 1)

			_Expand_All_Click()
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			; Clear previous results
			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $sAppsPanelDir = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)     ; extended mode
				If UBound($aSize) >= 2 Then
					$FileCount = $aSize[1]
					RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)   ;Search through all files and folders
					ProgressWrite(0)
				EndIf
			EndIf

			$aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)     ; extended mode
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)   ;Search through all files and folders
				Sleep(100)
				ProgressWrite(0)
			EndIf

			FillListViewWithFiles()

			If _GUICtrlListView_GetItemCount($idListview) > 0 Then

				_Assign_Groups_To_Found_Files()

				$ListViewSelectFlag = 1   ; Set Flag to Selected State
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus

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
				EndIf
			Else
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			EndIf

			;_Collapse_All_Click()
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

		Case $idMsg = $idButtonCustomFolder     ; Select Custom Path
			ToggleLog(0)
			MyFileOpenDialog()
			_Expand_All_Click()
			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			Else
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 64)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus
			EndIf

		Case $idMsg = $idBtnDeselectAll     ; Deselect-Select All
			ToggleLog(0)
			If $ListViewSelectFlag = 1 Then
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				Next
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
			Else
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
				Next
				$ListViewSelectFlag = 1   ; Set Flag to Selected State
			EndIf

		Case $idMsg = $idBtnCure
			ToggleLog(0)
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
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)
					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

					MyGlobalPatternSearch($ItemFromList)
					ProgressWrite(0)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "medication :)")
					LogWrite(1, $ItemFromList)
					Sleep(100)

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)


					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))


			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
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

		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & "" & @CRLF & "Config Version: " & $ConfigVerVar & "" & @CRLF)
			ToggleLog(0)
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
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList, $iCheckedItems, $iProgress
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)

					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
					$iCheckedItems = _GUICtrlListView_GetSelectedCount($idListview)
					$iProgress = 100 / $iCheckedItems
					ProgressWrite(0)
					RestoreFile($ItemFromList)

					ProgressWrite($iProgress)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "restoring :)")
					Sleep(100)

					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
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
			FillListViewWithInfo()

			ToggleLog(1)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf

		Case $idMsg = $idEnableMD5
			If _IsChecked($idEnableMD5) Then
				$bEnableMD5 = 1
			Else
				$bEnableMD5 = 0
			EndIf

		Case $idMsg = $idOnlyAFolders
			If _IsChecked($idOnlyAFolders) Then
				$bOnlyAFolders = 1
			Else
				$bOnlyAFolders = 0
			EndIf

		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

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

			;Case $idMsg = $idBtnCleanFirewall
			;	CleanFirewall()

			;Case $idMsg = $idBtnEnableDisableWF
			;	EnableDisableWFRules()

		Case $idMsg = $idBtnToggleRuntimeInstaller
			ToggleLog(0)
			UnpackRuntimeInstallers()

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

		Case $idMsg = $idBtnRuntimeInfo
			ShowInfoPopup("Select apps may pack the RuntimeInstaller.dll with UPX causing patching to fail. GenP can unpack these files so they can then be patched." & @CRLF & @CRLF & @CRLF & @CRLF & _
					"UPX 5.0.1, Copyright (C) 1996-2025 Markus Oberhumer, Laszlo Molnar & John Reiser" & @CRLF & _
					"UPX is distributed under a modified GNU GPL v2. See https://github.com/upx/upx for license and source code.")

		Case $idMsg = $idBtnWintrustInfo
			ShowInfoPopup("Avoid popups by ' trusting' each app. Uses a modified DLL + registry edit for allowing DLL redirection. Trust/Untrust each app or add/remove the reg key as needed. Reg key is auto-added when trusting apps." & @CRLF & @CRLF & "Shout out Team V.R !")
	EndSelect
WEnd

Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 510, -1, -1, BitOR($WS_MAXIMIZEBOX, $WS_MINIMIZEBOX, $WS_SIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 510)

	$hMainTab = GUICtrlCreateTabItem("Main")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 355)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview) ; get handle for use in the notify events
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
	$iStyles = _WinAPI_GetWindowLong($MyhGUI, $GWL_STYLE)
	_WinAPI_SetWindowLong($MyhGUI, $GWL_STYLE, BitXOR($iStyles, $WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX))

	; Add columns
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "[Click to expand/collapse all]", 532, 2)

	; Build groups
	_GUICtrlListView_EnableGroupView($idListview)
	_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1) ; Group 1
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	FillListViewWithInfo()

	$idButtonCustomFolder = GUICtrlCreateButton("Path", 10, 430, 80, 30)
	GUICtrlSetTip(-1, "Set custom search path")
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton("Search", 134, 430, 80, 30)
	GUICtrlSetTip(-1, "Search path for installed apps")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton("Stop", 134, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Stop search")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton("Patch", 258, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Patch selected file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateButton("De/Select", 381, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "De/Select all files")
	GUICtrlSetImage(-1, "imageres.dll", -76, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton("Restore", 505, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore original file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 397, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$g_idHyperlinkMain = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("Options")

	$idFindACC = GUICtrlCreateCheckbox("Always search for ACC", 10, 50, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then
		GUICtrlSetState($idFindACC, $GUI_CHECKED)
	Else
		GUICtrlSetState($idFindACC, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateCheckbox("Enable MD5 Checksum", 10, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableMD5 = 1 Then
		GUICtrlSetState($idEnableMD5, $GUI_CHECKED)
	Else
		GUICtrlSetState($idEnableMD5, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idOnlyAFolders = GUICtrlCreateCheckbox("Search in default named folders only", 10, 130, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then
		GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idOnlyAFolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts List URL:", 10, 180, 100, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 90, 175, 490, 20, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 430, 100, 30)
	GUICtrlSetTip(-1, "Save options to config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkOptions, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkOptions, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkOptions, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkOptions, 0)

	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("Pop-up Tools")

	; --- Genuine Services ---
	$idBtnAGSInfo = GUICtrlCreateButton("?", 385, 38, 20, 20)
	GUICtrlSetFont($idBtnAGSInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnAGSInfo, $GUI_DOCKAUTO)
	$sRemoveAGSText = "GENUINE SERVICES"
	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, 5, 40, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRemoveAGS = GUICtrlCreateButton("Remove AGS", 225, 65, 140, 30)
	GUICtrlSetTip(-1, "Remove Genuine Services files/services to remove pop-up")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Firewall ---
	$idBtnFirewallInfo = GUICtrlCreateButton("?", 330, 113, 20, 20)
	GUICtrlSetFont($idBtnFirewallInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnFirewallInfo, $GUI_DOCKAUTO)
	$sCleanFirewallText = "FIREWALL"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, 5, 115, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnCreateFW = GUICtrlCreateButton("Add Rules", 10, 140, 140, 30)
	GUICtrlSetTip(-1, "Add new firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleFW = GUICtrlCreateButton("Toggle Rules", 155, 140, 140, 30)
	GUICtrlSetTip(-1, "Enable/Disable all GenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRemoveFW = GUICtrlCreateButton("Remove Rules", 300, 140, 140, 30)
	GUICtrlSetTip(-1, "Remove all GenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", 445, 140, 140, 30)
	GUICtrlSetTip(-1, "Open Windows Firewall with Advanced Security console")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Hosts ---
	$idBtnHostsInfo = GUICtrlCreateButton("?", 320, 188, 20, 20)
	GUICtrlSetFont($idBtnHostsInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnHostsInfo, $GUI_DOCKAUTO)
	$sEditHostsText = "HOSTS"
	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, 5, 190, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnUpdateHosts = GUICtrlCreateButton("Update hosts", 10, 215, 140, 30)
	GUICtrlSetTip(-1, "Update hosts with domains from hosts list URL")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnEditHosts = GUICtrlCreateButton("Edit hosts", 155, 215, 140, 30)
	GUICtrlSetTip(-1, "Manually edit hosts in notepad")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnCleanHosts = GUICtrlCreateButton("Clean hosts", 300, 215, 140, 30)
	GUICtrlSetTip(-1, "Remove hosts added by GenP")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRestoreHosts = GUICtrlCreateButton("Restore hosts", 445, 215, 140, 30)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore hosts from hosts.bak")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Runtime Installer ---
	$idBtnRuntimeInfo = GUICtrlCreateButton("?", 365, 263, 20, 20)
	GUICtrlSetFont($idBtnRuntimeInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnRuntimeInfo, $GUI_DOCKAUTO)
	$sRuntimeInstallerText = "RUNTIME INSTALLER"
	$idLabelRuntimeInstaller = GUICtrlCreateLabel($sRuntimeInstallerText, 5, 265, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRuntimeInstaller, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleRuntimeInstaller = GUICtrlCreateButton("Unpack", 225, 290, 140, 30)
	GUICtrlSetTip(-1, "Unpack RuntimeInstaller.dll")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- WinTrust ---
	$idBtnWintrustInfo = GUICtrlCreateButton("?", 333, 338, 20, 20)
	GUICtrlSetFont($idBtnWintrustInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnWintrustInfo, $GUI_DOCKAUTO)
	$sWinTrustText = "WINTRUST"
	$idLabelWinTrust = GUICtrlCreateLabel($sWinTrustText, 5, 340, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelWinTrust, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleWinTrust = GUICtrlCreateButton("Toggle WinTrust", 155, 365, 140, 30)
	GUICtrlSetTip(-1, "Enable/disable wintrust.dll override")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnDevOverride = GUICtrlCreateButton("Toggle Reg Key", 300, 365, 140, 30)
	GUICtrlSetTip(-1, "Add/remove DevOverrideEnable registry key")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkPopup = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkPopup, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkPopup, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkPopup, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkPopup, 0)

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("Log")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP Version: " & $g_Version & "" & @CRLF & "Config Version: " & $ConfigVerVar & "" & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("Copy", 257, 430, 80, 30)
	GUICtrlSetTip(-1, "Copy log to clipboard")
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkLog = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")

	GUICtrlSetState($idButtonSearch, 256) ; Set focus
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>MainGui

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	_GUICtrlListView_SetItemText($idListview, 1, "Searching for files.", 1)
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
					If StringInStr($FileTarget, "$") Then
						$FileTarget = StringSplit($FileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $FileTarget[2]
						$FileTarget = $FileTarget[1]
					EndIf
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($FileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") And Not StringInStr(StringLower($IPATH), "wintrust") Then
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAFolders = 0 Then
								If $PathToCheck = "" Then
									_ArrayAdd($FilesToPatch, $IPATH)
								Else
									If StringInStr($IPATH, $PathToCheck) Then
										_ArrayAdd($FilesToPatch, $IPATH)
									EndIf
								EndIf
							EndIf
						ElseIf StringInStr($IPATH, ".bak") Then
							_ArrayAdd($FilesToRestore, $IPATH)
						EndIf
					EndIf
					$PathToCheck = ""
				Next
			EndIf
		EndIf
	WEnd

	; Lazy screen updates
	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "Searching in " & $FileCount & " files" & @TAB & @TAB & "Found : " & UBound($FilesToPatch) & @CRLF & _
				"---" & @CRLF & _
				"Level: " & $DEPTH & " Time elapsed : " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @TAB & @TAB & "Excluded because of *.bak: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR _
				)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
	EndIf

	FileClose($HSEARCH)
EndFunc   ;==>RecursiveFileSearch

Func FillListViewWithInfo()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

	_Expand_All_Click()
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	; Add items
	For $i = 0 To 5
		_GUICtrlListView_AddItem($idListview, "", $i)
		_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
	Next

	_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
	_GUICtrlListView_AddSubItem($idListview, 1, "GenP", 1)
	_GUICtrlListView_AddSubItem($idListview, 2, "Originally created by uncia", 1)
	_GUICtrlListView_AddSubItem($idListview, 3, '---------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 4, "Press 'Search' to find installed products; 'Patch' to patch selected products/files", 1)
	_GUICtrlListView_AddSubItem($idListview, 5, "Current search path: " & $MyDefPath & " -- press 'Path' to change", 1)

	$fFilesListed = 0

EndFunc   ;==>FillListViewWithInfo

Func FillListViewWithFiles()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	If UBound($FilesToPatch) > 0 Then
		Global $aItems[UBound($FilesToPatch)][2]
		For $i = 0 To UBound($aItems) - 1
			$aItems[$i][0] = $i
			$aItems[$i][1] = $FilesToPatch[$i][0]

		Next
		_GUICtrlListView_AddArray($idListview, $aItems)

		MemoWrite(@CRLF & UBound($FilesToPatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s) at:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the 'Patch Files'")
		LogWrite(1, UBound($FilesToPatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @CRLF)
		;_ArrayDisplay($FilesToPatch)
		$fFilesListed = 1
	Else
		MemoWrite(@CRLF & "Nothing was found in" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
		LogWrite(1, "Nothing was found in " & $MyDefPath)
		$fFilesListed = 0
	EndIf

EndFunc   ;==>FillListViewWithFiles

; Write a line to the memo control
Func MemoWrite($sMessage)
	GUICtrlSetData($idMemo, $sMessage)
EndFunc   ;==>MemoWrite

Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc   ;==>LogWrite

Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
EndFunc   ;==>ToggleLog

Func SendToClipBoard()
	If BitAND(GUICtrlGetState($idMemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idLog))
	Else
		ClipPut(GUICtrlRead($idMemo))
	EndIf
EndFunc   ;==>SendToClipBoard

Func GUICtrlSetDataEx($hWnd, $sText, $bTS)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iLength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0x000E, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xB1, "wparam", $iLength[0], "lparam", $iLength[0]) ; $EM_SETSEL
	If $bTS = 1 Then
		Local $iData = @CRLF & $sText
	Else
		Local $iData = $sText
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xC2, "wparam", True, "wstr", $iData) ; $EM_REPLACESEL
EndFunc   ;==>GUICtrlSetDataEx

; Send a message to the Progress control
Func ProgressWrite($msg_Progress)
	;_SendMessage($hWnd_Progress, $PBM_SETPOS, $msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc   ;==>ProgressWrite


Func MyFileOpenDialog()
	; Create a constant variable in Local scope of the message to display in FileOpenDialog.
	Local Const $sMessage = "Select a Path"

	; Display an open dialog to select a file.
	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)


	If @error Then
		; Display the error message.
		;MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)
		_GUICtrlListView_DeleteAllItems($g_idListview)
		_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
		_GUICtrlListView_AddItem($idListview, "", 0)
		_GUICtrlListView_AddItem($idListview, "", 1)
		_GUICtrlListView_AddItem($idListview, "", 2)
		_GUICtrlListView_AddItem($idListview, "", 3)
		_GUICtrlListView_AddItem($idListview, "", 4)
		_GUICtrlListView_AddItem($idListview, "", 5)
		_GUICtrlListView_AddItem($idListview, "", 6)
		_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
		_GUICtrlListView_AddSubItem($idListview, 1, "Path:", 1)
		_GUICtrlListView_AddSubItem($idListview, 2, " " & $MyDefPath, 1)
		_GUICtrlListView_AddSubItem($idListview, 3, "Step 1:", 1)
		_GUICtrlListView_AddSubItem($idListview, 4, " Press 'Search' - wait until search completes", 1)
		_GUICtrlListView_AddSubItem($idListview, 5, "Step 2:", 1)
		_GUICtrlListView_AddSubItem($idListview, 6, " Press 'Patch' - wait until patching completes", 1)
		_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 3, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 4, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 5, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 6, 1)
		_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the Search button")
		; Display the selected folder.
		;MsgBox($MB_SYSTEMMODAL, "", "You chose the following folder:" & @CRLF & $MyDefPath)
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
		$fFilesListed = 0

	EndIf

EndFunc   ;==>MyFileOpenDialog


Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc   ;==>_ProcessCloseEx


Func MyGlobalPatternSearch($MyFileToParse)
	;ConsoleWrite($MyFileToParse & @CRLF)
	$aInHexArray = $aNullArray   ; Nullifay Array that will contain Hex later
	$aOutHexGlobalArray = $aNullArray     ; Nullifay Array that will contain Hex later

	ProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15

	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")

	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")
	LogWrite(1, "Checking File: " & $sFileName & " ")
	;MsgBox($MB_SYSTEMMODAL,"","$sFileName = " & $sFileName & @CRLF & "$sExt = " & $sExt)

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
		;MsgBox($MB_SYSTEMMODAL, "", "Special File: " & $sFileName)
		LogWrite(0, " - using Custom Patterns")
		ExecuteSearchPatterns($sFileName, 0, $MyFileToParse)
	Else
		LogWrite(0, " - using Default Patterns")
		ExecuteSearchPatterns($sFileName, 1, $MyFileToParse)
		;MsgBox($MB_SYSTEMMODAL, "", "File: " & $sFileName & @CRLF & "Not in Special Files")
	EndIf
	Sleep(100)
EndFunc   ;==>MyGlobalPatternSearch

Func ExecuteSearchPatterns($FileName, $DefaultPatterns, $MyFileToParse)

	Local $aPatterns, $sPattern, $sData, $aArray, $sSearch, $sReplace, $iPatternLength

	If $DefaultPatterns = 0 Then
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	;_ArrayDisplay($aPatterns, "Patterns for " & $FileName)

	For $i = 0 To UBound($aPatterns) - 1
		$sPattern = $aPatterns[$i]
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

				;MsgBox(0,0, $MyFileToParse & @CRLF & $sSearch & @CRLF  & $aReplace & @CRLF  & $sPattern )
				LogWrite(1, "Searching for: " & $sPattern & ": " & $sSearch)

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

				;Exit ; STOP AT FIRST VALUE - COMMENT OUT TO CONTINUE
			EndIf
			;Exit
		EndIf

	Next

EndFunc   ;==>ExecuteSearchPatterns


Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)  ; Path to a file to parse
	;MsgBox($MB_SYSTEMMODAL, "Path", $FileToParse)
	;ConsoleWrite($FileToParse & @CRLF)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	FileSetPos($hFileOpen, 60, 0)

	$sz_type = FileRead($hFileOpen, 4)
	FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

	$sz_type = FileRead($hFileOpen, 2)

	If $sz_type = "0x4C01" And StringInStr($FileToParse, "Acrobat", 2) > 0 Then ; Acrobat x86 won't work with this script

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
		For $i = 256 To 1 Step -2 ; limiting to 256 -?-
			$GeneQuestionMark = _StringRepeat("??", $i / 2) ; Repeat the string -??- $i/2 times.
			$AnyNumOfBytes = "(.{" & $i & "})"
			$OutStringForRegExp = StringReplace($PatternToSearch, $GeneQuestionMark, $AnyNumOfBytes)
			$PatternToSearch = $OutStringForRegExp
		Next

		Local $sSearchPattern = $OutStringForRegExp     ;string
		Local $aReplacePattern = $PatternToReplace     ;string
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
			;_ArrayDisplay($aInHexArray)

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]   ; full founded Search Pattern index 0
				$sWildcardReplacePattern = $aReplacePattern

				;MsgBox(-1,"",$sWildcardSearchPattern & @CRLF & $sWildcardReplacePattern) ; full search and full patch with ?? symbols

				If StringInStr($sWildcardReplacePattern, "?") Then
					;MsgBox($MB_SYSTEMMODAL, "Found ? symbol", "Constructing new Replace string")
					For $j = 1 To StringLen($sWildcardReplacePattern) + 1
						; Retrieve a characters from the $jth position in each string.
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
		ProgressWrite(Round($MyRegExpGlobalPatternSearchCount / $Count * 100))
		Sleep(100)

	EndIf      ;==>If $sz_type = "0x4C01"

EndFunc   ;==>MyRegExpGlobalPatternSearch


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
	;MsgBox($MB_SYSTEMMODAL, "", $MyFileToPatch)
	;_ArrayDisplay($MyArrayToPatch)
	ProgressWrite(0)
	;MemoWrite("Current path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")
	Local $iRows = UBound($MyArrayToPatch) ; Total number of rows
	If $iRows > 0 Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")
		Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
		Local $sFileRead = FileRead($hFileOpen)
		Local $sStringOut

		For $i = 0 To $iRows - 1 Step 2
			$sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
			$sFileRead = $sStringOut
			$sStringOut = $sFileRead
			ProgressWrite(Round($i / $iRows * 100))
		Next

		;MsgBox($MB_SYSTEMMODAL, "", "binary: " & Binary($sStringOut))
		FileClose($hFileOpen)
		FileMove($MyFileToPatch, $MyFileToPatch & ".bak", $FC_OVERWRITE)
		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		FileWrite($hFileOpen1, Binary($sStringOut))
		FileClose($hFileOpen1)
		ProgressWrite(0)
		Sleep(100)
		;MemoWrite1(@CRLF & "---" & @CRLF & "Waitng for your command :)" & @CRLF & "---")

		LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)
		If $bEnableMD5 = 1 Then
			_Crypt_Startup()
			Local $sMD5Checksum = _Crypt_HashFile($MyFileToPatch, $CALG_MD5)
			If Not @error Then
				LogWrite(1, "MD5 Checksum: " & $sMD5Checksum & @CRLF)
			EndIf
			_Crypt_Shutdown()
		EndIf

	Else
		;Empty array - > no search-replace patterns
		;File is already patched or no patterns were found .
		MemoWrite(@CRLF & "No patterns were found" & @CRLF & "---" & @CRLF & "or" & @CRLF & "---" & @CRLF & "file is already patched.")
		Sleep(100)

		LogWrite(1, "No patterns were found or file already patched." & @CRLF)

	EndIf
	;Sleep(100)
	;MemoWrite2("***")
EndFunc   ;==>MyGlobalPatternPatch

Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		If $MyFileToDelete = "AppsPanelBL.dll" Or $MyFileToDelete = "Adobe Desktop Service.exe" Then
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
	Else
		Sleep(100)
		MemoWrite(@CRLF & "No backup file found" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "No backup file found.")
	EndIf
EndFunc   ;==>RestoreFile

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
				;$g_iIndex = $aHit[0]
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_ListView_LeftClick

Func _ListView_RightClick()
	Local $aHit
	$aHit = _GUICtrlListView_HitTest($g_idListview)
	If $aHit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 1)
		EndIf
		;$g_iIndex = $aHit[0]
	EndIf
EndFunc   ;==>_ListView_RightClick

Func _Assign_Groups_To_Found_Files()
	ConsoleWrite("Entering _Assign_Groups_To_Found_Files()" & @CRLF)
	Local $MyListItemCount = _GUICtrlListView_GetItemCount($idListview)
	ConsoleWrite("Item Count in ListView: " & $MyListItemCount & @CRLF)
	Local $ItemFromList
	Local $aGroups[0]
	Local $iGroupID = 1

	ReDim $g_aGroupIDs[0]

	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		ConsoleWrite("Item Text (Column 2): " & $ItemFromList & @CRLF)

		Local $sGroupName = ""
		Select
			Case StringInStr($ItemFromList, "AppsPanel") Or StringInStr($ItemFromList, "Adobe Desktop Service") Or StringInStr($ItemFromList, "HDPIM")
				$sGroupName = "Creative Cloud"
			Case StringInStr($ItemFromList, "Acrobat")
				$sGroupName = "Acrobat"
			Case StringInStr($ItemFromList, "Aero")
				$sGroupName = "Aero"
			Case StringInStr($ItemFromList, "After Effects")
				$sGroupName = "After Effects"
			Case StringInStr($ItemFromList, "Animate")
				$sGroupName = "Animate"
			Case StringInStr($ItemFromList, "Audition")
				$sGroupName = "Audition"
			Case StringInStr($ItemFromList, "Adobe Bridge")
				$sGroupName = "Bridge"
			Case StringInStr($ItemFromList, "Character Animator")
				$sGroupName = "Character Animator"
			Case StringInStr($ItemFromList, "Dimension")
				$sGroupName = "Dimension"
			Case StringInStr($ItemFromList, "Dreamweaver")
				$sGroupName = "Dreamweaver"
			Case StringInStr($ItemFromList, "Elements") And StringInStr($ItemFromList, "Organizer")
				$sGroupName = "Elements Organizer"
			Case StringInStr($ItemFromList, "Illustrator")
				$sGroupName = "Illustrator"
			Case StringInStr($ItemFromList, "InCopy")
				$sGroupName = "InCopy"
			Case StringInStr($ItemFromList, "InDesign")
				$sGroupName = "InDesign"
			Case StringInStr($ItemFromList, "Lightroom CC")
				$sGroupName = "Lightroom CC"
			Case StringInStr($ItemFromList, "Lightroom Classic")
				$sGroupName = "Lightroom Classic"
			Case StringInStr($ItemFromList, "Media Encoder")
				$sGroupName = "Media Encoder"
			Case StringInStr($ItemFromList, "Photoshop Elements")
				$sGroupName = "Photoshop Elements"
			Case StringInStr($ItemFromList, "Photoshop")
				$sGroupName = "Photoshop"
			Case StringInStr($ItemFromList, "Premiere Elements")
				$sGroupName = "Premiere Elements"
			Case StringInStr($ItemFromList, "Premiere Pro")
				$sGroupName = "Premiere Pro"
			Case StringInStr($ItemFromList, "Premiere Rush")
				$sGroupName = "Premiere Rush"
			Case StringInStr($ItemFromList, "Substance 3D Designer")
				$sGroupName = "Substance 3D Designer"
			Case StringInStr($ItemFromList, "Substance 3D Modeler")
				$sGroupName = "Substance 3D Modeler"
			Case StringInStr($ItemFromList, "Substance 3D Painter")
				$sGroupName = "Substance 3D Painter"
			Case StringInStr($ItemFromList, "Substance 3D Sampler")
				$sGroupName = "Substance 3D Sampler"
			Case StringInStr($ItemFromList, "Substance 3D Stager")
				$sGroupName = "Substance 3D Stager"
			Case StringInStr($ItemFromList, "Substance 3D Viewer")
				$sGroupName = "Substance 3D Viewer"
			Case Else
				$sGroupName = "Else"
		EndSelect

		ConsoleWrite("Group Name Assigned: " & $sGroupName & @CRLF)

		Local $iGroupIndex = _ArraySearch($aGroups, $sGroupName)
		If $iGroupIndex = -1 Then
			_ArrayAdd($aGroups, $sGroupName)
			_GUICtrlListView_InsertGroup($idListview, $i, $iGroupID, "", 1)
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupID)
			_GUICtrlListView_SetGroupInfo($idListview, $iGroupID, $sGroupName, 1, $LVGS_COLLAPSIBLE)
			_ArrayAdd($g_aGroupIDs, $iGroupID)
			ConsoleWrite("New Group Created - ID: " & $iGroupID & @CRLF)
			$iGroupID += 1
		Else
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupIndex + 1)
			ConsoleWrite("Assigned to Existing Group: " & $sGroupName & " (ID: " & $iGroupIndex + 1 & ")" & @CRLF)
		EndIf
	Next

	For $i = 0 To $MyListItemCount - 1
		_GUICtrlListView_SetItemChecked($idListview, $i, 1)
	Next

	ConsoleWrite("Exiting _Assign_Groups_To_Found_Files()" & @CRLF)
	ConsoleWrite("Number of Groups in $g_aGroupIDs: " & UBound($g_aGroupIDs) & @CRLF)
	For $i = 0 To UBound($g_aGroupIDs) - 1
		ConsoleWrite("Group ID in $g_aGroupIDs: " & $g_aGroupIDs[$i] & @CRLF)
	Next
EndFunc   ;==>_Assign_Groups_To_Found_Files

Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

			For $i = 1 To 25
				$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
				If IsArray($aInfo) Then
					_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
			_RedrawWindow($idListview)
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
	EndIf
EndFunc   ;==>_Collapse_All_Click

Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

		For $i = 1 To 25
			$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
			If IsArray($aInfo) Then
				_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
		_RedrawWindow($idListview)
	EndIf
EndFunc   ;==>_Expand_All_Click

Func _SendMessageL($hWnd, $Msg, $wParam, $lParam)
	Return DllCall("user32.dll", "LRESULT", "SendMessageW", "HWND", GUICtrlGetHandle($hWnd), "UINT", $Msg, "WPARAM", $wParam, "LPARAM", $lParam)[0]
EndFunc   ;==>_SendMessageL

Func _RedrawWindow($hWnd)
	DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", GUICtrlGetHandle($hWnd), "ptr", 0, "ptr", 0, "uint", 0x0100)
EndFunc   ;==>_RedrawWindow

Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) = $idButtonStop Then $fInterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	Local $iCode = DllStructGetData($tNMHDR, "Code")
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
EndFunc   ;==>WM_NOTIFY

Func hL_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF)
	Local $iCode = BitShift($wParam, 16)

	If $iCode = $STN_CLICKED Then
		If $iIDFrom = $g_idHyperlinkMain Or $iIDFrom = $g_idHyperlinkLog Or $iIDFrom = $g_idHyperlinkOptions Or $iIDFrom = $g_idHyperlinkPopup Then
			Local $sUrl = Deloader($g_aSignature)
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute($sUrl)
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
			Return $GUI_RUNDEFMSG
		EndIf
	EndIf

	Return WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>hL_WM_COMMAND

Func _Exit()
	Exit
EndFunc   ;==>_Exit

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
EndFunc   ;==>IniReadArray

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
EndFunc   ;==>ReplaceToArray

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked


Func SaveOptionsToConfig()
	If _IsChecked($idFindACC) Then
		IniWrite($sINIPath, "Options", "FindACC", "1")
	Else
		IniWrite($sINIPath, "Options", "FindACC", "0")
	EndIf
	If _IsChecked($idEnableMD5) Then
		IniWrite($sINIPath, "Options", "EnableMD5", "1")
	Else
		IniWrite($sINIPath, "Options", "EnableMD5", "0")
	EndIf
	If _IsChecked($idOnlyAFolders) Then
		IniWrite($sINIPath, "Options", "OnlyDefaultFolders", "1")
	Else
		IniWrite($sINIPath, "Options", "OnlyDefaultFolders", "0")
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
EndFunc   ;==>SaveOptionsToConfig

Func Deloader($sLoaded)
	Local $sDeloaded = ""
	For $i = 1 To StringLen($sLoaded)
		Local $iAscii = Asc(StringMid($sLoaded, $i, 1))
		$sDeloaded &= Chr($iAscii - 10)
	Next
	Return $sDeloaded
EndFunc   ;==>Deloader

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
EndFunc   ;==>ShowInfoPopup

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func RemoveAGS()
	GUICtrlSetState($idBtnRemoveAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "Removing AGS from this Computer" & @CRLF & "---" & @CRLF & "Please wait...")

	Local $aServices = ["AGMService", "AGSService"]
	Local $ProgramFilesX86 = EnvGet("ProgramFiles(x86)")
	Local $PublicDir = EnvGet("PUBLIC")
	Local $WinDir = @WindowsDir
	Local $LocalAppData = EnvGet("LOCALAPPDATA")
	Local $aPaths[9] = [ _
			$ProgramFilesX86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe", _
			$ProgramFilesX86 & "\Common Files\Adobe\AdobeGCClient", _
			$ProgramFilesX86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient", _
			$PublicDir & "\Documents\AdobeGCData", _
			$WinDir & "\System32\Tasks\AdobeGCInvoker-1.0", _
			$WinDir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0", _
			$ProgramFilesX86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe", _
			$WinDir & "\Temp\adobegc.log", _
			$LocalAppData & "\Temp\adobegc.log" _
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
EndFunc   ;==>RemoveAGS

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func RemoveHostsEntries()
	_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>RemoveHostsEntries

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
EndFunc   ;==>ScanDNSCache

Func UpdateHostsFile()
	_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>UpdateHostsFile

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
EndFunc   ;==>EditHosts

Func RestoreHosts()
	_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>RestoreHosts

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
	If $sOutput <> "" Then
		$g_sThirdPartyFirewall = $sOutput
		MemoWrite("Third-party firewall detected: " & $g_sThirdPartyFirewall)
		Return True
	Else
		$g_sThirdPartyFirewall = ""
		MemoWrite("Windows Firewall is the default firewall.")
		Return False
	EndIf
EndFunc   ;==>CheckThirdPartyFirewall

Func FindApps($bForLocalDLL = False)
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
		Local $basePath = StringRegExpReplace($MyDefPath & "\" & $relativePath, "\\\\+", "\\")
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
EndFunc   ;==>FindApps

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
EndFunc   ;==>RuleExists

Func ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>ShowFirewallStatus

Func RemoveFirewallRules()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite("Starting firewall rule removal process...")
	LogWrite(1, "Starting firewall rule removal process.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot remove rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & ". This option only supports Windows Firewall.")
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
EndFunc   ;==>RemoveFirewallRules

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
	_GUICtrlTab_SetCurFocus($hTab, 3)

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
EndFunc   ;==>CreateFirewallRules

Func ShowAppSelectionGUI($foundFiles)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
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
	AdlibRegister("CheckParentCheckboxes", 250)

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
				AdlibRegister("CheckParentCheckboxes", 250)
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
				_GUICtrlTab_SetCurFocus($hTab, 3)
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
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>ShowAppSelectionGUI

Func CheckParentCheckboxes()
	Local $hItem = _GUICtrlTreeView_GetFirstItem($ghTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($ghTreeView, $hItem)
		Local $childCount = _GUICtrlTreeView_GetChildCount($ghTreeView, $hItem)
		If $childCount > 0 Then
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
EndFunc   ;==>CheckParentCheckboxes

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
				_GUICtrlTab_SetCurFocus($hTab, 3)
				GUIDelete($hToggleGUI)
				EnableAllFWRules()
				Return
			Case $hDisableButton
				_GUICtrlTab_SetCurFocus($hTab, 3)
				GUIDelete($hToggleGUI)
				DisableAllFWRules()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>ShowToggleRulesGUI

Func EnableAllFWRules()
	MemoWrite("Enabling all GenP firewall rules...")
	LogWrite(1, "Starting process to enable all GenP firewall rules.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot modify rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & ". This option only supports Windows Firewall.")
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
EndFunc   ;==>EnableAllFWRules

Func DisableAllFWRules()
	MemoWrite("Disabling all GenP firewall rules...")
	LogWrite(1, "Starting process to disable all GenP firewall rules.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("Third-party firewall detected. Cannot modify rules.")
		LogWrite(1, "Third-party firewall detected" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & ". This option only supports Windows Firewall.")
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
EndFunc   ;==>DisableAllFWRules

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func FindRuntimeInstallerFiles()
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	Local $tRuntimePaths = IniReadSection($sINIPath, "RuntimeInstallers")
	Local $dllPaths[0]

	If @error Or $tRuntimePaths[0][0] = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>FindRuntimeInstallerFiles

Func UnpackRuntimeInstallers()
	MemoWrite("Scanning for RuntimeInstaller.dll files...")
	Local $foundFiles = FindRuntimeInstallerFiles()

	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("No file(s) found at: " & $MyDefPath)
		LogWrite(1, "No file(s) found at: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $selectedFiles = RuntimeDllSelectionGUI($foundFiles, "Unpack")

	If Not IsArray($selectedFiles) Or UBound($selectedFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
		LogWrite(1, "No files selected to unpack.")
		ToggleLog(1)
		Return
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			_GUICtrlTab_SetCurFocus($hTab, 3)
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
EndFunc   ;==>UnpackRuntimeInstallers

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
EndFunc   ;==>IsUPXPacked

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
EndFunc   ;==>PatchUPXHeader

Func RuntimeDllSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
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
	AdlibRegister("CheckParentCheckboxes", 250)

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
				AdlibRegister("CheckParentCheckboxes", 250)
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
					_GUICtrlTab_SetCurFocus($hTab, 3)
					MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
					LogWrite(1, "No RuntimeInstaller.dll files selected to unpack.")
					ToggleLog(1)
					Return ""
				EndIf
				_GUICtrlTab_SetCurFocus($hTab, 3)
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
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>RuntimeDllSelectionGUI

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("Error: Failed to enable registry key " & $sValueName & ".")
		LogWrite(1, "Error: Failed to set registry key " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>AddDevOverride

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
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("Error: Failed to disable registry key " & $sValueName & ".")
		LogWrite(1, "Error: Failed to remove registry key " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>RemoveDevOverride

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
EndFunc   ;==>ShowRebootPopup

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
EndFunc   ;==>ManageWinTrust

Func FindTrustEXEs()
	Local $foundApps = FindApps(True)
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
EndFunc   ;==>FindTrustEXEs

Func TrustEXEs()
	MemoWrite("Scanning for applications to trust...")
	Local $foundApps = FindApps(True)

	If UBound($foundApps) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("No applications found to trust at: " & $MyDefPath)
		LogWrite(1, "No applications found to trust at: " & $MyDefPath)
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
			Else
				FileDelete($dllPath)
				If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
					MemoWrite("Replaced wintrust.dll at: " & $dllPath)
					LogWrite(1, "Replaced wintrust.dll at: " & $dllPath)
					$successCount += 1
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
	ToggleLog(1)
EndFunc   ;==>TrustEXEs

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
		Else
			MemoWrite("Failed to untrust: " & $appName)
			LogWrite(1, "Failed to untrust: " & $appName)
		EndIf
	Next

	MemoWrite("Untrust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " application(s).")
	LogWrite(1, "Untrust completed. Successfully processed " & $successCount & " of " & UBound($SelectedApps) & " application(s).")
	ToggleLog(1)
EndFunc   ;==>UntrustEXEs

Func TrustSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("No applications found to " & StringLower($operation) & " at: " & $MyDefPath)
		LogWrite(1, "No applications found to " & StringLower($operation) & " at: " & $MyDefPath)
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
	AdlibRegister("CheckParentCheckboxes", 250)

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
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("Scanning for selected items...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						If StringInStr($itemText, ".exe") Then
							_ArrayAdd($selectedFiles, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, 3)
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
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>TrustSelectionGUI

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
EndFunc   ;==>ManageDevOverride

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func OpenWF()
	Local $sWFPath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $sWFPath)
	ConsoleWrite("Opening Windows Firewall...")
EndFunc   ;==>OpenWF
