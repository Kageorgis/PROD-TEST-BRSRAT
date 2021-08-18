@IsTest
private class CP_ProductUtilityTest {
    @TestSetup
    static void createTestData(){    
        Id licRecTypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('WBCP Licensee').getRecordTypeId();
        Id retRecTypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('WBCP Retailer').getRecordTypeId();        
        Account licenceeAcc = (Account)TestDataFactory.createSObject('Account', new Map<String,Object>{
            'RecordTypeId' => licRecTypeid
                },true);
        Account retailerAcc = (Account)TestDataFactory.createSObject('Account', new Map<String,Object>{
            'RecordTypeId' => retRecTypeid
                });        
        WBCP_Country__c countRecord = (WBCP_Country__c)TestDataFactory.createSObject('WBCP_Country__c',new Map<String,object>{
            'Name' => 'United States'
                });
        Property__c propRec = (Property__c)TestDataFactory.createSObject('Property__c',new Map<String,object>{
            'Name' => 'Justice League Core'
                });
        CP_Product__c prodRec =  (CP_Product__c)TestDataFactory.createSObject('CP_Product__c', new Map<String,Object>{
            'Licensee__c' => licenceeAcc.Id,
                'WBCP_Country__c' => countRecord.Id,
                'GTIN__c' => '024054817896',
                'MPN__c' => '8875823',
                'cp_Retailer_Description__c' => retailerAcc.Id,
                'Retailer_SKU__c' => '567021036',
                'cp_Licensed_Property__c' => propRec.Id,
                'Sub_Category__c' => 'Vehicles / Remote Control'
                });
    }
    
    @IsTest
    static void test_getErrorRecProductsName(){
        CP_Product__c prod = [Select Id FROM CP_Product__c LIMIT 1];
        Set<Id> recId = new Set<Id>{prod.Id};
        CP_ProductUtility.getErrorRecProductsName(recId);
    }
}