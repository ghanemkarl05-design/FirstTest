/**
@Description: This Apex Class is the controller for the LWC customerOrders. It handles calling OTO to get the orders and get the related account information
@Author: Georges Al Hajj
@Company: EI-Technologies
@Last Modified : 30-04-2026
@Last Modified By  : Georges Al Hajj
@Test Class: AP02_customerOrdersController_Test
*/
public with sharing class Reservation {

    public static void checkResourceAvailability(List<Resource_Reservation__c> records, Map<Id, Resource_Reservation__c> oldMap) {

        // figure out which ones actually need checking
        List<Resource_Reservation__c> recordsToCheck = new List<Resource_Reservation__c>();
        for (Resource_Reservation__c r : records) {
            if (oldMap == null) {
                // brand new insert, always check it
                recordsToCheck.add(r);
            } else {
                Resource_Reservation__c oldVersion = oldMap.get(r.Id);
                // only re-check if resource or dates actually changed
                if (oldVersion.Resource__c != r.Resource__c
                    || oldVersion.Start_Date__c != r.Start_Date__c
                    || oldVersion.End_Date__c != r.End_Date__c) {
                    recordsToCheck.add(r);
                }
            }
        }

        // nothing to check? bail early
        if (recordsToCheck.isEmpty()) return;

        // grab the resources we actually care about
        Set<Id> resourceIds = new Set<Id>();
        for (Resource_Reservation__c r : recordsToCheck) {
            if (r.Resource__c != null) resourceIds.add(r.Resource__c);
        }

        // pull every existing booking for those resources, grouped by resource
        Map<Id, List<Resource_Reservation__c>> existingByResource = new Map<Id, List<Resource_Reservation__c>>();
        for (Resource_Reservation__c existing : [SELECT Id, Resource__c, Start_Date__c, End_Date__c 
                                                   FROM Resource_Reservation__c 
                                                   WHERE Resource__c IN :resourceIds]) {
            if (!existingByResource.containsKey(existing.Resource__c)) {
                existingByResource.put(existing.Resource__c, new List<Resource_Reservation__c>());
            }
            existingByResource.get(existing.Resource__c).add(existing);
        }

        // keeps track of stuff we already cleared in THIS save (catches bulk conflicts)
        Map<Id, List<Resource_Reservation__c>> seenInThisBatch = new Map<Id, List<Resource_Reservation__c>>();

        for (Resource_Reservation__c r : recordsToCheck) {
            // skip if missing the basics, can't check anyway
            if (r.Resource__c == null || r.Start_Date__c == null || r.End_Date__c == null) continue;

            Boolean conflictFound = false;

            // check against what's already saved in the DB
            if (existingByResource.containsKey(r.Resource__c)) {
                for (Resource_Reservation__c existing : existingByResource.get(r.Resource__c)) {
                    if (existing.Id == r.Id) continue; // don't compare a record to itself
                    if (datesOverlap(r.Start_Date__c, r.End_Date__c, existing.Start_Date__c, existing.End_Date__c)) {
                        conflictFound = true;
                        break;
                    }
                }
            }

            // also check against other new ones in this same transaction
            if (!conflictFound && seenInThisBatch.containsKey(r.Resource__c)) {
                for (Resource_Reservation__c other : seenInThisBatch.get(r.Resource__c)) {
                    if (datesOverlap(r.Start_Date__c, r.End_Date__c, other.Start_Date__c, other.End_Date__c)) {
                        conflictFound = true;
                        break;
                    }
                }
            }

            if (conflictFound) {
                // block the save, resource's taken
                r.addError('This resource is already reserved during the selected time range.');
            } else {
                // all good, remember it so the next record in this batch checks against it too
                if (!seenInThisBatch.containsKey(r.Resource__c)) {
                    seenInThisBatch.put(r.Resource__c, new List<Resource_Reservation__c>());
                }
                seenInThisBatch.get(r.Resource__c).add(r);
            }
        }
    }

    // simple overlap math: starts before the other ends, AND ends after the other starts
    private static Boolean datesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
        return start1 < end2 && end1 > start2;
    }
}