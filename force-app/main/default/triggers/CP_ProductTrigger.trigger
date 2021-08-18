/**
* Created by XMMORENO on 3/26/2020.
*/

trigger CP_ProductTrigger on CP_Product__c(before insert, before update, after insert, after update){
    
    if(trigger.isInsert){

        if(trigger.isBefore){
            CP_ProductTriggerSequenceController.executeBeforeInsert(trigger.new);
        }

        if(trigger.isAfter){
            CPProductApexSharingHandler.shareCPRecords(trigger.new,Null,CP_ProductUtility.WBCP_TRIGGER);
        }
    }
    
    if(trigger.isUpdate){
        
        if(trigger.isBefore){
            CP_ProductTriggerSequenceController.executeBeforeUpdate(trigger.new, trigger.oldMap);
        }
    }
    
}