@isTest
private class Reservation_Test {

    // quick helper so we don't repeat this everywhere
    private static Resource__c createResource(String name) {
        Resource__c res = new Resource__c(Name = name, Type__c = 'Room');
        insert res;
        return res;
    }

    // just builds the object, doesn't insert it (caller decides when)
    private static Resource_Reservation__c buildReservation(Id resourceId, DateTime startDt, DateTime endDt) {
        return new Resource_Reservation__c(
            Resource__c = resourceId,
            Start_Date__c = startDt,
            End_Date__c = endDt
        );
    }

    // simplest case, no conflicts, should just work
    @isTest
    static void testNoConflictSavesSuccessfully() {
        Resource__c res = createResource('Room A');
        DateTime start = DateTime.now();
        DateTime endDt = start.addHours(1);

        Resource_Reservation__c r = buildReservation(res.Id, start, endDt);
        insert r;

        System.assertEquals(1, [SELECT COUNT() FROM Resource_Reservation__c WHERE Id = :r.Id]);
    }

    // two bookings on the same room overlapping in time, this should get blocked
    @isTest
    static void testOverlappingReservationBlocked() {
        Resource__c res = createResource('Room B');
        DateTime start = DateTime.now();

        insert buildReservation(res.Id, start, start.addHours(1));

        Resource_Reservation__c overlapping = buildReservation(res.Id, start.addMinutes(30), start.addMinutes(90));

        Boolean exceptionThrown = false;
        try {
            insert overlapping;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('already reserved'), 'Should mention the resource is already reserved.');
        }
        System.assert(exceptionThrown, 'Overlapping reservation should have been blocked.');
    }

    // one ends exactly when the other starts, shouldn't count as a clash
    @isTest
    static void testBackToBackReservationSucceeds() {
        Resource__c res = createResource('Room C');
        DateTime start = DateTime.now();
        DateTime middle = start.addHours(1);

        insert buildReservation(res.Id, start, middle);

        Resource_Reservation__c backToBack = buildReservation(res.Id, middle, middle.addHours(1));
        insert backToBack;

        System.assertEquals(1, [SELECT COUNT() FROM Resource_Reservation__c WHERE Id = :backToBack.Id]);
    }

    // same time slot, but different rooms, that's totally fine
    @isTest
    static void testSameTimeDifferentResourceSucceeds() {
        Resource__c resA = createResource('Room D');
        Resource__c resB = createResource('Room E');
        DateTime start = DateTime.now();
        DateTime endDt = start.addHours(1);

        insert buildReservation(resA.Id, start, endDt);
        Resource_Reservation__c onDifferentResource = buildReservation(resB.Id, start, endDt);
        insert onDifferentResource;

        System.assertEquals(1, [SELECT COUNT() FROM Resource_Reservation__c WHERE Id = :onDifferentResource.Id]);
    }

    // new booking squeezed inside an existing one, still a conflict
    @isTest
    static void testFullyNestedOverlapBlocked() {
        Resource__c res = createResource('Room F');
        DateTime start = DateTime.now();

        insert buildReservation(res.Id, start, start.addHours(3));

        Resource_Reservation__c nested = buildReservation(res.Id, start.addHours(1), start.addHours(2));

        Boolean exceptionThrown = false;
        try {
            insert nested;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'A reservation nested inside an existing one should be blocked.');
    }

    // flip side of the test above, new booking swallows the whole existing one
    @isTest
    static void testFullyContainingOverlapBlocked() {
        Resource__c res = createResource('Room G');
        DateTime start = DateTime.now();

        insert buildReservation(res.Id, start.addHours(1), start.addHours(2));

        Resource_Reservation__c containing = buildReservation(res.Id, start, start.addHours(3));

        Boolean exceptionThrown = false;
        try {
            insert containing;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'A reservation fully containing an existing one should be blocked.');
    }

    // editing something unrelated shouldn't trigger a recheck at all
    @isTest
    static void testUpdateWithoutChangingDatesSucceeds() {
        Resource__c res = createResource('Room H');
        DateTime start = DateTime.now();

        Resource_Reservation__c r = buildReservation(res.Id, start, start.addHours(1));
        insert r;

        r.Description__c = 'Updated description only';
        update r;

        System.assertEquals('Updated description only', [SELECT Description__c FROM Resource_Reservation__c WHERE Id = :r.Id].Description__c);
    }

    // booking was fine at first, then got edited into a clash, should still catch it
    @isTest
    static void testUpdateCreatingConflictBlocked() {
        Resource__c res = createResource('Room I');
        DateTime start = DateTime.now();

        insert buildReservation(res.Id, start, start.addHours(1));

        Resource_Reservation__c r2 = buildReservation(res.Id, start.addHours(2), start.addHours(3));
        insert r2;

        r2.Start_Date__c = start.addMinutes(30);
        r2.End_Date__c = start.addMinutes(90);

        Boolean exceptionThrown = false;
        try {
            update r2;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Updating to create an overlap should be blocked.');
    }

    // two brand new clashing bookings in the SAME save, neither's in the db yet
    @isTest
    static void testBulkInsertConflictingWithEachOtherBlocked() {
        Resource__c res = createResource('Room J');
        DateTime start = DateTime.now();

        Resource_Reservation__c r1 = buildReservation(res.Id, start, start.addHours(1));
        Resource_Reservation__c r2 = buildReservation(res.Id, start.addMinutes(30), start.addMinutes(90));

        Database.SaveResult[] results = Database.insert(new List<Resource_Reservation__c>{ r1, r2 }, false);

        System.assert(results[0].isSuccess(), 'First record should succeed.');
        System.assert(!results[1].isSuccess(), 'Second record should fail due to conflicting with the first, in the same batch.');
    }

    // a bigger batch, just making sure nothing breaks at scale
    @isTest
    static void testBulkInsertNonConflictingAcrossResources() {
        List<Resource__c> resources = new List<Resource__c>();
        for (Integer i = 0; i < 10; i++) {
            resources.add(new Resource__c(Name = 'Bulk Room ' + i, Type__c = 'Room'));
        }
        insert resources;

        DateTime start = DateTime.now();
        List<Resource_Reservation__c> reservations = new List<Resource_Reservation__c>();
        for (Resource__c r : resources) {
            reservations.add(buildReservation(r.Id, start, start.addHours(1)));
        }

        Test.startTest();
        insert reservations;
        Test.stopTest();

        System.assertEquals(10, [SELECT COUNT() FROM Resource_Reservation__c WHERE Resource__c IN :resources]);
    }
}