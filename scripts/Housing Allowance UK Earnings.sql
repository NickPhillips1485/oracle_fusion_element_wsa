/*DEFAULT SECTION*/
DEFAULT FOR AMOUNT IS 0
DEFAULT FOR CST_VISION_PAY_368_ASG_ITD IS 0



/*INPUTS SECTION*/
INPUTS ARE AMOUNT





/* VRIABLE DECLARATION/INTIALISATION SECTION*/
L_AMOUNT = AMOUNT





/*ACTUAL LOGIC SECTION*/
		/*



		THERE ARE SOME WRITTEN LOGIC BY PREVIOUS TEAM




		*/
		
		IF (WSA_EXISTS('WSA_TEST', 'NUMBER')) THEN
		(
		l_value = L_AMOUNT + WSA_GET('WSA_TEST', 0)
		)
		ELSE
		(
		l_value = L_AMOUNT
		)
		

		

	
		

		MESG = 'MY MESSAGE'
		LOUG = PAY_INTERNAL_LOG_WRITE('MY MESSAGE WITH LOG'+ TO_CHAR(L_AMOUNT))


LOUG = PAY_INTERNAL_LOG_WRITE('[HOUSING ALLOWANCE uk] CST_VISION_PAY_368_ASG_ITD '+ TO_CHAR(CST_VISION_PAY_368_ASG_ITD))
/* RETURN SECTION*/
RETURN l_value, MESG

