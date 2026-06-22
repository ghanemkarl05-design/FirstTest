@isTest
private class Exercise2_Test {

    // Helper: create and insert an Account, return it
    private static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    // -----------------------------------------------------------------------
    // TEST 1: Contact with LastName = 'Smith' increments the Account count
    // -----------------------------------------------------------------------
    @isTest
    static void testSmithLastNameIncreasesCount() {
        Account acc = createAccount('Smith Test Account');

        Contact c = new Contact(
            LastName   = 'Smith',
            FirstName  = 'Jane',
            AccountId  = acc.Id
        );
        insert c;

        // Re-query the account to check the custom field
        Account updatedAcc = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, updatedAcc.Smith_Count__c,
            'Smith_Count__c should be 1 after inserting one Smith contact.');
    }

    // -----------------------------------------------------------------------
    // TEST 2: Contact with null FirstName increments the Account count
    // -----------------------------------------------------------------------
    @isTest
    static void testNullFirstNameIncreasesCount() {
        Account acc = createAccount('Null FirstName Account');

        Contact c = new Contact(
            LastName  = 'Jones',
            FirstName = null,
            AccountId = acc.Id
        );
        insert c;

        Account updatedAcc = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, updatedAcc.Smith_Count__c,
            'Smith_Count__c should be 1 after inserting a contact with null FirstName.');
    }

    // -----------------------------------------------------------------------
    // TEST 3: Contact that does NOT match either condition → count stays 0
    // -----------------------------------------------------------------------
    @isTest
    static void testNonMatchingContactDoesNotIncreaseCount() {
        Account acc = createAccount('No Match Account');

        Contact c = new Contact(
            LastName  = 'Williams',
            FirstName = 'Bob',
            AccountId = acc.Id
        );
        insert c;

        Account updatedAcc = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, updatedAcc.Smith_Count__c,
            'Smith_Count__c should remain 0 for a non-matching contact.');
    }

    // -----------------------------------------------------------------------
    // TEST 4: Multiple matching contacts on one Account accumulate correctly
    // -----------------------------------------------------------------------
    @isTest
    static void testMultipleMatchingContactsAccumulate() {
        Account acc = createAccount('Multi Smith Account');

        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Smith', FirstName = 'Alice',  AccountId = acc.Id),
            new Contact(LastName = 'Smith', FirstName = 'Bob',    AccountId = acc.Id),
            new Contact(LastName = 'Jones', FirstName = null,     AccountId = acc.Id)
        };
        insert contacts;

        Account updatedAcc = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(3, updatedAcc.Smith_Count__c,
            'Smith_Count__c should be 3 for two Smith contacts and one null-FirstName contact.');
    }

    // -----------------------------------------------------------------------
    // TEST 5: Deleting a matching contact decreases the count
    // -----------------------------------------------------------------------
    @isTest
    static void testDeletingMatchingContactDecreasesCount() {
        Account acc = createAccount('Delete Test Account');

        Contact c1 = new Contact(LastName = 'Smith', FirstName = 'Alice', AccountId = acc.Id);
        Contact c2 = new Contact(LastName = 'Smith', FirstName = 'Bob',   AccountId = acc.Id);
        insert new List<Contact>{ c1, c2 };

        // Verify starting count
        Account afterInsert = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(2, afterInsert.Smith_Count__c, 'Should start with 2 Smith contacts.');

        delete c1;

        Account afterDelete = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, afterDelete.Smith_Count__c,
            'Smith_Count__c should be 1 after deleting one Smith contact.');
    }

    // -----------------------------------------------------------------------
    // TEST 6: Updating a Smith contact to a non-matching contact decreases count
    // -----------------------------------------------------------------------
    @isTest
    static void testUpdatingContactRemovesFromCount() {
        Account acc = createAccount('Update Test Account');

        Contact c = new Contact(LastName = 'Smith', FirstName = 'Alice', AccountId = acc.Id);
        insert c;

        Account afterInsert = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, afterInsert.Smith_Count__c, 'Should start with 1.');

        // Change so it no longer matches either condition
        c.LastName  = 'Johnson';
        c.FirstName = 'Alice';
        update c;

        Account afterUpdate = [SELECT Smith_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, afterUpdate.Smith_Count__c,
            'Smith_Count__c should be 0 after contact no longer matches.');
    }

    // -----------------------------------------------------------------------
    // TEST 7: Contacts with no AccountId are ignored (no exception thrown)
    // -----------------------------------------------------------------------
    @isTest
    static void testContactWithNoAccountIdIsIgnored() {
        Contact c = new Contact(LastName = 'Smith', FirstName = 'Orphan');
        // No AccountId — should not cause an error
        Test.startTest();
        insert c;
        Test.stopTest();
        // If we get here without exception the test passes
        System.assert(true, 'Inserting a contact with no AccountId should not throw an exception.');
    }

    // -----------------------------------------------------------------------
    // TEST 8: Bulk scenario — 200 contacts across multiple accounts (governor limits)
    // -----------------------------------------------------------------------
    @isTest
    static void testBulkInsertMixedContacts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i));
        }
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        // 20 Smith contacts per account = 100 matching, plus 20 non-matching per account
        for (Account a : accounts) {
            for (Integer i = 0; i < 20; i++) {
                contacts.add(new Contact(LastName = 'Smith',   FirstName = 'S' + i, AccountId = a.Id));
                contacts.add(new Contact(LastName = 'NonSmith',FirstName = 'N' + i, AccountId = a.Id));
            }
        }

        Test.startTest();
        insert contacts;
        Test.stopTest();

        for (Account a : [SELECT Smith_Count__c FROM Account WHERE Id IN :accounts]) {
            System.assertEquals(20, a.Smith_Count__c,
                'Each account should have 20 Smith contacts counted.');
        }
    }
}