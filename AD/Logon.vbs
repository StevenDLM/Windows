
'CREATE NETWORK OBJECTS
Set mWSHNetwork = CreateObject("WScript.Network")
Set mExisitingMappedDrives = mWSHNetwork.EnumNetworkDrives
Set wshPrn = mWSHNetwork.EnumPrinterConnections
Set mFileSystemObject = CreateObject("Scripting.FileSystemObject")

'strUserName = mWSHNetwork.UserName
'strUserFolder = "\\FileSRV01\users\" & strUserName


'DEFAULT NETWORK DRIVES 
extraNetworkDrives = "L:, \\FileSRV01\public"

'extraNetworkDrives = extraNetworkDrives & "; u:, " & strUserFolder

Call RemoveNetworkDrives()

'EXTRA NETWORK DRIVES 

If IsMember("CLI Brokers") Then
    extraNetworkDrives = extraNetworkDrives & "; P:, \\FileSRV01\clibrokers"
End If

extraNetworkDrives = Split(extraNetworkDrives, ";")
Call MapNetworkDrives(extraNetworkDrives)

'REMOVE PRINTERS
For x = 0 To wshPrn.Count - 1 Step 2
    If Left(wshPrn.Item(x+1),2) = "\\" Then mWSHNetwork.RemovePrinterConnection wshPrn.Item(x+1),True,True
Next

'ADD PRINTERS
mWSHNetwork.AddWindowsPrinterConnection "\\FileSRV01\LexGround"
mWSHNetwork.AddWindowsPrinterConnection "\\FileSRV01\LexLevel1"
mWSHNetwork.AddWindowsPrinterConnection "\\FileSRV01\LexLevel2"
mWSHNetwork.AddWindowsPrinterConnection "\\FileSRV01\LexColLvl1"

If IsMember("PRT_LexGround") Then
    mWSHNetwork.SetDefaultPrinter "\\FileSRV01\LexGround"
End If

If IsMember("PRT_LexLevel1") Then
    mWSHNetwork.SetDefaultPrinter "\\FileSRV01\LexLevel1"
End If

If IsMember("PRT_LexLevel2") Then
    mWSHNetwork.SetDefaultPrinter "\\FileSRV01\LexLevel2"
End If

If IsMember("PRT_LexColLvl1") Then
    mWSHNetwork.SetDefaultPrinter "\\FileSRV01\LexColLvl1"
End If

'CLEANUP OBJECTS
Set mWSHNetwork = Nothing
Set mFileSystemObject = Nothing

'objExplorer.Quit


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'RELEVENT FUNCTIONS BELOW

Dim errorReport


Private Sub RemoveNetworkDrives()

	'REMOVE ALL CURRENT MAPPED DRIVES
    For i = 0 To mExisitingMappedDrives.Count -1 Step 2
    	On Error Resume Next
    	Call UpdateBrowser("<br>Removing Drive (" & Trim(mExisitingMappedDrives.Item(i)) & ")...")
	    mWSHNetwork.RemoveNetworkDrive mExisitingMappedDrives.Item(i), True, True
	   	If err.Number <> 0 Then
	        'remove network drive error found
	        If len(trim(errorReport)) = 0 Then
    	        errorReport = "<ul><li>Unable to remove drive: " & Trim(mExisitingMappedDrives.Item(i))
            Else
                errorReport = errorReport & "<li>Unable to remove drive: " & Trim(mExisitingMappedDrives.Item(i))
            End If
            Call UpdateBrowser(" Failed.")
	   	Else
        	Call UpdateBrowser(" Success!")
        End If
    Next
    
End Sub


Private Sub MapNetworkDrives(driveArray)

    'MAP NETWORK DRIVES
    For Each mNetworkDrive In driveArray
    On Error Resume Next
	    mCurrentMappedDrivePair = Split(mNetworkDrive, ",")
	    Call UpdateBrowser("<br>Mapping Drive (" & Trim(mCurrentMappedDrivePair(0)) & ")...")
	    mWSHNetwork.MapNetworkDrive Trim(mCurrentMappedDrivePair(0)), Trim(mCurrentMappedDrivePair(1))
		Set oShell = CreateObject("Shell.Application")
		oShell.NameSpace(Trim(mCurrentMappedDrivePair(0))).Self.Name = Trim(mCurrentMappedDrivePair(2))
    Next

End Sub

Private Function IsMember(groupName)
    domain = mWSHNetwork.UserDomain
    user = mWSHNetwork.UserName

    flgIsMember = False
    Set userObj = GetObject("WinNT://" & domain & "/" & user & ",user")
    For Each grp In userObj.Groups
        If Trim(grp.Name) = Trim(groupName) Then
            flgIsMember = true
            Exit For
        End If
    Next
    IsMember = flgIsMember
    Set userObj = Nothing
End Function

'Private Sub UpdateBrowser(echoText)
'	strSafeTime = Right("0" & Hour(Now), 2) & ":" & Right("0" & Minute(Now), 2) & ":" & Right("0" & Second(Now), 2)
'	Wscript.echo echoText & " - " & strSafeTime
'End Sub
