public class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Name, Industry, Phone, Rating FROM Account LIMIT 50];
    }
}
