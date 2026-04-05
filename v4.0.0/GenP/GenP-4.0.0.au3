#NoTrayIcon
#RequireAdmin
#Region
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=GenP-v4.0.0.exe
#AutoIt3Wrapper_Res_Comment=GenP
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_Description=GenP
#AutoIt3Wrapper_Res_Fileversion=4.0.0
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2026
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2026
#AutoIt3Wrapper_Res_ProductName=GenP
#AutoIt3Wrapper_Res_ProductVersion=4.0.0
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Run_Tidy=n
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=y
#EndRegion

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

Global $g_Version = "4.0.0"
Global $g_AppWndTitle = "GenP v" & $g_Version
Global $g_AppVersion = "GenP" & @CRLF & "Originally created by uncia"

Global $aChecked[0]

If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit
EndIf

Global $MyLVGroupIsExpanded = True
Global $g_aGroupIDs[0]
Global $fInterrupt = 0
Global $FilesToPatch[0][4], $FilesToPatchNull[0][4]
Global $FilesToRestore[0][1], $fFilesListed = 0
Global $g_FilesToPatchCount, $g_FilesToPatchCapacity, $g_WaitAnim = 0, $g_LastAnimUpdate = 0, $g_AppCount = 0, $g_LastAppFolder = "", $g_AppSeen[1]
Global Const $PATCH_STATE_UNKNOWN = 0, $PATCH_STATE_UNPATCHED = 1, $PATCH_STATE_PATCHED = 2
Global Const $STATE_PATCHED_TEXT = "[Patched]", $STATE_UNPATCHED_TEXT = "[Unpatched]"
Global $MyhGUI, $g_hGUI, $hGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview
Global $hOptionsTab, $hUnpackTab, $hWinTrustTab, $hHostsTab, $hAGSTab, $hFirewallTab, $g_aHoverButtons[18]
Global $idButtonSearch, $idButtonStop, $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag
Global $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC, $idEnableMD5, $idOnlyAFolders, $idGood1, $idShowBetaApps, $idBtnSaveOptions, $idOptionsReminder 
Global $idCustomDomainListLabel, $idCustomDomainListInput
Global $idBtnToggleRuntimeInstaller, $idLabelRuntimeInstaller, $sRuntimeInstallerText, $idBtnRuntimeInfo
Global $idBtnToggleWinTrust, $idBtnDevOverride, $idLabelWinTrust, $sWinTrustText, $idBtnWintrustInfo
Global $idBtnUpdateHosts, $idBtnEditHosts, $idBtnCleanHosts, $idBtnRestoreHosts, $idLabelEditHosts, $sEditHostsText, $idBtnHostsInfo
Global $idBtnRemoveAGS, $idLabelRemoveAGS, $sRemoveAGSText, $idBtnAGSInfo
Global $idBtnCreateFW, $idBtnToggleFW, $idBtnRemoveFW, $idBtnOpenWF, $idLabelCleanFirewall, $sCleanFirewallText, $idBtnFirewallInfo
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkUnpack, $g_idHyperlinkWinTrust, $g_idHyperlinkHosts, $g_idHyperlinkAGS, $g_idHyperlinkFirewall, $g_idHyperlinkLog
Global $g_dotCounter = 0
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

Global $BetaApps[]

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = IniRead($sINIPath, "Options", "EnableMD5", "1")
Global $bOnlyAFolders = IniRead($sINIPath, "Options", "OnlyDefaultFolders", "1")
Global $g_sEdition = IniRead($sINIPath, "Options", "Edition", "GenP")
Global $EnableGood1 = IniRead($sINIPath, "Options", "EnableGood1", "0")
Global $bShowBetaApps = IniRead($sINIPath, "Options", "ShowBetaApps", "0")

Global $g_sThirdPartyFirewall = ""
Global $fwc = ""
Global $SelectedApps = []

Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)

Global $g_OrigFindACC = $bFindACC
Global $g_OrigEnableMD5 = $bEnableMD5
Global $g_OrigOnlyAFolders = $bOnlyAFolders
Global $g_OrigGood1 = $EnableGood1
Global $g_OrigShowBetaApps = $bShowBetaApps

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

If Not @error Then
	Local $i
	For $i = 1 To UBound($aSpecialFiles) - 1
	If $aSpecialFiles[$i][0] = "Good1" And $EnableGood1 = 0 Then ContinueLoop
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
	Next
EndIf

Global $g_aSignature = "r~~z}D99""sus8nl%o|:8myw9qoxz7q sno}9"

If $CmdLine[0] = 1 And $CmdLine[1] = "-updatehosts" Then
	UpdateHostsFile()
	Exit
EndIf

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

Func CheckOptionsChanged()

	If $bFindACC <> $g_OrigFindACC _
 	Or $bEnableMD5 <> $g_OrigEnableMD5 _
	Or $bOnlyAFolders <> $g_OrigOnlyAFolders _
	Or $EnableGood1 <> $g_OrigGood1 _
	Or $bShowBetaApps <> $g_OrigShowBetaApps Then

        GUICtrlSetState($idBtnSaveOptions, $GUI_ENABLE)
	Else
        GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	EndIf

EndFunc

Func FixListViewWidth()
	Local $aGui = WinGetPos($MyhGUI)
	Local $iWidth = $aGui[2] - 75
	GUICtrlSendMsg($g_idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)
EndFunc

Func ResetMainListView()

    _SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)

    _GUICtrlListView_EnableGroupView($g_idListview, False)
    _GUICtrlListView_SetColumn($g_idListview, 1, "", 532)

    FillListViewWithInfo()
    FixListViewWidth()

    _SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
    _RedrawWindow($g_idListview)
    UpdateUIState()

EndFunc

Func _InitScanScreen()

    _GUICtrlListView_DeleteAllItems($g_idListview)
    _GUICtrlListView_RemoveAllGroups($g_idListview)
    _GUICtrlListView_EnableGroupView($g_idListview, True)

    _GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
    _GUICtrlListView_SetGroupInfo($g_idListview, 1, "Detected Applications", 1, 0)

    _GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

    For $i = 0 To 7
        _GUICtrlListView_AddItem($g_idListview, "", $i)
        _GUICtrlListView_SetItemGroupID($g_idListview, $i, 1)
    Next
    UpdateUIState()

EndFunc

