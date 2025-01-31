## oracle_fusion_element_wsa

As I'll soon be starting a new role as an Oracle Fusion Payroll Consultant, I wanted to practice some of the required skills, especially in relation to Oracle's Fast Formula programming language. In this mini-project I'll be learning how to use the Working Storage Array (WSA) functions in Fast Formula in order to populate a variable in one formula and then retrieve it in another formula. 

### Scenario

The purpose of the WSA function is to be able to store and use variables globally across formulas. 
I have added two elements to an employee record (91842)in Aug 2025:

- WSA Test Element NP (£500 per month)
- Housing Allowance UK (£2000 per month)


I will amend the formula for each of those elements so that the 'WSA Test Element NP' element contains a WSA_SET call and the 'Housing Allowance UK' contains the WSA_EXISTS and the WSA_GET calls.
WSA_DELETE will be used in both formulas to clear the WSA after use.   

### Steps

- Update the 'WSA Test Element Earnings' formula to add a local variable that will be the subject of the WSA_SET function call, and enter the WSA_SET call itself. The arguments
in WSA_SET are the name of the WSA function you are setting, and the variable which is the subject of the call. 

```
l_test = 20
WSA_SET('WSA_TEST', l_test)
```

- Update the 'Housing Allowance UK Earnings' formula to include the WSA_EXISTS and WSA_GET function calls. The WSA_EXISTS function checks for the presence of the WSA_SET and specifies its data type.
The WSA_GET function retrieves the WSA (providing it exists).

- Place these calls within a conditional logic block (IF / THEN / ELSE) to add the variable being called to l_value if it exists, but if it doesn't exist just use l_amount as l_value.

```
		IF (WSA_EXISTS('WSA_TEST', 'NUMBER')) THEN
		(
		l_value = L_AMOUNT + WSA_GET('WSA_TEST', 0)
		WSA_DELETE('WSA_TEST')
		)
		ELSE
		(
		l_value = L_AMOUNT
		)
```

- For the test to be successful, a quick pay should produce an amount of £2020 for the 'Housing Allowance UK' element, which is made up of the £2000 entry value
plus £20 from the l_test variable. The other element, 'WSA Test Element NP' should pay be unaffected by this i.e. the entry value of £500 should be paid.

- The test completed successfully. 

### Challenges

Element Priority
Logging

Default redundancy issue
WSA_DELETE
Logging

### Summary 