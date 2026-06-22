public with sharing class Exercise2 {

    // Entry point: called from the trigger handler whenever Contacts are
    // inserted, updated, or deleted. Takes the affected Contacts and
    // recalculates the "Smith Count" on each related Account.
    public static void countContactOccurences(List<Contact> contacts, Map<Id, Contact> oldMap) {

        // STEP 1: Collect the distinct AccountIds touched by this trigger run.
        // We use a Set to avoid duplicates if multiple Contacts share an Account.
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : contacts) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        // STEP 2: Query ALL Contacts (not just the trigger's records) that
        // belong to those Accounts AND match our condition: blank FirstName
        // OR LastName = 'Smith'. We requery the full picture to get an
        // accurate total count, not just a +1/-1 guess.
        List<Contact> matchingContacts = [SELECT AccountId, FirstName, LastName 
                                           FROM Contact 
                                           WHERE AccountId IN :accountIds 
                                           AND (LastName = 'Smith' OR FirstName = null)];

        // STEP 3: Tally up how many matching Contacts each Account has,
        // using a Map where the key is the AccountId and the value is the count.
        Map<Id, Integer> counts = new Map<Id, Integer>();

        for (Contact c : matchingContacts) {
            if (counts.containsKey(c.AccountId)) {
                // Already seen this Account before — bump its count by 1
                Integer current = counts.get(c.AccountId);
                counts.put(c.AccountId, current + 1);
            } else {
                // First matching Contact seen for this Account — start at 1
                counts.put(c.AccountId, 1);
            }
        }

        // STEP 4: Build the list of Account records to update.
        // IMPORTANT: loop over ALL accountIds (not just counts.keySet()) so
        // that Accounts with ZERO matches still get reset to 0 — otherwise
        // a deleted/edited Smith contact would leave a stale, too-high count.
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : accountIds) {
            Integer countVal = counts.containsKey(accId) ? counts.get(accId) : 0;
            accountsToUpdate.add(new Account(Id = accId, Smith_Count__c = countVal));
        }

        // STEP 5: Save the updated counts back to the database in one
        // single bulk DML call (never inside a loop!).
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}