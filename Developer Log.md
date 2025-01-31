## oracle_fusion_element_wsa

As I'll soon be starting a new role as an Oracle Fusion Payroll Consultant, I wanted to practice some of the required skills, especially in relation to Oracle's Fast Formula programming language. In this mini-project I'll be learning how to use the Working Storage Array (WSA) functions in Fast Formula in order to populate a variable in one formula and then retrieve it in another formula. 

### Scenario

The purpose of the WSA function is to be able to store and use variables globally across formulas. 
I have added two elements to an employee record (91842)in Aug 2025:

- WSA Test Element NP (£500 per month)
- Housing Allowance UK (£2000 per month)

I will amend the formula for each of those elements so that the 'WSA Test Element NP' element contains a WSA_SET call and the 'Housing Allowance UK' contains the WSA_EXISTS and the WSA_GET calls.
WSA_DELETE will be used in both formulas to clear the WSA after use.

The exercise is taking place in a Dev environment, so the data is not real and no sensitive information will be displayed in the repository.   

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

- The test completed successfully (see screenshot of QP in tests folder). 

### Challenges

- Not so much a challenge but a consideration: I assume that for the WSA calls to work, the element which is handling the WSA_SET must have a lower processing priority
i.e. gets processed earlier than the element using WSA_GET. Wasn't an issue here because 'WSA Test Element NP' had 2500 and 'Housing Allowance UK' had 9999, but one to be aware of for the future.

- I'm a bit confused by an aspect of my conditional logic because WSA_GET has a default of 0, but since WSA_GET only executes if WSA_EXISTS, what is the point of a default. 
I tried taking the default out but then it wouldn't compile so clearly it has to be there. It's not a problem as such, just a bit confusing.

- I'm not sure what the criteria is for where I shouldn't use WSA_DELETE vs where I should. I've used it in this exercise (in conjunction with both the SET and GET calls),
but is there a scenario where not using it could create an issue? 

- On the basis that the test worked first time I haven't bothered to go back and add any **logging**, but were I to do this again I probably should include something like this:

l_debug = ESS_LOG_WRITE('WSA_TEST' + to_char(WSA_TEST))

### Summary 

Overall then, a successful outcome and I feel more confident for having practiced this technique, albeit using a fairly simple test case. 