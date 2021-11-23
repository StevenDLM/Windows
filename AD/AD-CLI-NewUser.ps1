#Function to Generate Password: 1xCapital, 4xLowerCase, 1x Special, 3xNumber
Function GenPWD{
	
	#Special Characters
	$pwChar = "!","?","@","#","$","%","&","*","-","."
	
	#Numbers
	foreach ($a in 48..57){
		$pwNum+=,[char][byte]$a
	}
	
	#Upper case
	foreach ($a in 65..90){
		$pwUp+=,[char][byte]$a
	}
	
	#Lower case
	foreach ($a in 97..122){
		$pwLow+=,[char][byte]$a
	}
	
	#GeneratePassword
	#1x Upper Case Char
	$PW +=  ($pwUp | GET-RANDOM)
	
	#4x Lower Case Char
	foreach ($loop in 1..4) {
		$PW+=($pwLow | GET-RANDOM)
	}
	
	#1x Special Char
	$PW +=  ($pwChar | GET-RANDOM)
	
	#3x Numbers
	foreach ($loop in 1..3) {
		$PW += ($pwNum | GET-RANDOM)
	}
	
	return $PW

}

#Function to populate yes/no dialogue
Function YesNo($caption,$message){

	$yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","help"
	$no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","help"
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
	$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

	$answer = (-Not $answer)
	$answer
}

params($FilePath = "C:\Users\curo\Documents\Scripts")

import-module activedirectory

$SearchOU = "DC=sfg,DC=cc,DC=com,DC=au"

