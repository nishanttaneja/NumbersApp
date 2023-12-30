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
            } else {
                let description = NSPersistentStoreDescription()
                description.shouldMigrateStoreAutomatically = false
                description.shouldInferMappingModelAutomatically = true
                container.persistentStoreDescriptions = [description]
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
            transaction.transactionType = newTransaction.transactionType.rawValue
            transaction.category = newTransaction.category.rawValue
            transaction.expenseType = newTransaction.expenseType.rawValue
            transaction.amount = newTransaction.amount
            // Add to Payment Method
            let paymentMethod = NBCDTransactionPaymentMethod(context: context)
            paymentMethod.paymentMethodID = newTransaction.paymentMethod.id
            paymentMethod.title = newTransaction.paymentMethod.title
            paymentMethod.addToTransactions(transaction)
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
                      let transactionTypeRawValue = savedTransaction.transactionType, let transactionType = NBTransaction.NBTransactionType(rawValue: transactionTypeRawValue),
                      let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                      let expenseTypeRawValue = savedTransaction.expenseType, let expenseType = NBTransaction.NBTransactionExpenseType(rawValue: expenseTypeRawValue),
                      let paymentMethodId = savedTransaction.paymentMethod?.paymentMethodID, let paymentMethodTitle = savedTransaction.paymentMethod?.title else { return nil }
                let paymentMethod = NBTransaction.NBTransactionPaymentMethod(id: paymentMethodId, title: paymentMethodTitle)
                return NBTransaction(id: transactionId, date: date, title: title, transactionType: transactionType, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: savedTransaction.amount)
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
                  let transactionTypeRawValue = savedTransaction.transactionType, let transactionType = NBTransaction.NBTransactionType(rawValue: transactionTypeRawValue),
                  let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                  let expenseTypeRawValue = savedTransaction.expenseType, let expenseType = NBTransaction.NBTransactionExpenseType(rawValue: expenseTypeRawValue),
                  let paymentMethodId = savedTransaction.paymentMethod?.paymentMethodID, let paymentMethodTitle = savedTransaction.paymentMethod?.title else  { throw NBCDError.noDataFound }
            let paymentMethod = NBTransaction.NBTransactionPaymentMethod(id: paymentMethodId, title: paymentMethodTitle)
            let transactionToDisplay = NBTransaction(id: transactionId, date: date, title: title, transactionType: transactionType, category: category, expenseType: expenseType, paymentMethod: paymentMethod, amount: savedTransaction.amount)
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
