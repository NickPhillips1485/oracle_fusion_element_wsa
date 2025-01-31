/*****************************************************************************

FORMULA NAME: WSA_TEST_ELEMENT_NP_EARN

FORMULA TYPE: Payroll

DESCRIPTION: 
This is the formula for processing a flat amount earning element. The formula 
assumes that the amounts and periodicity are available in element entries. 
For a Salary element, the Salary and Periodicity are available in  element entry, 
that is created by Oracle Fusion Compensation.
This formula is created by Global Earnings template.

Formula Results :

 l_value               Direct Result for Earnings Pay Value. 
 l_reduce              Direct Result for Earnings Reduce Regular Earnings.
 mesg                  Warning message will be issued for this assignment.

*******************************************************************************/

/* Database Item Defaults */

DEFAULT FOR amount                         is 0
DEFAULT FOR mesg                           is ' '
DEFAULT FOR ENTRY_LEVEL       IS 'AP'
DEFAULT FOR PAYROLL_PERIOD_TYPE IS ' '
DEFAULT FOR PAY_EARN_PERIOD_START  is '0001/01/01 00:00:00' (date)
DEFAULT FOR PAY_EARN_PERIOD_END is '4712/12/31 00:00:00' (date)
DEFAULT FOR REDUCE_REGULAR_EARNINGS_ASG_RUN is 0
DEFAULT FOR REDUCE_REGULAR_EARNINGS_TRM_RUN IS 0
DEFAULT FOR GB_REDUCE_REGULAR_ABSENCE_EARNINGS_ASG_RUN is 0
DEFAULT FOR GB_REDUCE_REGULAR_ABSENCE_HOURS_ASG_RUN is 0
DEFAULT FOR WSA_TEST_ELEMENT_NP_SECONDARY_CLASSIFICATION IS ' '
DEFAULT FOR ASG_HR_ASG_ID    is 0
DEFAULT FOR TERM_HR_TERM_ID    is 0
DEFAULT FOR pay_value is 0
DEFAULT FOR ENTRY_CREATOR_TYPE IS ' '
DEFAULT FOR NET is 0
DEFAULT FOR PRORATION_METHOD IS 'X'
DEFAULT FOR PRORATION_CONVERSION_RULE IS 'X'
DEFAULT FOR PRORATE_START is '0001/01/01 00:00:00' (date)
DEFAULT FOR PRORATE_END is '0001/01/01 00:00:00' (date)
DEFAULT FOR reporting_unit IS 'X'
DEFAULT FOR WORK_UNITS_CONVERSION_RULE IS 'ANNUALIZED RATE CONVERSION'
DEFAULT FOR PERIODICITY_CONVERSION_RULE IS 'ANNUALIZED RATE CONVERSION'
/* Inputs  */
INPUTS ARE        amount (number),
                  periodicity (text),
                  reduce_regular (text),
                  pay_value(number),
                  new_guess(number),
                  additional_amount(number),  
                  guess(number),   
                  first_run(number),
                  net(number),
                  proration_method(text),
      WORK_UNITS_CONVERSION_RULE(text),
   PRORATION_CONVERSION_RULE(text),
   PERIODICITY_CONVERSION_RULE(text),
      reporting_unit(text),
      prorate_start,
                  prorate_end

if (net = 0 and net was defaulted) then (

l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN)Initializing the Flat Amount Earnings Formula')

l_amount           = amount
l_value            = 0
l_reduce           = 0
l_reduce_hours     = 0
l_reduce_abs       = 0
l_reduce_hours_abs = 0
l_reduce_abs_hours = 0
l_hours            = 0
l_days =0
l_actual_amount = 0
l_test = 0
l_actual_start_date = '0001/01/01 00:00:00' (Date)
l_actual_end_date = '0001/01/01 00:00:00' (Date)


l_fte=1


l_prorate_start = prorate_start
l_prorate_end = prorate_end

/*    Assigning the  Values to the local variables*/
l_actual_start_date = PAY_EARN_PERIOD_START
l_actual_end_date = PAY_EARN_PERIOD_END
l_secondary_classification = WSA_TEST_ELEMENT_NP_SECONDARY_CLASSIFICATION
l_source_periodicity = periodicity



l_payroll_rel_action_id = 0
l_report_unit= reporting_unit

l_target_periodicity=PAYROLL_PERIOD_TYPE
 

