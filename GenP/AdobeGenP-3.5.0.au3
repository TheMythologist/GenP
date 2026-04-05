#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=AdobeGenP.exe
#AutoIt3Wrapper_Res_Comment=AdobeGenP
#AutoIt3Wrapper_Res_CompanyName=AdobeGenp
#AutoIt3Wrapper_Res_Description=Adobe Generic Patcher
#AutoIt3Wrapper_Res_Fileversion=3.5.0.0
#AutoIt3Wrapper_Res_LegalCopyright=AdobeGenP 2025
#AutoIt3Wrapper_Res_LegalTradeMarks=AdobeGenP 2025
#AutoIt3Wrapper_Res_ProductName=AdobeGenP
#AutoIt3Wrapper_Res_ProductVersion=3.5.0
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Array.au3>
#include <ButtonConstants.au3>
#include <Crypt.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <GUITab.au3>
#include <Inet.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <ProgressConstants.au3>
#include <String.au3>
#include <WindowsConstants.au3>
#include <WinAPIProc.au3>
#include <WinAPI.au3>

AutoItSetOption("GUICloseOnESC", 0)  ;1=ESC closes, 0=ESC won't close

Global $g_Version = "v3.5.0"
Global $g_AppWndTitle = "AdobeGenP"
Global $g_AppVersion = "Original version by uncia - CGP Community Edition - " & $g_Version

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
Global $idBtnBlockPopUp, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAdobeFolders, $idBtnSaveOptions, $idCustomDomainListLabel, $idCustomDomainListInput
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF
;Global $idBtnCleanFirewall, $idBtnEnableDisableWF

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf

Global $MyDefPath = IniRead($sINIPath, "Default", "Path", @ProgramFilesDir)
If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	IniWrite($sINIPath, "Default", "Path", @ProgramFilesDir)
	$MyDefPath = @ProgramFilesDir
EndIf

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = IniRead($sINIPath, "Options", "EnableMD5", "1")
Global $bOnlyAdobeFolders = IniRead($sINIPath, "Options", "OnlyAdobeFolder", "1")

Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)

Local $tTargetFileList_Adobe = IniReadSection($sINIPath, "TargetFiles")
Global $TargetFileList_Adobe[0]
If Not @error Then
	ReDim $TargetFileList_Adobe[$tTargetFileList_Adobe[0][0]]
	For $i = 1 To $tTargetFileList_Adobe[0][0]
		$TargetFileList_Adobe[$i - 1] = StringReplace($tTargetFileList_Adobe[$i][1], '"', "")
	Next
EndIf
;_ArrayDisplay($TargetFileList_Adobe, "TargetFileList_Adobe")

$aSpecialFiles = IniReadSection($sINIPath, "CustomPatterns")
;_ArrayDisplay($aSpecialFiles)
For $i = 1 To UBound($aSpecialFiles) - 1
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
Next
;MsgBox(0, "", $sSpecialFiles)

