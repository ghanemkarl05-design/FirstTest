@isTest
private class Exercise4_Test {

    private static Opportunity createOpportunity(String identifier) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp ' + identifier,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Identifier__c = identifier
        );
        insert opp;
        return opp;
    }

    @isTest
    static void testFirstOfferGetsZeroSequence() {
        Opportunity opp = createOpportunity('EIT');

        Offer__c offer = new Offer__c(Opportunity__c = opp.Id);
        insert offer;

        Offer__c result = [SELECT Identifier__c, Sequence_Number__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('EIT-000', result.Identifier__c, 'First offer should be EIT-000.');
        System.assertEquals(0, result.Sequence_Number__c, 'First offer sequence number should be 0.');
    }

    @isTest
    static void testSecondOfferIncrementsSequence() {
        Opportunity opp = createOpportunity('EIT');

        Offer__c offer1 = new Offer__c(Opportunity__c = opp.Id);
        insert offer1;

        Offer__c offer2 = new Offer__c(Opportunity__c = opp.Id);
        insert offer2;

        Offer__c result = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer2.Id];
        System.assertEquals('EIT-001', result.Identifier__c, 'Second offer should be EIT-001.');
    }

    @isTest
    static void testBulkInsertSameOpportunitySequencesCorrectly() {
        Opportunity opp = createOpportunity('BLK');

        List<Offer__c> offers = new List<Offer__c>();
        for (Integer i = 0; i < 5; i++) {
            offers.add(new Offer__c(Opportunity__c = opp.Id));
        }

        Test.startTest();
        insert offers;
        Test.stopTest();

        List<Offer__c> results = [SELECT Identifier__c FROM Offer__c WHERE Opportunity__c = :opp.Id ORDER BY Sequence_Number__c];
        System.assertEquals(5, results.size(), 'Should have 5 offers.');

        for (Integer i = 0; i < 5; i++) {
            String expected = 'BLK-' + String.valueOf(i).leftPad(3, '0');
            System.assertEquals(expected, results[i].Identifier__c, 'Offer ' + i + ' should be ' + expected);
        }
    }

    @isTest
    static void testMultipleOpportunitiesEachStartAtZero() {
        Opportunity opp1 = createOpportunity('AAA');
        Opportunity opp2 = createOpportunity('BBB');

        Offer__c offer1 = new Offer__c(Opportunity__c = opp1.Id);
        Offer__c offer2 = new Offer__c(Opportunity__c = opp2.Id);
        insert new List<Offer__c>{ offer1, offer2 };

        Offer__c result1 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer1.Id];
        Offer__c result2 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer2.Id];

        System.assertEquals('AAA-000', result1.Identifier__c, 'First offer of opp1 should be AAA-000.');
        System.assertEquals('BBB-000', result2.Identifier__c, 'First offer of opp2 should be BBB-000, independent sequence.');
    }

    @isTest
    static void testChangingOpportunityRecalculatesIdentifier() {
        Opportunity opp1 = createOpportunity('OLD');
        Opportunity opp2 = createOpportunity('NEW');

        Offer__c offer = new Offer__c(Opportunity__c = opp1.Id);
        insert offer;

        Offer__c check1 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('OLD-000', check1.Identifier__c, 'Should start as OLD-000.');

        offer.Opportunity__c = opp2.Id;
        update offer;

        Offer__c check2 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('NEW-000', check2.Identifier__c, 'After moving to a new Opportunity, should become NEW-000.');
    }

    @isTest
    static void testUpdatingWithoutChangingOpportunityKeepsSameIdentifier() {
        Opportunity opp = createOpportunity('SAM');

        Offer__c offer = new Offer__c(Opportunity__c = opp.Id);
        insert offer;

        Offer__c check1 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('SAM-000', check1.Identifier__c);

        offer.Opportunity__c = opp.Id;
        update offer;

        Offer__c check2 = [SELECT Identifier__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('SAM-000', check2.Identifier__c, 'Identifier should remain unchanged since Opportunity did not actually change.');
    }

    @isTest
    static void testBulkInsertAcrossMultipleOpportunitiesGovernorLimits() {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Identifier__c = 'O' + i
            ));
        }
        insert opps;

        List<Offer__c> offers = new List<Offer__c>();
        for (Opportunity o : opps) {
            for (Integer j = 0; j < 3; j++) {
                offers.add(new Offer__c(Opportunity__c = o.Id));
            }
        }

        Test.startTest();
        insert offers;
        Test.stopTest();

        for (Opportunity o : opps) {
            List<Offer__c> theseOffers = [SELECT Identifier__c FROM Offer__c WHERE Opportunity__c = :o.Id ORDER BY Sequence_Number__c];
            System.assertEquals(3, theseOffers.size());
            System.assertEquals(o.Identifier__c + '-000', theseOffers[0].Identifier__c);
            System.assertEquals(o.Identifier__c + '-001', theseOffers[1].Identifier__c);
            System.assertEquals(o.Identifier__c + '-002', theseOffers[2].Identifier__c);
        }
    }
}
