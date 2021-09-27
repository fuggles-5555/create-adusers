# Create-ADUsers

Powershell script to create bulk active directory users when building vulnerable domains for security training. 

**WARNING - This is for the purpose of quickly creating accounts when building vulnerable ad environments.  
Do not use in a production environment**

* Random names are generated in the firstname.lastname format.
* The number of accounts requested must be 10% or less of the total number of possible names from multiplying the firstname and the lastname. This is to prevent excessive numbers of account name collisions during creation. 
* Password policy is weakened to a minimum password length of 4 and to disable password complexity.
* Roughly 10% of accounts will also have DoesNotRequirePreAuth option set which enables ASRepRoasting.

Two files are output to the current directory. These contain a list of the new users, and a list of the users with DoesNotRequirePreAuth set.

Usage:

```. .\CreateAdUsers.ps1
Create-AdUsers -FirstNameFile firstnames.txt -LastNameFile lastnames.txt -PasswordFile passwords.lst -NumberOfAccounts 200
```

