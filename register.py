```
The module, register.py, receives as inputs from the user first name, last name and phone number.
It returns a unique ID and validates ID with response to phone text code. 
This probably needs to be written in OOP classes.
```

first_name = input("First name: ")
last_name = input("Last name: ")
phone_number = input("Phone number: ")


def registername(first_name='N/A', last_name='N/A', phone_number):
    # Need an error check here to return a 'Must enter a valid name', etc.
    # Need to call a hash function that associates a unique hash to this name/number combo
    # Check if user name already exists
    pass
    

def hashsecure(first, last, number):
    # Need to validate the hash is unique and secure
    pass