Func _ShowStatusScreen($mode)

    For $i = 0 To 7
        _GUICtrlListView_SetItemText($g_idListview, $i, "", 1)
    Next
        _GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

    Switch $mode

        Case "complete"
            _GUICtrlListView_SetItemText($g_idListview, 2, "Scan complete.", 1)
            _GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
            _GUICtrlListView_SetItemText($g_idListview, 5, "Files scanned: " & _FormatNumber($FileSearchedCount), 1)
            _GUICtrlListView_SetItemText($g_idListview, 6, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
            _GUICtrlListView_SetItemText($g_idListview, 7, "Loading detected applications...", 1)

        Case "restore"
            _GUICtrlListView_SetItemText($g_idListview, 2, "Restore operation complete.", 1)

        Case "scanning"
            _GUICtrlListView_SetItemText($g_idListview, 1, _AnimatedDots("Scanning for installed applications"), 1)
            _GUICtrlListView_SetItemText($g_idListview, 2, "Searching...:", 1)
            _GUICtrlListView_SetItemText($g_idListview, 3, _AnimatedDots("Starting..."), 1)
            _GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
            _GUICtrlListView_SetItemText($g_idListview, 5, "Files scanned: " & _FormatNumber($FileSearchedCount), 1)
            _GUICtrlListView_SetItemText($g_idListview, 6, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
            _GUICtrlListView_SetItemText($g_idListview, 7, _AnimatedDots("Please wait"), 1)
            Sleep(10)

        Case "stopped"
            _GUICtrlListView_SetItemText($g_idListview, 2, "Scan stopped by user.", 1)

    EndSwitch

EndFunc

Func _ReturnToMain($seconds)

    For $i = $seconds To 1 Step -1
        _GUICtrlListView_SetItemText($g_idListview, 6, "Returning to main screen in " & $i & "...", 1)
        Sleep(1000)
    Next

    _GUICtrlTab_SetCurSel(GUICtrlGetHandle($hTab), 0)
    Sleep(100)

    ResetMainListView()

EndFunc

Func _FormatNumber($num)
    Return StringRegExpReplace($num, "(?<=\d)(?=(\d{3})+$)", ",")
EndFunc

Func _AppAlreadySeen($name)

For $i = 0 To UBound($g_AppSeen) - 1
    If $g_AppSeen[$i] = $name Then Return True
Next

ReDim $g_AppSeen[UBound($g_AppSeen) + 1]
$g_AppSeen[UBound($g_AppSeen) - 1] = $name
Return False

EndFunc

Func _HandleButtonHover()

    Static $iLastCtrl = 0

    Local $aCursor = GUIGetCursorInfo($g_hGUI)
    If Not IsArray($aCursor) Then Return

    Local $iCtrlID = $aCursor[4]

    If $iCtrlID = $iLastCtrl Then Return

    If $iLastCtrl <> 0 Then
        GUICtrlSetFont($iLastCtrl, 9, 400)
    EndIf

    For $i = 0 To UBound($g_aHoverButtons) - 1
        If $g_aHoverButtons[$i] = $iCtrlID Then
            If Not BitAND(GUICtrlGetState($iCtrlID), $GUI_DISABLE) Then
                GUICtrlSetFont($iCtrlID, 9, 700)
                $iLastCtrl = $iCtrlID
                Return
            EndIf
        EndIf
    Next

    $iLastCtrl = 0

EndFunc

Func UpdateUIState()

    Local $items = _GUICtrlListView_GetItemCount($g_idListview)

    If $items = 0 Then
        GUICtrlSetState($idBtnCure, $GUI_DISABLE)
        GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
        Return
    EndIf

    Local $bCanPatch = False
    Local $bCanRestore = False
    Local $state

    For $i = 0 To $items - 1

        If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then

            $state = _GUICtrlListView_GetItemParam($g_idListview, $i)

            Switch $state
                Case $PATCH_STATE_UNPATCHED
                    $bCanPatch = True

                Case $PATCH_STATE_PATCHED
                    $bCanRestore = True
            EndSwitch

        EndIf

        If $bCanPatch And $bCanRestore Then ExitLoop

    Next

    If $bCanPatch Then
        GUICtrlSetState($idBtnCure, $GUI_ENABLE)
    Else
        GUICtrlSetState($idBtnCure, $GUI_DISABLE)
    EndIf

    If $bCanRestore Then
        GUICtrlSetState($idBtnRestore, $GUI_ENABLE)
    Else
        GUICtrlSetState($idBtnRestore, $GUI_DISABLE)
    EndIf

EndFunc

Func _SetFilePatchState($file, $state)

    Local $count = _GUICtrlListView_GetItemCount($g_idListview)

    For $i = 0 To $count - 1

        Local $path = _GUICtrlListView_GetItemText($g_idListview, $i, 1)

        If $path = $file Then
            _GUICtrlListView_SetItemParam($g_idListview, $i, $state)
            ExitLoop
        EndIf

    Next

EndFunc

Func _FindListViewIndexByPath($sPath)

    Local $iCount = _GUICtrlListView_GetItemCount($g_idListview)

    For $i = 0 To $iCount - 1
        Local $sItemPath = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
        If $sItemPath = $sPath Then Return $i
    Next

    Return -1

EndFunc

Func DisplayFileStates()
    Local $sFileStateList = ""  ; This will hold the output for the message box
    Local $iItemCount = _GUICtrlListView_GetItemCount($g_idListview)

    If $iItemCount > 0 Then
        For $i = 0 To $iItemCount - 1
            Local $filePath = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
            Local $state = _GUICtrlListView_GetItemParam($g_idListview, $i)

            Local $stateDescription = ""
            Switch $state
                Case $PATCH_STATE_UNPATCHED
                    $stateDescription = "Unpatched"
                Case $PATCH_STATE_PATCHED
                    $stateDescription = "Patched"
                Case Else
                    $stateDescription = "Unknown"
            EndSwitch

            $sFileStateList &= $filePath & " - " & $stateDescription & @CRLF
        Next

        ;MsgBox($MB_SYSTEMMODAL, "File States", $sFileStateList) ; Commented out for background debugging - possible add and show in tool in future
    Else
        ;MsgBox($MB_SYSTEMMODAL, "No Files", "There are no files to display.") ; Commented out for background debugging - possible add and show in tool in future
    EndIf
EndFunc

Func DebugShowFileStates()

    Local $msg = ""
    Local $count = _GUICtrlListView_GetItemCount($g_idListview)

    For $i = 0 To $count - 1

        Local $file = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
        Local $state = _GUICtrlListView_GetItemParam($g_idListview, $i)

        Local $sState = "UNKNOWN"

        Switch $state
            Case $PATCH_STATE_UNPATCHED
                $sState = "UNPATCHED"

            Case $PATCH_STATE_PATCHED
                $sState = "PATCHED"
        EndSwitch

        $msg &= $i & " | " & $sState & " | " & $file & @CRLF

    Next

    ;MsgBox(0, "File States", $msg) ; Commented out for background debugging - possible add and show in tool in future

EndFunc

Func _AnimatedDots($text)
    Local $dots = StringRepeat(".", Mod($g_dotCounter, 3) + 1)
    $g_dotCounter += 1
    Return $text & $dots
EndFunc

Func StringRepeat($char, $count)
    Local $out = ""
    For $i = 1 To $count
        $out &= $char
    Next
    Return $out
EndFunc

Func _GetAppFolderName($path)
    Local $a = StringSplit(StringTrimRight($path, 1), "\")
    Return $a[$a[0]]
EndFunc

MainGui()

$g_aHoverButtons[0] = $idButtonCustomFolder
$g_aHoverButtons[1] = $idButtonSearch
$g_aHoverButtons[2] = $idButtonStop
$g_aHoverButtons[3] = $idBtnDeselectAll
$g_aHoverButtons[4] = $idBtnRestore
$g_aHoverButtons[5] = $idBtnSaveOptions
$g_aHoverButtons[6] = $idBtnToggleRuntimeInstaller
$g_aHoverButtons[7] = $idBtnToggleWinTrust
$g_aHoverButtons[8] = $idBtnDevOverride
$g_aHoverButtons[9] = $idBtnUpdateHosts
$g_aHoverButtons[10] = $idBtnEditHosts
$g_aHoverButtons[11] = $idBtnCleanHosts
$g_aHoverButtons[12] = $idBtnRestoreHosts
$g_aHoverButtons[13] = $idBtnRemoveAGS
$g_aHoverButtons[14] = $idBtnCreateFW
$g_aHoverButtons[15] = $idBtnToggleFW
$g_aHoverButtons[16] = $idBtnRemoveFW
$g_aHoverButtons[17] = $idBtnOpenWF

For $i = 0 To UBound($g_aHoverButtons) - 1
	GUICtrlSetCursor($g_aHoverButtons[$i], 0)
Next

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
	_HandleButtonHover()
	$idMsg = GUIGetMsg()
	Sleep(20)
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
			GUICtrlSendMsg($g_idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)

		Case $idMsg = $idButtonStop
			$fInterrupt = 1
			GUISetState(@SW_LOCK)
			Sleep(10)
			GUISetState(@SW_UNLOCK)
			$ListViewSelectFlag = 0
			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Ready for next action.")
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
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idEnableMD5, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idGood1, 64)
			GUICtrlSetState($idShowBetaApps, 64)

		Case $idMsg = $idButtonSearch

			Local $aChecked = _GetCheckedItems()
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
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idEnableMD5, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idGood1, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			_GUICtrlListView_DeleteAllItems($g_idListview)
			UpdateUIState()
			_GUICtrlListView_EnableGroupView($g_idListview, True)
			_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

			_GUICtrlListView_RemoveAllGroups($g_idListview)
			_GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
			_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Detected Applications", 1, 0)

			For $i = 0 To 7
			_GUICtrlListView_AddItem($g_idListview, "", $i)
			_GUICtrlListView_SetItemGroupID($g_idListview, $i, 1)
			Next

			$g_WaitAnim = 0
			$g_LastAppFolder = ""
			$g_AppCount = 0
			ReDim $g_AppSeen[1]
			_ShowStatusScreen("scanning")

			_Expand_All_Click()

			$g_FilesToPatchCount = 0
			$g_FilesToPatchCapacity = 250
			ReDim $FilesToPatch[$g_FilesToPatchCapacity][5]
			ReDim $FilesToRestore[0]

			$timestamp = TimerInit()

			Local $FileCount

			Local $sAppsPanelDir = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
			Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)
			If UBound($aSize) >= 2 Then
					$FileCount = $aSize[1]
					RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)
					ProgressWrite(0)
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

			If $fInterrupt Then

			_GUICtrlListView_DeleteAllItems($g_idListview)
			UpdateUIState()
			_GUICtrlListView_RemoveAllGroups($g_idListview)
			_GUICtrlListView_EnableGroupView($g_idListview, True)

			_GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
			_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Detected Applications", 1, 0)

			For $i = 0 To 7
			_GUICtrlListView_AddItem($g_idListview, "", $i)
			_GUICtrlListView_SetItemGroupID($g_idListview, $i, 1)
			Next

			_ShowStatusScreen("stopped")
			ProgressWrite(0)
			_ReturnToMain(3)
			_GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)

			$fInterrupt = 0
			ContinueLoop
			
			EndIf

			If $g_FilesToPatchCount > 0 Then
				ReDim $FilesToPatch[$g_FilesToPatchCount][5]
			Else
				ReDim $FilesToPatch[0][5]
			EndIf

			_GUICtrlListView_DeleteAllItems($g_idListview)
			UpdateUIState()
			_GUICtrlListView_RemoveAllGroups($g_idListview)
			_GUICtrlListView_EnableGroupView($g_idListview, True)

			_GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
			_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Detected Applications", 1, 0)

			_GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

			For $i = 0 To 7
			_GUICtrlListView_AddItem($g_idListview, "", $i)
			_GUICtrlListView_SetItemGroupID($g_idListview, $i, 1)
			Next

			_ShowStatusScreen("complete")

			Sleep(2500)

			FillListViewWithFiles()
			UpdateUIState()
			DebugShowFileStates()
			DisplayFileStates()
			_GUICtrlListView_SetExtendedListViewStyle($g_idListview, _
			BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
			_RestoreCheckedItems($aChecked)

			If _GUICtrlListView_GetItemCount($g_idListview) > 0 Then

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
					GUICtrlSetState($idFindACC, 128)
					GUICtrlSetState($idEnableMD5, 128)
					GUICtrlSetState($idOnlyAFolders, 128)
					GUICtrlSetState($idGood1, 128)
					GUICtrlSetState($idShowBetaApps, 128)
				EndIf
			Else
				$ListViewSelectFlag = 0
				ResetMainListView()
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
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idEnableMD5, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idGood1, 64)
			GUICtrlSetState($idShowBetaApps, 64)

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
 			_GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

		Case $idMsg = $idBtnDeselectAll
			ToggleLog(0)
			If $ListViewSelectFlag = 1 Then
				For $i = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
					_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
				Next
				$ListViewSelectFlag = 0   
			Else
				For $i = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
					_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
				Next
				$ListViewSelectFlag = 1   
			EndIf
			UpdateUIState()

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
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idEnableMD5, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idGood1, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($g_idListview, 0, 0)
			_GUICtrlListView_SetItemSelected($g_idListview, 0, False, False)
			MemoWrite(@CRLF & "Starting patch process...")
			ProgressWrite(0)
			Local $ItemFromList
			For $i = _GUICtrlListView_GetItemCount($g_idListview) - 1 To 0 Step -1
			Sleep(0)
				If _GUICtrlListView_GetItemChecked($g_idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($g_idListview, $i, True, True)
					_GUICtrlListView_EnsureVisible($g_idListview, $i, True)
					$ItemFromList = _GUICtrlListView_GetItemText($g_idListview, $i, 1)

					MyGlobalPatternSearch($ItemFromList)
					ProgressWrite(0)
					Sleep(10)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "Applying patch...")
					LogWrite(1, $ItemFromList)
					Sleep(10)

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)

					_GUICtrlListView_SetItemParam($g_idListview, $i, $PATCH_STATE_PATCHED)
					_GUICtrlListView_SetItemText($g_idListview, $i, $STATE_PATCHED_TEXT, 2)

					_GUICtrlListView_SetItemChecked($g_idListview, $i, False)
					_GUICtrlListView_SetItemSelected($g_idListview, $i, False, False)
					_GUICtrlListView_EnsureVisible($g_idListview, $i, True)
					Sleep(10)

				EndIf

			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))


			_GUICtrlListView_RemoveAllGroups($g_idListview)
			_GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
			_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Patch Results", 1, 0)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Ready for next action")
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
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idEnableMD5, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idGood1, 64)
			GUICtrlSetState($idShowBetaApps, 64)

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Acrobat 32-bit Not Supported", "GenP does not support patching the 32-bit version of Acrobat. Please use the 64-bit version instead.")
				LogWrite(1, "GenP does not support patching the 32-bit version of Acrobat. Please use the 64-bit version instead.")
			EndIf
			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "ARM Not Supported", "This GenP build does not support ARM binaries. Only x64 binaries are supported.")
				LogWrite(1, "This GenP build does not support ARM binaries. Only x64 binaries are supported.")
			EndIf

			ResetMainListView()
			UpdateUIState()
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
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idEnableMD5, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idGood1, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($g_idListview, 0, 0)

			MemoWrite(@CRLF & "Starting restore process...")
			ProgressWrite(0)
			Local $iCheckedItems = 0
			For $x = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
			If _GUICtrlListView_GetItemChecked($g_idListview, $x) Then $iCheckedItems += 1
			Next

			Local $ItemFromList
			Local $iStep = 0
			Local $iProgress = 0
			If $iCheckedItems > 0 Then $iStep = 100 / $iCheckedItems

			For $i = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
			Sleep(1)
			If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then

			_GUICtrlListView_SetItemSelected($g_idListview, $i, True, False)

			$ItemFromList = _GUICtrlListView_GetItemText($g_idListview, $i, 1)

			RestoreFile($ItemFromList)

			$iProgress += $iStep
			ProgressWrite($iProgress)
			Sleep(100)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "Restoring original file...")

			Sleep(100)

			_GUICtrlListView_EnsureVisible($g_idListview, $i, False)
			Sleep(100)

			EndIf

			_GUICtrlListView_SetItemChecked($g_idListview, $i, False)

			Next
			ProgressWrite(100)
			MemoWrite(@CRLF & "Restore process completed.")
			Sleep(100)
			ProgressWrite(0)

			_GUICtrlListView_DeleteAllItems($g_idListview)
			UpdateUIState()
			_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

			_GUICtrlListView_RemoveAllGroups($g_idListview)
			_GUICtrlListView_InsertGroup($g_idListview, -1, 1, "")
			_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Restore Results", 1, 0)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Ready for next action")
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
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idEnableMD5, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idGood1, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			ResetMainListView()
			_GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)
			ToggleLog(1)
			GUICtrlSetState($hLogTab, $GUI_SHOW)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf
			CheckOptionsChanged()
			UpdateUIState()

		Case $idMsg = $idEnableMD5
			If _IsChecked($idEnableMD5) Then
				$bEnableMD5 = 1
			Else
				$bEnableMD5 = 0
			EndIf
			CheckOptionsChanged()
			UpdateUIState()

		Case $idMsg = $idOnlyAFolders
			If _IsChecked($idOnlyAFolders) Then
				$bOnlyAFolders = 1
			Else
				$bOnlyAFolders = 0
			EndIf
			CheckOptionsChanged()
			UpdateUIState()

		Case $idMsg = $idGood1
			If _IsChecked($idGood1) Then
				$EnableGood1 = 1
			Else
				$EnableGood1 = 0
			EndIf
			IniWrite($sINIPath, "Options", "EnableGood1", $EnableGood1)
			CheckOptionsChanged()
			UpdateUIState()

			Local $aChecked[0]
			Local $iItemCount = _GUICtrlListView_GetItemCount($g_idListview)
			For $i = 0 To $iItemCount - 1
			If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then
			_ArrayAdd($aChecked, _GUICtrlListView_GetItemText($g_idListview, $i, 1))
			EndIf
			Next

			_GUICtrlListView_BeginUpdate($g_idListview)
			FillListViewWithFiles()
			_GUICtrlListView_EndUpdate($g_idListview)

			_RestoreCheckedItems($aChecked)

		Case $idMsg = $idShowBetaApps
			If _IsChecked($idShowBetaApps) Then
				$bShowBetaApps = 1
			Else
				$bShowBetaApps = 0
			EndIf
			CheckOptionsChanged()
			UpdateUIState()

			Local $aChecked[0]
			Local $iItemCount = _GUICtrlListView_GetItemCount($g_idListview)
			For $i = 0 To $iItemCount - 1
			If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then
			_ArrayAdd($aChecked, _GUICtrlListView_GetItemText($g_idListview, $i, 1))
			EndIf
			Next

			Local $iTopIndex = _GUICtrlListView_GetTopIndex($g_idListview)
			Local $iGroupCount = _GUICtrlListView_GetGroupCount($g_idListview)
			Local $aGroupState[0]

			If $iGroupCount > 0 Then
			ReDim $aGroupState[$iGroupCount]
			For $g = 0 To $iGroupCount - 1
			Local $tGroup = _GUICtrlListView_GetGroupInfo($g_idListview, $g)
			$aGroupState[$g] = BitAND(DllStructGetData($tGroup, "State"), $LVGS_COLLAPSED)
			Next
			EndIf

			_GUICtrlListView_BeginUpdate($g_idListview)
			FillListViewWithFiles()
			_GUICtrlListView_EndUpdate($g_idListview)

			_RestoreCheckedItems($aChecked)
			_GUICtrlListView_EnsureVisible($g_idListview, $iTopIndex, False)

			Local $iNewGroupCount = _GUICtrlListView_GetGroupCount($g_idListview)
			If $iNewGroupCount > 0 Then
			For $g = 0 To $iNewGroupCount - 1
			If $g < UBound($aGroupState) And $aGroupState[$g] <> 0 Then
			_GUICtrlListView_SetGroupInfo($g_idListview, $g, "", BitOR($LVGS_COLLAPSIBLE, $LVGS_COLLAPSED))
			EndIf
			Next
			EndIf

		Case $idMsg = $idBtnSaveOptions
			Local $aChecked[0]
			Local $iItemCount = _GUICtrlListView_GetItemCount($g_idListview)
 			For $i = 0 To $iItemCount - 1
			If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then
 			_ArrayAdd($aChecked, _GUICtrlListView_GetItemText($g_idListview, $i, 1))
			EndIf
			Next

			SaveOptionsToConfig()
			$g_OrigFindACC = $bFindACC
			$g_OrigEnableMD5 = $bEnableMD5
			$g_OrigOnlyAFolders = $bOnlyAFolders
			$g_OrigGood1 = $EnableGood1
			$g_OrigShowBetaApps = $bShowBetaApps
			CheckOptionsChanged()

			_GUICtrlListView_BeginUpdate($g_idListview)
			FillListViewWithFiles()
			_GUICtrlListView_EndUpdate($g_idListview)
 			_RestoreCheckedItems($aChecked)

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

		Case $idMsg = $idBtnToggleRuntimeInstaller
			ToggleLog(0)
			UnpackRuntimeInstallers()

		Case $idMsg = $idBtnToggleWinTrust
			ToggleLog(0)
			ManageWinTrust()

		Case $idMsg = $idBtnDevOverride
			ToggleLog(0)
			ManageDevOverride()

		Case $g_idListview
			UpdateUIState()
	EndSelect
	Sleep(10)
