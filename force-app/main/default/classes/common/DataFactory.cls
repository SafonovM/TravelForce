public with sharing class DataFactory {

    public Account businessAccount;
    public Contact customerContact;
    public Flight__c flight;
    public Ticket__c ticket;
    public Trip__c trip;

    public Account createAccount(Boolean persist) {
        this.businessAccount = new Account(
            Name = 'ACME Corp.'
        );

        if (persist) {
            insert this.businessAccount;
        }

        return this.businessAccount;
    }

    
    public Contact createContact(Boolean persist) {
        this.customerContact = new Contact(
            FirstName = 'Harry',
            LastName = 'Potter'
        );

        if (persist) {
            insert this.customerContact;
        }

        return this.customerContact;
    }

    public Flight__c createFlight(Boolean persist) {
        this.flight = new Flight__c(
            Start__c = Date.today()
        );

        if (persist) {
            insert this.flight;
        }

        return this.flight;
    }

    public Ticket__c createTicket(Boolean persist) {
        this.ticket = new Ticket__c( );

        if (persist) {
            insert this.ticket;
        }

        return this.ticket;
    }

    public Trip__c createTrip(Boolean persist) {
        this.trip = new Trip__c();

        if (persist) {
            insert this.trip;
        }

        return this.trip;
    }
}