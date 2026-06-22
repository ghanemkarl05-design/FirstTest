trigger ReservationTrigger on Resource_Reservation__c (before insert, before update) {
    new ReservationTriggerHandler().run();
}