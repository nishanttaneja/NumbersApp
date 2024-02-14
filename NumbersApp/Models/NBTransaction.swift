//
//  NBTransaction2.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 14/02/24.
//

import Foundation

// MARK: - NBTransaction
struct NBTransaction {
    // MARK: Category
    enum NBTransactionCategory: String, CaseIterable {
        case billPayment = "bill payment"
        case culture
        case need
        case unplanned
        case want
    }
    
    // MARK: ExpenseType
    enum NBTransactionSubCategory: String, CaseIterable {
        case education
        case entertainment
        case foodAndDrinks = "food & drinks"
        case gifts
        case healthAndFitness = "health & fitness"
        case lifestyle
        case others
        case transportAndFuel = "transport & fuel"
        case utilities
    }
    
    // MARK: PaymentMethod
    struct NBTransactionPaymentMethod: Equatable {
        let id: UUID
        let title: String
        let transactions: [NBTransaction]
        
        init(id: UUID = UUID(), title: String, transactions: [NBTransaction] = []) {
            self.id = id
            self.title = title
            self.transactions = transactions
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: Field
    enum NBTransactionField: String, CaseIterable {
        case date, title, description, category
        case subCategory = "Sub Category"
        case debitAccount = "Debit Account"
        case creditAccount = "Credit Account"
        case amount
    }
    
    // MARK: Temp
    struct NBTempTransaction {
        var id: UUID?
        var date: Date?
        let defaultDate: Date = .now
        var title: String?
        var description: String?
        var category: NBTransactionCategory?
        var subCategory: NBTransactionSubCategory?
        var debitAccount: NBTransactionPaymentMethod?
        var creditAccount: NBTransactionPaymentMethod?
        var amount: Double?
    }
    
    let id: UUID
    let date: Date
    let title: String
    let description: String
    let category: NBTransactionCategory
    let subCategory: NBTransactionSubCategory
    let debitAccount: NBTransactionPaymentMethod?
    let creditAccount: NBTransactionPaymentMethod?
    let amount: Double
    
    // MARK: Constructor
    init(id: UUID = UUID(), date: Date = .now, title: String, description: String = "", category: NBTransactionCategory, subCategory: NBTransactionSubCategory, debitAccount: NBTransactionPaymentMethod?, creditAccount: NBTransactionPaymentMethod?, amount: Double) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.category = category
        self.subCategory = subCategory
        self.debitAccount = debitAccount
        self.creditAccount = creditAccount
        self.amount = amount
    }
}


// MARK: - Category
extension NBTransaction.NBTransactionCategory {
    var title: String {
        rawValue.capitalized
    }
    
    static func getCategory(for importText: String) -> NBTransaction.NBTransactionCategory {
        switch importText.lowercased() {
        case "needs", "health & fitness", "gifts", "mummy", "home", "love", "papa", "office", "utilities", "udit", "clothing", "self care", "education", "car", "bike":
            return .need
        case "credit bill payments":
            return .billPayment
        case "friends":
            return .culture
        case "personal", "entertainment", "wants", "food & drinks":
            return .want
        case "others", "":
            return .unplanned
        default:
            let category = NBTransaction.NBTransactionCategory(rawValue: importText.lowercased())
            if category == nil {
                debugPrint(#function, "Using 'Want' Category for '\(importText)'")
            }
            return category ?? .want
        }
    }
}


// MARK: - ExpenseType
extension NBTransaction.NBTransactionSubCategory {
    var title: String {
        rawValue.capitalized
    }
}


// MARK: - TempTransaction
extension NBTransaction.NBTempTransaction {
    func getTransaction() -> NBTransaction? {
        guard let title, let category, let subCategory, let amount else {
            debugPrint(#function, self)
            return nil
        }
        return NBTransaction(id: id ?? UUID(), date: date ?? .now, title: title, description: description ?? "", category: category, subCategory: subCategory, debitAccount: debitAccount, creditAccount: creditAccount, amount: amount)
    }
    
    init(transaction: NBTransaction) {
        self.init(id: transaction.id, date: transaction.date, title: transaction.title, description: transaction.description, category: transaction.category, subCategory: transaction.subCategory, debitAccount: transaction.debitAccount, creditAccount: transaction.creditAccount, amount: transaction.amount)
    }
}


// MARK: - Amount Description
extension NBTransaction {
    var amountDescription: String {
        (debitAccount == nil ? "+ " : "") + "₹" + abs(amount).formatted()
    }
}
