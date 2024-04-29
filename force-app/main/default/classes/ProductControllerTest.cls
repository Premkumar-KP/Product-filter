@isTest
private class ProductControllerTest {
    
    @testSetup
    public static void loadDataToTest(){
        
        Account testAccount= new Account();
        testAccount.Name='Test Company';
        insert testAccount;
        
        String standardPricebook = Test.getStandardPricebookId();
        
        List<Pricebook2> pricebookListTest = new List<Pricebook2>();
        pricebookListTest.add(new Pricebook2( Name='Hardware', isActive=true));
        insert pricebookListTest;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting',
                                                      CloseDate = Date.today(), Pricebook2Id =pricebookListTest[0].Id);
        insert testOpportunity;
        
        Contract testContract = new Contract(AccountId=testAccount.Id, Status='Draft',
                                              StartDate=Date.today(), ContractTerm=1);
        insert testContract;
        
        Order testOrder = new Order(Status = 'Draft', Pricebook2Id = pricebookListTest[0].Id, AccountId=testAccount.Id,
                                    OpportunityId=testOpportunity.Id, EffectiveDate=Date.today(),
                                    ContractId=testContract.Id);
        insert testOrder;
        
        Quote testQuote = new Quote(Name = 'Test Quote', Status = 'Draft', Pricebook2Id = pricebookListTest[0].Id,
                                    OpportunityId=testOpportunity.Id);
        insert testQuote;
        
        List<Product2> ProductListTest = new List<Product2>();
        ProductListTest.add(new Product2(Name='Product 1', ProductCode='10094', IsActive=true));
        ProductListTest.add(new Product2(Name='Product 2', ProductCode='10083', IsActive=true));
        ProductListTest.add(new Product2(Name='Product 3', ProductCode='100941', IsActive=true));
        ProductListTest.add(new Product2(Name='Product 4', ProductCode='1008312', IsActive=true));
        
        insert ProductListTest;
        
        List<PricebookEntry> pricbookEntryListTest = new List<PricebookEntry>();
        
        pricbookEntryListTest.add(new PricebookEntry(Pricebook2Id = standardPricebook,Product2Id = ProductListTest[0].Id,
                                                     UnitPrice = 100.00));
        pricbookEntryListTest.add(new PricebookEntry(Pricebook2Id = standardPricebook,Product2Id = ProductListTest[1].Id,
                                                     UnitPrice = 100.00));
        pricbookEntryListTest.add(new PricebookEntry(Pricebook2Id = standardPricebook,Product2Id = ProductListTest[2].Id,
                                                     UnitPrice = 100.00));
        pricbookEntryListTest.add(new PricebookEntry(Pricebook2Id = standardPricebook,Product2Id = ProductListTest[3].Id,
                                                     UnitPrice = 100.00));
        insert pricbookEntryListTest;
        
        List<PricebookEntry> pricbookEntryListTestCustom = new List<PricebookEntry>();
        
        pricbookEntryListTestCustom.add(new PricebookEntry(Pricebook2Id = pricebookListTest[0].Id,Product2Id = ProductListTest[0].Id,
                                                           UnitPrice = 100.00, IsActive = true));
        pricbookEntryListTestCustom.add(new PricebookEntry(Pricebook2Id = pricebookListTest[0].Id,Product2Id = ProductListTest[1].Id,
                                                           UnitPrice = 100.00, IsActive = true));
        pricbookEntryListTestCustom.add(new PricebookEntry(Pricebook2Id = pricebookListTest[0].Id,Product2Id = ProductListTest[2].Id,
                                                           UnitPrice = 100.00, IsActive = true));
        pricbookEntryListTestCustom.add(new PricebookEntry(Pricebook2Id = pricebookListTest[0].Id,Product2Id = ProductListTest[3].Id,
                                                           UnitPrice = 100.00, IsActive = true));
        insert pricbookEntryListTestCustom;
        
        
        List<OpportunityLineItem> opportunityLineItemListTest = new List<OpportunityLineItem>();
        opportunityLineItemListTest.add(new OpportunityLineItem(OpportunityId=testOpportunity.Id, UnitPrice=300, Quantity=2,
                                                                PricebookEntryId=pricbookEntryListTestCustom[0].Id));
        opportunityLineItemListTest.add(new OpportunityLineItem(OpportunityId=testOpportunity.Id, UnitPrice=300, Quantity=2,
                                                                PricebookEntryId=pricbookEntryListTestCustom[1].Id));
        insert opportunityLineItemListTest;
        
        List<QuoteLineItem> quoteLineItemListTest = new List<QuoteLineItem>();
        quoteLineItemListTest.add(new QuoteLineItem(QuoteId=testQuote.Id, UnitPrice=300, Quantity=2,
                                                    PricebookEntryId=pricbookEntryListTestCustom[0].Id));
        quoteLineItemListTest.add(new QuoteLineItem(QuoteId=testQuote.Id, UnitPrice=300, Quantity=2,
                                                    PricebookEntryId=pricbookEntryListTestCustom[1].Id));
        insert quoteLineItemListTest;
        
