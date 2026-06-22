trigger ErrorMessageTrigger on Error_Message__e (after insert) {

    List<Error_Log__c> errs = new List<Error_Log__c>();
    
    for (Error_Message__e event : Trigger.new) {
        Error_Log__c log = new Error_Log__c(
            Source_Component__c = event.Source_Component__c,
            Error_Message__c = event.Error_Message__c
        );
        errs.add(log);
    }
    
    insert errs;
}