#Do{
	"What Kind of User is it:
	1. Head Office
	2. Store
	3. Shared Mailbox
	4. Service Account"

	$UserType = read-host "Select a number 1,2,3 or 4"
	
	$FName = ""
	$LName = ""
	$UName = ""
	$Alias = ""
	$EmployeeID = ""
	$JobTitle = ""
	$UserPrincipal = ""
    $TelephoneNumber = ""
	$TargetOU = "OU=Users,OU=Root,DC=sfg,DC=cc,DC=com,DC=au"
	$AddToWAP = $FALSE
	$Groups = @()
	[string]$NewPW = $NULL
	$NewPW = GenPWD
	cls
	
	Switch ($UserType){
		1{
            Write-Host -ForegroundColor Yellow "This option requires the following information:"
            Write-Host -ForegroundColor Yellow "User's Firstname and Last Name"
            Write-Host -ForegroundColor Yellow "Employee ID (optional)"
            Write-Host -ForegroundColor Yellow "Job Title (Optional)"
            Write-Host -ForegroundColor Yellow "Employee Location (Head Office or Regional, optional)"
            Write-Host -ForegroundColor Yellow "Employee phone number or extension? (Optional)"
            if ((read-host "Do you have this information? [y/n]") -like"y") {Write-Host -ForegroundColor Green "Proceeding...";sleep 1} else {write-host -ForegroundColor Red "Exiting...";sleep 2;exit}
			$FName = read-host "Enter First Name"
			$LName = read-host "Enter Last Name"
			$UName = ($FName.substring(0,1)) + ($LName -replace ' ','')
			$Alias = $FName + "." + ($LName -replace ' ','')
			$EmployeeID = read-host "Enter Employee ID (hit enter if none)"
			$JobTitle = read-host "Enter Job Title (hit enter if none)"
			$UserPrincipalName = $UName + "@cc.com.au"
			$TargetOU = "OU=Head Office," + $TargetOU
			$Groups += "Office_Users"
			$Groups += "AllTeamcc"
			$Groups += "DRV_Public_Team"
            $Groups += "DRV_av"
			$Groups += "CCX_PWD_Expiry"
            if ((read-host "Is this employee based at Head Office? [y/n]") -like"y")
			{
                $Groups += "CCHQ"
                $Groups += "CC Security Awareness Training"
                Write-Host -ForegroundColor Green "Added to CCHQ!"
                sleep 1
            }
            if ((read-host "Does the user have a mobile number or extension?") -like "y") {$TelephoneNumber = read-host "Enter phone number:"}
		}
		2{
            Write-Host -ForegroundColor Yellow "This option requires the following information:"
            Write-Host -ForegroundColor Yellow "Store Location Name"
            Write-Host -ForegroundColor Yellow "Store Number"
            Write-Host -ForegroundColor Yellow "Store Region Code and Store type (MYER, AU, NZ)"
            Write-Host -ForegroundColor Yellow "Store Phone Number or Extension Number(Optional)"
            if ((read-host "Do you have this information? [y/n]") -like"y") {Write-Host -ForegroundColor Green "Proceeding...";sleep 1} else {write-host -ForegroundColor Red "Exiting...";sleep 2;exit}
			$FName = "cc"
			$LName = read-host "Enter Store Location ONLY"
			$UName = read-host "Enter Store Number ONLY"
			$Alias = $UName
			$UserPrincipalName = $UName + "@cc.com.au"
			$TargetOU = "OU=Stores," + $TargetOU
			$Groups += "Stores"
			$Groups += "Patch_cc_Visitors_AU"
			$Groups += read-host "Enter Store Region Code (e.g. R123)"
            if ((read-host "Does the store have a assigned number or extension?") -like "y") {$TelephoneNumber = read-host "Enter phone number:"}
	"What Type of Store is it:
	1. MYER
	2. AU
	3. NZ"
			$StoreType = read-host "Select a number 1,2,3"
			Switch ($StoreType){
				"MYER"{
					$Groups += "Store Myer"
				}
				"AU"{
					$Groups += "StoresAU"
				}
				"NZ"{
					$Groups += "StoresNZ"
				}
                default {$Groups += "StoresAU"}
			}
			
		}
		3{
            Write-Host -ForegroundColor Yellow "This option requires the following information:"
            Write-Host -ForegroundColor Yellow "Function Name"
            Write-Host -ForegroundColor Yellow "User name"
            Write-Host -ForegroundColor Yellow "Email Alias"
            if ((read-host "Do you have this information? [y/n]") -like"y") {Write-Host -ForegroundColor Green "Proceeding...";sleep 1} else {write-host -ForegroundColor Red "Exiting...";sleep 2;exit}
			$FName = "cc"
			$LName = read-host "Enter Function name"
			$UName = read-host "Enter User Name"
			$Alias = read-host "Enter Email Alias"
			$UserPrincipalName = $UName + "@cc.com.au"
			$TargetOU = "OU=Shared," + $TargetOU
		}
		4{
            Write-Host -ForegroundColor Yellow "This option requires the following information:"
            Write-Host -ForegroundColor Yellow "Account Function"
            Write-Host -ForegroundColor Yellow "User Name"
            if ((read-host "Do you have this information? [y/n]") -like"y") {Write-Host -ForegroundColor Green "Proceeding...";sleep 1} else {write-host -ForegroundColor Red "Exiting...";sleep 2;exit}
			$FName = read-host "Enter Account Function"
			$LName = "Admin"
			$UName = read-host "Enter User Name"
			$Alias = $UName
			$UserPrincipalName = $UName + "@sfg.cc.com.au"
			$TargetOU = "OU=Service Accounts,OU=Root,DC=sfg,DC=cc,DC=com,DC=au"
		}
		default {
			$FName = read-host "Enter First Name"
			$LName = read-host "Enter Last Name"
			$UName = read-host "Enter User Name"
			$Alias = read-host "Enter Email Alias"
			$UserPrincipalName = $UName + "@sfg.cc.com.au"
		}
	}


	$Emails = New-Object -TypeName 'object[]' -ArgumentList 2
	$Emails[0] = "SMTP:" + $Alias + "@cc.com.au"
	$Emails[1] = "smtp:" + $Alias + "@ccau.onmicrosoft.com";
	cls
	
	try{

		#Check if user exists
		if (Get-ADUser -SearchBase $SearchOU -filter * | ?{$_.SAMAccountName -like "$UName"}){
			
			"Username already exists"

		}else{
			#Need to build function to test for duplicate email address
			#foreach($Email in Emails){
			#	if (Get-ADUser -SearchBase $SearchOU -filter * -property proxyAddresses| ?{$_.SAMAccountName -like "$UName"})
			#}
			
			#Create additional name required for New-ADUser
			"Creating new User"
			$DisplayName = $FName + " " + $LName
			
			#Create new ADUser
			New-ADUser -Path $TargetOU `
			   -Name $DisplayName `
			   -UserPrincipalName $UserPrincipalName `
			   -SamAccountName $UName `
			   -Enabled $true `
			   -GivenName $FName `
			   -SurName $LName `
			   -DisplayName $DisplayName `
			   -email $Emails[0].substring(5) `
			   -EmployeeID $EmployeeID `
			   -Title $JobTitle `
			   -AccountPassword (ConvertTo-SecureString $NewPW -asplaintext -force) `
			   -ErrorAction Stop -WarningAction Stop
			
			Set-ADUser $UName -replace @{ProxyAddresses=$Emails}
            Set-ADuser $UName -replace @{mailNickname=($Alias + "@cc.com.au")}
            if (($TelephoneNumber).length -gt 0) {Set-ADUser $UName -replace @{telephonenumber=$TelephoneNumber}}
			
			foreach($Group in $Groups){
				Add-ADGroupMember -Identity $Group -Members $UName
			}
			
			#Output New User Details
			
			$outputCSV = "$FilePath\SFG-NewUsers.csv"
			
			$NewUser = [pscustomobject][ordered]@{
				TimeStamp = (Get-Date -format "HHmm_ddMMyyyy")
				DisplayName = $DisplayName
				UserName = $UserPrincipalName
				Email = $($Emails[0].substring(5))
				Password = $NewPW;
			}
			
			
			"Name: $($NewUser.DisplayName)
			User: $($NewUser.UserName)
			Email: $($NewUser.Email)
			Password: $($NewUser.Password)"
			
			$NewUser | Export-csv -path $outputCSV -append
			
		}

			
	}
	#Just in case there's an error
	catch{
	echo "execution error with user: $DisplayName"
	echo $error[0]
	}
	
	$Users = Get-ADUser -filter * -searchbase "OU=Disabled,OU=Users,OU=Root,DC=sfg,DC=cc,DC=com,DC=au"
	foreach($User in $Users){ Set-ADUser $User -Replace @{msExchHideFromAddressLists=$true}}
	
	Read-Host "Press Enter to continue"
#} while(YesNo "Create" "Another New User?")
