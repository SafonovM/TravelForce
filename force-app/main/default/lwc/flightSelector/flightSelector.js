import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFlightsWithUnbookedTickets from "@salesforce/apex/FlightSelectorController.getFlightsWithUnbookedTickets";
import { getRecord, getFieldValue,getRecordNotifyChange } from 'lightning/uiRecordApi';
import assignFlightOnTrip from "@salesforce/apex/FlightSelectorController.assignFlightOnTrip";
import cancelFlight from "@salesforce/apex/FlightSelectorController.cancelFlight";
import FLIGHT_FIELD from '@salesforce/schema/Trip__c.Flight__c';


const fields = [FLIGHT_FIELD];


export default class FlightSelector extends LightningElement {
    @api recordId;
    @api result;
    options = [];
    value = '';
    serverTrip = false;
    flightField = FLIGHT_FIELD;
    title = {
        error: 'error',
        success: 'Flight Assigned!',
        cancel: 'Flight Cancelled',
    };
    message = {
        error: 'error',
        success: 'You have succesfully assigned flight',
        cancel: 'You have succesfully cancelledd flight'
    };

    variant = {
        error: 'error',
        success: 'success',
        cancel: 'info'
    };

    @wire(getRecord, { recordId: '$recordId', fields })
    trip;

    
    get isFlightAssigned() {
        this.flightFieldValue = getFieldValue(this.trip.data, FLIGHT_FIELD);
        return this.flightFieldValue != null || this.flightFieldValue != undefined;
    }

    connectedCallback() {
        this.getFlights();
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    async getFlights() {
        this.serverTrip = true;
        try {
            this.options = await getFlightsWithUnbookedTickets({recordId:this.recordId });
        } catch(e) {
            console.log(JSON.stringify(e));
        } finally {
            this.serverTrip = false;
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    async handleAssign() {
        this.serverTrip = true;
        try {
            await assignFlightOnTrip({tripdId:this.recordId, flightId:this.value});
        } catch(e) {
            console.log(JSON.stringify(e));
            this.showNotification(this.title.error, JSON.stringify(e), this.variant.error);
        } finally {
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.serverTrip = false;
            this.showNotification(this.title.success, this.message.success, this.variant.success);
        }

    }

    async handleCancellation() {
        this.serverTrip = true;
        try {
            await cancelFlight({tripdId:this.recordId, flightId:this.flightFieldValue});
        } catch(e) {
            console.log(JSON.stringify(e));
            this.showNotification(this.title.error, JSON.stringify(e), this.variant.error);
        } finally {
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.serverTrip = false;
            this.showNotification(this.title.cancel, this.message.cancel, this.variant.success);
        }
    }
}