/*
   @Author: Tejasvini Telangi
   @name CPProductApexSharingHandler
   @CreateDate 22 March 2021
   @Description: Apex Class to handle sharing of CP Product to User Record based on Region they belong to and Access(Local/Regional/Global)they have.
   @Version 52
  */
public without sharing class CPProductApexSharingHandler {
   
    public static void shareCPRecords(List<CP_Product__c> newCPProductList,List<User> newUserList,String instance){
        Set<String> cpProdSet = new Set<String>();
        Map<Id,CP_Product__c> cpProdMap;

        if(newCPProductList != Null && newCPProductList.size()>0){
            for(CP_Product__c cpProdRec : newCPProductList){
                cpProdSet.add(cpProdRec.Id);
            }
        }
        
        Set<String> profileSet = new Set<string>{CP_ProductUtility.WBCP_ADMIN_LICENSEE_PROFILE,CP_ProductUtility.WBCP_PLAT_LICENSEE_PROFILE};
        List<User> userList = new List<User>();
        if(cpProdSet != Null && cpProdSet.size()>0){
            cpProdMap = new Map<Id,CP_Product__c>([Select Id,Licensee__c,WBCP_Country__c,WBCP_Country__r.Name,OwnerId from CP_Product__c WHERE Id IN : cpProdSet]);
        }

        if(instance == CP_ProductUtility.WBCP_TRIGGER){
            userList = [SELECT Id,User_License_Type__c,ProfileId,WBCP_Access_Role__c,UserRoleId,UserRole.Name, Country FROM User WHERE User_License_Type__c =: CP_ProductUtility.WBCP_SALESFORCE_PLATFORM AND isActive = True AND WBCP_Access_Role__c != Null AND Profile.Name IN: profileSet];
        }else if(instance == CP_ProductUtility.WBCP_BATCH){
            if(newUserList != Null && newUserList.size()>0){
                userList = newUserList;
            }
        }
        
        Map<String,WBCP_TerritoryData__c> territoryMapping = WBCP_TerritoryData__c.getAll();
        List<CP_Product__Share> cpProductShareList = new List<CP_Product__Share>();

        if(cpProdMap != Null && cpProdMap.size()>0){
            for(Id cpProductRecId : cpProdMap.keySet()){
                CP_Product__Share cpShareExt;
                if(userList != Null && userList.size()>0){
                    for(User userRecord : userList){
                        if(cpProdMap.get(cpProductRecId).OwnerId == userRecord.Id)
                                continue;
                        if((cpProdMap.get(cpProductRecId) != Null && cpProdMap.get(cpProductRecId).WBCP_Country__c != Null && cpProdMap.get(cpProductRecId).WBCP_Country__r.Name != Null) 
                                && userRecord.WBCP_Access_Role__c != Null){
                            if(userRecord.WBCP_Access_Role__c == CP_ProductUtility.WBCP_LOCAL){
                                
                                if(userRecord.Country == cpProdMap.get(cpProductRecId).WBCP_Country__r.Name){
                                    cpShareExt = new CP_Product__Share();
                                    CPProductApexSharingHandler.assignShareRecordValues(cpShareExt,cpProductRecId,userRecord);
                                    cpProductShareList.add(cpShareExt);
                                }
                            }else if(userRecord.WBCP_Access_Role__c == CP_ProductUtility.WBCP_GLOBAL){
                                cpShareExt = new CP_Product__Share();
                                CPProductApexSharingHandler.assignShareRecordValues(cpShareExt,cpProductRecId,userRecord);
                                cpProductShareList.add(cpShareExt);
                            }else if(userRecord.WBCP_Access_Role__c == CP_ProductUtility.WBCP_REGIONAL){
                                String cpProductRegion = CP_ProductUtility.getRegionValue(cpProdMap.get(cpProductRecId).WBCP_Country__r.Name,territoryMapping);
                                String userCountryRegion = CP_ProductUtility.getRegionValue(userRecord.Country,territoryMapping);
                                if((cpProductRegion != Null && userCountryRegion != Null) && userCountryRegion == cpProductRegion){
                                    cpShareExt = new CP_Product__Share();
                                    CPProductApexSharingHandler.assignShareRecordValues(cpShareExt,cpProductRecId,userRecord);
                                    cpProductShareList.add(cpShareExt);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if(cpProductShareList != Null && cpProductShareList.size()>0){
            Database.SaveResult[] saveResultList = Database.insert(cpProductShareList,false);
            Integer i=0;
            
            // Process the save results
            for(Database.SaveResult sr : saveResultList){
                if(!sr.isSuccess()){
                    Database.Error err = sr.getErrors()[0];
                   
                    if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                                &&  err.getMessage().contains('AccessLevel'))){
                        // Throw an error when the error is not related to trivial access level.
                        trigger.newMap.get(cpProductShareList[i].ParentId).
                        addError('Unable to grant sharing access due to following exception: ' + err.getMessage());
                    }
                }
                i++;
            }
        }
    }

    public static void assignShareRecordValues(CP_Product__Share cpShareExt, Id cpProdRecId,User userRecord){
        cpShareExt.ParentId = cpProdRecId;
        cpShareExt.UserOrGroupId = userRecord.Id;
        cpShareExt.AccessLevel = 'Edit';
        cpShareExt.RowCause = Schema.CP_Product__Share.RowCause.WBCP_User_Access__c;
    }
}