If $CmdLine[0] = 1 And $CmdLine[1] = "-popup" Then
	; Directly call BlockPopUp then exit
	BlockPopUp()
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
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnCure, 128)

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
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
					GUICtrlSetState($idBtnBlockPopUp, 128)
					GUICtrlSetState($idBtnRestore, 64)
				EndIf
			Else
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			EndIf

			_Collapse_All_Click()
			;expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)

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


		Case $idMsg = $idBtnBlockPopUp
			ToggleLog(0)
			BlockPopUp()

		Case $idMsg = $idBtnCure
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
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
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "AdobeGenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
				LogWrite(1, "AdobeGenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
			EndIf

			ToggleLog(1)

			GUICtrlSetState($hLogTab, $GUI_SHOW)

		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "Activity Log (" & $g_Version & ")" & @CRLF)
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
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
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
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

		Case $idMsg = $idOnlyAdobeFolders
			If _IsChecked($idOnlyAdobeFolders) Then
				$bOnlyAdobeFolders = 1
			Else
				$bOnlyAdobeFolders = 0
			EndIf

		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

		Case $idMsg = $idBtnCleanHosts
			RemoveHostsEntries()

		Case $idMsg = $idBtnEditHosts
			EditHosts()

		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		Case $idMsg = $idBtnOpenWF
			OpenWF()

			;Case $idMsg = $idBtnCleanFirewall
			;	CleanFirewall()

			;Case $idMsg = $idBtnEnableDisableWF
			;	EnableDisableWFRules()

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

	$idButtonSearch = GUICtrlCreateButton("Search", 110, 430, 80, 30)
	GUICtrlSetTip(-1, "Search path for installed apps")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton("Stop", 110, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Stop search")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateButton("De/Select", 210, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "De/Select all files")
	GUICtrlSetImage(-1, "imageres.dll", -76, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton("Patch", 305, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Patch selected file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton("Restore", 405, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore original file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnBlockPopUp = GUICtrlCreateButton("Pop-up", 505, 430, 80, 30)
	GUICtrlSetTip(-1, "Block Unlicensed pop-up")
	GUICtrlSetImage(-1, "imageres.dll", -101, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 397, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	GUICtrlCreateLabel($g_AppVersion, 10, 477, 575, 25, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
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

	$idOnlyAdobeFolders = GUICtrlCreateCheckbox("Search for files only in Adobe/Acrobat folders", 10, 130, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAdobeFolders = 1 Then
		GUICtrlSetState($idOnlyAdobeFolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idOnlyAdobeFolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts List URL:", 10, 180, 100, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 90, 175, 490, 20, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 430, 100, 30)
	GUICtrlSetTip(-1, "Save options to config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("Pop-up Tools")

	$sRemoveAGSText = "ADOBE GENUINE SERVICE REMOVAL"

	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, 5, 40, 575, 20, $ES_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRemoveAGS = GUICtrlCreateButton("Remove AGS", 225, 65, 140, 30)
	GUICtrlSetTip(-1, "Delete AGS from computer")
	;GUICtrlSetImage(-1, "imageres.dll", 167, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$sEditHostsText = "MANAGE HOSTS"

	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, 5, 115, 575, 20, $ES_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCleanHosts = GUICtrlCreateButton("Clean hosts", 70, 140, 140, 30)
	GUICtrlSetTip(-1, "Remove hosts added by GenP")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnEditHosts = GUICtrlCreateButton("Edit hosts", 225, 140, 140, 30)
	GUICtrlSetTip(-1, "Edit hosts in notepad")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestoreHosts = GUICtrlCreateButton("Restore hosts", 380, 140, 140, 30)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore hosts from hosts.bak")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$sCleanFirewallText = "MANAGE WINDOWS FIREWALL"

	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, 5, 190, 575, 20, $ES_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", 225, 215, 140, 30)
	GUICtrlSetTip(-1, "Open Windows Firewall with Advanced Security console")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	;$idBtnCleanFirewall = GUICtrlCreateButton("Remove Firewall Rule", 235, 215, 140, 30)
	;GUICtrlSetTip(-1, "Delete Windows Firewall pop-up rule")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	;GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	;$idBtnEnableDisableWF = GUICtrlCreateButton("Enable/Disable Rule", 315, 443, 140, 30)
	;GUICtrlSetTip(-1, "Toggle Windows Firewall Unlicensed pop-up rule")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	;GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("Log")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "Activity Log (" & $g_Version & ")" & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("Copy", 257, 430, 80, 30)
	GUICtrlSetTip(-1, "Copy log to clipboard")
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateLabel($g_AppVersion, 10, 477, 575, 25, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")

	GUICtrlSetState($idButtonSearch, 256) ; Set focus
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>MainGui

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	;_FileListToArrayEx
	_GUICtrlListView_SetItemText($idListview, 1, "Searching for files.", 1)
	;_GUICtrlListView_SetItemGroupID($idListview, 0, 1)

	Local $RecursiveFileSearch_MaxDeep = 8
	; Local $RecursiveFileSearch_WhenFoundRaiseToLevel = 0 ;0 to disable raising
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
			; raise up in recursion to wanted level
;~ 			if ( $targetDepth > 0 ) and _
;~ 			 ( $targetDepth < $DEPTH ) Then _
;~ 				Return $targetDepth
		Else
			$IPATH = $STARTDIR & $NEXT
			Local $FileNameCropped, $PathToCheck
			If (IsArray($TargetFileList_Adobe)) Then
				For $AdobeFileTarget In $TargetFileList_Adobe

					If StringInStr($AdobeFileTarget, "$") Then
						;  split the string at the $ sign
						$AdobeFileTarget = StringSplit($AdobeFileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $AdobeFileTarget[2]
						$AdobeFileTarget = $AdobeFileTarget[1]

						;  ConsoleWrite($AdobeFileTarget & " / " & $PathToCheck & @CRLF)

					EndIf
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($AdobeFileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") Then
							;_ArrayAdd( $FilesToPatch, $DEPTH & " - " & $IPATH )
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAdobeFolders = 0 Then
								If $PathToCheck = "" Then
									_ArrayAdd($FilesToPatch, $IPATH)
								Else
									If StringInStr($IPATH, $PathToCheck) Then
										_ArrayAdd($FilesToPatch, $IPATH)
									EndIf
								EndIf
							EndIf
						Else
							_ArrayAdd($FilesToRestore, $IPATH)
						EndIf

						; File Found and stored - Quit search in current dir
;~ 					return $RecursiveFileSearch_WhenFoundRaiseToLevel
					EndIf
					$PathToCheck = ""
				Next
			EndIf
		EndIf
	WEnd

	;Lazy screenupdates
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
	For $i = 0 To 4
		_GUICtrlListView_AddItem($idListview, "", $i)
		_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
	Next

	_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
	_GUICtrlListView_AddSubItem($idListview, 1, "Adobe Generic Patcher", 1)
	_GUICtrlListView_AddSubItem($idListview, 2, '---------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 3, "Press 'Search' to find installed products; 'Patch' to patch selected products/files", 1)
	_GUICtrlListView_AddSubItem($idListview, 4, "Default search path: [Program Files] -- press 'Path' to change", 1)

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
		Local $iData = @CRLF & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " " & $sText
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
		GUICtrlSetState($idBtnBlockPopUp, 64)
		GUICtrlSetState($idBtnRestore, 128)
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

		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "File is 32bit. Aborting..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundAcro32 = True

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

		LogWrite(1, "File patched.")
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
		Return False
	EndIf

	If Not StringInStr($sHostsContent, $sMarkerStart) Or Not StringInStr($sHostsContent, $sMarkerEnd) Then
		LogWrite(1, "No Adobe entries to remove." & @CRLF)
		ToggleLog(1)
		Return True
	EndIf

	$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)" & $sMarkerStart & ".*?" & $sMarkerEnd, "")

	Local $hTempFile = FileOpen($sTempHosts, 2)
	If $hTempFile = -1 Then
		MemoWrite("Error creating temp hosts file for removal." & @CRLF)
		Return False
	EndIf
	FileWrite($hTempFile, $sHostsContent)
	FileClose($hTempFile)

	MemoWrite("Temp file created at: " & $sTempHosts & @CRLF)
	MemoWrite("Temp file content:" & @CRLF & FileRead($sTempHosts) & @CRLF)

	If Not FileCopy($sTempHosts, $sHostsPath, 1) Then
		MemoWrite("Error writing updated hosts file." & @CRLF)
		MemoWrite("Attempting to copy from: " & $sTempHosts & " to: " & $sHostsPath & @CRLF)
		FileDelete($sTempHosts)
		Return False
	EndIf
	FileDelete($sTempHosts)

	FileSetAttrib($sHostsPath, "+R")

	LogWrite(1, "Hosts file cleaned of existing entries." & @CRLF)
	ToggleLog(1)
	Return True
EndFunc   ;==>RemoveHostsEntries

Func BlockPopUp()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	RemoveHostsEntries()
	GUICtrlSetState($idBtnBlockPopUp, $GUI_DISABLE)
	MemoWrite(@CRLF & "Updating Hosts File..." & @CRLF)

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
			GUICtrlSetState($idBtnBlockPopUp, $GUI_ENABLE)
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
		GUICtrlSetState($idBtnBlockPopUp, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sDomainList = FileRead($sTempFileDownload)
	FileDelete($sTempFileDownload)
	MemoWrite("Downloaded list:" & @CRLF & $sDomainList & @CRLF)

	$sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("Error reading hosts file." & @CRLF)
		GUICtrlSetState($idBtnBlockPopUp, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf

	Local $sNewContent = $sMarkerStart & @CRLF & $sDomainList & @CRLF & $sMarkerEnd

	Local $hFile = FileOpen($sHostsPath, 17)
	If $hFile = -1 Then
		Local $iLastError = _WinAPI_GetLastError()
		MemoWrite("Error opening hosts file for appending: Last Error = " & $iLastError & @CRLF)
		GUICtrlSetState($idBtnBlockPopUp, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf

	If FileGetSize($sHostsPath) > 0 Then
		FileWrite($hFile, $sNewContent)
	Else
		FileWrite($hFile, $sNewContent)
	EndIf
	FileClose($hFile)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "Hosts file updated successfully." & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnBlockPopUp, $GUI_ENABLE)
EndFunc   ;==>BlockPopUp

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
			Case StringInStr($ItemFromList, "Photoshop")
				$sGroupName = "Photoshop"
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
	If _IsChecked($idOnlyAdobeFolders) Then
		IniWrite($sINIPath, "Options", "OnlyAdobeFolders", "1")
	Else
		IniWrite($sINIPath, "Options", "OnlyAdobeFolders", "0")
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

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func RemoveAGS()
	GUICtrlSetState($idBtnRemoveAGS, 128)
	_GUICtrlTab_SetCurFocus($hTab, 3)

	MemoWrite(@CRLF & "Removing AGS from this Computer" & @CRLF & "---" & @CRLF & "Please wait...")

	Local $aServicesToStop = ["AGMService", "AGSService"]
	For $sServiceName In $aServicesToStop
		If AGSServiceExists($sServiceName) Then
			If StopAGSService($sServiceName) Then
				LogWrite(1, $sServiceName & " stopped successfully.")
			Else
				LogWrite(1, "Failed to stop service: " & $sServiceName)
			EndIf

			If DeleteAGSService($sServiceName) Then
				LogWrite(1, $sServiceName & " deleted successfully.")
			Else
				LogWrite(1, "Failed to delete service: " & $sServiceName)
			EndIf
		Else
			LogWrite(1, "Service not found: " & $sServiceName)
		EndIf
	Next

	DeleteAGSFiles()

	LogWrite(1, "AGS removal completed." & @CRLF)
	ToggleLog(1)
EndFunc   ;==>RemoveAGS

Func StopAGSService($sServiceName)
	Local $hProcess = Run("sc stop " & $sServiceName, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	ProcessWaitClose($hProcess)
	Local $sOutput = StdoutRead($hProcess)

	If StringRegExp($sOutput, "STATE\s*:\s*3") Then
		For $i = 1 To 10
			Sleep(1000)
			$hProcess = Run("sc query " & $sServiceName, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
			ProcessWaitClose($hProcess)
			$sOutput = StdoutRead($hProcess)
			If StringRegExp($sOutput, "STATE\s*:\s*1") Then
				Return True
			EndIf
		Next
		Return False ; Timed out
	ElseIf StringRegExp($sOutput, "STATE\s*:\s*1") Then
		Return True ; Already stopped
	Else
		Return False ; Unexpected output
	EndIf
EndFunc   ;==>StopAGSService

Func DeleteAGSService($sServiceName)
	Local $hProcess = Run("sc delete " & $sServiceName, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	ProcessWaitClose($hProcess)
	Local $sOutput = StdoutRead($hProcess)

	If StringInStr($sOutput, "[SC] DeleteAGSService SUCCESS") Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>DeleteAGSService

Func AGSServiceExists($sServiceName)
	Local $hProcess = Run("sc query " & $sServiceName, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	ProcessWaitClose($hProcess)
	Local $sOutput = StdoutRead($hProcess)
	Return StringInStr($sOutput, "STATE")
EndFunc   ;==>AGSServiceExists

Func DeleteAGSFiles()
	Local $ProgramFilesX86 = EnvGet("ProgramFiles(x86)")
	Local $PublicDir = EnvGet("PUBLIC")
	Local $WinDir = @WindowsDir
	Local $LocalAppData = EnvGet("LOCALAPPDATA")

	Local $aPaths[9]
	$aPaths[0] = $ProgramFilesX86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe"
	$aPaths[1] = $ProgramFilesX86 & "\Common Files\Adobe\AdobeGCClient"
	$aPaths[2] = $ProgramFilesX86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient"
	$aPaths[3] = $PublicDir & "\Documents\AdobeGCData"
	$aPaths[4] = $WinDir & "\System32\Tasks\AdobeGCInvoker-1.0"
	$aPaths[5] = $WinDir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0"
	$aPaths[6] = $ProgramFilesX86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe"
	$aPaths[7] = $WinDir & "\Temp\adobegc.log"
	$aPaths[8] = $LocalAppData & "\Temp\adobegc.log"

	For $i = 0 To UBound($aPaths) - 1
		Local $sPath = $aPaths[$i]

		If FileExists($sPath) Then
			If StringInStr(FileGetAttrib($sPath), "D") Then
				If DirRemove($sPath, 1) Then
					LogWrite(1, "Deleted Directory: " & $sPath)
				Else
					LogWrite(1, "Failed to delete directory: " & $sPath)
				EndIf
			Else
				FileDelete($sPath)
				LogWrite(1, "Deleted File: " & $sPath)
			EndIf
		Else
			LogWrite(1, "File or folder not found: " & $sPath)
		EndIf
	Next
EndFunc   ;==>DeleteAGSFiles

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func EditHosts()
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	; Remove the read-only attribute
	FileSetAttrib($sHostsPath, "-R")

	; If the backup file doesn't exist, create it
	If Not FileExists($sBackupPath) Then
		FileCopy($sHostsPath, $sBackupPath)
	EndIf

	; Open the hosts file with Notepad
	Run("notepad.exe " & $sHostsPath)

	; Wait for the hosts file to be closed
	While ProcessExists("notepad.exe")
		Sleep(1000) ; Wait for 1 second
	WEnd

	; Reset the read-only attribute
	FileSetAttrib($sHostsPath, "+R")
EndFunc   ;==>EditHosts

Func RestoreHosts()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "Restoring the hosts file from backup..." & @CRLF & "---" & @CRLF & "Please wait..." & @CRLF)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	; If the backup file exists, restore it
	If FileExists($sBackupPath) Then
		; Remove the read-only attribute from the hosts file
		FileSetAttrib($sHostsPath, "-R")

		; Replace the hosts file with the backup file
		FileCopy($sBackupPath, $sHostsPath, 1)

		; Reset the read-only attribute
		FileSetAttrib($sHostsPath, "+R")

		; Delete the backup file
		FileDelete($sBackupPath)
		LogWrite(1, "Restoring the hosts file from backup: Commands completed successfully." & @CRLF)
	Else
		LogWrite(1, "Restoring the hosts file from backup: No backup file found." & @CRLF)
	EndIf
	ToggleLog(1)
EndFunc   ;==>RestoreHosts

;Func CleanFirewall()
;	_GUICtrlTab_SetCurFocus($hTab, 3)
;	Local $sCmdInfo = "netsh advfirewall firewall delete rule name=""Adobe Unlicensed Pop-up"""
;	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
;	Local $sOutput = ""
;	While 1
;		$sOutput &= StdoutRead($iPID)
;		If @error Then ExitLoop
;	WEnd
;	ProcessWaitClose($iPID)
;	LogWrite(1, "Removing Adobe Firewall Blocks:" & @CRLF & $sOutput & @CRLF)
;
;	ToggleLog(1)
;EndFunc    ;==>CleanFirewall

Func OpenWF()
	Local $sWFPath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $sWFPath)
	ConsoleWrite("Opening Windows Firewall...")
EndFunc   ;==>OpenWF

;Func EnableDisableWFRules()
;	_GUICtrlTab_SetCurFocus($hTab, 3)
;	MemoWrite(@CRLF & "Checking state of Windows Firewall Rules..." & @CRLF & "---" & @CRLF & "Please wait...")
;	Local $sCmdInfo = "PowerShell -NoProfile Set-ExecutionPolicy Bypass -scope Process -Force;try{$name = (Get-NetFirewallRule -DisplayName 'Adobe Unlicensed Pop-up').Name} catch{$name='no'};If($name -ne 'no'){(Get-NetFirewallRule -Name $name).Enabled};"
;	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
;	Local $sOutput = ""
;	While 1
;		$sOutput &= StdoutRead($iPID)
;		If @error Then ExitLoop
;	WEnd
;	ProcessWaitClose($iPID)
;
;	If StringInStr($sOutput, "True") > 0 Then
;		; If the rule is enabled, disable it
;		$sCmdInfo = 'netsh advfirewall firewall set rule name="Adobe Unlicensed Pop-up" new enable=no'
;		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
;		LogWrite(1, "Disabling Windows Firewall Rule: Adobe Unlicensed Pop-up" & @CRLF)
;	Else
;		; If the rule is disabled, enable it
;		$sCmdInfo = 'netsh advfirewall firewall set rule name="Adobe Unlicensed Pop-up" new enable=yes'
;		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
;		LogWrite(1, "Enabling Windows Firewall Rule: Adobe Unlicensed Pop-up" & @CRLF)
;	EndIf
;	Local $sOutput = ""
;	While 1
;		$sOutput &= StdoutRead($iPID)
;		If @error Then ExitLoop
;	WEnd
;	ProcessWaitClose($iPID)
;	LogWrite(0, "Windows Firewall Rule Status: " & $sOutput & @CRLF)
;	ToggleLog(1)
;EndFunc    ;==>EnableDisableWFRules
