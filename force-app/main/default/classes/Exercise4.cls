public with sharing class Exercise4 {

    public static void assignIdentifiers(List<Offer__c> records, Map<Id, Offer__c> oldMap) {

        // STEP 1: Figure out which records actually need a new Identifier —
        // all of them on insert, but on update ONLY the ones whose
        // Opportunity actually changed (per the "Opportunity can be changed" rule).
        List<Offer__c> recordsNeedingIdentifier = new List<Offer__c>();
        for (Offer__c o : records) {
            if (oldMap == null) {
                recordsNeedingIdentifier.add(o);
            } else {
                Offer__c oldVersion = oldMap.get(o.Id);
                if (oldVersion.Opportunity__c != o.Opportunity__c) {
                    recordsNeedingIdentifier.add(o);
                }
            }
        }

        if (recordsNeedingIdentifier.isEmpty()) return;

        // STEP 2: Collect the distinct Opportunities involved.
        Set<Id> oppIds = new Set<Id>();
        for (Offer__c o : recordsNeedingIdentifier) {
            if (o.Opportunity__c != null) oppIds.add(o.Opportunity__c);
        }

        // STEP 3: Get each Opportunity's 3-character Identifier code.
        Map<Id, String> oppIdentifiers = new Map<Id, String>();
        for (Opportunity opp : [SELECT Id, Identifier__c FROM Opportunity WHERE Id IN :oppIds]) {
            oppIdentifiers.put(opp.Id, opp.Identifier__c);
        }

        // STEP 4: Find the current highest Sequence_Number__c already used
        // per Opportunity, so we know where to continue counting from.
        Map<Id, Integer> currentMaxSequence = new Map<Id, Integer>();
        for (Offer__c existing : [SELECT Opportunity__c, Sequence_Number__c FROM Offer__c WHERE Opportunity__c IN :oppIds ORDER BY Sequence_Number__c DESC]) {
            if (existing.Sequence_Number__c == null) continue;
            if (!currentMaxSequence.containsKey(existing.Opportunity__c)) {
                currentMaxSequence.put(existing.Opportunity__c, Integer.valueOf(existing.Sequence_Number__c));
            }
        }

        // STEP 5: Assign sequence numbers one record at a time, incrementing
        // a running counter per Opportunity as we go. This is what makes
        // bulk-inserting multiple Offers for the SAME Opportunity work
        // correctly in one transaction.
        for (Offer__c o : recordsNeedingIdentifier) {
            if (o.Opportunity__c == null) continue;

            Integer nextSeq = currentMaxSequence.containsKey(o.Opportunity__c)
                ? currentMaxSequence.get(o.Opportunity__c) + 1
                : 0;

            o.Sequence_Number__c = nextSeq;

            String oppCode = oppIdentifiers.get(o.Opportunity__c);
            o.Identifier__c = oppCode + '-' + String.valueOf(nextSeq).leftPad(3, '0');

            currentMaxSequence.put(o.Opportunity__c, nextSeq);
        }
    }
}