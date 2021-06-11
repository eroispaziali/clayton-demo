/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LineItemTriggerTest {
	
	private static final Integer TEST_VOLUMES_NUMBER_OF_ACCOUNTS = 100;
	private static final Integer TEST_VOLUMES_NUMBER_OF_LOTS = 1000;
	private static final Integer TEST_VOLUMES_LINE_ITEMS_PER_PURCHASE = 10;
	private static final Decimal TEST_PRICE_ORANGES = 4;
	private static final Decimal TEST_PRICE_APPLES = 2;
	private static final Decimal TEST_PRICE_PEARS = 3;

	/** TEST WRAPPER COMPARATOR
		==========================================================================================
    	A sortable wrapper is used to sort results when counting product and product categories
    	per order. This test ensure the comparator works as it should. 
    	========================================================================================== */	
	static testMethod void testWrapperComparator() {
		Test.startTest();
		
		// Prepare wrappers: w1=w2, w1>w3
		LineItemTriggerHandler.CategoryWrapper w1 = new LineItemTriggerHandler.CategoryWrapper('w1');
		LineItemTriggerHandler.CategoryWrapper w2 = new LineItemTriggerHandler.CategoryWrapper('w2');
		LineItemTriggerHandler.CategoryWrapper w3 = new LineItemTriggerHandler.CategoryWrapper('w3');
		w1.addUnits(1);
		w2.addUnits(1);
		w3.addUnits(2);
		
		// Check results
		System.assertEquals(1, w1.compareTo(w3), 'w1 greater than w3');
		System.assertEquals(-1, w3.compareTo(w1), 'w3 less than w1');
		System.assertEquals(0, w1.compareTo(w2), 'w1 equals w2');
		
		Test.stopTest();
	}

	/** TEST COMPUTATION ON VOLUMES
		==========================================================================================
    	This test ensures code scale to the required volumes without breaking governor limits
			- 1000 product lots, 10 OLI per order, 10 Orders per Purchase agreement
		Please note: no assertions on logic here, only volumes are tested. Logic is tested below. 
    	========================================================================================== */	
	static testMethod void testLargeVolumes() {
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		List<Lot__c> allTheLots;

		// Inventory manager sets up accounts		
		System.runAs(inventoryManager) {
			allTheLots = TestDataFactory.createLots(TEST_VOLUMES_NUMBER_OF_LOTS);
			insert allTheLots;
		}
		
		// Account manager creates accounts and orders
		System.runAs(accountManager) {
			List<Account> accounts = TestDataFactory.createAccounts(TEST_VOLUMES_NUMBER_OF_ACCOUNTS);
			insert accounts;
			List<Order__c> orders = TestDataFactory.createOrders(accounts);
			insert orders;
			
			List<Lot__c> someLots = new List<Lot__c>();
			for (Integer i=0; i<TEST_VOLUMES_LINE_ITEMS_PER_PURCHASE; i++) {
				someLots.add(allTheLots[i]);
			}
			
			List<Line_Item__c> largeBulk = TestDataFactory.createLineItems(orders, someLots, 1);
			Test.startTest();
				insert largeBulk;
			Test.stopTest();
		}
		
	}
	
	@IsTest(seeAllData=false)
	private static void testOrphanLineItems() {
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			Account myStore = TestDataFactory.createAccount();
			Account anotherStore = TestDataFactory.createAccount();
			insert new List<Account> { myStore, anotherStore };
		}
		
		System.runAs(accountManager) {
			Lot__c apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
	    	Lot__c pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
	    	Lot__c oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
	    	List<Lot__c> lots = new List<Lot__c> { pears, oranges, apples }; 
	    	insert lots;
	    	
	    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
	    	Line_Item__c myApples = TestDataFactory.createLineItem(apples, 10);
	    	Line_Item__c myOranges = TestDataFactory.createLineItem(oranges, 9);
	    	Line_Item__c myPears = TestDataFactory.createLineItem(pears, 8);
	    	lineItems.add( myOranges );
	    	lineItems.add( myApples );
	    	lineItems.add( myPears );
	    	
	    	Test.startTest();
	    		insert lineItems;
	    	Test.stopTest();
	    	
	    	lineItems = [SELECT Id, Order__c FROM Line_Item__c];
	    	for (Line_Item__c li : lineItems) {
	    		System.assertEquals(null, li.Order__c, 'Order should be null');
	    	}
		}
	}
	
	static testMethod void testOrdersWithLineItemsInsert() {
		
		Order__c myOrder;
		Lot__c apples, pears, oranges;
		List<Lot__c> lots;
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
	    	pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
	    	oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
	    	lots = new List<Lot__c> { pears, oranges, apples }; 
	    	insert lots;
		}
		
		System.runAs(accountManager) {
			
			Account myStore = TestDataFactory.createAccount();
			Account anotherStore = TestDataFactory.createAccount();
			insert new List<Account> { myStore, anotherStore };
			
	    	myOrder = TestDataFactory.createOrder(myStore);
	    	Order__c anotherOrder = TestDataFactory.createOrder(myStore);
	    	Order__c someoneElsesOrder = TestDataFactory.createOrder(anotherStore);
	    	insert new List<Order__c> { myOrder, anotherOrder, someoneElsesOrder };
	    	
	    	/* Bulk INSERT
	    	 * Create many orders and line items in the same transactions, ensure that logic works 
	    	 * without messing up with different orders. 
	    	=============================================================================================================== */
	    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
	    	Line_Item__c myApples = TestDataFactory.createLineItem(myOrder, apples, 10);
	    	Line_Item__c myOranges = TestDataFactory.createLineItem(myOrder, oranges, 9);
	    	Line_Item__c myPearsFirstBit = TestDataFactory.createLineItem(myOrder, pears, 6);
	    	Line_Item__c myPearsSecondBit = TestDataFactory.createLineItem(myOrder, pears, 5); 
	    	lineItems.add( myOranges );
	    	lineItems.add( myApples );
	    	lineItems.add( myPearsFirstBit );
	    	lineItems.add( myPearsSecondBit );
	    	
	    	// create some other orders to ensure processing doesn't mess up with orders
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, apples, 20) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, pears, 7) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, oranges, 6) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, oranges, 1) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, pears, 2) );
	    	
	    	Test.startTest();
	    		insert lineItems;
	    	Test.stopTest();
		}
		
		// Reload myOrder and assert results on insert (for both price and 1st + 2nd category)
		Decimal expectedAmount = 9*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 10*TEST_PRICE_APPLES;
    	myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
    	System.assertEquals(expectedAmount, myOrder.Purchased__c, 'Purchased price is incorrect on insert');
    	System.assertEquals('pears', myOrder.Product_Category_1__c,  'First product category is incorrect on insert');
    	System.assertEquals(11, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on insert');
    	System.assertEquals('apples', myOrder.Product_Category_2__c, 'Second product category is incorrect on insert');
    	System.assertEquals(10, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on insert');
		
	}
	
	static testMethod void testOrdersWithLineItemsUpdate() {
		
		Order__c myOrder;
		Lot__c apples, pears, oranges;
		List<Lot__c> lots;
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
	    	pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
	    	oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
	    	lots = new List<Lot__c> { pears, oranges, apples }; 
	    	insert lots;
		}
		
		System.runAs(accountManager) {
			
			Account myStore = TestDataFactory.createAccount();
			Account anotherStore = TestDataFactory.createAccount();
			insert new List<Account> { myStore, anotherStore };
			
	    	myOrder = TestDataFactory.createOrder(myStore);
	    	Order__c anotherOrder = TestDataFactory.createOrder(myStore);
	    	Order__c someoneElsesOrder = TestDataFactory.createOrder(anotherStore);
	    	insert new List<Order__c> { myOrder, anotherOrder, someoneElsesOrder };
	    	
	    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
	    	Line_Item__c myApples = TestDataFactory.createLineItem(myOrder, apples, 10);
	    	Line_Item__c myOranges = TestDataFactory.createLineItem(myOrder, oranges, 9);
	    	Line_Item__c myPearsFirstBit = TestDataFactory.createLineItem(myOrder, pears, 6);
	    	Line_Item__c myPearsSecondBit = TestDataFactory.createLineItem(myOrder, pears, 5); 
	    	lineItems.add( myOranges );
	    	lineItems.add( myApples );
	    	lineItems.add( myPearsFirstBit );
	    	lineItems.add( myPearsSecondBit );
	    	
	    	// create some other orders to ensure processing doesn't mess up with orders
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, apples, 20) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, pears, 7) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, oranges, 6) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, oranges, 1) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, pears, 2) );
	    	
	    	insert lineItems;
	    	
	    	/* BULK UPDATE
	    	 * Update some line items with different number of units, ensure logic works
	    	============================================================================== */
			List<Line_Item__c> orangesAndApples = new List<Line_Item__c> { myApples, myOranges }; 
			myApples.Units__c = 20;
			myOranges.Units__c = 7;
	    	Test.startTest();
	    		update orangesAndApples;
	    	Test.stopTest();
		}
			
		// Reload myOrder and check expected results (for both price and 1st + 2nd category)
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		Decimal expectedAmount = 7*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 20*TEST_PRICE_APPLES;
		System.assertEquals(expectedAmount, myOrder.Purchased__c, 'Purchased price is incorrect on update');
		System.assertEquals('apples', myOrder.Product_Category_1__c,  'First product category is incorrect on update');
		System.assertEquals(20, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on update');
		System.assertEquals('pears', myOrder.Product_Category_2__c, 'Second product category is incorrect on update');
		System.assertEquals(11, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on update');
	}
	
	static testMethod void testOrdersWithLineItemsDelete() {
		
		Order__c myOrder;
		Lot__c apples, pears, oranges;
		List<Lot__c> lots;
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
	    	pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
	    	oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
	    	lots = new List<Lot__c> { pears, oranges, apples }; 
	    	insert lots;
		}
		
		System.runAs(accountManager) {
			
			Account myStore = TestDataFactory.createAccount();
			Account anotherStore = TestDataFactory.createAccount();
			insert new List<Account> { myStore, anotherStore };
			
	    	myOrder = TestDataFactory.createOrder(myStore);
	    	Order__c anotherOrder = TestDataFactory.createOrder(myStore);
	    	Order__c someoneElsesOrder = TestDataFactory.createOrder(anotherStore);
	    	insert new List<Order__c> { myOrder, anotherOrder, someoneElsesOrder };
	    	
	    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
	    	Line_Item__c myApples = TestDataFactory.createLineItem(myOrder, apples, 10);
	    	Line_Item__c myOranges = TestDataFactory.createLineItem(myOrder, oranges, 9);
	    	Line_Item__c myPearsFirstBit = TestDataFactory.createLineItem(myOrder, pears, 6);
	    	Line_Item__c myPearsSecondBit = TestDataFactory.createLineItem(myOrder, pears, 5); 
	    	lineItems.add( myOranges );
	    	lineItems.add( myApples );
	    	lineItems.add( myPearsFirstBit );
	    	lineItems.add( myPearsSecondBit );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, apples, 20) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, pears, 7) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, oranges, 6) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, oranges, 1) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, pears, 2) );
	    	insert lineItems;
	    	
    		/* BULK DELETE
    	 	* Delete something from the order, but leave something else in, ensure logic works
    		===================================================================================== */
    		List<Line_Item__c> orangesAndApples = new List<Line_Item__c> { myApples, myOranges }; 
	    	Test.startTest();
	    		delete orangesAndApples;
	    	Test.stopTest();
		}
			
		// Reload myOrder and check expected results (for both price and 1st + 2nd category)
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		Decimal expectedAmount = (6+5)*TEST_PRICE_PEARS;
		System.assertEquals( expectedAmount, myOrder.Purchased__c, 'Purchased price is incorrect on delete');
    	System.assertEquals('pears', myOrder.Product_Category_1__c,  'First product category is incorrect on delete');
    	System.assertEquals(11, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on delete');
    	System.assertEquals(null, myOrder.Product_Category_2__c, 'Second product category should be null on delete');
    	System.assertEquals(null, myOrder.Product_Category_Units_2__c, 'Second product category should be null on delete');
    	
    	/* ADDITIONAL TEST CASE
		   Test with empty orders (no Line Items) 
    	========================================== */
    	List<Line_Item__c> allMyOrderItems = [SELECT Id FROM Line_Item__c WHERE Order__c = :myOrder.Id];
    	delete allMyOrderItems;
    	
    	// Reload myOrder and check expected results (for both price and 1st + 2nd category)
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		expectedAmount = 0;
		System.assertEquals(expectedAmount, myOrder.Purchased__c, 'Purchased price is incorrect on and empty order');
    	System.assertEquals(null, myOrder.Product_Category_1__c,  'First product category should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_Units_1__c, 'First product category units should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_2__c, 'Second product category should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_Units_2__c, 'Second product category should be null on an empty order');
    	
	}
	
	static testMethod void testOrdersWithLineItemsUndelete() {
		
		Order__c myOrder;
		Lot__c apples, pears, oranges;
		List<Lot__c> lots;
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
	    	pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
	    	oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
	    	lots = new List<Lot__c> { pears, oranges, apples }; 
	    	insert lots;
		}
		
		System.runAs(accountManager) {
			
			Account myStore = TestDataFactory.createAccount();
			Account anotherStore = TestDataFactory.createAccount();
			insert new List<Account> { myStore, anotherStore };
			
	    	myOrder = TestDataFactory.createOrder(myStore);
	    	Order__c anotherOrder = TestDataFactory.createOrder(myStore);
	    	Order__c someoneElsesOrder = TestDataFactory.createOrder(anotherStore);
	    	insert new List<Order__c> { myOrder, anotherOrder, someoneElsesOrder };
	    	
	    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
	    	Line_Item__c myApples = TestDataFactory.createLineItem(myOrder, apples, 20);
	    	Line_Item__c myOranges = TestDataFactory.createLineItem(myOrder, oranges, 9);
	    	Line_Item__c myPearsFirstBit = TestDataFactory.createLineItem(myOrder, pears, 6);
	    	Line_Item__c myPearsSecondBit = TestDataFactory.createLineItem(myOrder, pears, 5); 
	    	lineItems.add( myOranges );
	    	lineItems.add( myApples );
	    	lineItems.add( myPearsFirstBit );
	    	lineItems.add( myPearsSecondBit );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, apples, 20) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, pears, 7) );
	    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, oranges, 6) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, oranges, 1) );
	    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, pears, 2) );
	    	insert lineItems;
	    	
	    	// delete
    		List<Line_Item__c> orangesAndApples = new List<Line_Item__c> { myApples, myOranges };
    		delete orangesAndApples;

			/* BULK UNDELETE
		 	 * Restore what was removed from the order above, ensure logic works
	    	====================================================================== */
	    	Test.startTest();
	    		undelete orangesAndApples;	
	    	Test.stopTest();
		}
		
		// Reload myOrder and check expected results (for both price and 1st + 2nd category)
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		Decimal expectedAmount =  9*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 20*TEST_PRICE_APPLES;
		System.assertEquals(expectedAmount, myOrder.Purchased__c, 'Purchased price is incorrect on undelete');
    	System.assertEquals('apples', myOrder.Product_Category_1__c,  'First product category is incorrect on undelete');
    	System.assertEquals(20, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on undelete');
    	System.assertEquals('pears', myOrder.Product_Category_2__c, 'Second product category is incorrect on undelete');
    	System.assertEquals(11, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on undelete');
	}
	
    
}