//
//  NBTransaction.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import Foundation

// MARK: - NBTransaction
struct NBTransaction {
    // MARK: Category
    enum NBTransactionCategory: String, CaseIterable {
        case bike, car, clothing, education, entertainment
        case foodAndDrinks = "Food & Drinks"
        case gifts
        case healthAndFitness = "Health & Fitness"
        case metro, others, rickshaw, scooty
        case selfCare = "Self Care"
        case utilities
    }
    
    // MARK: ExpenseType
    enum NBTransactionExpenseType: String, CaseIterable {
        case friends, home, love,  mummy, office, personal, udit
    }
    
    // MARK: PaymentMethod
    enum NBTransactionPaymentMethod: String, CaseIterable {
        case appleWallet = "Apple Wallet"
        case amazonICICI = "Amazon ICICI Credit Card"
        case auBank = "AU Bank Savings Account"
        case auLit = "AU Lit Credit Card"
        case axisMyZone = "Axis My Zone Credit Card"
        case bpclSBI = "BPCL RuPay SBI Credit Card"
        case cash
        case flipkartAxis = "Flipkart Axis Credit Card"
        case hdfcBank = "HDFC Bank Savings Account"
        case hdfcRuPay = "HDFC RuPay Credit Card"
        case mummy
        case oneCard = "OneCard"
        case papa
        case paytmBank = "Paytm Payments Bank Account"
        case paytmHDFC = "Paytm HDFC Credit Card"
        case postPe = "PostPe"
        case sbiRuPay = "SBI RuPay Credit Card - xx31"
        case swiggyHDFC = "Swiggy HDFC Credit Card"
        case swiggyMoney = "Swiggy Money"
    }
    
    // MARK: Field
    enum NBTransactionField: String, CaseIterable {
        case date, title, category
        case expenseType = "Expense Type"
        case paymentMethod = "Payment Method"
        case amount
    }
    
    // MARK: TransactionType
    enum NBTransactionType: String, CaseIterable {
        case credit, debit
    }
    
    // MARK: Temp
    struct NBTempTransaction {
        var id: UUID?
        var date: Date?
        var title: String?
        var transactionType: NBTransactionType = .debit
        var category: NBTransactionCategory?
        var expenseType: NBTransactionExpenseType?
        var paymentMethod: NBTransactionPaymentMethod?
        var amount: Double?
    }
    
    let id: UUID
    let date: Date
    let title: String
    let transactionType: NBTransactionType
    let category: NBTransactionCategory
    let expenseType: NBTransactionExpenseType
    let paymentMethod: NBTransactionPaymentMethod
    let amount: Double
    
    // MARK: Constructor
    init(id: UUID = UUID(), date: Date = .now, title: String, transactionType: NBTransactionType, category: NBTransactionCategory, expenseType: NBTransactionExpenseType, paymentMethod: NBTransactionPaymentMethod, amount: Double) {
        self.id = id
        self.date = date
        self.title = title
        self.transactionType = transactionType
        self.category = category
        self.expenseType = expenseType
        self.paymentMethod = paymentMethod
        self.amount = amount
    }
}


// MARK: - Category
extension NBTransaction.NBTransactionCategory {
    var title: String {
        rawValue.capitalized
    }
}


// MARK: - ExpenseType
extension NBTransaction.NBTransactionExpenseType {
    var title: String {
        rawValue.capitalized
    }
}


// MARK: - PaymentMethod
extension NBTransaction.NBTransactionPaymentMethod {
    var title: String {
        rawValue.capitalized
    }
}


// MARK: - Field
extension NBTransaction.NBTransactionField {
    func getTitle(for transactionType: NBTransaction.NBTransactionType) -> String {
        let paidOrReceivedString = transactionType == .debit ? "Paid" : "Received"
        switch self {
        case .date:
            return "\(Date.now.formatted(date: .abbreviated, time: .omitted)) (Default)"
        case .title:
            return paidOrReceivedString + " for..."
        case .category, .expenseType:
            return rawValue.capitalized
        case .paymentMethod:
            return paidOrReceivedString + " using..."
        case .amount:
            return rawValue.capitalized
        }
    }
}


// MARK: - TransactionType
extension NBTransaction.NBTransactionType {
    var title: String {
        rawValue.capitalized
    }
}


// MARK: - TempTransaction
extension NBTransaction.NBTempTransaction {
    func getTransaction() -> NBTransaction? {
        guard let title, let category, let expenseType, let paymentMethod, let amount else { return nil }
        return NBTransaction(id: id ?? UUID(), date: date ?? .now, title: title, transactionType: transactionType, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: amount)
    }
    
    init(transaction: NBTransaction) {
        self.init(id: transaction.id, date: transaction.date, title: transaction.title, transactionType: transaction.transactionType, category: transaction.category, expenseType: transaction.expenseType, paymentMethod: transaction.paymentMethod, amount: transaction.amount)
    }
}
