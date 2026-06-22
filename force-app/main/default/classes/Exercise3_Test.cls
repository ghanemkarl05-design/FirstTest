@isTest
private class Exercise3_Test {

    private static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(String name, Id accountId) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Quote createQuote(String name, Id opportunityId) {
        Quote q = new Quote(
            Name = name,
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;
        return q;
    }

    // -----------------------------------------------------------------------
    // TEST 1: Competitor with only Opportunity populated saves successfully
    // -----------------------------------------------------------------------
    @isTest
    static void testInsertCompetitorWithOpportunityOnlySucceeds() {
        Account acc = createAccount('Acc Opp Only');
        Opportunity opp = createOpportunity('Opp1', acc.Id);

        Competitor__c c = new Competitor__c(Name = 'Comp1', Account__c = acc.Id, Opportunity__c = opp.Id);
        insert c;

        List<Competitor__c> results = [SELECT Id FROM Competitor__c WHERE Account__c = :acc.Id];
        System.assertEquals(1, results.size(), 'Should have exactly 1 Competitor for this account.');
    }

    // -----------------------------------------------------------------------
    // TEST 2: Competitor with only Quote populated auto-creates an Opportunity Competitor
    // -----------------------------------------------------------------------
    @isTest
    static void testInsertCompetitorWithQuoteOnlyAutoCreatesOpportunityLink() {
        Account acc = createAccount('Acc Quote Only');
        Opportunity opp = createOpportunity('Opp2', acc.Id);
        Quote q = createQuote('Quote1', opp.Id);

        Competitor__c c = new Competitor__c(Name = 'Comp2', Account__c = acc.Id, Quote__c = q.Id);
        insert c;

        List<Competitor__c> results = [SELECT Id, Opportunity__c, Quote__c FROM Competitor__c WHERE Account__c = :acc.Id];
        System.assertEquals(2, results.size(), 'Should have 2 Competitors: the Quote one and the auto-created Opportunity one.');

        Boolean foundOppLink = false;
        for (Competitor__c result : results) {
            if (result.Opportunity__c == opp.Id && result.Quote__c == null) {
                foundOppLink = true;
            }
        }
        System.assert(foundOppLink, 'An auto-created Competitor linked to the Opportunity should exist.');
    }

    // -----------------------------------------------------------------------
    // TEST 3: A second Competitor with a DIFFERENT Opportunity for the same Account is blocked
    // -----------------------------------------------------------------------
    @isTest
    static void testSecondOpportunityLinkForSameAccountBlocked() {
        Account acc = createAccount('Acc Two Opps');
        Opportunity opp1 = createOpportunity('Opp A', acc.Id);
        Opportunity opp2 = createOpportunity('Opp B', acc.Id);

        Competitor__c c1 = new Competitor__c(Name = 'Comp3', Account__c = acc.Id, Opportunity__c = opp1.Id);
        insert c1;

        Competitor__c c2 = new Competitor__c(Name = 'Comp4', Account__c = acc.Id, Opportunity__c = opp2.Id);

        Boolean exceptionThrown = false;
        try {
            insert c2;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('already related to an opportunity'),
                'Error message should mention the account is already related to an opportunity.');
        }
        System.assert(exceptionThrown, 'Inserting a second Opportunity-linked Competitor for the same Account should fail.');
    }

    // -----------------------------------------------------------------------
    // TEST 4: A second Competitor with a DIFFERENT Quote for the same Account is blocked
    // -----------------------------------------------------------------------
    @isTest
    static void testSecondQuoteLinkForSameAccountBlocked() {
        Account acc = createAccount('Acc Two Quotes');
        Opportunity opp1 = createOpportunity('Opp C', acc.Id);
        Opportunity opp2 = createOpportunity('Opp D', acc.Id);
        Quote q1 = createQuote('Quote A', opp1.Id);
        Quote q2 = createQuote('Quote B', opp2.Id);

        Competitor__c c1 = new Competitor__c(Name = 'Comp5', Account__c = acc.Id, Quote__c = q1.Id);
        insert c1; // also auto-creates an Opportunity link to opp1

        Competitor__c c2 = new Competitor__c(Name = 'Comp6', Account__c = acc.Id, Quote__c = q2.Id);

        Boolean exceptionThrown = false;
        try {
            insert c2;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('already related to a quote'),
                'Error message should mention the account is already related to a quote.');
        }
        System.assert(exceptionThrown, 'Inserting a second Quote-linked Competitor for the same Account should fail.');
    }

    // -----------------------------------------------------------------------
    // TEST 5: Rule 2 auto-add is SKIPPED if the Account already has an Opportunity link
    // -----------------------------------------------------------------------
    @isTest
    static void testAutoAddSkippedIfAccountAlreadyHasOpportunityLink() {
        Account acc = createAccount('Acc Already Has Opp');
        Opportunity opp1 = createOpportunity('Existing Opp', acc.Id);
        Opportunity opp2 = createOpportunity('Quote Opp', acc.Id);
        Quote q = createQuote('Quote C', opp2.Id);

        Competitor__c c1 = new Competitor__c(Name = 'Comp7', Account__c = acc.Id, Opportunity__c = opp1.Id);
        insert c1;

        Competitor__c c2 = new Competitor__c(Name = 'Comp8', Account__c = acc.Id, Quote__c = q.Id);
        insert c2;

        List<Competitor__c> results = [SELECT Id FROM Competitor__c WHERE Account__c = :acc.Id];
        System.assertEquals(2, results.size(),
            'Should have exactly 2 Competitors (c1 and c2) — no auto-created third record, since the Account already has an Opportunity link.');
    }

    // -----------------------------------------------------------------------
    // TEST 6: Updating a Competitor without changing Account/Opportunity/Quote does not error
    // -----------------------------------------------------------------------
    @isTest
    static void testUpdateWithoutRelevantFieldChangeDoesNotError() {
        Account acc = createAccount('Acc Update Test');
        Opportunity opp = createOpportunity('Opp Update', acc.Id);

        Competitor__c c = new Competitor__c(Name = 'Comp9', Account__c = acc.Id, Opportunity__c = opp.Id);
        insert c;

        c.Opportunity__c = opp.Id; // re-setting the same value, no real change
        update c; // should NOT throw

        System.assert(true, 'Updating without changing Account/Opportunity/Quote should not throw an error.');
    }

    // -----------------------------------------------------------------------
    // TEST 7: Bulk insert across many distinct Accounts succeeds (governor limits)
    // -----------------------------------------------------------------------
    @isTest
    static void testBulkInsertAcrossManyAccounts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 20; i++) {
            accounts.add(new Account(Name = 'Bulk Acc ' + i));
        }
        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Account a : accounts) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + a.Name,
                AccountId = a.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;

        List<Competitor__c> competitors = new List<Competitor__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            competitors.add(new Competitor__c(
                Name = 'Bulk Comp ' + i,
                Account__c = accounts[i].Id,
                Opportunity__c = opps[i].Id
            ));
        }

        Test.startTest();
        insert competitors;
        Test.stopTest();

        System.assertEquals(20, [SELECT COUNT() FROM Competitor__c WHERE Account__c IN :accounts],
            'Each of the 20 Accounts should have exactly 1 Competitor.');
    }
}