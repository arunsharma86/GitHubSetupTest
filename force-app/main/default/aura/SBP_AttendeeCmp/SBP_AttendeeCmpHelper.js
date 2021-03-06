({
    init: function() {
        
    },
    handleTextInputChange: function(component, event, helper) {
        var currentVal = event.getSource().get("v.value");
        var index = event.getSource().get("v.title");
        var type = event.getSource().get("v.name");
        var attendeeMap = component.get('v.attendeeMap');
        //console.log(currentVal);
        //console.log(index);
        //console.log(type);
        
        attendeeMap['attendee' + index][type] = currentVal;
        component.set('v.attendeeMap', attendeeMap);
    },
    buildAttendeeList: function(component, event, helper) {
        var attendeeMap = component.get('v.attendeeMap');
        var numberOfAttendees = component.get('v.numberOfAttendees');
        component.set('v.attendeeMap', null);
        var attendeeObj = {};
        attendeeObj['list'] = [];
        for (var i = 0; i < numberOfAttendees; i++) {
            attendeeObj['attendee' + i] = {
                First_Name__c: ' ',
                Last_Name__c: ' ',
                Email__c: ' ',
                Phone_Number__c: ' ',
                Plant_Event__c: component.get('v.plantEventId')
            };
            attendeeObj['list'].push(i);
        }
        
        component.set('v.attendeeMap', attendeeObj);
    },
    createAttendees: function(component, event, helper) {
        var attendeeMap = component.get('v.attendeeMap');
        var action = component.get("c.createAttendeeRecords");
        delete attendeeMap['list'];
        
        console.log('JSON ', JSON.stringify(Object.values(attendeeMap)));
        
        action.setParams({
            "jsonAttendees": JSON.stringify(Object.values(attendeeMap))
        });
        
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(data) {
                var state = data.getState();
                if (state == 'SUCCESS') {
                    var returnVal = data.getReturnValue();
                    resolve(returnVal);
                    console.log('RETURN VAL ', returnVal);
                    
                } else if (state == 'ERROR') {
                    console.log(data.getError());
                } else {
                    console.log(data.getError());
                }
            });
            $A.enqueueAction(action);
        });
    },
    
    checkAttendeeValidity: function(component, event, helper) {
        var brand = component.get('v.brand');
        var isValid;
        
        if(brand!='El Tesoro'){
        var attendee_info = component.find('attendee_info');
        isValid = attendee_info.checkValidity();
        console.log('inside attendee_info:::',isValid);
        }
        
        /*if(brand=='El Tesoro'){
        var elTesoro_attendee_info = component.find('elTesoro_attendee_info');
        isValid = elTesoro_attendee_info.checkValidity();
            console.log('inside elTesoro_attendee_info:::',isValid);    
        }*/

        var numberOfAttendees = component.get('v.numberOfAttendees');

        if (!isValid && brand!='El Tesoro') {
            helper.showToast('Please check the number of attendees entered', 'Error', 'error');
        }
        
        if(brand=='El Tesoro' && numberOfAttendees > 0){
        isValid = component.find('requiredid').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        
        }
        
        if (!isValid && numberOfAttendees > 0) {
            helper.showToast('Please fill attendee missing info', 'Error', 'error');
        }
        
        if(brand=='El Tesoro' && (numberOfAttendees == '' || numberOfAttendees == undefined || numberOfAttendees == null) ){
            helper.showToast('Please fill the Number of Guests', 'Error', 'error');
            isValid = false;
        }
        
        if(brand=='El Tesoro' && numberOfAttendees <= 0 && (numberOfAttendees != '' || numberOfAttendees != undefined || numberOfAttendees != null)){
            helper.showToast('Number of attendees should be greater than 0', 'Error', 'error');
            isValid = false;
        }
        
		if(brand=='El Tesoro' && numberOfAttendees >2 && (numberOfAttendees != '' || numberOfAttendees != undefined || numberOfAttendees != null)){
            helper.showToast('Please check the number of attendees entered and it should be less than 3', 'Error', 'error');
            isValid = false;
        }        
        
        return isValid;
    },
    showToast: function(message, title, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": "dismissible"
        });
        toastEvent.fire();
    },
    
})