        List<OrderItem> orderItemListTest = new List<OrderItem>();
        orderItemListTest.add(new OrderItem(OrderId=testOrder.Id, UnitPrice=300, Quantity=2,
                                            PricebookEntryId=pricbookEntryListTestCustom[0].Id));
        orderItemListTest.add(new OrderItem(OrderId=testOrder.Id, UnitPrice=300, Quantity=2,
                                            PricebookEntryId=pricbookEntryListTestCustom[1].Id));
        insert orderItemListTest;
    }
    
    @isTest
    static void testGetPricebookDetail() {
        Test.startTest();
        List<Pricebook2> pricebookList = ProductController.getPricebookDetail();
        Test.stopTest();
        System.assertNotEquals(null, pricebookList, 'Pricebook list should not be null');
        System.assertEquals(1, pricebookList.size(), 'Pricebook size did not matching');
    }
    
    @isTest
    static void testGetPricebookIdOpportunity() {
        List<Opportunity> oppoList =[Select Id From Opportunity Limit 1];
        Test.startTest();
        String pricebookId = ProductController.getPricebookId(oppoList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, pricebookId, 'Pricebook ID should not be null');
    }
    
    @isTest
    static void testGetPricebookIdOrder() {        
        List<Order> orderList =[Select Id From Order Limit 1];
        Test.startTest();
        String pricebookId = ProductController.getPricebookId(orderList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, pricebookId, 'Pricebook ID should not be null');
    }
    
    @isTest
    static void testGetPricebookIdQuote() {
        List<Quote> quoteList =[Select Id From Quote Limit 1];
        Test.startTest();
        String pricebookId = ProductController.getPricebookId(quoteList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, pricebookId, 'Pricebook ID should not be null');
    }
    
    @isTest
    static void testDeleteRelatedLineitemOpportunity() {
        List<Opportunity> oppoList =[Select Id From Opportunity Limit 1];
        Test.startTest();
        ProductController.deleteRelatedLineitem(oppoList[0].Id);
        Test.stopTest();
        List<OpportunityLineItem> opportunityLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppoList[0].Id];
        System.assertEquals(0, opportunityLineItems.size(), 'Opportunity Line Items should be deleted');
    }
    
    @isTest
    static void testDeleteRelatedLineitemOrder() {
        List<Order> orderList =[Select Id From Order Limit 1];
        Test.startTest();
        ProductController.deleteRelatedLineitem(orderList[0].Id);
        Test.stopTest();
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE OrderId = :orderList[0].Id];
        System.assertEquals(0, orderItems.size(), 'Order Items should be deleted');
    }
    
    @isTest
    static void testDeleteRelatedLineitemQuote() {
        List<Quote> quoteList =[Select Id From Quote Limit 1];
        Test.startTest();
        ProductController.deleteRelatedLineitem(quoteList[0].Id);
        Test.stopTest();
        List<QuoteLineItem> quoteLineItems = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteList[0].Id];
        System.assertEquals(0, quoteLineItems.size(), 'Quote Line Items should be deleted');
    }
    
    @isTest
    static void testGetAllProductsWithUnitPriceOpportunity() {
        List<Pricebook2> pricebookList = [Select FIELDS(STANDARD) From Pricebook2 Limit 1]; 
        List<Opportunity> opportunityList = [Select FIELDS(STANDARD) From opportunity Limit 1];
        
        Test.startTest();
        List<ProductController.productWrapper> result = ProductController.getAllProductsWithUnitPrice(pricebookList[0].Id, opportunityList[0].Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        for (ProductController.productWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.columnForProductTable, 'Column for Product Table should not be null');
            System.assertNotEquals(null, wrapper.objectName, 'Object Name should not be null');
            System.assertEquals('Opportunity', wrapper.objectName, 'Object Name should match');
            System.assertNotEquals(null, wrapper.pricebookEntryList, 'Pricebook Entry List should not be null');
            System.assertNotEquals(null, wrapper.productList, 'Product List should not be null');
        }
    }
    
    @isTest
    static void testGetFieldSetForFilter() {
        Test.startTest();
        String fieldSetForFilters = ProductController.getFieldSetForFilter();
        Test.stopTest();
        System.assertNotEquals(null, fieldSetForFilters, 'Field set should not be null');
    }
    
    @isTest
    static void testGetProductsToFilter() {
        List<Pricebook2> pricebookList = [Select FIELDS(STANDARD) From Pricebook2 Limit 1];
        
        Test.startTest();
        List<Product2> result = ProductController.getProductsTofilter(pricebookList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(4, result.size(), 'Result size should be 4');
    }
    
      @isTest
    static void testGetFieldSetForConfigurationTableOpportunity() {
        List<Opportunity> oppoList =[Select Id From Opportunity Limit 1];
        Test.startTest();
        String fieldSet = ProductController.getFieldSetForConfigurationTable(oppoList[0].Id);
        Test.stopTest();
         System.assertNotEquals(null, fieldSet, 'Field set should not be null');
    }

    @isTest
    static void testGetFieldSetForConfigurationTableOrder() {
       List<Order> orderList =[Select Id From Order Limit 1];
        Test.startTest();
        String fieldSet = ProductController.getFieldSetForConfigurationTable(orderList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, fieldSet, 'Field set should not be null');
    }

    @isTest
    static void testGetFieldSetForConfigurationTableQuote() {
       List<Quote> quoteList =[Select Id From Quote Limit 1];
        Test.startTest();
        String fieldSet = ProductController.getFieldSetForConfigurationTable(quoteList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, fieldSet, 'Field set should not be null');
    }
}