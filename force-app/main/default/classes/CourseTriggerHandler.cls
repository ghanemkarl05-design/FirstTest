public with sharing class CourseTriggerHandler {

    static final String RETIRED = 'Retired';
    static final String ENROLLED = 'Enrolled';
    static final String SCHEDULED = 'Scheduled';
    static final String CANCELLED = 'Cancelled';
    static final String COURSE_ERROR_MESSAGE = 'Course has enrolled students';
    static final String DELIVERY_ERROR_MESSAGE = 'Unable to update scheduled delivery status';

    public static void checkStatus(List<Course__c> triggerNew, Map<Id, Course__c> oldMap, Map<Id, Course__c> newMap) {

        Set<Id> courseIds = new Set<Id>();

        for (Course__c course : triggerNew) {
            if (oldMap.get(course.Id).Status__c != RETIRED && course.Status__c == RETIRED) {
                courseIds.add(course.Id);
            }
        }

        if (courseIds.size() > 0) {

            for (List<Course_Delivery__c> cds : [SELECT Id, Course__c, Status__c,
                                                  (SELECT Status__c FROM Course_Attendees__r WHERE Status__c = :ENROLLED)
                                                  FROM Course_Delivery__c
                                                  WHERE Course__c IN :courseIds AND Status__c = :SCHEDULED]) {

                List<Course_Delivery__c> courseDeliveriesToUpdate = new List<Course_Delivery__c>();

                for (Course_Delivery__c cd : cds) {
                    if (cd.Course_Attendees__r != null && cd.Course_Attendees__r.size() > 0) {
                        newMap.get(cd.Course__c).addError(COURSE_ERROR_MESSAGE);
                    } else {
                        cd.Status__c = CANCELLED;
                        courseDeliveriesToUpdate.add(cd);
                    }
                }

                if (!courseDeliveriesToUpdate.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(courseDeliveriesToUpdate, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        if (!results[i].isSuccess()) {
                            newMap.get(courseDeliveriesToUpdate[i].Course__c).addError(DELIVERY_ERROR_MESSAGE);
                        }
                    }
                }
            }
        }
    }
}