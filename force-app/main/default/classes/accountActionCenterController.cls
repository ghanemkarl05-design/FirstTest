public with sharing class AccountActionCenterController {
    
    @AuraEnabled
    public static List<Account> getRecentAccounts() {
        return [SELECT Id, Name, Rating, Phone, Industry, Description 
                FROM Account 
                ORDER BY CreatedDate DESC 
                LIMIT 10];
    }

    @AuraEnabled
    public static List<Account> getHotAccounts() {
        return [SELECT Id, Name, Rating, Phone, Industry, Description 
                FROM Account 
                WHERE Rating = 'Hot' 
                ORDER BY Name ASC];
    }

    @AuraEnabled
    public static List<Account> getAccountsWithoutPhone() {
        return [SELECT Id, Name, Rating, Phone, Industry, Description 
                FROM Account 
                WHERE Phone = null 
                ORDER BY Name ASC];
    }

    @AuraEnabled
    public static void updateAccountDescription(Id accountId, String description) {
        if (String.isBlank(accountId)) {
            throw new AuraHandledException('Account ID cannot be blank.');
        }
        Account acc = new Account(Id = accountId, Description = description);
        update acc;
    }
}
