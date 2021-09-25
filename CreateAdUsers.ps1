<#
This is a script to create ad users. 

WARNING - This is for the purpose of quickly creating accounts when building vulnerable ad environments only. 

It takes the following inputs:
* FirstNameFile - text file containing first names
* LastNameFile - text file containing last names
* PasswordFile - text file containing passwords
* NumberOfAccounts - integer for the number of accounts to create

Random names are generated in the firstname.lastname format.
The number of accounts requested must be 10% or less of the total number of possible names from multiplying the firstname and the lastname.
This is to prevent excessive numbers of account name collisions during creation. Is there a better way to solve this problem?
Password policy is weakened to a minimum password length of 4 and to disable password complexity. 
Roughly 5% of accounts will also have DoesNotRequirePreAuth option set which enables ASRepRoasting.
A test file is output to the current directory containing a list of the new users. 
#>

function CreateAdUsers ($FirstNameFile, $LastNameFile, $PasswordFile, $NumberOfAccounts) {
    # starting
    Write-Host("Starting the CreateAdUsers script...")
    
    # local variables to hold values of parameters
    $firstNameArray = Get-Content $FirstNameFile
    $lastNameArray = Get-Content $LastNameFile
    $passwordArray = Get-Content $PasswordFile
    $numberToCreate = 0

    # check NumberOfAccounts is an integer
    if ($NumberOfAccounts -is [Int]){
        $numberToCreate = $NumberOfAccounts
    } else {
        Write-Host("NumberOfAccounts was not an integer.")
        Break
    }

    # counters for number of accounts and number of no pre-auth accounts
    $countOfCreatedAccounts = 0
    $countOfNoPreAuth = 0
    $countOfUserCollisions = 0

    # checks that the number of accounts requested is 10% or less than the total possible accounts from the input files
    Write-Host("Checking input files are sufficient to create the number of accounts requested.")
    Write-Host("Requested accounts must be less than 10% of total firstnames times total lastnames.")
    if (-not([int](($firstNameArray.Length*$lastNameArray.Length)*0.1) -gt $NumberOfAccounts)){ 
        Write-Host("Too many accounts for the size of the input name files.")
        Write-Host("Add more names or reduce the number of accounts requested.")
        Pause
        Exit
    }

    # check whether output files already exist and exits if they do
    if ((Get-Item -Path "user-list-new.txt" -ErrorAction Ignore) -or (Get-Item -Path "user-list-preauth.txt" -ErrorAction Ignore)){
        Write-Host("The file user-list-new.txt and/or user-list-preauth.txt already exists.")
        Write-Host("Delete or rename them before running this script.")
        Pause
        Exit
    }
    
    # weakening password policy
    Write-Host("Weakining password policy...")
    Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).Name -MinPasswordLength 4 -ComplexityEnabled $false

    # loop account creation
    $countOfCreatedAccounts = 0
    while ($countOfCreatedAccounts -lt $numberToCreate){
        # random firstname, lastname, password positions
        $randFirst=((Get-Random) % $firstNameArray.Length)
        $randLast=((Get-Random) % $lastNameArray.Length)
        $randPass=((Get-Random) % $passwordArray.Length)
        # combine the name into the desired format
        $name = $firstNameArray[$randFirst] + "." + $lastNameArray[$randLast]
        
        # check whether name is too long (samaccountname has a 20 character limit)
        if ($name.Length -gt 20){
            continue
        }
        
        # check whether name is null, whitespace or empty
        if ([String]::IsNullOrWhiteSpace($name) -or [String]::IsNullOrEmpty($name)){
            continue
        }

        # check whether the account already exists
        if (Get-ADUser -Filter {SamAccountName -eq $name }){
            # account exists so break out of loop
            $countOfUserCollisions = $countOfUserCollisions + 1
            continue
        } else {
            # account does not exist so create it
            New-ADUser -Name $name -GivenName $firstNameArray[$randFirst] -Surname $lastNameArray[$randLast] -SamAccountName $name -PasswordNeverExpires $true -AccountPassword (ConvertTo-SecureString $passwordArray[$randPass] -AsPlainText -Force) -WarningAction SilentlyContinue -Enabled $true
            # increment count of created accounts
            $countOfCreatedAccounts = $countOfCreatedAccounts + 1
            # handle output
            Write-Host("Account: " + $name + " created")
            Out-File "user-list-new.txt" -InputObject $name -Append
            # randomise whether to disable kerberos preauth
            if (((Get-Random) % 20) -eq 10){
                Set-ADAccountControl -Identity $name -DoesNotRequirePreAuth $true
                $countOfNoPreAuth = $countOfNoPreAuth +1
                Out-File "user-list-preauth.txt" -InputObject $name -Append
            }        
        }  
    }
    Write-Host("Total accounts created is " + $countOfCreatedAccounts)
    Write-Host("Total accounts with no pre-auth is " + $countOfNoPreAuth) 
    Write-Host("Total user collisions is " + $countOfUserCollisions) 
}
