//
//  NBCreditCardBill.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import Foundation

struct NBCreditCardBill {
    // MARK: Field
    enum NBCreditCardBillField: String, CaseIterable {
        case startDate = "Start Date"
        case endDate = "End Date"
        case dueDate = "Due Date"
        case title, amount
    }
    
    // MARK: Temp
    struct NBTempCreditCardBill {
        var id: UUID?
        var startDate: Date?
        var endDate: Date?
        var dueDate: Date?
        var title: String?
        var amount: Double?
        var paymentStatus: NBCreditCardBillPaymentStatus = .due
    }
    
    // MARK: TransactionType
    enum NBCreditCardBillPaymentStatus: String, CaseIterable {
        case paid, due
    }
    
    let id: UUID
    let startDate: Date
    let endDate: Date
    let dueDate: Date
    let title: String
    let amount: Double
    let paymentStatus: NBCreditCardBillPaymentStatus
    
    init(id: UUID = UUID(), startDate: Date, endDate: Date, dueDate: Date, title: String, amount: Double, paymentStatus: NBCreditCardBillPaymentStatus = .due) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.dueDate = dueDate
        self.title = title
        self.amount = amount
        self.paymentStatus = paymentStatus
    }
}

// MARK: - Temp Bill
extension NBCreditCardBill.NBTempCreditCardBill {
    func getCreditCardBill() -> NBCreditCardBill? {
        guard let title, let startDate, let endDate, let dueDate, let amount else { return nil }
        return NBCreditCardBill(id: id ?? UUID(), startDate: startDate, endDate: endDate, dueDate: dueDate, title: title, amount: amount, paymentStatus: paymentStatus)
    }
    
    init(creditCardBill: NBCreditCardBill) {
        self.init(id: creditCardBill.id, startDate: creditCardBill.startDate, endDate: creditCardBill.endDate, dueDate: creditCardBill.dueDate, title: creditCardBill.title, amount: creditCardBill.amount, paymentStatus: creditCardBill.paymentStatus)
    }
}

// MARK: - PaymentStatus
extension NBCreditCardBill.NBCreditCardBillPaymentStatus {
    var title: String {
        rawValue.capitalized
    }
}
