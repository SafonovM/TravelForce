trigger TicketTrigger on Ticket__c(before update) {
    new TicketTriggerHandler().run();
}