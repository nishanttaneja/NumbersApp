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
    
    enum NBCDError: Error {
        case noDataFound
    }
    
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
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
    func loadTransaction(having id: UUID, completionHandler: @escaping (_ result: Result<NBTransaction, Error>) -> Void) {
        let request = NBCDTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransaction.transactionID), id as CVarArg)
        do {
            let savedTransactions = try persistentContainer.viewContext.fetch(request)
            if savedTransactions.count > 1 {
                debugPrint(#function, "Multiple transactions found for id \(id)")
            }
            guard let savedTransaction = savedTransactions.first,
                  let transactionId = savedTransaction.transactionID,
                  let date = savedTransaction.date,
                  let title = savedTransaction.title,
                  let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                  let expenseTypeRawValue = savedTransaction.expenseType, let expenseType = NBTransaction.NBTransactionExpenseType(rawValue: expenseTypeRawValue),
                  let paymentMethodRawValue = savedTransaction.paymentMethod, let paymentMethod = NBTransaction.NBTransactionPaymentMethod(rawValue: paymentMethodRawValue) else { throw NBCDError.noDataFound }
            let transactionToDisplay = NBTransaction(id: transactionId, date: date, title: title, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: savedTransaction.amount)
            completionHandler(.success(transactionToDisplay))
        } catch let error {
            debugPrint(#function, error)
            completionHandler(.failure(error))
        }
    }
    func deleteTransaction(having id: UUID, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let request = NBCDTransaction.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransaction.transactionID), id as CVarArg)
            do {
                let transactionsToDelete = try context.fetch(request)
                if transactionsToDelete.count > 1 {
                    debugPrint(#function, "Multiple transactions found for id \(id)")
                }
                transactionsToDelete.forEach { transactionToDelete in
                    context.delete(transactionToDelete)
                }
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
}
