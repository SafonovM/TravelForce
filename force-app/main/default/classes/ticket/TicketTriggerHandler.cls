public with sharing class TicketTriggerHandler extends TriggerHandler{
    private List<Ticket__c> newTickets;

    public TicketTriggerHandler() {
        newTickets = (List<Ticket__c>) Trigger.new;
    }

    protected override void beforeUpdate() {
        setTicketInExternalSystem(JSON.serialize(newTickets));
    }

    @future(callout=true)
    public static void setTicketInExternalSystem(String serialisedNewTickets) {
        List<Ticket__c> newTickets = (List<Ticket__c>) JSON.deserialize(serialisedNewTickets, List<Ticket__c>.class);
        for(Ticket__c ticket : newTickets) {
            if(ticket.Contact__c != null) {
                String queryParameters = '{"ticketnumber":' +'"'+ ticket.Name +'"'+ ',"contact":'+ '"'+ ticket.Contact__c +'"}';
                HttpResponse response = HttpService.call(HttpService.POST_METHOD, Constants.BOOK_TICKET_ENDPOINT, queryParameters);
            }
        }
    }
}