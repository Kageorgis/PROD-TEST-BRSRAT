@isTest
private class CRM_DealApprovalPOSandDFI_Test {
	// @testsetup 
	public static List<Product2> products =new List<Product2>();
   	public static List<OpportunityLineItem> dealProds = new List<OpportunityLineItem>();
    static void allTheDataForThisTestClass(){
        User u = CRM_TestDataFactory.createUser('System Administrator', true);
        system.runAs(u){
            // create account  
            List<Account> lstAccount = CRM_TestDataFactory.createAccounts(1, false);
            lstAccount[0].Sales_Organization__c = CRM_AppConstants.TERRITORY_US_CODE;
            lstAccount[0].RecordTypeId = CRM_RecordTypeUTil.RT_ACCOUNT_SHIP_TO; 
            insert lstAccount;
            system.assertEquals(CRM_AppConstants.TERRITORY_US_CODE, lstAccount[0].Sales_Organization__c);
            Map<String,PricebookEntry> mapOfProductCodeToPB = new Map<String,PricebookEntry>(); 
            // create deal
            List<Opportunity> lstOpportunity = CRM_TestDataFactory.createOpportunitiesWithAccounts(lstAccount, 3, false);

            lstOpportunity[0].RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            lstOpportunity[0].Start_date__c = System.today();  
            lstOpportunity[0].CloseDate = System.today()+15;
            lstOpportunity[0].Promo_Start_Date__c =System.today()+1;
            lstOpportunity[0].Promo_End_Date__c =System.today()+20;
            
            lstOpportunity[1].Start_date__c = System.today();  
            lstOpportunity[1].CloseDate = System.today()+15;
            lstOpportunity[1].Promo_Start_Date__c =System.today()+1;
            lstOpportunity[1].Promo_End_Date__c =System.today()+20;
            insert lstOpportunity;
            List<Opportunity> opp =[select id,RecordTypeId from Opportunity where id IN: lstOpportunity];
            system.assertEquals(CRM_RecordTypeUtil.RT_Physical_POS_Deal, opp[0].RecordTypeId);
            
            integer intCount = 0;
            products = CRM_TestDataFactory.createProducts(2, false);
            for(Product2 prod : products) {
                prod.ProductCode = '10000' + intCount;
                prod.SAP_Dist_chain_product_Status__c =  CRM_AppConstants.PRODUCT_SAP_DIST_STATUS_ACTIVE ;
                prod.SAP_Sales_Org__c = CRM_AppConstants.TERRITORY_US_CODE;
                prod.Product_Format__c = 'DVD';
                prod.isActive = true;
                intCount++;
            }
            insert products; 
            
            List<PricebookEntry> pricebookentries = CRM_TestDataFactory.createPriceBookEntries(products, 1, true); 
            System.assertEquals(2,pricebookentries.size());
            
            List<Pricebook_Entry_Period__c> pbeD=CRM_TestDataFactory.createPriceBookEntryPeriods(products, 1, true);
            system.assertEquals(2,pbeD.size());
            
            dealProds = CRM_TestDataFactory.createDealProductsWithOpportunities(pricebookentries, lstOpportunity, 2, false);
            for(Integer nProductCount = 0; nProductCount < products.size(); nProductCount++){ 
                for(OpportunityLineItem oli : dealProds) {
                    oli.Reason__c = 'POS Rebate';
                    oli.Product2Id = products[nProductCount].Id;
                    oli.Comments__c = 'Test Comment';
                    oli.Dollar_of_Discount__c = 3;
                    oli.Start_Date__c = System.today()+1;
                    oli.End_Date__c = System.today()+20;
                    oli.Customer_Reference__c = 'Test Reference';
                }
            }
            insert dealProds;
            System.assertEquals(6,dealProds.size());
        }
    }
     static testMethod void testGetItems(){
		allTheDataForThisTestClass();
         List<Opportunity> plannedOpportunity = [select id,name,Deal_Overlap_Exists__c,Deal_Overlap_Review_Completed__c from Opportunity];
         Opportunity plannedOpp = plannedOpportunity[0];
         plannedOpp.Deal_Overlap_Exists__c = false;
         plannedOpp.Deal_Overlap_Review_Completed__c = true;
         update plannedOpp;
         Opportunity existingDeal = plannedOpportunity[1];
         existingDeal.Promo_Start_Date__c =System.today()+1;
         existingDeal.Promo_End_Date__c =System.today()+15;
         update existingDeal;
         Test.startTest();
                    CRM_DealApprovalPOSandDFI.DealWrapper dw = CRM_DealApprovalPOSandDFI.getDealOverlapFuture(plannedOpp.id);
                    system.assertEquals(false, dw.showMessage);
                     if(dw.showMessage == false){
                         CRM_DealApprovalPOSandDFI.callStandardApprovalProcess(plannedOpp.id);
                     }
         try{
             CRM_DealApprovalPOSandDFI.DealWrapper dwFail = CRM_DealApprovalPOSandDFI.getDealOverlapFuture(plannedOpp.id);
         }catch(Exception e) {
            system.assertEquals(true, e.getMessage().contains('Invalid Deal Stage'));
        }
        Test.stopTest();
         			List<ProcessInstance> processInstances = [select Id, Status from ProcessInstance where TargetObjectId = :plannedOpp.id];
                    System.assertEquals(processInstances.size(),1);	
    }
    static testMethod void unitTestOverlappingConditionNotClicked() {
        User u = CRM_TestDataFactory.createUser('System Administrator', true);
        system.runAs(u){
            allTheDataForThisTestClass();
            List<Account> lstAccount = [select id,name from Account];
            list<Opportunity> opportunities = [select id,name,Start_Date__c,Deal_Overlap_Review_Completed__c,Deal_Overlap_Exists__c,
                                               RecordTypeId,CloseDate,Promo_Start_Date__C,Promo_End_Date__c,accountId,StageName 
                                               from Opportunity LIMIT 50000 ];
            // set dates of opp1 and opp2 so that they overlap
            Opportunity newPlannedDeal = opportunities[0];
            newPlannedDeal.RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            newPlannedDeal.AccountId = lstAccount[0].id;
            newPlannedDeal.Promo_Start_Date__c= system.today()+1;
            newPlannedDeal.Promo_End_Date__c= system.today()+15;
            newPlannedDeal.Start_Date__c= system.today()+1;
            newPlannedDeal.CloseDate= system.today()+15;
            newPlannedDeal.StageName= CRM_AppConstants.OPPORTUNITY_STAGE_PLANNED;
            
            Opportunity existingPlannedDeal = opportunities[1];
            existingPlannedDeal.RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            existingPlannedDeal.Promo_Start_Date__c= system.today()+1;
            existingPlannedDeal.Promo_End_Date__c= system.today()+15;
            existingPlannedDeal.Start_Date__c= system.today()+1;
            existingPlannedDeal.CloseDate= system.today()+15;
            existingPlannedDeal.AccountId = lstAccount[0].id;
            existingPlannedDeal.StageName= CRM_AppConstants.OPPORTUNITY_STAGE_PLANNED;
            
            
            update opportunities;

            list<OpportunityLineItem> oppLinesExisting = [SELECT id, OpportunityId,Product2Id,Reason__c,Start_Date__c,End_Date__c
                                                          from OpportunityLineItem
                                                          where OpportunityId =: opportunities[0].id LIMIT 50000];
            
            OpportunityLineItem oppLine1e = oppLinesExisting[0];
            OpportunityLineItem oppLine2e = oppLinesExisting[1];
            oppLine1e.Start_Date__c = system.today()+1;
            oppLine1e.End_Date__c = system.today()+15;
            oppLine1e.Reason__c = 'POS Rebate';
            oppLine2e.Reason__c = 'POS Rebate';
            oppLine2e.Start_Date__c = system.today()+1;
            oppLine2e.End_Date__c = system.today()+15;
            update oppLinesExisting;
            
            list<OpportunityLineItem> oppLines = [SELECT id, OpportunityId,Product2Id,Reason__c,Start_Date__c,End_Date__c
                                                  from OpportunityLineItem
                                                  where OpportunityId =: opportunities[1].id LIMIT 50000];
            
            OpportunityLineItem oppLine1 = oppLines[0];
            OpportunityLineItem oppLine2 = oppLines[1];
            oppLine1.Start_Date__c = system.today()+1;
            oppLine1.End_Date__c = system.today()+14;
            oppLine1.Reason__c = 'POS Rebate';
            oppLine2.Reason__c = 'POS Rebate';
            oppLine2.Start_Date__c = system.today()+1;
            oppLine2.End_Date__c = system.today()+14;
            update oppLines;
            
            
            List<Opportunity> newOpp = new List<Opportunity>();
            newOpp.add(opportunities[0]);
			
            Test.startTest();
            Opportunity oppDetails = CRM_DealApprovalPOSandDFI.getOpportunityDetails(opportunities[0].id);
            system.assertEquals(oppDetails.id,opportunities[0].id);
            
            String message = CRM_DealApprovalPOSandDFI.getOverlapDeals(opportunities[0].id);
            CRM_DealApprovalPOSandDFI.DealWrapper msgDone = (CRM_DealApprovalPOSandDFI.DealWrapper)System.JSON.deserialize(message,CRM_DealApprovalPOSandDFI.DealWrapper.class);
            system.assertEquals(msgDone.validationError,true);
            Test.stopTest();
        }
    }
    static testMethod void unitTestOverlappingCondition() {
        User u = CRM_TestDataFactory.createUser('System Administrator', true);
        system.runAs(u){
            allTheDataForThisTestClass();
            List<Account> lstAccount = [select id,name from Account];
            list<Opportunity> opportunities = [select id,name,Start_Date__c,Deal_Overlap_Review_Completed__c,Deal_Overlap_Exists__c,
                                               RecordTypeId,CloseDate,Promo_Start_Date__C,Promo_End_Date__c,accountId,StageName 
                                               from Opportunity LIMIT 50000 ];
            // set dates of opp1 and opp2 so that they overlap
            Opportunity newPlannedDeal = opportunities[0];
            newPlannedDeal.RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            newPlannedDeal.AccountId = lstAccount[0].id;
            newPlannedDeal.Promo_Start_Date__c= system.today()+1;
            newPlannedDeal.Promo_End_Date__c= system.today()+15;
            newPlannedDeal.Start_Date__c= system.today()+1;
            newPlannedDeal.CloseDate= system.today()+15;
            newPlannedDeal.StageName= CRM_AppConstants.OPPORTUNITY_STAGE_PLANNED;
            
            Opportunity existingPlannedDeal = opportunities[1];
            existingPlannedDeal.RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            existingPlannedDeal.Promo_Start_Date__c= system.today()+1;
            existingPlannedDeal.Promo_End_Date__c= system.today()+15;
            existingPlannedDeal.Start_Date__c= system.today()+1;
            existingPlannedDeal.CloseDate= system.today()+15;
            existingPlannedDeal.AccountId = lstAccount[0].id;
            existingPlannedDeal.StageName= CRM_AppConstants.OPPORTUNITY_STAGE_PLANNED;
            
            Opportunity existingPlannedDeal2 = opportunities[2];
            existingPlannedDeal2.RecordTypeId = CRM_RecordTypeUtil.RT_Physical_POS_Deal;
            existingPlannedDeal2.Promo_Start_Date__c= system.today()+1;
            existingPlannedDeal2.Promo_End_Date__c= system.today()+15;
            existingPlannedDeal2.Start_Date__c= system.today()+1;
            existingPlannedDeal2.CloseDate= system.today()+15;
            existingPlannedDeal2.AccountId = lstAccount[0].id;
            existingPlannedDeal2.StageName= CRM_AppConstants.OPPORTUNITY_STAGE_PLANNED;
            update opportunities;

            list<OpportunityLineItem> oppLinesExisting = [SELECT id, OpportunityId,Product2Id,Reason__c,Start_Date__c,End_Date__c
                                                          from OpportunityLineItem
                                                          where OpportunityId =: opportunities[0].id LIMIT 50000];
            
            OpportunityLineItem oppLine1e = oppLinesExisting[0];
            OpportunityLineItem oppLine2e = oppLinesExisting[1];
            oppLine1e.Start_Date__c = system.today()+1;
            oppLine1e.End_Date__c = system.today()+15;
            oppLine1e.Reason__c = 'POS Rebate';
            oppLine2e.Reason__c = 'POS Rebate';
            oppLine2e.Start_Date__c = system.today()+1;
            oppLine2e.End_Date__c = system.today()+15;
            update oppLinesExisting;
            
            list<OpportunityLineItem> oppLines = [SELECT id, OpportunityId,Product2Id,Reason__c,Start_Date__c,End_Date__c
                                                  from OpportunityLineItem
                                                  where OpportunityId =: opportunities[1].id LIMIT 50000];
            
            OpportunityLineItem oppLine1 = oppLines[0];
            OpportunityLineItem oppLine2 = oppLines[1];
            oppLine1.Start_Date__c = system.today()+1;
            oppLine1.End_Date__c = system.today()+14;
            oppLine1.Reason__c = 'POS Rebate';
            oppLine2.Reason__c = 'POS Rebate';
            oppLine2.Start_Date__c = system.today()+1;
            oppLine2.End_Date__c = system.today()+14;
            update oppLines;
            
            list<OpportunityLineItem> oppLines2 = [SELECT id, OpportunityId,Product2Id,Reason__c,Start_Date__c,End_Date__c
                                                  from OpportunityLineItem
                                                  where OpportunityId =: opportunities[2].id LIMIT 50000];
            
            OpportunityLineItem oppLine1New = oppLines2[0];
            OpportunityLineItem oppLine2New = oppLines2[1];
            oppLine1New.Start_Date__c = system.today()+1;
            oppLine1New.End_Date__c = system.today()+14;
            oppLine1New.Reason__c = 'POS Rebate';
            oppLine2New.Reason__c = 'POS Rebate';
            oppLine2New.Start_Date__c = system.today()+1;
            oppLine2New.End_Date__c = system.today()+14;
            update oppLines2;
            
            List<Opportunity> newOpp = new List<Opportunity>();
            newOpp.add(opportunities[0]);
			
            Test.startTest();
            CRM_Deal_Overlap_Review_POS_DFI.generateOverlaps(newOpp);
            Test.stopTest();
            Opportunity oppDetails = CRM_DealApprovalPOSandDFI.getOpportunityDetails(opportunities[0].id);
            system.assertEquals(oppDetails.id,opportunities[0].id);
            
            String message = CRM_DealApprovalPOSandDFI.getOverlapDeals(opportunities[0].id);
            CRM_DealApprovalPOSandDFI.DealWrapper msgDone = (CRM_DealApprovalPOSandDFI.DealWrapper)System.JSON.deserialize(message,CRM_DealApprovalPOSandDFI.DealWrapper.class);
            
            system.assertEquals(msgDone.showMessage,true);
        }
    }
}