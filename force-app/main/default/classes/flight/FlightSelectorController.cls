public with sharing class FlightSelectorController {
    @AuraEnabled
    public static  List<FlightWrapper> getFlightsWithUnbookedTickets(String recordId) {
        Trip__c trip = [
                SELECT Id, Contact__c, PrefferedTripStart__c 
                FROM Trip__c 
                WHERE Id =:recordId 
                LIMIT 1
            ];

            List<FlightWrapper> avalibaleFlights = new List<FlightWrapper>();

        for(Ticket__c ticket : [SELECT Id, Flight__c, Flight__r.Name FROM Ticket__c  WHERE Contact__c = '' AND DAY_ONLY(Flight__r.Start__c) = :trip.PrefferedTripStart__c]) {
            avalibaleFlights.add(new FlightWrapper(ticket.Flight__r.Name, ticket.Flight__c));
        }

        return avalibaleFlights;
    }

    @AuraEnabled
    public static void assignFlightOnTrip(String tripdId, String flightId) {
        Trip__c trip = [
                SELECT Id, Contact__c, Flight__c 
                FROM Trip__c 
                WHERE Id =:tripdId 
                LIMIT 1
            ];

        Ticket__c ticket = [
                SELECT Id, Flight__c 
                FROM Ticket__c 
                WHERE Contact__c = '' 
                AND Flight__c = :flightId
            ];

        ticket.Contact__c = trip?.Contact__c;
        trip.Flight__c = ticket?.Flight__c;
        trip.Status__c = Constants.TRIP_STATUS_FLIGHT_BOOKED;
        

        List<SObject> objectsToUpdate = new List<SObject>();
        objectsToUpdate.add(trip);
        objectsToUpdate.add(ticket);

        update objectsToUpdate;
    }

    @AuraEnabled
    public static void cancelFlight(String tripdId, String flightId) {
        Trip__c trip = [
                SELECT Id, Contact__c, Flight__c,Status__c
                FROM Trip__c 
                WHERE Id =:tripdId 
                LIMIT 1
            ];

        Ticket__c ticket = [
                SELECT Id, Flight__c,Contact__c
                FROM Ticket__c 
                WHERE Contact__c = :trip.Contact__c
                AND Flight__c = :flightId
            ];

        ticket.Contact__c = null;
        trip.Flight__c = null;
        trip.Status__c = Constants.TRIP_STATUS_FLIGHT_SEARCH;

        List<SObject> objectsToUpdate = new List<SObject>();
        objectsToUpdate.add(trip);
        objectsToUpdate.add(ticket);

        update objectsToUpdate;
    }
}