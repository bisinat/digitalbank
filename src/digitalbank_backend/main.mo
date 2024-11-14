import List "mo:base/List";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Random "mo:base/Random";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
actor SimpleBank{
  type Result<T,E> = Result.Result<T, E>;
  type Operation = {
    #deposit;
    #withdraw;
  };
  type Customer = {
    name: Text;
    pin: Nat;
    id: Principal;
    var amount: Float;
  };
  type BankTransaction = {
    id: Principal;
    amount: Float;
    timestamp: Int;
    customerId: Principal;
    operation: Operation;
  };
  type Bank = {
    var totalDeposits: Float;
    var transactions: List.List<BankTransaction>;
    var customers: List.List<Customer>;
  };
  type ImmutBank = {
     totalDeposits: Float;
     transactions: List.List<BankTransaction>;
  };
  stable  var bankStorage: Bank = {
    var totalDeposits= 0.0;
    var transactions= List.nil();
    var customers = List.nil();
  };
  var currentCustomer: ?Customer = null;
  public query func getBankDetails(): async Result<ImmutBank, Text> {
    let immutBank: ImmutBank = {
      totalDeposits = bankStorage.totalDeposits;
      transactions = bankStorage.transactions;
    };
   return #ok(immutBank);
 };
 public query func getBalance(): async Result<Text, Text>{
   switch(currentCustomer) {
     case(null) {
       #err("User is not logged in!");
       };
     case(?currentCustomer) {
       #ok("Current Balance: " # Float.toText(currentCustomer.amount));
      };
   };
 };
   public query func getCustomerTransactions() : async Result<List.List<BankTransaction>, Text>{
      switch(currentCustomer) {
     case(null) {
       #err("User is not logged in!");
       };
     case(?currentCustomer) {
       let transactions = List.filter<BankTransaction>(bankStorage.transactions, func t {t.customerId == currentCustomer.id});
       #ok(transactions);
      };
   };
   };
  public  func createTransaction (amount: Float, operation: Operation) : async Result<Text, Text> {
    switch(currentCustomer) {
     case(null) {
       #err("User is not logged in!");
       };
     case(?currentCustomer) {
        if(operation == #deposit){
          currentCustomer.amount += amount;
          bankStorage.totalDeposits += amount;
        };
        if(operation == #withdraw){
          currentCustomer.amount  -= amount;
          bankStorage.totalDeposits -= amount;
        };
        let transaction : BankTransaction = {
          amount = amount;
          customerId = currentCustomer.id;
          timestamp = Time.now();
          id = await generatePrincipal();
          operation = operation;
        };
        bankStorage.transactions := List.push<BankTransaction>(transaction, bankStorage.transactions);
        #ok("done");
      };
   };
  };
   func generatePrincipal() : async Principal {
     let random_blob = await Random.blob();
     let principal_blob = Blob.fromArray(Iter.toArray(Array.slice<Nat8>((Blob.toArray(random_blob), 0, 29))));
     return Principal.fromBlob(principal_blob);
   };
  public func createCustomer(name: Text, pin: Nat, amount: Float ): async Result<Text,Text>{
  let customer = List.filter<Customer>(bankStorage.customers, func c { c.name == name});
  switch(customer){
    case(null){
      let newCustomer: Customer = {
        name = name;
        pin = pin;
        var amount = amount;
        id = await generatePrincipal();
      };
      bankStorage.customers := List.push<Customer>(newCustomer, bankStorage.customers);
      bankStorage.totalDeposits += amount;
      return #ok("Customer " # name # " has been created");
    };
    case(?customer){
      return #err("account already taken");
    }
  }
  };
  public func authenticCustomer(name: Text, pin:Nat): async Result<Text, Text>{
    switch(currentCustomer){
      case(null){
        let customer = List.filter<Customer>(bankStorage.customers, func c { c.name == name and c.pin == pin});
        if(List.size(customer) == 0){
            return #err("user does not exist");
        } else {
            currentCustomer := List.get(customer, 0);
            return #ok("authenticated user!");
        };
        };
      case(?currentCustomer){
        return #err("user already logged in");
      };
    };
  };
  public func signOut(): async Result<Text, Text>{
    currentCustomer := null;
    return #ok("logged out successfully");
  };
}

