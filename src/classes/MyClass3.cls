public class MyClass3 {

	public static void foo1() {
		for (Integer i=0; i<10; i++) {
			List<SObject> items = [Select Id, Name FROM account LIMIT 10];
		}
		items = [Select Id, Name FROM account WHERE Name ='abc'];
		items = [Select Id, Name FROM account];
		items = [Select Id, Name FROM account WHERE Name ='abc' LIMIT 10];
	}
	
	public static void select() {
		for (Integer i=0; i<10; i++) {
			if ([Select Id, Name FROM account LIMIT 10]) {
			}
		}
		[Select Id, Name FROM account LIMIT 10];
	}
	
	public void negativeScenario() {
		for (Integer i=0; i<10; [select id, name from group where name = 'abc']) {
			i++;
		}
	}
	
	global public void useless() {
		System.debug("useless");
	}
	
		
}
