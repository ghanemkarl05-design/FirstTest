public with sharing class ReservationTriggerHandler extends TriggerHandler implements ITriggerHandler {

    private Map<Id, Resource_Reservation__c> newMap;
    private Map<Id, Resource_Reservation__c> oldMap;
    private List<Resource_Reservation__c> TriggerNew;
    private List<Resource_Reservation__c> TriggerOld;


    public ReservationTriggerHandler() {
        this.newMap = (Map<Id, Resource_Reservation__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Resource_Reservation__c>) Trigger.oldMap;
        this.TriggerNew = (List<Resource_Reservation__c>) Trigger.New;
        this.TriggerOld = (List<Resource_Reservation__c>) Trigger.Old;
    }

    
    public static Boolean TriggerDisabled = false;

    // interface needs this, just returns the flag above
    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    public override void beforeInsert() {
        // new reservations, check for conflicts before they save
        Reservation.checkResourceAvailability(TriggerNew, null);
    }

    public override void afterInsert() {
        // nothing needed here for this exercise
    }

    public override void beforeUpdate() {
        // edited reservations, recheck in case resource/dates changed
        Reservation.checkResourceAvailability(TriggerNew, oldMap);
    }

    public override void afterUpdate() {
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUnDelete() {
    }
}