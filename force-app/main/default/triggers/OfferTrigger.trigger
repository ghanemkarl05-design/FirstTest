trigger OfferTrigger on Offer__c (before insert, before update) {
    new OfferTriggerHandler().run();
}