public with sharing class Exercise3 {

    // RULE 1 (tutor's version): An Account can only have ONE Competitor
    // linked to a Quote, and ONE Competitor linked to an Opportunity.
    public static void checkCompetitorLinks(List<Competitor__c> newList, Map<Id,Competitor__c> oldMap, Map<Id,Competitor__c> newMap){

        // Creating a map of Account IDs to Competitors. One for the quotes and one for the opps
        Map<Id,Competitor__c> accountIdsToCompetitorForQuotesMap = new Map<Id,Competitor__c>();
        Map<Id,Competitor__c> accountIdsToCompetitorForOppsMap = new Map<Id,Competitor__c>();

        // Looping over the new list of created competitors
        for(Competitor__c comp : newList){

            // If the old map is null (ie: in a create state) or the quote has been changed or the account has been changed
            if(
                (oldMap == null || oldMap.get(comp.Id).Quote__c != comp.Quote__c || oldMap.get(comp.Id).Account__c != comp.Account__c)
                    &&
                (comp.Quote__c != null && comp.Account__c != null)
            ) {
                // Add the account Id and the competitor to the corresponsing map
                accountIdsToCompetitorForQuotesMap.put(comp.Account__c,comp);
            }

            // If the old map is null (ie: in a create state) or the opportunity has been changed or the account has been changed
            if(
                (oldMap == null || oldMap.get(comp.Id).Opportunity__c != comp.Opportunity__c || oldMap.get(comp.Id).Account__c != comp.Account__c)
                    &&
                (comp.Opportunity__c != null && comp.Account__c != null)
            ) {
                // Add the account Id and the competitor to the corresponsing map
                accountIdsToCompetitorForOppsMap.put(comp.Account__c,comp);
            }
        }
        // If the map isn't empty
        if(!accountIdsToCompetitorForQuotesMap.isEmpty()){

            // Looping over all the accounts that have the account ids in the map and quote is not null
            for(Competitor__c comp : [SELECT Id,Account__c FROM Competitor__c WHERE Account__c IN :accountIdsToCompetitorForQuotesMap.keySet() AND Quote__c != null]){

                // If the comprtitor is not part of the current transaction
                if(newMap == null || (newMap != null && !newMap.keySet().contains(comp.Id))){
                    // Getting the competitor from the filled map
                    Competitor__c accountComp = accountIdsToCompetitorForQuotesMap.get(comp.Account__c);

                    // Adding the error
                    accountComp.addError('This account is already related to a quote through a competitor');
                }

            }
        }

        // If the map isn't empty
        if(!accountIdsToCompetitorForOppsMap.isEmpty()){

            // Looping over all the accounts that have the account ids in the map and opportunity is not null
            for(Competitor__c comp : [SELECT Id,Account__c FROM Competitor__c WHERE Account__c IN :accountIdsToCompetitorForOppsMap.keySet() AND Opportunity__c != null]){

                // If the comprtitor is not part of the current transaction
                if(newMap == null || (newMap != null && !newMap.keySet().contains(comp.Id))){
                    // Getting the competitor from the filled map
                    Competitor__c accountComp = accountIdsToCompetitorForOppsMap.get(comp.Account__c);

                    // Adding the error
                    accountComp.addError('This account is already related to an opportunity through a competitor');
                }
            }
        }

    }
    public static void addAccountToOpportunityIfMissing(List<Competitor__c> newRecords) {

    // Only care about records that were just added via a Quote
    List<Competitor__c> quoteCompetitors = new List<Competitor__c>();
    for (Competitor__c c : newRecords) {
        if (c.Quote__c != null) quoteCompetitors.add(c);
    }
    if (quoteCompetitors.isEmpty()) return;

    // Find each Quote's parent Opportunity
    Set<Id> quoteIds = new Set<Id>();
    for (Competitor__c c : quoteCompetitors) quoteIds.add(c.Quote__c);

    Map<Id, Id> quoteToOpportunity = new Map<Id, Id>();
    for (Quote q : [SELECT Id, OpportunityId FROM Quote WHERE Id IN :quoteIds]) {
        quoteToOpportunity.put(q.Id, q.OpportunityId);
    }

    Set<Id> accountIds = new Set<Id>();
    for (Competitor__c c : quoteCompetitors) accountIds.add(c.Account__c);

    // Which of these Accounts already have an Opp-linked Competitor?
    Set<Id> accountsWithOppLink = new Set<Id>();
    for (Competitor__c ec : [SELECT Account__c FROM Competitor__c WHERE Account__c IN :accountIds AND Opportunity__c != null]) {
        accountsWithOppLink.add(ec.Account__c);
    }

    // Build the list of brand-new Competitor records to create
    List<Competitor__c> toInsert = new List<Competitor__c>();
    Set<Id> queuedAccounts = new Set<Id>();

    for (Competitor__c c : quoteCompetitors) {
        Id oppId = quoteToOpportunity.get(c.Quote__c);
        if (oppId == null) continue;
        if (accountsWithOppLink.contains(c.Account__c)) continue;
        if (queuedAccounts.contains(c.Account__c)) continue;

        toInsert.add(new Competitor__c(Account__c = c.Account__c, Opportunity__c = oppId));
        queuedAccounts.add(c.Account__c);
    }

    if (!toInsert.isEmpty()) insert toInsert;
}
}