/* Key Variable values retrival*/
l_element_entry_id       = GET_CONTEXT(ELEMENT_ENTRY_ID, 0)

l_payroll_rel_action_id  = GET_CONTEXT(PAYROLL_REL_ACTION_ID, 0)

 l_date_earned = GET_CONTEXT(DATE_EARNED, PAY_EARN_PERIOD_END)


 l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) l_date_earned =  '|| to_char(l_date_earned))
 
 IF l_payroll_rel_action_id = 0 THEN
(
   l_msg      = GET_MESG('HRX','HRX_USETE_CONTEXT_NOT_SET','CONTEXT','PAYROLL_REL_ACTION_ID')
   l_log = PAY_LOG_ERROR(l_msg)
/*   dummy = 1 */
   /* Formula must error out at this point */
)

/* avoid unnecessary conversion to Workhour Workday*/
IF ( l_source_periodicity = 'ORA_WORKHOUR') THEN
   (
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) set source periodicity Workhour')
    l_source_periodicity = 'Workhour'  
   )

ELSE IF ( l_source_periodicity = 'ORA_WEEKDAY') THEN   (       
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) set source periodicity Workday')
    l_source_periodicity = 'Workday'
   )
   
  

IF l_element_entry_id = 0 THEN
(
   l_msg      = GET_MESG('HRX','HRX_USETE_CONTEXT_NOT_SET','CONTEXT','ELEMENT_ENTRY_ID')
   l_log = PAY_LOG_ERROR(l_msg)
/*   dummy = 1 */
   /* Formula must error out at this point */
)


was_payroll_rel_action_id=0
If wsa_exists('WAS_REL_ACTION_ID','NUMBER' ) then
 ( was_payroll_rel_action_id = WSA_GET('WAS_REL_ACTION_ID',0) )

/* for ADD REPORT WORK UNIT CHECK BEFORE REDUCE REGULAR  */
GLB_REPORT_UNIT_KEY = 'REPORT_UNIT_'||ENTRY_LEVEL||'-'||TO_CHAR(l_element_entry_id)||'-'|| TO_CHAR(l_payroll_rel_action_id) 
l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_REPORT_UNIT_KEY ' ||GLB_REPORT_UNIT_KEY)
 
if( was_payroll_rel_action_id <> l_payroll_rel_action_id )then
( 

  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Payroll Rel Action ID in WAS : '||TO_CHAR(was_payroll_rel_action_id))
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Payroll Rel Action ID in Current run : '||TO_CHAR(l_payroll_rel_action_id))
  
  WSA_DELETE('proration_method')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear proration_method in WSA')
  
   /* for ADD REPORT WORK UNIT CHECK BEFORE REDUCE REGULAR  */
  WSA_DELETE(GLB_REPORT_UNIT_KEY)
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear l_report_unit in WSA')
  
  WSA_DELETE('WORK_UNITS_CONVERSION_RULE')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear WORK_UNITS_CONVERSION_RULE in WSA')
	
  WSA_DELETE('PERIODICITY_CONVERSION_RULE')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear PERIODICITY_CONVERSION_RULE in WSA')
	
  WSA_DELETE('PRORATION_CONVERSION_RULE')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear PRORATION_CONVERSION_RULE in WSA')
	
  WSA_DELETE('source_periodicity')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear source_periodicity in WSA')
	
  WSA_DELETE('target_periodicity')
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Clear target_periodicity in WSA')
	
  wsa_set('WAS_REL_ACTION_ID' ,GET_CONTEXT(PAYROLL_REL_ACTION_ID, 0))
)

 if (proration_method was not defaulted) then (
 
  IF (WSA_EXISTS('proration_method','TEXT_NUMBER')) THEN
   (
    log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for proration_method')
    wsa_proration_method = WSA_GET('proration_method', EMPTY_TEXT_NUMBER)
   )
  wsa_proration_method[l_element_entry_id] = proration_method
  WSA_SET('proration_method',wsa_proration_method)
)


  /* for ADD REPORT WORK UNIT CHECK BEFORE REDUCE REGULAR */
  WSA_SET(GLB_REPORT_UNIT_KEY, l_report_unit)



  IF (WSA_EXISTS('WORK_UNITS_CONVERSION_RULE','TEXT_NUMBER')) THEN
   (
    log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for WORK_UNITS_CONVERSION_RULE')
    was_WORK_UNITS_CONVERSION_RULE = WSA_GET('WORK_UNITS_CONVERSION_RULE', EMPTY_TEXT_NUMBER)
   )
  was_WORK_UNITS_CONVERSION_RULE[l_element_entry_id] = WORK_UNITS_CONVERSION_RULE
  WSA_SET('WORK_UNITS_CONVERSION_RULE',was_WORK_UNITS_CONVERSION_RULE)
  
  
    IF (WSA_EXISTS('PERIODICITY_CONVERSION_RULE','TEXT_NUMBER')) THEN
   (
    log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for PERIODICITY_CONVERSION_RULE')
    was_PERIODICITY_CONVERSION_RULE = WSA_GET('PERIODICITY_CONVERSION_RULE', EMPTY_TEXT_NUMBER)
   )
  was_PERIODICITY_CONVERSION_RULE[l_element_entry_id] = PERIODICITY_CONVERSION_RULE
  WSA_SET('PERIODICITY_CONVERSION_RULE',was_PERIODICITY_CONVERSION_RULE)
  
  if (PRORATION_CONVERSION_RULE ='X') then (
    PRORATION_CONVERSION_RULE=WORK_UNITS_CONVERSION_RULE
  )
  
  IF (WSA_EXISTS('PRORATION_CONVERSION_RULE','TEXT_NUMBER')) THEN
   (
    log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for PRORATION_CONVERSION_RULE')
    was_proration_rate_formula = WSA_GET('PRORATION_CONVERSION_RULE', EMPTY_TEXT_NUMBER)
   )
  was_proration_rate_formula[l_element_entry_id] = PRORATION_CONVERSION_RULE
  WSA_SET('PRORATION_CONVERSION_RULE',was_proration_rate_formula)
  

