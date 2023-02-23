@IsTest
public with sharing class FlightSelectorController_Test {
    @IsTest
    private static void getFlightsWithUnbookedTickets_Test() {
        DataFactory factory = new DataFactory();
        Integer ticketsCount = 3;
        Contact testContact = factory.createContact(true);

        Trip__c testTrip = factory.createTrip(false);
        testTrip.Contact__c = testContact.Id;
        testTrip.PrefferedTripStart__c = Date.today();
        insert testTrip;

        Flight__c testFlight = factory.createFlight(false);
        testFlight.Start__c = Date.today();
        insert testFlight;

        List<Ticket__c> testTickets = new List<Ticket__c>();
        for(Integer i = 0; i < ticketsCount; i++) {
            Ticket__c testTicket = factory.createTicket(false);
            testTicket.Flight__c = testFlight.Id;
            testTickets.add(testTicket);
        }

        insert testTickets;

        Test.startTest();
        List<FlightWrapper> flightToTest = FlightSelectorController.getFlightsWithUnbookedTickets(testTrip.Id);
        Test.stopTest();

        System.assert(flightToTest.size()>0, 'Flights not found');

    }
}