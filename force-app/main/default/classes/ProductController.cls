/*
**********************************************************
Class Name     : ProductController
Created Date   : Feb 14 , 2024
@description   : This class provides methods for retrieving and manipulating product-related data.
It includes functionality to fetch Pricebook records, retrieve PricebookEntry and Product records 
based on various criteria, and handle related line items deletion.
@author        : RedFerns Tech
*********************************************************
*/

public with sharing class ProductController {
    
    /*
* @description : Fetches all the Pricebook record.
* @param 	   : None.
* @return 	   : List<Pricebook2>: List of Pricebook2 records.
*/
    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getPricebookDetail(){
        return [SELECT Id,Name FROM Pricebook2 WHERE IsActive=true WITH SECURITY_ENFORCED];
    }
    
    /*
* @description 	  : Fetch Pricebook ID based on record ID.
* @param recordId : The ID of the record.
* @return 	      : String : Pricebook2Id.
*/
    @AuraEnabled(cacheable=true)
    public static String getPricebookId(Id recordId) {
        string PricebookId;
        string objectName=recordId.getSObjectType().getDescribe().getName();
        if(objectName=='Opportunity'){
            List<Opportunity> opportunityList =[SELECT Pricebook2Id FROM Opportunity WHERE Id=:recordId WITH SECURITY_ENFORCED];
            if(!opportunityList.isEmpty()){
                PricebookId=opportunityList[0].Pricebook2Id;
            }
        }else if(objectName=='Order'){
            List<Order> orderList =[SELECT Pricebook2Id FROM Order WHERE Id=:recordId WITH SECURITY_ENFORCED];
            if(!orderList.isEmpty()){
                PricebookId=orderList[0].Pricebook2Id;
            }
        }else if(objectName=='Quote'){
            List<Quote> quoteList =[SELECT Pricebook2Id FROM Quote WHERE Id=:recordId WITH SECURITY_ENFORCED];
            if(!quoteList.isEmpty()){
                PricebookId=quoteList[0].Pricebook2Id;
            }
        }
        return PricebookId;
    }
    
/*
* @description    : Delete related lineitem based on record ID.
* @param recordId : The ID of the record.
* @return 	      : None.
*/
    @AuraEnabled
    public static void deleteRelatedLineitem(Id recordId) {
        
        string objectName=recordId.getSObjectType().getDescribe().getName();
        if(objectName=='Opportunity'){
            List<OpportunityLineItem> opportunityLineList =[SELECT Id FROM OpportunityLineItem WHERE OpportunityId=:recordId WITH SECURITY_ENFORCED];
            if(!opportunityLineList.isEmpty()){
                delete AS User opportunityLineList;
            }
        }else if(objectName=='Order'){
            List<OrderItem> orderLineList =[SELECT Id FROM OrderItem WHERE OrderId=:recordId WITH SECURITY_ENFORCED];
            if(!orderLineList.isEmpty()){
                delete AS User orderLineList;
            }
        }else if(objectName=='Quote'){
            List<QuoteLineItem> quoteLineList =[SELECT Id FROM QuoteLineItem WHERE QuoteId=:recordId WITH SECURITY_ENFORCED];
            if(!quoteLineList.isEmpty()){
                delete AS User quoteLineList;
            }
        }
    }
    
    /*
* @description : Fetches fieldset from the Product object and PricebookEntry records based on the Pricebook ID.
*               Retrieves Product records based on the PricebookEntry IDs and the provided record ID's object name.
* @param pricebookId The ID of the Pricebook.
* @param recordId The ID of the record.
* @return 	   : List<productWrapper>: List of productWrapper class.
*/
    @AuraEnabled(cacheable=true)
    public static List<productWrapper> getAllProductsWithUnitPrice(string pricebookId, Id recordId){
        
        string objectName=recordId.getSObjectType().getDescribe().getName();
        List<productWrapper> wrapList = new List<productWrapper>();
        Set<Id> productIds = new Set<Id>();
        List<Map<String ,String>> listOfFieldSet  = new  List<Map<String ,String>>();
        
        for(Schema.FieldSetMember fieldset : SObjectType.Product2.FieldSets.Add_Products_LWC_Column_Field_Set.getFields()) {
            Map<String ,String> lableAPIMap = new Map<String ,String>();
            lableAPIMap.put('label', fieldset.getLabel());
            lableAPIMap.put('apiName', fieldset.getFieldPath());
            listOfFieldSet.add(lableAPIMap);
        }
        List<PricebookEntry> PricebookEntryList = [SELECT Id,Name,Product2Id,UnitPrice
                                                   From PricebookEntry
                                                   WHERE IsActive= true AND Pricebook2Id=:pricebookId WITH SECURITY_ENFORCED];
        
        for(PricebookEntry pricebookEntryRec:PricebookEntryList){
            productIds.add(pricebookEntryRec.Product2Id);
        }
        
        String queryString = 'select id';
        for (Schema.FieldSetMember fieldSet : SObjectType.Product2.FieldSets.Add_Products_LWC_Column_Field_Set.getFields()) {
            queryString += ',' + fieldSet.getFieldPath();
        }
        queryString += ' from Product2 WHERE IsActive=true AND Id=:productIds WITH SECURITY_ENFORCED';
        
        List<Product2> productList= Database.query(queryString);
        
        wrapList.add(new productWrapper(PricebookEntryList, productList,listOfFieldSet,objectName));
        return wrapList;
    }
    
    /*
* @description : Wraps the values returned by the getAllProductsWithUnitPrice method.
* @param 	   : None.
* @return 	   : None.
*/
    public class productWrapper{
        @AuraEnabled public List<Product2> productList{get;set;}
        @AuraEnabled public List<PricebookEntry> pricebookEntryList{get;set;}
        @AuraEnabled public String objectName{get;set;}
        @AuraEnabled public List<Map<String,String>> columnForProductTable{get;set;}
        
        public productWrapper(List<PricebookEntry> pricebookEntryList, List<Product2> productList,
                              List<Map<String ,String>> columnForProductDatatable, String objectName){
                                  this.productList = productList;
                                  this.pricebookEntryList = pricebookEntryList;
                                  this.columnForProductTable=columnForProductDatatable;
                                  this.objectName=objectName;
                              }
    }
    
    /*
* @description : Fetches the fielset from product object.
* @param 	   : None.
* @return 	   : String Serialized list of maps containing field information.
*/
    @AuraEnabled(cacheable=true)
    public static String getFieldSetForFilter() {
        List<Map<String, String>> listOfFieldSet = new List<Map<String, String>>();
       for (Schema.FieldSetMember fieldset : SObjectType.Product2.FieldSets.Product_Filter_Field_Set.getFields()) {
            Map<String, String> fieldInfoMap = new Map<String, String>();
            fieldInfoMap.put('label', fieldset.getLabel());
            fieldInfoMap.put('apiName', fieldset.getFieldPath());
            fieldInfoMap.put('type', String.valueOf(fieldset.getType())); 
            listOfFieldSet.add(fieldInfoMap);
        }
        return JSON.serialize(listOfFieldSet);
    }
    
    /*
* @description : Fetches PricebookEntry records based on the Pricebook ID and retrieves the associated 
Product records.
* @param 	   : None.
* @return 	   : List<Pricebook2>: List of Pricebook2 records.
*/
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsTofilter(string pricebookId){
        Set<Id> productIds = new Set<Id>();
        List<PricebookEntry> PricebookEntryList = [SELECT Name,Product2Id,UnitPrice
                                                   From PricebookEntry
                                                   WHERE IsActive= true AND Pricebook2Id=:pricebookId WITH SECURITY_ENFORCED];
        
        for(PricebookEntry pricebookEntryRec:PricebookEntryList){
            productIds.add(pricebookEntryRec.Product2Id);
        }
        
        String queryString = 'select id';
            for (Schema.FieldSetMember fieldSet : SObjectType.Product2.FieldSets.Product_Filter_Field_Set.getFields()) {
            queryString += ',' + fieldSet.getFieldPath();
        }
        queryString += ' from Product2 WHERE IsActive=true AND Id=:productIds WITH SECURITY_ENFORCED';
        return Database.query(queryString);
    }
    
    /*
* @description : Fetches the fieldset based on the object type of the provided record ID.
* @param 	   : None.
* @return 	   : String Serialized list of maps containing field information.
*/
    @AuraEnabled(cacheable=true)
    public static String getFieldSetForConfigurationTable(Id recordId) {
        List<Schema.FieldSetMember> fieldsetList = new List<Schema.FieldSetMember>();
        string objectName=recordId.getSObjectType().getDescribe().getName();
        if(objectName=='Opportunity'){
            fieldsetList= SObjectType.OpportunityLineItem.FieldSets.Product_Configuration_Table_Field_Set.getFields();
        }else if(objectName=='Order'){
            fieldsetList= SObjectType.OrderItem.FieldSets.Product_Configuration_Table_Field_Set.getFields();
        }else if(objectName=='Quote'){
            fieldsetList= SObjectType.QuoteLineItem.FieldSets.Product_Configuration_Table_Field_Set.getFields();
        }
        
        List<Map<String, String>> listOfFieldSet = new List<Map<String, String>>();
        for (Schema.FieldSetMember fieldset : fieldsetList) {
            Map<String, String> fieldInfoMap = new Map<String, String>();
            fieldInfoMap.put('label', fieldset.getLabel());
            fieldInfoMap.put('apiName', fieldset.getFieldPath());
            fieldInfoMap.put('type', String.valueOf(fieldset.getType())); 
            listOfFieldSet.add(fieldInfoMap);
        }
        return JSON.serialize(listOfFieldSet);
    }
}