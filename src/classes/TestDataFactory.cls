@isTest
public class TestDataFactory {
	
	public static final String TEST_ACCOUNT_NAME = 'A Test Account';
	public static final String TEST_LOT_NAME = 'A Test Lot';
	public static final String TEST_LOT_CATEGORY = 'A Test Category';
	public static final Integer TEST_LOT_SIZE = 100;
	public static final Decimal TEST_LOT_PRICE = 10.0;
	public static final String TEST_USER_ENCODING = 'UTF-8';
	public static final String TEST_USER_EMAIL_POSTFIX = '@pbwc.com.nospam';
	public static final String TEST_USER_LOCALE = 'en_US';
	public static final String TEST_USER_TIMEZONE = 'Europe/London';
	public static final String TEST_USER_FIRSTNAME = 'John';
	public static final String TEST_USER_LASTNAME = 'Doe';
	
	public static Account createAccount() {
		return createAccounts(1).get(0);
	}
	
	public static List<Account> createAccounts(Integer howMany) {
		howMany = (howMany!=null && howMany!=0) ? Math.abs(howMany) : 1;
		List<Account> accounts = new List<Account>();
		for (Integer i=0; i<howMany; i++) {
			Account a = new Account(name = TEST_ACCOUNT_NAME);
			accounts.add(a);
		}
		return accounts;	
	}
	
	public static Order__c createOrder(Account a) {
		return createOrders(new List<Account> {a}).get(0);
	}

	public static Order__c createOrder(Decimal budget) {
		Order__c o = new Order__c();
		o.Budget__c = budget;
		o.Name = 'A test order';
		o.Status__c = 'Draft';
		return o; 
	}
	
	
	public static List<Order__c> createOrders(List<Account> accounts) {
		List<Order__c> orders = new List<Order__c>();
		for (Account a : accounts) {
			Order__c o = new Order__c();
			o.Name = 'A test order';
			o.Status__c = 'Draft';
			o.Store__c = a.Id;
			orders.add(o);
		}
		return orders;
	}
	
	public static Line_Item__c createLineItem(Order__c anOrder, Lot__c lot, Integer units) {
		return createLineItems(new List<Order__c>{anOrder}, new List<Lot__c>{lot}, units).get(0);
	}
	
	public static Line_Item__c createLineItem(Lot__c lot, Integer units) {
		return createLineItems(new List<Lot__c>{lot}, units).get(0);
	}
	
	public static List<Line_Item__c> createLineItems(List<Order__c> orders, List<Lot__c> lots, Integer units) {
		List<Line_Item__c> lineItems = new List<Line_Item__c>();
		for (Order__c o : orders) {
			for (Lot__c l : lots) {
				Line_Item__c lineItem = new Line_Item__c(
					Order__c = o.Id,
					Lot__c = l.Id,
					Units__c = units
				);
				lineItems.add(lineItem);
			}
		}
		return lineItems;
	}
	
	public static List<Line_Item__c> createLineItems(List<Lot__c> lots, Integer units) {
		List<Line_Item__c> lineItems = new List<Line_Item__c>();
		for (Lot__c l : lots) {
			Line_Item__c lineItem = new Line_Item__c(
				Lot__c = l.Id,
				Units__c = units
			);
			lineItems.add(lineItem);
		}
		return lineItems;
	}
	
	public static List<Line_Item__c> createLineItems(Map<Id, List<Id>> orderMap, Integer howMany) {
		howMany = (howMany!=null && howMany!=0) ? Math.abs(howMany) : 1;
		List<Line_Item__c> lineItems = new List<Line_Item__c>();
		for (Id orderId : orderMap.keySet()) {
			for (Id lotId : orderMap.get(orderId)) {
				for (Integer i=0; i<howMany; i++) {
					Line_Item__c lineItem = new Line_Item__c(
						Order__c = orderId,
						Lot__c = lotId,
						Units__c = 1
					);
					lineItems.add(lineItem);
				}
			}
		}
		return lineItems;
	}
	
	public static Line_Item__c createLineItem(Id orderId, Id lotId, Integer units) {
		Line_Item__c li = new Line_Item__c(
			Order__c = orderId,
			Lot__c = lotId,
			Units__c = units
		);
		return li; 
	}
	
	public static Line_Item__c createLineItem(Id lotId, Integer units) {
		Line_Item__c li = new Line_Item__c(
			Lot__c = lotId,
			Units__c = units
		);
		return li; 
	}
	
	public static Lot__c createLot(String productCategory, Decimal unitPrice) {
		Lot__c myLot = createLots(productCategory, 1).get(0);
		myLot.Unit_Price__c = unitPrice;
		return myLot;
	}
	
	public static Lot__c createLot(String productCategory, Decimal unitPrice, Integer lotSize) {
		Lot__c myLot = createLots(productCategory, 1).get(0);
		myLot.Unit_Price__c = unitPrice;
		myLot.Lot_Size__c = lotSize;
		return myLot;
	}
	
	
	public static List<Lot__c> createLots(Integer howMany) {
		return createLots(TEST_LOT_CATEGORY, howMany);
	}
	
	public static List<Lot__c> createLots(String categoryName, Integer howMany) {
		howMany = (howMany!=null && howMany!=0) ? Math.abs(howMany) : 1;
		List<Lot__c> lots = new List<Lot__c>();
		for (Integer i=0; i<howMany; i++) {
			Lot__c lot = new Lot__c(
				Product__c = TEST_LOT_NAME,
				Product_Category__c = categoryName,
				Lot_Size__c = TEST_LOT_SIZE,
				Unit_Price__c = TEST_LOT_PRICE
			);
			lots.add(lot);	
		}
		return lots;
	}
	
	public static User createUser(String profile, String myAlias) {
		Profile p = [SELECT Id FROM Profile WHERE Name=:profile LIMIT 1][0];
		String mail = myAlias + TEST_USER_EMAIL_POSTFIX; 
		User myUser = new User(alias = myAlias, Email=mail, 
			FirstName = TEST_USER_FIRSTNAME, LastName=TEST_USER_LASTNAME,
      		EmailEncodingKey=TEST_USER_ENCODING, LanguageLocaleKey=TEST_USER_LOCALE, 
      		LocaleSidKey=TEST_USER_LOCALE, ProfileId = p.Id, 
      		TimeZoneSidKey=TEST_USER_TIMEZONE, UserName=mail);
      	insert myUser;
      	return myUser;
	}
    
}