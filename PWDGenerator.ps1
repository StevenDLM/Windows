Function GenPWD{
	#Params set length of LowerCase, Special and Numbers used in Password
  params([int]$LenLow, [int]$LenChar, [int]$LenNum)
	  
  

	
	#Retrieves Charset of Upper case
	foreach ($a in 65..90){
		$pwUp+=,[char][byte]$a
	}
	
	#Retrieves Charset of Lower case
	foreach ($a in 97..122){
		$pwLow+=,[char][byte]$a
	}
  
  #Sets allowed Special characters
	$pwChar = "!","?","@","#","$","%","&","*","-","."
	
	#Retrieves Charset of Numbers
	foreach ($a in 48..57){
		$pwNum+=,[char][byte]$a
	}
  
  #Single UpperCase
	$PW +=  ($pwUp | GET-RANDOM)
	
  #Number of Lower case chars set by $LenLow
	foreach ($loop in 1..$LenLow) {
		$PW+=($pwLow | GET-RANDOM)
	}
	
  #Number of Upper case chars set by $LenChar
	foreach ($loop in 1..$LenChar) {
    $PW +=  ($pwChar | GET-RANDOM)
	}
  
  #Number of Number chars set by $LenNum
	foreach ($loop in 1..$LenNum) {
		$PW += ($pwNum | GET-RANDOM)
	}
	
	return $PW

}
