trigger CompetitorTrigger on Competitor__c (before insert, before update, after insert) {
    new CompetitorTriggerHandler().run();
}