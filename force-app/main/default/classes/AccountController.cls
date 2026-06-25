public with sharing class AccountController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByEmployeeCount(Integer employeeCount) {
        // If the user hasn't entered anything, default to 0
        Integer finalCount = (employeeCount == null) ? 0 : employeeCount;
        
        return [
            SELECT Id, Name, NumberOfEmployees, Phone 
            FROM Account 
            WHERE NumberOfEmployees >= :finalCount 
            WITH SECURITY_ENFORCED
            ORDER BY NumberOfEmployees ASC
            LIMIT 10
        ];
    }
}