WEnd

Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 510, -1, -1, BitOR($WS_MAXIMIZEBOX, $WS_MINIMIZEBOX, $WS_SIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 510, $TCS_FIXEDWIDTH)
	_SendMessage(GUICtrlGetHandle($hTab), 0x1329, 0, 74)

	$hMainTab = GUICtrlCreateTabItem("Main")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 355)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
	$iStyles = _WinAPI_GetWindowLong($MyhGUI, $GWL_STYLE)
	_WinAPI_SetWindowLong($MyhGUI, $GWL_STYLE, BitXOR($iStyles, $WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX))

	_GUICtrlListView_SetItemCount($g_idListview, $g_FilesToPatchCount)
	_GUICtrlListView_AddColumn($g_idListview, "", 20)
	_GUICtrlListView_AddColumn($g_idListview, "", 532, 2)

	_GUICtrlListView_EnableGroupView($g_idListview)
	_GUICtrlListView_InsertGroup($g_idListview, -1, 0, "", 1)
	_GUICtrlListView_EnableGroupView($g_idListview, False)

	FillListViewWithInfo()

	_RestoreCheckedItems($aChecked)

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
	GUICtrlSetFont($idBtnCure, 10, 700)
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

	$idProgressBar = GUICtrlCreateProgress(10, 397, 575, 25, $PBS_SMOOTH)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetData($idProgressBar, 0)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idProgressBar), "", "")
	GUICtrlSetColor($idProgressBar, 0x0078D7)

	$g_idHyperlinkMain = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("Options")

	GUICtrlCreateGroup("Scan Options", 5, 35, 585, 130)

	$idFindACC = GUICtrlCreateCheckbox("Always search for ACC", 15, 55, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then
		GUICtrlSetState($idFindACC, $GUI_CHECKED)
	Else
		GUICtrlSetState($idFindACC, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateCheckbox("Enable MD5 Checksum", 15, 85, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableMD5 = 1 Then
		GUICtrlSetState($idEnableMD5, $GUI_CHECKED)
	Else
		GUICtrlSetState($idEnableMD5, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idOnlyAFolders = GUICtrlCreateCheckbox("Search in default named folders only", 15, 115, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then
		GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idOnlyAFolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Patch Options", 5, 175, 585, 100)

	$idGood1 = GUICtrlCreateCheckbox("Enable Good Patch", 15, 195, 300, 25, _
		BitOR($BS_AUTOCHECKBOX, $BS_LEFT))

	If $EnableGood1 = 1 Then
		GUICtrlSetState($idGood1, $GUI_CHECKED)
	Else
		GUICtrlSetState($idGood1, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idShowBetaApps = GUICtrlCreateCheckbox("Show Beta Apps", 15, 225, 300, 25, _
		BitOR($BS_AUTOCHECKBOX, $BS_LEFT))

	If $bShowBetaApps = 1 Then
		GUICtrlSetState($idShowBetaApps, $GUI_CHECKED)
	Else
		GUICtrlSetState($idShowBetaApps, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts List URL:", 10, 295, 100, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 110, 290, 470, 20, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)
	GUICtrlSetResizing($idCustomDomainListInput, $GUI_DOCKWIDTH)

	$idOptionsReminder = GUICtrlCreateLabel("Changes will not take effect until saved", 10, 400, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idOptionsReminder, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idOptionsReminder, 0x444444)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 430, 100, 30)
	GUICtrlSetTip(-1, "Save options to config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkOptions, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkOptions, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkOptions, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkOptions, 0)

	GUICtrlCreateTabItem("")

	$hUnpackTab = GUICtrlCreateTabItem("Unpack")

	$sRuntimeInstallerText = "RUNTIME INSTALLER"
	$idLabelRuntimeInstaller = GUICtrlCreateLabel($sRuntimeInstallerText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRuntimeInstaller, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnToggleRuntimeInstaller = GUICtrlCreateButton("Unpack", (595 - 140) / 2, 90, 140, 30)
	GUICtrlSetTip(-1, "Unpack RuntimeInstaller.dll")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idLabelInfo = GUICtrlCreateLabel( _
	    "Some Adobe components, such as RuntimeInstaller.dll, may be compressed using the UPX format." & @CRLF & @CRLF & _
	    "This compression can interfere with patching and cause unexpected popups." & @CRLF & @CRLF & _
	    "Unpacking these files allows them to be properly modified so the patch can be applied correctly." & @CRLF & @CRLF & _
	    "This helps reduce runtime errors, missing functionality, or popups after patching.", _
	    (595 - 580) / 2, 320, 580, 120, $SS_CENTER)
	GUICtrlSetFont($idLabelInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($idLabelInfo, $GUI_DOCKAUTO)

	$g_idHyperlinkUnpack = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkUnpack, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkUnpack, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkUnpack, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkUnpack, 0)

	GUICtrlCreateTabItem("") 

	$hWinTrustTab = GUICtrlCreateTabItem("WinTrust")

	$sWinTrustText = "WINTRUST"
	$idLabelWinTrust = GUICtrlCreateLabel($sWinTrustText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelWinTrust, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnToggleWinTrust = GUICtrlCreateButton("Toggle WinTrust", (595 - 140) / 2, 90, 140, 30)
	GUICtrlSetTip(-1, "Enable/disable wintrust.dll override")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnToggleWinTrust, 9, 400, 0, "Segoe UI")

	$idBtnDevOverride = GUICtrlCreateButton("Toggle Reg Key", (595 - 140) / 2, 125, 140, 30)
	GUICtrlSetTip(-1, "Add/remove DevOverrideEnable registry key")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnDevOverride, 9, 400, 0, "Segoe UI")

	$idLabelInfo = GUICtrlCreateLabel( _ 
	    "Reduce popups by trusting applications that use DLL redirection." & @CRLF & @CRLF & _
	    "This feature manages the required registry entry automatically." & @CRLF & @CRLF & _
	    "You can trust or untrust applications at any time as needed." & @CRLF & @CRLF & _
	    "Credit to Team V.R.", _
	    (595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont($idLabelInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($idLabelInfo, $GUI_DOCKAUTO)

	$g_idHyperlinkWinTrust = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkWinTrust, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkWinTrust, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkWinTrust, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkWinTrust, 0)

	GUICtrlCreateTabItem("") 

	$hHostsTab = GUICtrlCreateTabItem("Hosts")

	$sEditHostsText = "HOSTS"
	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnUpdateHosts = GUICtrlCreateButton("Update hosts", (595 - 140) / 2, 90, 140, 30)
	GUICtrlSetTip(-1, "Update hosts with domains from hosts list URL")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnUpdateHosts, 9, 400, 0, "Segoe UI")

	$idBtnEditHosts = GUICtrlCreateButton("Edit hosts", (595 - 140) / 2, 125, 140, 30)
	GUICtrlSetTip(-1, "Manually edit hosts in notepad")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnEditHosts, 9, 400, 0, "Segoe UI")

	$idBtnCleanHosts = GUICtrlCreateButton("Clean hosts", (595 - 140) / 2, 160, 140, 30)
	GUICtrlSetTip(-1, "Remove hosts added by GenP")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnCleanHosts, 9, 400, 0, "Segoe UI")

	$idBtnRestoreHosts = GUICtrlCreateButton("Restore hosts", (595 - 140) / 2, 195, 140, 30)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore hosts from hosts.bak")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnRestoreHosts, 9, 400, 0, "Segoe UI")

	$idLabelInfo = GUICtrlCreateLabel( _ 
	    "Manage the hosts file to block domains associated with popups." & @CRLF & @CRLF & _
	    "Update the hosts file automatically from a list URL, edit it manually, or restore a backup." & @CRLF & @CRLF & _
	    "Keeping the hosts file updated helps maintain protection over time.", _
	    (595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont($idLabelInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($idLabelInfo, $GUI_DOCKAUTO)

	$g_idHyperlinkHosts = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkHosts, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkHosts, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkHosts, 0)

	GUICtrlCreateTabItem("") 

	$hAGSTab = GUICtrlCreateTabItem("AGS")

	$sRemoveAGSText = "GENUINE SERVICES"
	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRemoveAGS = GUICtrlCreateButton("Remove AGS", (595 - 140) / 2, 90, 140, 30)
	GUICtrlSetTip(-1, "Remove Genuine Services files/services to remove popup")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnRemoveAGS, 9, 400, 0, "Segoe UI")

	$idLabelInfo = GUICtrlCreateLabel( _ 
	    "Disables the 'Genuine Service Alert' popup by removing the related Genuine Service components." & @CRLF & @CRLF & _
	    "This only affects alerts with 'Genuine Service Alert' in the window title.", _
	    (595 - 580) / 2, 320, 580, 80, $SS_CENTER)
	GUICtrlSetFont($idLabelInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($idLabelInfo, $GUI_DOCKAUTO)

	$g_idHyperlinkAGS = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkAGS, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkAGS, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkAGS, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkAGS, 0)

	GUICtrlCreateTabItem("") 

	$hFirewallTab = GUICtrlCreateTabItem("Firewall")

	$sCleanFirewallText = "FIREWALL"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCreateFW = GUICtrlCreateButton("Add Rules", (595 - 140) / 2, 90, 140, 30)
	GUICtrlSetTip(-1, "Add new firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnToggleFW = GUICtrlCreateButton("Toggle Rules", (595 - 140) / 2, 125, 140, 30)
	GUICtrlSetTip(-1, "Enable/Disable all GenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRemoveFW = GUICtrlCreateButton("Remove Rules", (595 - 140) / 2, 160, 140, 30)
	GUICtrlSetTip(-1, "Remove all GenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", (595 - 140) / 2, 195, 140, 30)
	GUICtrlSetTip(-1, "Open Windows Firewall with Advanced Security console")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idLabelInfo = GUICtrlCreateLabel( _ 
	    "Manage Windows Firewall rules to block applications from internet access, which may reduce popups." & @CRLF & @CRLF & _
	    "Add or remove outbound rules, enable or disable them, or delete all rules." & @CRLF & @CRLF & _
	    "Note: Some application features may not function when internet access is blocked.", _
	    (595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont($idLabelInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing($idLabelInfo, $GUI_DOCKAUTO)

	$g_idHyperlinkFirewall = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkFirewall, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkFirewall, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkFirewall, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkFirewall, 0)

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

	$g_idHyperlinkLog = GUICtrlCreateLabel("GenP Wiki && Guides", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Ready for next action")

	GUICtrlSetState($idButtonSearch, 256) ; Set focus
	GUISetState(@SW_SHOW)
	CheckOptionsChanged()
	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>MainGui

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	Local $HSEARCH
	If $fInterrupt Then Return
	Local $RecursiveFileSearch_MaxDeep = 8
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

	Local $STARTDIR = $INSTARTDIR & "\"
	$FileSearchedCount += 1

	$HSEARCH = FileFindFirstFile($STARTDIR & "*.*")
	If @error Then Return

	Local $NEXT, $IPATH, $isDir

	While 1
		If $fInterrupt Then
			FileClose($HSEARCH)
 			Return
		EndIf
		
		$NEXT = FileFindNextFile($HSEARCH)
		If @error Then ExitLoop
		If $NEXT = "." Or $NEXT = ".." Then ContinueLoop
		$FileSearchedCount += 1

		; Animate "Please wait..." every 25 files
		If Mod($FileSearchedCount, 25) = 0 Then
			If TimerDiff($g_LastAnimUpdate) > 350 Then
				$g_LastAnimUpdate = TimerInit()
				$g_WaitAnim += 1
				If $g_WaitAnim > 3 Then $g_WaitAnim = 0
				Local $dots = StringRepeat(".", $g_WaitAnim)

				_GUICtrlListView_SetItemText($g_idListview, 4, "Applications found: " & $g_AppCount, 1)
				_GUICtrlListView_SetItemText($g_idListview, 5, "Files scanned: " & _FormatNumber($FileSearchedCount), 1)
				_GUICtrlListView_SetItemText($g_idListview, 6, "Files eligible: " & _FormatNumber($g_FilesToPatchCount), 1)
				_GUICtrlListView_SetItemText($g_idListview, 7, "Please wait" & $dots, 1)
				Sleep(1)
			EndIf
		EndIf

		$isDir = StringInStr(FileGetAttrib($STARTDIR & $NEXT), "D")
		If $isDir Then
			If $fInterrupt Then ExitLoop
			RecursiveFileSearch($STARTDIR & $NEXT, $DEPTH + 1, $FileCount)
			If $fInterrupt Then ExitLoop
		Else
			$IPATH = $STARTDIR & $NEXT

			; Track .bak files and mark as patched
			If StringRight(StringLower($IPATH), 4) = ".bak" Then
			_SetFilePatchState($IPATH, $PATCH_STATE_PATCHED) ; Mark the file as patched
			If _ArraySearch($FilesToRestore, $IPATH) = -1 Then
			_ArrayAdd($FilesToRestore, $IPATH)
			EndIf
			ContinueLoop
			EndIf

			Local $FileNameCropped, $PathToCheck
			If IsArray($TargetFileList) Then
				For $FileTarget In $TargetFileList
					If $fInterrupt Then ExitLoop
					$PathToCheck = ""
					If StringInStr($FileTarget, "$") Then
						$FileTarget = StringSplit($FileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $FileTarget[2]
						$FileTarget = $FileTarget[1]
					EndIf

					If StringLower($NEXT) = StringLower($FileTarget) Then
						If Not StringInStr(StringLower($IPATH), "wintrust") Then
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAFolders = 0 Then
								
								Local $bAddFile = False
								If $PathToCheck = "" Or StringInStr($IPATH, $PathToCheck) Then $bAddFile = True

								; Keep  good patch  files in memory
								Local $requiresGood1 = False
								If StringInStr($IPATH, "dynamic-torqnative.dll") Or _
								   StringInStr($IPATH, "dynamic-torqnative.dll.i64") Or _
								   StringInStr($IPATH, "lec.dll") Then $requiresGood1 = True

								If $bAddFile Then
									If $g_FilesToPatchCount >= $g_FilesToPatchCapacity Then
										$g_FilesToPatchCapacity += 100
 										ReDim $FilesToPatch[$g_FilesToPatchCapacity][5]
									EndIf

									$FilesToPatch[$g_FilesToPatchCount][0] = $IPATH
									$FilesToPatch[$g_FilesToPatchCount][1] = StringInStr($IPATH, "(Beta)", 2) > 0
									$FilesToPatch[$g_FilesToPatchCount][2] = StringInStr($IPATH, "Common Files\Adobe") > 0

									; Determine GUI folder name
									Local $groupName = "Unknown"
									Local $isBeta = StringInStr($IPATH, "(Beta)", 2) > 0

									If StringInStr($IPATH, "Common Files\Adobe\Adobe Desktop Common") Then
										$groupName = "Creative Cloud"
									Else
										Local $parts = StringSplit($IPATH, "\")
										For $j = 1 To $parts[0]
											If StringLower($parts[$j]) = "adobe" And $j+1 <= $parts[0] Then
												$groupName = StringRegExpReplace($parts[$j+1], "^Adobe\s+", "")
												If $isBeta And Not StringInStr($groupName, "(Beta)") Then $groupName &= " (Beta)"
												ExitLoop
											EndIf
										Next
									EndIf

									$FilesToPatch[$g_FilesToPatchCount][3] = $groupName
									$FilesToPatch[$g_FilesToPatchCount][4] = $requiresGood1

									If Not _AppAlreadySeen($groupName) Then $g_AppCount += 1

									; Update GUI only on folder change
									If $groupName <> $g_LastAppFolder Then
										$g_LastAppFolder = $groupName
										_GUICtrlListView_SetItemText($g_idListview, 3, $groupName, 1)
									EndIf

									$g_FilesToPatchCount += 1
								EndIf
							EndIf
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	WEnd

	; Log progress occasionally
	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "Searching in " & $FileCount & " files" & @TAB & "Found: " & $g_FilesToPatchCount & @CRLF & _
				"---" & @CRLF & _
				"Level: " & $DEPTH & " Time elapsed: " & Round(TimerDiff($timestamp)/1000,0) & " sec" & @TAB & "Excluded *.bak: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
	EndIf

	FileClose($HSEARCH)
EndFunc

Func FillListViewWithInfo()

    _GUICtrlListView_DeleteAllItems($g_idListview)
    _GUICtrlListView_RemoveAllGroups($g_idListview)

    _GUICtrlListView_InsertGroup($g_idListview, -1, 1, "", 1)
    _GUICtrlListView_SetGroupInfo($g_idListview, 1, "Detected Applications", 1, 0)

    _GUICtrlListView_SetExtendedListViewStyle($g_idListview, _
       BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))

    Local $sTitle = "GenP v4.0.0"

    Local $sOptionsLine = ""

    If Number($EnableGood1) Then
        $sOptionsLine &= "Good1 patch enabled"
    EndIf

    If Number($bShowBetaApps) Then
        If $sOptionsLine <> "" Then $sOptionsLine &= " / "
        $sOptionsLine &= "Beta apps included"
    EndIf

    Local $iTotalRows = 13
    If $sOptionsLine <> "" Then $iTotalRows += 1

    For $i = 0 To $iTotalRows - 1
        Local $idx = _GUICtrlListView_AddItem($g_idListview, "", $i)
        _GUICtrlListView_SetItemGroupID($g_idListview, $idx, 1)
    Next

    _GUICtrlListView_AddSubItem($g_idListview, 0, "", 1)
    _GUICtrlListView_AddSubItem($g_idListview, 1, "GenP", 1)
    _GUICtrlListView_AddSubItem($g_idListview, 2, "Originally created by uncia", 1)
    _GUICtrlListView_AddSubItem($g_idListview, 3, "", 1)
    _GUICtrlListView_AddSubItem($g_idListview, 4, "--------------------", 1)
    _GUICtrlListView_AddSubItem($g_idListview, 5, $sTitle, 1)

    Local $line = 6

    If $sOptionsLine <> "" Then
        _GUICtrlListView_AddSubItem($g_idListview, $line, $sOptionsLine, 1)
        $line += 1
    EndIf

    _GUICtrlListView_AddSubItem($g_idListview, $line, "--------------------", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, "", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, _
        "Current search path:", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, _
        $MyDefPath, 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, "", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, _
        "Press 'Path' to change the search location", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, _
        "Press 'Search' to scan for installed applications", 1)
    $line += 1

    _GUICtrlListView_AddSubItem($g_idListview, $line, _
        "Press 'Patch' to apply patches to selected files", 1)
    $line += 1

    If $bShowBetaApps = 1 Then
        For $i = 0 To UBound($BetaApps) - 1
            _GUICtrlListView_AddSubItem($g_idListview, $line, $BetaApps[$i] & " (Beta)", 1)
            $line += 1
        Next
    EndIf

    $fFilesListed = 0
    UpdateUIState()

EndFunc

Func _GetCheckedItems()
    Local $aChecked[0]
    Local $iCount = _GUICtrlListView_GetItemCount($g_idListview)

    For $i = 0 To $iCount - 1
        If _GUICtrlListView_GetItemChecked($g_idListview, $i) Then
            _ArrayAdd($aChecked, _
                _GUICtrlListView_GetItemText($g_idListview, $i, 0)) ; column 0 = ID/path
        EndIf
    Next

    Return $aChecked
EndFunc

Func _RestoreCheckedItems(ByRef $aChecked)
    If UBound($aChecked) = 0 Then Return

    Local $iCount = _GUICtrlListView_GetItemCount($g_idListview)

    For $i = 0 To $iCount - 1
        Local $sText = _GUICtrlListView_GetItemText($g_idListview, $i, 0)

        For $j = 0 To UBound($aChecked) - 1
            If $sText = $aChecked[$j] Then
                _GUICtrlListView_SetItemChecked($g_idListview, $i, True)
                ExitLoop
            EndIf
        Next
    Next
EndFunc

; =========================================================
; UI rebuild controller
; Do not call filtering or ListView manipulation elsewhere.
; Scan -> Data -> Filter -> Build UI pipeline only.
; =========================================================

Func FillListViewWithFiles()

    If Not $fFilesListed And $g_FilesToPatchCount <= 0 Then Return
    If $g_FilesToPatchCount <= 0 Or Not IsArray($FilesToPatch) Then Return

    Local $aFiltered = _GetFilteredFiles()

    _BuildListView($aFiltered)
    
    _GUICtrlListView_SetColumn($g_idListview, 1, "Collapse All", 532)

    _GUICtrlListView_EnableGroupView($g_idListview, True)
    UpdateUIState()

EndFunc

Func _GetFilteredFiles()

    Local $aTemp[0][5]
    Local $count = 0

    Local $isScanningBetaRoot = (StringInStr($MyDefPath, "(Beta)", 2) > 0)

    For $i = 0 To $g_FilesToPatchCount - 1
        If $i >= UBound($FilesToPatch) Then ExitLoop

        If Not $isScanningBetaRoot And $bShowBetaApps = 0 And $FilesToPatch[$i][1] Then ContinueLoop
        If $bFindACC = 0 And $FilesToPatch[$i][2] Then ContinueLoop
        If Not $EnableGood1 And $FilesToPatch[$i][4] Then ContinueLoop

        ReDim $aTemp[$count + 1][5]

        $aTemp[$count][0] = $FilesToPatch[$i][0]
        $aTemp[$count][1] = $FilesToPatch[$i][1]
        $aTemp[$count][2] = $FilesToPatch[$i][2]
        $aTemp[$count][3] = $FilesToPatch[$i][3]
        $aTemp[$count][4] = $FilesToPatch[$i][4]

        $count += 1
    Next

    Return $aTemp

EndFunc

Func _BuildListView(ByRef $aFiles)
    If Not IsArray($aFiles) Then Return
    If UBound($aFiles) = 0 Then Return
    If $g_idListview = 0 Then Return
    If Not WinExists($hGUI) Then Return
    If $g_FilesToPatchCount <= 0 Then Return
    Local $allChecked = True
    Local $checked = ObjCreate("Scripting.Dictionary")

    Local $oldCount = _GUICtrlListView_GetItemCount($g_idListview)
    For $i = 0 To $oldCount - 1
        Local $path = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
        If Not $checked.Exists($path) Then
            $checked.Add($path, _GUICtrlListView_GetItemChecked($g_idListview, $i))
        EndIf
    Next

    _GUICtrlListView_DeleteAllItems($g_idListview)
    _GUICtrlListView_RemoveAllGroups($g_idListview)

    _GUICtrlListView_SetExtendedListViewStyle($g_idListview, _
        BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, _
              $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

    Local $groupID = 0
    Local $iIndex = 0
    Local $groupMap = ObjCreate("Scripting.Dictionary")

    For $i = 0 To UBound($aFiles) - 1

        Local $filePath = $aFiles[$i][0]
        Local $groupName = $aFiles[$i][3]
        If $groupName = "" Then ContinueLoop

        If Not $groupMap.Exists($groupName) Then
            $groupID += 1
            $groupMap.Add($groupName, $groupID)
            _GUICtrlListView_InsertGroup($g_idListview, -1, $groupID, "", 1)
            _GUICtrlListView_SetGroupInfo($g_idListview, $groupID, $groupName, 1, $LVGS_COLLAPSIBLE)
        EndIf

        Local $thisGroupID = $groupMap.Item($groupName)
        Local $idx = _GUICtrlListView_AddItem($g_idListview, $iIndex)
        _GUICtrlListView_AddSubItem($g_idListview, $idx, $filePath, 1)
        _GUICtrlListView_SetItemGroupID($g_idListview, $idx, $thisGroupID)
        If FileExists($filePath & ".bak") Then
        _GUICtrlListView_SetItemParam($g_idListview, $idx, $PATCH_STATE_PATCHED)
        Else
        _GUICtrlListView_SetItemParam($g_idListview, $idx, $PATCH_STATE_UNPATCHED)
        EndIf
        If $checked.Exists($filePath) Then
            _GUICtrlListView_SetItemChecked($g_idListview, $idx, $checked.Item($filePath))
        ElseIf $allChecked Then
            _GUICtrlListView_SetItemChecked($g_idListview, $idx, True)
        If FileExists($filePath & ".bak") Then
            _GUICtrlListView_SetItemParam($g_idListview, $idx, $PATCH_STATE_PATCHED)
            _GUICtrlListView_SetItemText($g_idListview, $idx, $STATE_PATCHED_TEXT, 2)
        Else
            _GUICtrlListView_SetItemParam($g_idListview, $idx, $PATCH_STATE_UNPATCHED)
            _GUICtrlListView_SetItemText($g_idListview, $idx, $STATE_UNPATCHED_TEXT, 2)
        EndIf
        EndIf

        $iIndex += 1
    Next

    $fFilesListed = ($iIndex > 0)
    UpdateUIState()

EndFunc

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

Func ProgressWrite($msg_Progress)
	;_SendMessage($hWnd_Progress, $PBM_SETPOS, $msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc   ;==>ProgressWrite


Func MyFileOpenDialog()
	Local Const $sMessage = "Select a Path"

	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)


	If @error Then
		;MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Ready for next action")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = StringRegExpReplace($MyTempPath, "\\+$", "")
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)
		_GUICtrlListView_DeleteAllItems($g_idListview)
		_GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)
		_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))
		_GUICtrlListView_AddItem($g_idListview, "", 0)
		_GUICtrlListView_AddItem($g_idListview, "", 1)
		_GUICtrlListView_AddItem($g_idListview, "", 2)
		_GUICtrlListView_AddItem($g_idListview, "", 3)
		_GUICtrlListView_AddItem($g_idListview, "", 4)
		_GUICtrlListView_AddItem($g_idListview, "", 5)
		_GUICtrlListView_AddItem($g_idListview, "", 6)
		_GUICtrlListView_AddItem($g_idListview, "", 7)
		_GUICtrlListView_AddItem($g_idListview, "", 8)
		_GUICtrlListView_AddSubItem($g_idListview, 0, "", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 1, "Path:", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 2, " " & $MyDefPath, 1)
		_GUICtrlListView_AddSubItem($g_idListview, 3, "", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 4, "Step 1:", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 5, "Press 'Search' and wait for completion", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 6, "", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 7, "Step 2:", 1)
		_GUICtrlListView_AddSubItem($g_idListview, 8, "Press 'Patch' and wait for completion", 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 0, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 1, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 2, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 3, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 4, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 5, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 6, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 7, 1)
		_GUICtrlListView_SetItemGroupID($g_idListview, 8, 1)
		_GUICtrlListView_SetGroupInfo($g_idListview, 1, "Next Steps", 1)

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
    UpdateUIState()

EndFunc   ;==>MyFileOpenDialog

Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc   ;==>_ProcessCloseEx


Func MyGlobalPatternSearch($MyFileToParse)
	;ConsoleWrite($MyFileToParse & @CRLF)
	$aInHexArray = $aNullArray   
	$aOutHexGlobalArray = $aNullArray     

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

	Local $aPatterns, $sPattern, $sData, $aArray
	Local $sSearch, $sReplace, $iPatternLength
	Local $sPatternList

	If $DefaultPatterns = 0 Then
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	If Not IsArray($aPatterns) Then Return

	For $i = 0 To UBound($aPatterns) - 1

		$sPattern = $aPatterns[$i]

		If $EnableGood1 = 0 And $sPattern = "Good1" Then ContinueLoop

		$sData = IniRead($sINIPath, "Patches", $sPattern, "")
		If $sData = "" Then ContinueLoop
		If StringInStr($sData, "|") Then

			$aArray = StringSplit($sData, "|")

			If UBound($aArray) = 3 Then

				$sSearch = StringReplace($aArray[1], '"', '')
				$sReplace = StringReplace($aArray[2], '"', '')

				$iPatternLength = StringLen($sSearch)

				If $iPatternLength <> StringLen($sReplace) Or Mod($iPatternLength, 2) <> 0 Then
				MsgBox($MB_SYSTEMMODAL, "Error", "Pattern Error in config.ini:" & @CRLF & $sPattern & @CRLF & $sSearch & @CRLF & $sReplace)

				Exit
				EndIf

				LogWrite(1, "Searching for: " & $sPattern & ": " & $sSearch)

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

			EndIf
		EndIf

	Next

EndFunc   ;==>ExecuteSearchPatterns

Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)  
	;MsgBox($MB_SYSTEMMODAL, "Path", $FileToParse)
	;ConsoleWrite($FileToParse & @CRLF)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	FileSetPos($hFileOpen, 60, 0)

	$sz_type = FileRead($hFileOpen, 4)
	FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

	$sz_type = FileRead($hFileOpen, 2)

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
		For $i = 256 To 1 Step -2 ; limiting to 256 -?-
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
			;_ArrayDisplay($aInHexArray)

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]   
				$sWildcardReplacePattern = $aReplacePattern

				;MsgBox(-1,"",$sWildcardSearchPattern & @CRLF & $sWildcardReplacePattern) 

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

    Local $iRows = UBound($MyArrayToPatch)

    If $iRows > 0 Then

        MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")

        Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
        Local $sFileRead = FileRead($hFileOpen)
        FileClose($hFileOpen)

        Local $sStringOut
        Local $bPatched = False
        Local $iRepl = 0

        For $i = 0 To $iRows - 1 Step 2

            $sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
            Local $iRepl = @extended

            If $iRepl > 0 Then $bPatched = True

            $sFileRead = $sStringOut

            ProgressWrite(Round($i / $iRows * 100))

        Next

        If $bPatched Then

            _SetFilePatchState($MyFileToPatch, $PATCH_STATE_PATCHED)

            Local $iIndex = _FindListViewIndexByPath($MyFileToPatch)
            If $iIndex <> -1 Then
            _GUICtrlListView_SetItemText($g_idListview, $iIndex, "Patched", 2)
            _GUICtrlListView_SetItemParam($g_idListview, $iIndex, $PATCH_STATE_PATCHED)
            EndIf

            FileMove($MyFileToPatch, $MyFileToPatch & ".bak", $FC_OVERWRITE)

            Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
            FileWrite($hFileOpen1, Binary($sStringOut))
            FileClose($hFileOpen1)

            LogWrite(1, "File patched by GenP " & $g_Version & " + config " & $ConfigVerVar)

        Else

            _SetFilePatchState($MyFileToPatch, $PATCH_STATE_UNPATCHED)

            Local $iIndex = _FindListViewIndexByPath($MyFileToPatch)
            If $iIndex <> -1 Then
            _GUICtrlListView_SetItemText($g_idListview, $iIndex, "Unpatched", 2)
            _GUICtrlListView_SetItemParam($g_idListview, $iIndex, $PATCH_STATE_UNPATCHED)
            EndIf

            MemoWrite(@CRLF & "No patterns were found" & @CRLF & "---" & @CRLF & "or" & @CRLF & "---" & @CRLF & "file is already patched.")

            LogWrite(1, "No patterns were found or file already patched." & @CRLF)

        EndIf

        If $bEnableMD5 = 1 Then

            _Crypt_Startup()
            Local $sMD5Checksum = _Crypt_HashFile($MyFileToPatch, $CALG_MD5)

            If Not @error Then
                LogWrite(1, "MD5 Checksum: " & $sMD5Checksum & @CRLF)
            EndIf

            _Crypt_Shutdown()

        EndIf

    EndIf
    UpdateUIState()
    _GUICtrlListView_SetColumn($g_idListview, 1, "", 500, 2)

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
				Local $GroupIdOfHitItem = _GUICtrlListView_GetItemGroupID($g_idListview, $aHit[0])
				If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
						If _GUICtrlListView_GetItemGroupID($g_idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($g_idListview) - 1
						If _GUICtrlListView_GetItemGroupID($g_idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
						EndIf
					Next
				EndIf
				;$g_iIndex = $aHit[0]
			EndIf
		EndIf
	EndIf
    UpdateUIState()
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
    UpdateUIState()
EndFunc   ;==>_ListView_RightClick

;Func _Assign_Groups_To_Found_Files()
;	ConsoleWrite("Entering _Assign_Groups_To_Found_Files()" & @CRLF)
;	Local $MyListItemCount = _GUICtrlListView_GetItemCount($g_idListview)
;	ConsoleWrite("Item Count in ListView: " & $MyListItemCount & @CRLF)
;	Local $ItemFromList
;	Local $aGroups[0]
;	Local $iGroupID = 1
;
;	ReDim $g_aGroupIDs[0]
;
;	For $i = 0 To $MyListItemCount - 1
;		$ItemFromList = _GUICtrlListView_GetItemText($g_idListview, $i, 1)
;		ConsoleWrite("Item Text (Column 2): " & $ItemFromList & @CRLF)
;
;		Local $absolutePath = StringReplace($ItemFromList, "\\", "\")
;
;		Local $sGroupName = ""
;
;		Local $bIsBeta = StringInStr($absolutePath, "(Beta)") > 0
;
;		Select
;			Case StringInStr($ItemFromList, "AppsPanel") Or StringInStr($ItemFromList, "Adobe Desktop Service") Or StringInStr($ItemFromList, "HDPIM")
;				$sGroupName = "Creative Cloud"
;			Case StringInStr($ItemFromList, "Acrobat")
;				$sGroupName = "Acrobat"
;			Case StringInStr($ItemFromList, "Aero")
;				$sGroupName = "Aero"
;			Case StringInStr($ItemFromList, "After Effects")
;				$sGroupName = "After Effects"
;			Case StringInStr($ItemFromList, "Animate")
;				$sGroupName = "Animate"
;			Case StringInStr($ItemFromList, "Audition")
;				$sGroupName = "Audition"
;			Case StringInStr($ItemFromList, "Bridge")
;				$sGroupName = "Bridge"
;			Case StringInStr($ItemFromList, "Character Animator")
;				$sGroupName = "Character Animator"
;			Case StringInStr($ItemFromList, "Dimension")
;				$sGroupName = "Dimension"
;			Case StringInStr($ItemFromList, "Dreamweaver")
;				$sGroupName = "Dreamweaver"
;			Case StringInStr($ItemFromList, "Elements") And StringInStr($ItemFromList, "Organizer")
;				$sGroupName = "Elements Organizer"
;			Case StringInStr($ItemFromList, "Illustrator")
;				$sGroupName = "Illustrator"
;			Case StringInStr($ItemFromList, "InCopy")
;				$sGroupName = "InCopy"
;			Case StringInStr($ItemFromList, "InDesign")
;				$sGroupName = "InDesign"
;			Case StringInStr($ItemFromList, "Lightroom CC")
;				$sGroupName = "Lightroom CC"
;			Case StringInStr($ItemFromList, "Lightroom Classic")
;				$sGroupName = "Lightroom Classic"
;			Case StringInStr($ItemFromList, "Media Encoder")
;				$sGroupName = "Media Encoder"
;			Case StringInStr($ItemFromList, "Photoshop Elements")
;				$sGroupName = "Photoshop Elements"
;			Case StringInStr($ItemFromList, "Photoshop")
;				$sGroupName = "Photoshop"
;			Case StringInStr($ItemFromList, "Premiere Elements")
;				$sGroupName = "Premiere Elements"
;			Case StringInStr($ItemFromList, "Premiere Pro")
;				$sGroupName = "Premiere Pro"
;			Case StringInStr($ItemFromList, "Premiere Rush")
;				$sGroupName = "Premiere Rush"
;			Case StringInStr($ItemFromList, "Substance 3D Designer")
;				$sGroupName = "Substance 3D Designer"
;			Case StringInStr($ItemFromList, "Substance 3D Modeler")
;				$sGroupName = "Substance 3D Modeler"
;			Case StringInStr($ItemFromList, "Substance 3D Painter")
;				$sGroupName = "Substance 3D Painter"
;			Case StringInStr($ItemFromList, "Substance 3D Sampler")
;				$sGroupName = "Substance 3D Sampler"
;			Case StringInStr($ItemFromList, "Substance 3D Stager")
;				$sGroupName = "Substance 3D Stager"
;			Case StringInStr($ItemFromList, "Substance 3D Viewer")
;				$sGroupName = "Substance 3D Viewer"
;			Case Else
;				$sGroupName = "Other"
;		EndSelect
;		If $sGroupName = "" Then $sGroupName = "Other"
;		If $bIsBeta Then $sGroupName &= " (Beta)"
;
;		ConsoleWrite("Group Name Assigned: " & $sGroupName & @CRLF)
;
;		Local $iGroupIndex = _ArraySearch($aGroups, $sGroupName)
;		If $iGroupIndex = -1 Then
;			_ArrayAdd($aGroups, $sGroupName)
;			_GUICtrlListView_InsertGroup($g_idListview, $i, $iGroupID, $sGroupName, 1)
;			_GUICtrlListView_SetGroupInfo($g_idListview, $iGroupID, $sGroupName, 1, 0)
;			_GUICtrlListView_SetItemGroupID($g_idListview, $i, $iGroupID)
;			_ArrayAdd($g_aGroupIDs, $iGroupID)
;			ConsoleWrite("New Group Created - ID: " & $iGroupID & @CRLF)
;			$iGroupID += 1
;		Else
;			_GUICtrlListView_SetItemGroupID($g_idListview, $i, $iGroupIndex + 1)
;			ConsoleWrite("Assigned to Existing Group: " & $sGroupName & " (ID: " & $iGroupIndex + 1 & ")" & @CRLF)
;		EndIf
;	Next
;
;	For $i = 0 To $MyListItemCount - 1
;		_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
;	Next
;
;	ConsoleWrite("Exiting _Assign_Groups_To_Found_Files()" & @CRLF)
;	ConsoleWrite("Number of Groups in $g_aGroupIDs: " & UBound($g_aGroupIDs) & @CRLF)
;	For $i = 0 To UBound($g_aGroupIDs) - 1
;		ConsoleWrite("Group ID in $g_aGroupIDs: " & $g_aGroupIDs[$i] & @CRLF)
;	Next
;EndFunc   ;==>_Assign_Groups_To_Found_Files

Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($g_idListview)
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

			For $i = 1 To $aCount

				$aInfo = _GUICtrlListView_GetGroupInfo($g_idListview, $i)
				If IsArray($aInfo) Then
					_GUICtrlListView_SetGroupInfo($g_idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
			_RedrawWindow($idListview)
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
		UpdateUIState()
	EndIf
EndFunc   ;==>_Collapse_All_Click

Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($g_idListview)
	If $aCount > 0 Then
		_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

		For $i = 0 To $aCount - 1
			$aInfo = _GUICtrlListView_GetGroupInfo($g_idListview, $i)
			If IsArray($aInfo) Then
				_GUICtrlListView_SetGroupInfo($g_idListview, $i, $aInfo[0], $aInfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($g_idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
		_RedrawWindow($idListview)
		UpdateUIState()
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
		If $iIDFrom = $g_idHyperlinkMain Or $iIDFrom = $g_idHyperlinkOptions Or $iIDFrom = $g_idHyperlinkUnpack Or $iIDFrom = $g_idHyperlinkWinTrust Or $iIDFrom = $g_idHyperlinkHosts Or $iIDFrom = $g_idHyperlinkAGS Or $iIDFrom = $g_idHyperlinkFirewall Or $iIDFrom = $g_idHyperlinkLog Then
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

	If _IsChecked($idGood1) Then
		IniWrite($sINIPath, "Options", "EnableGood1", "1")
		$EnableGood1 = 1
	Else
		IniWrite($sINIPath, "Options", "EnableGood1", "0")
		$EnableGood1 = 0
	EndIf
	If _IsChecked($idShowBetaApps) Then
		IniWrite($sINIPath, "Options", "ShowBetaApps", "1")
		$bShowBetaApps = 1
	Else
		IniWrite($sINIPath, "Options", "ShowBetaApps", "0")
		$bShowBetaApps = 0
	EndIf

	Local $sNewDomainListURL = StringStripWS(GUICtrlRead($idCustomDomainListInput), 1)

	If $sNewDomainListURL = "" Then
		$sNewDomainListURL = $sDefaultDomainListURL
		GUICtrlSetData($idCustomDomainListInput, $sNewDomainListURL)
		MsgBox(48, "Empty URL", "The custom domain list URL cannot be empty." & @CRLF & _
 		"The default URL has been restored.")
	EndIf

	If Not StringRegExp($sNewDomainListURL, "(?i)^https?://") Then
		MsgBox(16, "Invalid URL", "Please enter a valid HTTP or HTTPS URL.")
		Return
	EndIf

	If $sNewDomainListURL <> $sCurrentDomainListURL Then
		IniWrite($sINIPath, "Options", "CustomDomainListURL", $sNewDomainListURL)
		$sCurrentDomainListURL = $sNewDomainListURL
	EndIf
	FillListViewWithInfo()

	GUICtrlSetData($idOptionsReminder, "Options saved successfully")
	AdlibUnRegister("_RestoreOptionsReminder")
	AdlibRegister("_RestoreOptionsReminder", 2000)
EndFunc   ;==>SaveOptionsToConfig

Func _RestoreOptionsReminder()
	GUICtrlSetData($idOptionsReminder, "Changes will not take effect until saved")
	AdlibUnRegister("_RestoreOptionsReminder")
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)
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
	_GUICtrlTab_SetCurFocus($hTab, 7)

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
		_GUICtrlTab_SetCurFocus($hTab, 7)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 7)
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
				_GUICtrlTab_SetCurFocus($hTab, 7)
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
				_GUICtrlTab_SetCurFocus($hTab, 7)
				GUIDelete($hToggleGUI)
				EnableAllFWRules()
				Return
			Case $hDisableButton
				_GUICtrlTab_SetCurFocus($hTab, 7)
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
		_GUICtrlTab_SetCurFocus($hTab, 7)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	Local $tRuntimePaths = IniReadSection($sINIPath, "RuntimeInstallers")
	Local $dllPaths[0]

	If @error Or $tRuntimePaths[0][0] = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 7)
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
		_GUICtrlTab_SetCurFocus($hTab, 7)
		MemoWrite("No file(s) found at: " & $MyDefPath)
		LogWrite(1, "No file(s) found at: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $selectedFiles = RuntimeDllSelectionGUI($foundFiles, "Unpack")

	If Not IsArray($selectedFiles) Or UBound($selectedFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 7)
		MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
		LogWrite(1, "No files selected to unpack.")
		ToggleLog(1)
		Return
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			_GUICtrlTab_SetCurFocus($hTab, 7)
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
		_GUICtrlTab_SetCurFocus($hTab, 7)
		MemoWrite("Error: Invalid Path: " & $MyDefPath)
		LogWrite(1, "Error: Invalid Path: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 7)
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
					_GUICtrlTab_SetCurFocus($hTab, 7)
					MemoWrite("No RuntimeInstaller.dll files selected to unpack.")
					LogWrite(1, "No RuntimeInstaller.dll files selected to unpack.")
					ToggleLog(1)
					Return ""
				EndIf
				_GUICtrlTab_SetCurFocus($hTab, 7)
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
		_GUICtrlTab_SetCurFocus($hTab, 7)
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
		_GUICtrlTab_SetCurFocus($hTab, 7)
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
				_GUICtrlTab_SetCurFocus($hTab, 7)
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
