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
    
    // MARK: Temp
    struct NBTempTransaction {
        var date: Date?
        var title: String?
        var category: NBTransactionCategory?
        var expenseType: NBTransactionExpenseType?
        var paymentMethod: NBTransactionPaymentMethod?
        var amount: Double?
    }
    
    let id: String
    let date: Date
    let title: String
    let category: NBTransactionCategory
    let expenseType: NBTransactionExpenseType
    let paymentMethod: NBTransactionPaymentMethod
    let amount: Double
    
    // MARK: Constructor
    init(id: String = UUID().uuidString, date: Date = .now, title: String, category: NBTransactionCategory, expenseType: NBTransactionExpenseType, paymentMethod: NBTransactionPaymentMethod, amount: Double) {
        self.id = id
        self.date = date
        self.title = title
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
    var title: String {
        switch self {
        case .date:
            return "\(Date.now.formatted(date: .abbreviated, time: .omitted)) (Default)"
        case .title:
            return "Paying for..."
        case .category, .expenseType:
            return rawValue.capitalized
        case .paymentMethod:
            return "Paid using..."
        case .amount:
            return rawValue.capitalized
        }
    }
}

// MARK: - TempTransaction
extension NBTransaction.NBTempTransaction {
    func getTransaction() -> NBTransaction? {
        guard let title, let category, let expenseType, let paymentMethod, let amount else { return nil }
        return NBTransaction(date: date ?? .now, title: title, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: amount)
    }
}