/* If pay value is already set, no further processing required for pay value */
IF (pay_value = 0 and pay_value was defaulted ) THEN
(
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) l_source_periodicity :'||l_source_periodicity)
   
    /* Element Template will convert hourly/daily into workhour/workday*/
  if (l_source_periodicity='Hourly') then (
  l_source_periodicity='WORKHOUR'
  )

   
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) ENTRY LEVEL IS ' ||ENTRY_LEVEL)
  IF ( ENTRY_LEVEL = 'AP') THEN
     (
   l_term_assignment_id = TERM_HR_TERM_ID 
   SET_INPUT('HR_ASSIGN_ID',l_term_assignment_id)  
   )
     ELSE IF ( ENTRY_LEVEL = 'PA') THEN   (       
      l_term_assignment_id = ASG_HR_ASG_ID
   SET_INPUT('HR_ASSIGN_ID',l_term_assignment_id)  
   )
     
 /** if it is 1$ per Unit, then how many $$ for Pay Period.. The $$ amount is the number of Units Worked **/
   
 if (l_report_unit = 'ORA_WORKDAYS') then (

  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) rate conversion formula is :'||WORK_UNITS_CONVERSION_RULE) 
   l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) target periodicity is :'||l_target_periodicity) 
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) reporting unit :'||l_report_unit) 
    
  CALL_FORMULA('RATE_CONVERTER',
        1 > 'SOURCE_AMOUNT',
     WORK_UNITS_CONVERSION_RULE> 'method',
        'WORKDAY' > 'SOURCE_PERIODICITY',
     l_target_periodicity > 'TARGET_PERIODICITY',
  l_date_earned > 'effdate',
    l_actual_start_date > 'start_date',
    l_actual_end_date > 'end_date',
        l_days  < 'TARGET_AMOUNT' DEFAULT 0
     )     

     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) reporting unit is days :'||TO_CHAR(l_days))
     
    )

  else if (l_report_unit='ORA_HOURSWORK') then (
   l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) rate conversion formula is :'||WORK_UNITS_CONVERSION_RULE) 
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) target periodicity is :'||l_target_periodicity) 
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) reporting unit :'||l_report_unit) 
     
   
    CALL_FORMULA('RATE_CONVERTER',
         1 > 'SOURCE_AMOUNT',
      WORK_UNITS_CONVERSION_RULE> 'method',
         'WORKHOUR' > 'SOURCE_PERIODICITY',
      l_target_periodicity > 'TARGET_PERIODICITY',
    l_date_earned > 'effdate',
      l_actual_start_date > 'start_date',
     l_actual_end_date > 'end_date',
         l_hours  < 'TARGET_AMOUNT' DEFAULT 0
      )
     
   l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) reporting unit is hours :'||TO_CHAR(l_hours))
    
    )
   
   

  IF (l_source_periodicity = 'PRD') THEN
         (
            l_value = l_amount
          )
         else
         ( 
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Amount : '||TO_CHAR(l_amount))
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN)Source Periodicity  : '||l_source_periodicity)
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN)Target periodicity  : '||l_target_periodicity)
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Parameter Initialization for Rate Converter Call')
  CALL_FORMULA('RATE_CONVERTER',
        l_amount > 'SOURCE_AMOUNT',
     PERIODICITY_CONVERSION_RULE> 'method',
        l_source_periodicity > 'SOURCE_PERIODICITY',
     l_target_periodicity > 'TARGET_PERIODICITY',
   l_date_earned > 'effdate',
     l_actual_start_date > 'start_date',
    l_actual_end_date > 'end_date',
        l_convert_amount  < 'TARGET_AMOUNT' DEFAULT 0
     )
  l_value=l_convert_amount
  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Convert amount :'||TO_CHAR(l_convert_amount))
  )


)   /* for IF of pay_value = 0 */
else
(
l_value = pay_value
)
l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Value : '||TO_CHAR(l_value))
l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) l_hours : '||TO_CHAR(l_hours))
l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) l_days : '||TO_CHAR(l_days))
   
  /* Reduce Regular earnings due to Absence payments - Processing begins */
   IF (ENTRY_CREATOR_TYPE = 'SP') THEN
   ( 
      

      l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) GB_REDUCE_REGULAR_ABSENCE_EARNINGS_ASG_RUN entered: ')
    /* Use the appropriate balance based on the employment level for the given element.*/
    IF ( ENTRY_LEVEL = 'PA') THEN
     (
   l_reduce_abs_days = GB_REDUCE_REGULAR_ABSENCE_DAYS_ASG_RUN
       l_reduce_abs_hours = GB_REDUCE_REGULAR_ABSENCE_HOURS_ASG_RUN
       l_reduce_abs = GB_REDUCE_REGULAR_ABSENCE_EARNINGS_ASG_RUN
     )
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce_abs ='||to_char(l_reduce_abs))
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce abs hours='||to_char(l_reduce_abs_hours))
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce abs days='||to_char(l_reduce_abs_days))
   
