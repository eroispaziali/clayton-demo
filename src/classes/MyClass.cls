public without sharing class MyClass {

     public void violationExpected(){
             String malicious = ApexPages.currentPage().getParameters().get('MALICIOUS_SOQL_CODE');
             Account account = [SELECT id,AccountId FROM Contact WHERE Id = :malicious LIMIT 1];
      }
 }