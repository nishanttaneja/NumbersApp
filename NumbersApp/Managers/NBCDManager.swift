//
//  NBCDManager.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 29/12/23.
//

import CoreData

// MARK: - NBCDManager
final class NBCDManager {
    private init() { }
    static let shared = NBCDManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NBDB")
        container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
        return container
    }()
}


// MARK: - Transaction
extension NBCDManager {
    func saveTransaction(_ newTransaction: NBTransaction, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let transaction = NBCDTransaction(context: context)
            transaction.transactionID = newTransaction.id
            transaction.date = newTransaction.date
            transaction.title = newTransaction.title
            transaction.category = newTransaction.category.rawValue
            transaction.expenseType = newTransaction.expenseType.rawValue
            transaction.paymentMethod = newTransaction.paymentMethod.rawValue
            transaction.amount = newTransaction.amount
            do {
                if context.hasChanges {
                    try context.save()
                    completionHandler(.success(true))
                } else {
                    completionHandler(.success(false))
                }
            } catch let error {
                debugPrint(#function, error)
                completionHandler(.failure(error))
            }
        }
    }
    
    func loadAllTransactions(completionHandler: @escaping (_ result: Result<[NBTransaction], Error>) -> Void) {
        let request = NBCDTransaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDTransaction.date), ascending: false)]
        do {
            let savedTransactions = try persistentContainer.viewContext.fetch(request)
            let transactionsToDisplay: [NBTransaction] = savedTransactions.compactMap { savedTransaction in
                guard let transactionId = savedTransaction.transactionID,
                      let date = savedTransaction.date,
                      let title = savedTransaction.title,
                      let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                      let expenseTypeRawValue = savedTransaction.expenseType, let expenseType = NBTransaction.NBTransactionExpenseType(rawValue: expenseTypeRawValue),
                      let paymentMethodRawValue = savedTransaction.paymentMethod, let paymentMethod = NBTransaction.NBTransactionPaymentMethod(rawValue: paymentMethodRawValue) else { return nil }
                return NBTransaction(id: transactionId, date: date, title: title, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: savedTransaction.amount)
            }
            completionHandler(.success(transactionsToDisplay))
        } catch let error {
            debugPrint(#function, error)
            completionHandler(.failure(error))
        }
    }
}
