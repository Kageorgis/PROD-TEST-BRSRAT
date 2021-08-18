({
    init: function(component, event, helper){
        component.set("v.spinner", true);
        component.set("v.disableExport", true);
        event.getSource().set("v.disabled", true);
        var uploadId = component.get('v.recordId');
        var action = component.get("c.getUploadObjectDetails");
        action.setParams({
            uploadId : uploadId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var result = response.getReturnValue();
                component.set("v.dealId", result.DealId__c);
                component.set("v.status", result.status__c);
                component.set("v.dealRecordType", result.DealRecordType__c);
                if(component.get("v.status") === "Failed"){
                    component.set("v.disableExport", false);
                    helper.getUploadObject(component, event, helper);
                }else{
                    component.set("v.disableExport", true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    reInit : function(component, event, helper){
        $A.get('e.force:refreshView').fire();
        var a = component.get('c.init');
        $A.enqueueAction(a);
    },
    downloadExportFile : function(component, event, helper) {
        event.getSource().set("v.disabled", true);
        var resultList = component.get("v.fullData");
        if(resultList !== null && resultList !== '' && resultList !== undefined)
        {
            var csvDataList=[];
            for(var i=0;i<resultList.length;i++){
                csvDataList.push(JSON.parse(resultList[i]));
            }
            var csv = helper.convertArrayOfObjectsToCSV(component, csvDataList);
            if (csv === null){return;}
            var hiddenElement = document.createElement('a');
            hiddenElement.href = 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csv);
            hiddenElement.target = '_blank';
            hiddenElement.download = "ErrorReport.csv";
            document.body.appendChild(hiddenElement);
            hiddenElement.click();
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                type: 'success',
                "message": "Download Success."
            });
            toastEvent.fire();
        }
        event.getSource().set("v.disabled", false);
        component.set("v.spinner", false);
    }
})