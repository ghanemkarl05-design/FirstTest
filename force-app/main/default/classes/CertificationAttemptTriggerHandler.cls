public without sharing class CertificationAttemptTriggerHandler {

    public static void createCertificationHeld(List<Certification_Attempt__c> certAttempts, Map<Id, Certification_Attempt__c> oldMap) {

        System.Debug('Calling the createCertificationHeld method');

        Set<Id> candidates = new Set<Id>();
        Set<Id> certifications = new Set<Id>();
        List<Certification_Attempt__c> certAttemptsPass = new List<Certification_Attempt__c>();
        Map<String, Integer> passCounts = new Map<String, Integer>();
        Map<String, Certification_Held__c> certsHeldToAdd = new Map<String, Certification_Held__c>();

        for (Certification_Attempt__c attempt : certAttempts) {
            if (attempt.Status__c == 'Complete/Pass' && (oldMap == null || oldMap.get(attempt.Id).Status__c != 'Complete/Pass')) {
                candidates.add(attempt.Certification_Candidate__c);
                certifications.add(attempt.Certification_Id__c);
                certAttemptsPass.add(attempt);
            }
        }

        for (List<Certification_Attempt__c> cAs : [SELECT Id, Certification_Id__c, Certification_Candidate__c, Number_of_Elements_for_Cert__c
                                                   FROM Certification_Attempt__c
                                                   WHERE Certification_Candidate__c IN :candidates
                                                   AND Status__c = 'Complete/Pass'
                                                   AND Certification_element__r.Certification__c IN :certifications]) {
            for (Certification_Attempt__c cA : cAs) {
                System.debug('Retrieved certAttempt id' + cA.id + ' candidate id'
                            + cA.Certification_Id__c + ' certification id' + cA.Certification_Candidate__c
                            + ' number of elements for cert ' + cA.Number_of_Elements_for_Cert__c);
                String curKey = cA.Certification_Candidate__c + cA.Certification_Id__c;
                if (passCounts.containsKey(curKey)) {
                    passCounts.put(curKey, (passCounts.get(curKey) + 1));
                } else {
                    passCounts.put(curKey, 1);
                }
            }
        }

        System.debug('Size of passCounts = ' + passCounts.size());

        for (Certification_Attempt__c certAttempt : certAttemptsPass) {
            String currentKey = certAttempt.Certification_Candidate__c + certAttempt.Certification_Id__c;
            if (passCounts.containsKey(currentKey) &&
                passCounts.get(currentKey) == certAttempt.Number_of_Elements_for_Cert__c) {
                Certification_Held__c certHeld = new Certification_Held__c();
                certHeld.Date_Achieved__c = certAttempt.Completion_Date__c;
                certHeld.Certification__c = certAttempt.Certification_Id__c;
                certHeld.Certified_Professional__c = certAttempt.Certification_Candidate__c;
                certsHeldToAdd.put(currentKey, certHeld);
                System.debug('A Certification Held record was added');
            }
        }

        try {
            if (certsHeldToAdd.size() > 0) {
                insert certsHeldToAdd.values();
                System.debug(certsHeldToAdd.size());
            }
        } catch (System.DmlException ex) {
            Error_Log__c err = new Error_Log__c();
            err.Source_Component__c = 'createCertificationHeld';
            err.Error_Message__c = ex.getMessage();
            insert err;
        }
    }

    public static void grantInstructorSharingAccess(List<Certification_Attempt__c> triggerNew, Map<Id, Certification_Attempt__c> oldMap, Boolean isInsert, Boolean isUpdate) {
        System.debug('Starting the Grant Instructor Sharing Access logic');
        List<Certification_Attempt__Share> sharesToCreate = new List<Certification_Attempt__Share>();
        List<Certification_Attempt__Share> sharesToDelete = new List<Certification_Attempt__Share>();
        Map<Id, Id> certAttemptToInstructorMap = new Map<Id, Id>();
        for (Certification_Attempt__c certAttempt : triggerNew) {
            if (isInsert || certAttempt.Certifying_Instructor__c != oldMap.get(certAttempt.Id).Certifying_Instructor__c) {
                if (certAttempt.Certifying_Instructor__c != null) {
                    Certification_Attempt__Share certAttemptShare = new Certification_Attempt__Share(
                        parentId = certAttempt.Id,
                        userOrGroupId = certAttempt.Certifying_Instructor__c,
                        rowCause = Schema.Certification_Attempt__Share.RowCause.Manual,
                        accessLevel = 'Edit'
                    );
                    sharesToCreate.add(certAttemptShare);
                }
            }
            if (isUpdate) {
                if (certAttempt.Certifying_Instructor__c != oldMap.get(certAttempt.Id).Certifying_Instructor__c) {
                    certAttemptToInstructorMap.put(certAttempt.Id, certAttempt.Certifying_Instructor__c);
                }
            }
        }
        if (certAttemptToInstructorMap.size() > 0) {
            for (Certification_Attempt__Share certAttemptShare :
                [SELECT UserOrGroupId, RowCause, ParentId, Id, AccessLevel
                   FROM Certification_Attempt__Share
                  WHERE ParentId IN :certAttemptToInstructorMap.keySet()
                    AND RowCause = 'Certifying_Instructor__c']) {
                if (certAttemptToInstructorMap.get(certAttemptShare.ParentId) != certAttemptShare.UserOrGroupId) {
                    sharesToDelete.add(certAttemptShare);
                }
            }
        }
        try {
            if (sharesToCreate.size() > 0) { insert sharesToCreate; }
            if (sharesToDelete.size() > 0) { delete sharesToDelete; }
        } catch (System.DmlException ex) {
            Error_Log__c err = new Error_Log__c();
            err.Source_Component__c = 'grantInstructorSharingAccess';
            err.Error_Message__c = ex.getMessage();
            insert err;
        }
    }

    public static void validateCertificationAttempt(List<Certification_Attempt__c> triggerNew) {
        System.debug('Starting the Validate Certification Attempt logic');
        Set<String> concatStudentElement = new Set<String>();
        Set<ID> candidateIDs = new Set<ID>();
        for (Certification_Attempt__c dbca : triggerNew) {
            candidateIDs.add(dbca.Certification_Candidate__c);
        }
        for (Certification_Attempt__c dbca : [SELECT Certification_Candidate__c, Certification_Element__c, Status__c
                                               FROM Certification_Attempt__c
                                              WHERE Status__c IN ('In Progress', 'Complete/Pass')
                                                AND Certification_Candidate__c IN :candidateIDs]) {
            concatStudentElement.add((String)dbca.Certification_Candidate__c + (String)dbca.Certification_Element__c + (String)dbca.Status__c);
        }
        for (Certification_Attempt__c ca : triggerNew) {
            if (concatStudentElement.contains((String)ca.Certification_Candidate__c + (String)ca.Certification_Element__c + 'In Progress') ||
                concatStudentElement.contains((String)ca.Certification_Candidate__c + (String)ca.Certification_Element__c + 'Complete/Pass')) {
                ca.addError('Cannot attempt cert for element already in progress or completed');
            }
        }
    }
}