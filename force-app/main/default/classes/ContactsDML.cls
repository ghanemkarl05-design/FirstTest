public class ContactsDML {
    public static void standaloneDML(){
        Contact name1 = new Contact(LastName = 'Minkowitz');
        Contact name2 = new Contact(LastName = 'Singh');
        List<Contact> contacts = new List<Contact>();
        contacts.add(name1);
        contacts.add(name2);
        insert contacts;
        System.debug(name1.Id);
        System.debug(name2.Id);
    }
    public static void databaseMethodDML(){
        Contact name1 = new Contact();
        Contact name2 = new Contact(LastName = 'Picasso');
        List<Contact> contacts = new List<Contact>();
        contacts.add(name1);
        contacts.add(name2);
        Database.insert(contacts, true);
    }
    public static void databaseMethodPartialCommit(){
        Contact name1 = new Contact();
        Contact name2 = new Contact(LastName = 'Picasso');
        List<Contact> contacts = new List<Contact>();
        contacts.add(name1);
        contacts.add(name2);
        Database.insert(contacts, false);
        System.debug(name2.Id);
    }
}