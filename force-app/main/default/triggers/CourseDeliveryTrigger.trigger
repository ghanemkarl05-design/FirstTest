trigger CourseDeliveryTrigger on Course_Delivery__c (before insert, before update) {

    Trigger_Switch__mdt tsw = Trigger_Switch__mdt.getInstance('Course_Delivery_Trigger');

    if (tsw == null || tsw.Active_Flag__c == true) {
        CourseDeliveryTriggerHandler.preventInvalidCourseDeliveries(
            Trigger.new, 
            Trigger.oldMap
        );
    }
}