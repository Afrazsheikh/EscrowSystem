pragma solidity ^0.8.0;
// contratc name 
contract EscrowTAsk {
    enum EscrowState { InProgress, Completed, Disputed }
    
    // createing struct for state buyer saller or arbitatry amount etc..
    struct EscrowTransaction {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
        EscrowState state;
        bool isFunded;
    }
    
    // map EscrowTransaction
    mapping(uint256 => EscrowTransaction) public transactions;
    uint256 public transactionCount;
    
    // modifer  so can onlyNuyer can acces the particular function
    modifier onlyBuyer(uint256 transactionId) {
        require(msg.sender == transactions[transactionId].buyer, "Only the buyer can call this function.");
        _;
    }
    // modifer  so can seller can acces the particular function

    
    modifier onlySeller(uint256 transactionId) {
        require(msg.sender == transactions[transactionId].seller, "Only the seller can call this function.");
        _;
    }
    // modifer  so can seller can acces the particular function
    
    modifier onlyArbiter(uint256 transactionId) {
        require(msg.sender == transactions[transactionId].arbiter, "Only the arbiter can call this function.");
        _;
    }
    // here emitiing events 
    event TransactionCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address arbiter, uint256 amount);
    event TransactionFunded(uint256 indexed transactionId);
    event TransactionCompleted(uint256 indexed transactionId);
    event TransactionDisputed(uint256 indexed transactionId);
    
    //   function allows a buyer to initiate a new  transaction. 
    function createTransaction(address _seller, address _arbiter) external payable {
        // this Ensures that the seller's _arbiter  address is not the zero address 
        require(_seller != address(0), "Seller address cannot be zero.");
        require(_arbiter != address(0), "Arbiter address cannot be zero.");
        require(msg.value > 0, "Amount must be greater than zero.");
        // this will update mapping and new escrow transaction 
        uint256 newTransactionId = transactionCount;
        transactions[newTransactionId] = EscrowTransaction(msg.sender, _seller, _arbiter, msg.value, EscrowState.InProgress, false);
        // The transactionCount is incremented to ensure the uniqueness of the next transaction identifier.
        transactionCount++;
        
        emit TransactionCreated(newTransactionId, msg.sender, _seller, _arbiter, msg.value);
    }
    // this funtion is used to fund transation  and only Buyer can access thius
    function fundTransaction(uint256 transactionId) external onlyBuyer(transactionId) payable {
        require(transactions[transactionId].state == EscrowState.InProgress, "Transaction is not in progress.");
        require(msg.value == transactions[transactionId].amount, "Funded amount must be equal to the transaction amount.");
        
        transactions[transactionId].isFunded = true;
        // it show transaction is funded 
        emit TransactionFunded(transactionId);
    }
    // function is used by the buyer to mark the escrow transaction as completed and release the funds to the seller
    function completeTransaction(uint256 transactionId) external onlyBuyer(transactionId) {
        // EscrowState.InProgress. This confirms that the transaction is currently in progress and can be completed.
        require(transactions[transactionId].state == EscrowState.InProgress, "Transaction is not in progress.");
        require(transactions[transactionId].isFunded, "Transaction is not funded.");
        // The funds being transferred are equal to the amount specified in the escrow transaction.
        transactions[transactionId].state = EscrowState.Completed;
        
        payable(transactions[transactionId].seller).transfer(transactions[transactionId].amount);
        
        emit TransactionCompleted(transactionId);
    }
    // this function allow  the buyer  to dipute the transaction funtiuon  having modifier so onlyBuyer csan access this
    function disputeTransaction(uint256 transactionId) external onlyBuyer(transactionId) {
        require(transactions[transactionId].state == EscrowState.InProgress, "Transaction is not in progress.");
        // transactionId has been funded. The isFunded flag must be set to true to proceed with the dispute.
        require(transactions[transactionId].isFunded, "Transaction is not funded.");
        
        transactions[transactionId].state = EscrowState.Disputed;
        
        emit TransactionDisputed(transactionId);
    }
    
    function resolveDispute(uint256 transactionId, bool isBuyerWinner) external onlyArbiter(transactionId) {
        require(transactions[transactionId].state == EscrowState.Disputed, "Transaction is not in dispute.");
        
        if (isBuyerWinner) {
            transactions[transactionId].state = EscrowState.Completed;
            payable(transactions[transactionId].buyer).transfer(transactions[transactionId].amount);
        } else {
            transactions[transactionId].state = EscrowState.Completed;
            payable(transactions[transactionId].seller).transfer(transactions[transactionId].amount);
        }
        
        emit TransactionCompleted(transactionId);
    }
}