/* Check prorate start date and prorate end date to decide if there is a proration event. If there is a event,  Reduce regular will be processed in the proration formula and will be skipped in base formula */
    IF ((prorate_start was not defaulted or prorate_end was not defaulted) and (prorate_start<>PAY_EARN_PERIOD_START or prorate_end <>PAY_EARN_PERIOD_END)) then
    (
       l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) This Element have proration, Reduce Regular moved to Proration Formula')
   /* Preparing Key for Absence Reduce Earnings and Absence Reduce Hours */

    GLB_ABS_EARN_REDUCE_KEY = ENTRY_LEVEL||'-'||TO_CHAR(l_element_entry_id)||'-'|| TO_CHAR(l_payroll_rel_action_id)||'_ABSENCE'
    l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_ABS_EARN_REDUCE_KEY '||GLB_ABS_EARN_REDUCE_KEY)

    GLB_ABS_EARN_REDUCE_EARNING_KEY = 'EARNING_'||GLB_ABS_EARN_REDUCE_KEY
    l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_ABS_EARN_REDUCE_EARNING_KEY ' ||GLB_ABS_EARN_REDUCE_EARNING_KEY)
    
       GLB_ABS_EARN_REDUCE_EARNING_DAYS_KEY = 'DAY_'||GLB_ABS_EARN_REDUCE_KEY
    l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_ABS_EARN_REDUCE_EARNING_DAYS_KEY ' ||GLB_ABS_EARN_REDUCE_EARNING_DAYS_KEY)
 
   GLB_ABS_EARN_REDUCE_EARNING_HOURS_KEY = 'HOUR_'||GLB_ABS_EARN_REDUCE_KEY
    l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_ABS_EARN_REDUCE_EARNING_HOURS_KEY ' ||GLB_ABS_EARN_REDUCE_EARNING_HOURS_KEY)

    /* Setting Payvalue and hours in WSA*/
    WSA_SET(GLB_ABS_EARN_REDUCE_EARNING_KEY,l_reduce_abs)

    WSA_SET(GLB_ABS_EARN_REDUCE_EARNING_HOURS_KEY,l_reduce_abs_hours)
     
    WSA_SET(GLB_ABS_EARN_REDUCE_EARNING_DAYS_KEY,l_reduce_abs_days)
      )
    else
     (
      if (l_report_unit='ORA_HOURSWORK') then
	  (
			If l_reduce_abs_hours <= l_hours Then
			   (
			  l_hours = l_hours - l_reduce_abs_hours
			   )
			   Else
			   (
			  l_reduce_abs_hours = l_hours
			  l_hours = 0
			  /* mesg = 'Insufficient hours to reduce for Absence hours' */
			  mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
			  l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
			   )
	  )
	  
	  
	  if (l_report_unit = 'ORA_WORKDAYS') then 
	  (
			If l_reduce_abs_days <= l_days Then
			   (
			  l_days = l_days - l_reduce_abs_days
			   )
			   Else
			   (
			  l_reduce_abs_days = l_days
			  l_days = 0
			  /* mesg = 'Insufficient days to reduce for Absence days' */
			  mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
			  l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
			   )
	  )
	      
     If l_reduce_abs <= l_value then
     (
       l_value = l_value - l_reduce_abs
      )
      Else
      (
        l_reduce_abs = l_value
        l_value = 0
       /* mesg = 'Insufficient earnings to reduce for Absence Payment' */
      mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
      l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
      )
    )
    )
   /* Reduce Regular Absences processing ends */

  /* Reduce Regular earnings by Vacation element (created using a earning classfication) */

  /****************************************************************************  
  This logic will be executed when the employee's regular salary needs
  to be reduced. For example, this may happen when employee might have taken
  Vacation Pay or Sick Pay and it reduces the regular salary. 
  The regular salary element being reduced, is created via Compensation and in addition 
  it's secondary classification cannot be REGULAR_NOT_WORKED, for 
  the formula to pick up for reducing it. The vacation element(reducing element) is typically
  Units X Rate earning element. Reducing due to Absences element is covered below this section. 
  ****************************************************************************/

    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) REDUCE_REGULAR_EARNINGS_ASG_RUN before: ')
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Secondary classification = ' || l_secondary_classification )
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) creator_type  = ' || ENTRY_CREATOR_TYPE )
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce Regular Calculation Begins')

   IF (l_secondary_classification <> 'Standard Earnings Regular Not Worked' AND ENTRY_CREATOR_TYPE = 'SP') THEN
   ( 
     l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) REDUCE_REGULAR_EARNINGS_ASG_RUN entered: ')
   /* Use the appropriate balance based on the employment level for the given element.*/
   IF ( ENTRY_LEVEL = 'PA') THEN
    (
   l_reduce_days = REDUCE_REGULAR_DAYS_ASG_RUN
      l_reduce_hours = REDUCE_REGULAR_HOURS_ASG_RUN
      l_reduce = REDUCE_REGULAR_EARNINGS_ASG_RUN
    )
   ELSE IF ( ENTRY_LEVEL = 'AP') THEN
    (
  l_reduce_days = REDUCE_REGULAR_DAYS_TRM_RUN
      l_reduce_hours = REDUCE_REGULAR_HOURS_TRM_RUN
      l_reduce = REDUCE_REGULAR_EARNINGS_TRM_RUN
    )
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce ='||to_char(l_reduce))
    l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce hours='||to_char(l_reduce_hours))
   l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Reduce days='||to_char(l_reduce_days))
  /* Check prorate start date and prorate end date to decide if there is a proration event. If there is a event,  Reduce regular will be processed in the proration formula and will be skipped in base formula */
     IF((prorate_start was not defaulted or prorate_end was not defaulted) and (prorate_start<>PAY_EARN_PERIOD_START or prorate_end <>PAY_EARN_PERIOD_END)) then
    (
       l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) This Element have proration, Reduce Regular moved to Proration Formula')
    /* Preparing Key for Reduce Earnings and Hours */

   GLB_EARN_REDUCE_KEY = ENTRY_LEVEL||'-'||TO_CHAR(l_element_entry_id)||'-'|| TO_CHAR(l_payroll_rel_action_id)
   l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_EARN_REDUCE_KEY '||GLB_EARN_REDUCE_KEY)

   GLB_EARN_REDUCE_EARNING_KEY = 'EARNING_'||GLB_EARN_REDUCE_KEY
   l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_EARN_REDUCE_EARNING_KEY ' ||GLB_EARN_REDUCE_EARNING_KEY)

   GLB_EARN_REDUCE_HOURS_KEY = 'HOUR_'|| GLB_EARN_REDUCE_KEY
   l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_EARN_REDUCE_HOURS_KEY ' ||GLB_EARN_REDUCE_HOURS_KEY)
   
    GLB_EARN_REDUCE_DAYS_KEY = 'DAY_'|| GLB_EARN_REDUCE_KEY
   l_log =PAY_INTERNAL_LOG_WRITE('(GLBEARN) GLB_EARN_REDUCE_DAYS_KEY ' ||GLB_EARN_REDUCE_DAYS_KEY)

   /* Setting Payvalue and hours in WSA*/
   WSA_SET(GLB_EARN_REDUCE_EARNING_KEY,l_reduce)
   WSA_SET(GLB_EARN_REDUCE_HOURS_KEY,l_reduce_hours)
    WSA_SET(GLB_EARN_REDUCE_DAYS_KEY,l_reduce_days)

      )
    else
     (
      if (l_report_unit='ORA_HOURSWORK') then
	  (
			If l_reduce_hours <= l_hours Then
			   (
			  l_hours = l_hours - l_reduce_hours
			   )
			   Else
			   (
			   l_reduce_hours = l_hours
			   l_hours = 0
			   /* mesg = 'Insufficient hours to reduce' */
			   mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
			   l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
			   )
	  )
	  
	  
	  if (l_report_unit = 'ORA_WORKDAYS') then 
	  (
			If l_reduce_days <= l_days Then
			   (
			  l_days = l_days - l_reduce_days
			   )
			   Else
			   (
			  l_reduce_days = l_days
			  l_days = 0
			  /* mesg = 'Insufficient days to reduce ' */
			  mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
			  l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
			   )
	  )
	  
      If l_reduce <= l_value then
      (
        l_value = l_value - l_reduce
       )
       Else
       (
      l_reduce = l_value
      l_value = 0
      /* mesg = 'Insufficient earnings to reduce' */
      mesg = GET_MESG('PAY','PAY_RED_REG_LIMIT')
      l_log = PAY_LOG_WARNING('PAY:PAY_RED_REG_LIMIT')
       )
          ) 
   
   )
  /*
    ** Before setting each array in the Working Storage Area
    ** We need to first check if each one already exists, and if so, retrieve it to add the new values.
    */
    IF (WSA_EXISTS('source_periodicity','TEXT_NUMBER')) THEN
    (
      log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for source_periodicity')
      wsa_source_periodicity = WSA_GET('source_periodicity', EMPTY_TEXT_NUMBER)
    )
    wsa_source_periodicity[l_element_entry_id] = l_source_periodicity
    WSA_SET('source_periodicity',wsa_source_periodicity)

    IF (WSA_EXISTS('target_periodicity','TEXT_NUMBER')) THEN
    (
      log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) - Array found for target_periodicity')
      wsa_target_periodicity = WSA_GET('target_periodicity', EMPTY_TEXT_NUMBER)
    )
    wsa_target_periodicity[l_element_entry_id] = l_target_periodicity
    WSA_SET('target_periodicity',wsa_target_periodicity)

  l_log = PAY_INTERNAL_LOG_WRITE('(GLBEARN) Derived value : '||TO_CHAR(l_value))
  
  WSA_DELETE('WSA_TEST')
  l_test = 20
  WSA_SET('WSA_TEST', l_test)

RETURN l_value          ,
       l_hours          ,
    l_days           ,
       l_reduce         ,
       l_reduce_hours   ,
    l_reduce_days   ,
       l_reduce_abs     ,
       l_reduce_abs_hours ,
    l_reduce_abs_days ,
       mesg )
ELSE /* Grossup Processing  Begin */
(
l_log = PAY_INTERNAL_LOG_WRITE('(GLBGRUP) Entering GrossupMode ')
l_value = 0
 if (first_run = 1) then  
  ( result2 = new_guess   )  
  else   
 (result2 = guess + additional_amount  )   
 guess = result2   
 l_value = result2
 L_LOG = PAY_INTERNAL_LOG_WRITE('(GLBGRUP) EXITING FLAT AMOUNT FORMULA ')
 return l_value
)

/* End Formula Text */
