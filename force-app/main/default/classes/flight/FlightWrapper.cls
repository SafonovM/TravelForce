public class FlightWrapper {
    @AuraEnabled public String  label { get; set; }
    @AuraEnabled public String  value { get; set; }

    public FlightWrapper(String flightName,String flightId ) {
        this.label = flightName;
        this.value = flightId;
    }
}