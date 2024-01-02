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
        case noDataFound, noPermission
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
            do {
                // Creating Transaction
                let transaction = NBCDTransaction(context: context)
                transaction.transactionID = newTransaction.id
                transaction.date = newTransaction.date
                transaction.title = newTransaction.title
                transaction.transactionType = newTransaction.transactionType.rawValue
                transaction.category = newTransaction.category.rawValue
                transaction.expenseType = newTransaction.expenseType.rawValue
                transaction.amount = (newTransaction.transactionType == .debit ? 1 : -1) * newTransaction.amount
                // Fetching Payment Method
                let request = NBCDTransactionPaymentMethod.fetchRequest()
                request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), newTransaction.paymentMethod.title)
                if let paymentMethod = try context.fetch(request).first {
                    // Adding to Payment Method
                    paymentMethod.addToTransactions(transaction)
                } else {
                    // Creating new Payment Method
                    let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                    paymentMethod.paymentMethodID = newTransaction.paymentMethod.id
                    paymentMethod.title = newTransaction.paymentMethod.title
                    paymentMethod.addToTransactions(transaction)
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
    private func saveTransactions(_ newTransactions: [NBTransaction], completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            do {
                for newTransaction in newTransactions {
                    // Creating Transaction
                    let transaction = NBCDTransaction(context: context)
                    transaction.transactionID = newTransaction.id
                    transaction.date = newTransaction.date
                    transaction.title = newTransaction.title
                    transaction.transactionType = newTransaction.transactionType.rawValue
                    transaction.category = newTransaction.category.rawValue
                    transaction.expenseType = newTransaction.expenseType.rawValue
                    transaction.amount = (newTransaction.transactionType == .debit ? 1 : -1) * newTransaction.amount
                    // Fetching Payment Method
                    let request = NBCDTransactionPaymentMethod.fetchRequest()
                    request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), newTransaction.paymentMethod.title)
                    if let paymentMethod = try context.fetch(request).first {
                        // Adding to Payment Method
                        paymentMethod.addToTransactions(transaction)
                    } else {
                        // Creating new Payment Method
                        let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                        paymentMethod.paymentMethodID = newTransaction.paymentMethod.id
                        paymentMethod.title = newTransaction.paymentMethod.title
                        paymentMethod.addToTransactions(transaction)
                    }
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
    func loadAllTransactions(havingPaymentMethod paymentMethodTitle: String, startDate: Date, completionHandler: @escaping (_ result: Result<[NBTransaction], Error>) -> Void) {
        let request = NBCDTransaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDTransaction.date), ascending: false)]
        let paymentMethodTitlePredicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransaction.paymentMethod.title), paymentMethodTitle)
        let startDatePredicate = NSPredicate(format: "%K > %@", #keyPath(NBCDTransaction.date), startDate as CVarArg)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [paymentMethodTitlePredicate, startDatePredicate])
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

extension NBCDManager {
    func importTransactions(from filePath: URL, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        do {
            guard filePath.startAccessingSecurityScopedResource() else { throw NBCDError.noPermission }
            let data = try Data(contentsOf: filePath)
            filePath.stopAccessingSecurityScopedResource()
            let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\r\n") ?? []
            var transactionsToSave = [NBTransaction]()
            for line in lines {
                let components = line.components(separatedBy: ",").reversed()
                guard let dateString = components.last, let date = Date.getDate(from: dateString, in: "dd/MM/yyyy") else { continue }
                var tempTransaction = NBTransaction.NBTempTransaction(date: date)
                var titleComponents: [String] = []
                for (index, component) in components.enumerated() {
                    guard index < components.count-1 else { break }
                    switch index {
                    case .zero:
                        guard let amount = Double(component) else { break }
                        tempTransaction.amount = amount
                        if amount < .zero {
                            tempTransaction.transactionType = .credit
                        }
                    case 1:
                        tempTransaction.paymentMethod = .init(title: component)
                    case 2:
                        tempTransaction.expenseType = .init(rawValue: component.lowercased())
                    case 3:
                        tempTransaction.category = .init(rawValue: component.lowercased())
                    default:
                        titleComponents.insert(component, at: .zero)
                    }
                }
                let title = titleComponents.joined(separator: ",")
                tempTransaction.title = title.replacingOccurrences(of: " ", with: "").isEmpty == false ? title : nil
                guard let transaction = tempTransaction.getTransaction() else { continue }
                transactionsToSave.append(transaction)
            }
            saveTransactions(transactionsToSave, completionHandler: completionHandler)
        } catch let error {
            completionHandler(.failure(error))
        }
    }
}


// MARK: - PaymentMethod
extension NBCDManager {
    func loadAllPaymentMethods(completionHandler: @escaping (_ result: Result<[NBTransaction.NBTransactionPaymentMethod], Error>) -> Void) {
        do {
            let request = NBCDTransactionPaymentMethod.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDTransactionPaymentMethod.title), ascending: true)]
            let savedPaymentMethods = try persistentContainer.viewContext.fetch(request)
            let paymentMethodsToDisplay: [NBTransaction.NBTransactionPaymentMethod] = savedPaymentMethods.compactMap { savedPaymentMethod in
                guard let id = savedPaymentMethod.paymentMethodID,
                      let title = savedPaymentMethod.title,
                      let transactions: [NBTransaction] = (savedPaymentMethod.transactions?.allObjects as? [NBCDTransaction])?.compactMap({ savedTransaction in
                          guard let transactionId = savedTransaction.transactionID,
                                let date = savedTransaction.date,
                                let title = savedTransaction.title,
                                let transactionTypeRawValue = savedTransaction.transactionType, let transactionType = NBTransaction.NBTransactionType(rawValue: transactionTypeRawValue),
                                let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                                let expenseTypeRawValue = savedTransaction.expenseType, let expenseType = NBTransaction.NBTransactionExpenseType(rawValue: expenseTypeRawValue) else  { return nil }
                          return NBTransaction(id: transactionId, date: date, title: title, transactionType: transactionType, category: category, expenseType: expenseType, paymentMethod: .init(id: id, title: title, transactions: []), amount: savedTransaction.amount)
                      }) else { return nil }
                return NBTransaction.NBTransactionPaymentMethod(id: id, title: title, transactions: transactions)
            }
            completionHandler(.success(paymentMethodsToDisplay))
        } catch let error {
            completionHandler(.failure(error))
        }
    }
}


// MARK: - CreditCardBill
extension NBCDManager {
    func saveCreditCardBill(_ newCreditCardBill: NBCreditCardBill, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            do {
                // Creating Credit Card Bill
                let creditCardBill = NBCDCreditCardBill(context: context)
                creditCardBill.creditCardBillID = newCreditCardBill.id
                creditCardBill.startDate = newCreditCardBill.startDate
                creditCardBill.endDate = newCreditCardBill.endDate
                creditCardBill.dueDate = newCreditCardBill.dueDate
                creditCardBill.title = newCreditCardBill.title
                creditCardBill.paymentStatus = newCreditCardBill.paymentStatus.rawValue
                creditCardBill.amount = newCreditCardBill.amount
                // Fetching Payment Method
                let request = NBCDTransactionPaymentMethod.fetchRequest()
                request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), newCreditCardBill.title)
                let paymentMethods = try context.fetch(request)
                if paymentMethods.isEmpty {
                    // Creating new Payment Method
                    let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                    paymentMethod.paymentMethodID = UUID()
                    paymentMethod.title = newCreditCardBill.title
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
    private func saveCreditCardBills(_ newCreditCardBills: [NBCreditCardBill], completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            do {
                for newCreditCardBill in newCreditCardBills {
                    // Creating Transaction
                    let creditCardBill = NBCDCreditCardBill(context: context)
                    creditCardBill.creditCardBillID = newCreditCardBill.id
                    creditCardBill.startDate = newCreditCardBill.startDate
                    creditCardBill.endDate = newCreditCardBill.endDate
                    creditCardBill.dueDate = newCreditCardBill.dueDate
                    creditCardBill.title = newCreditCardBill.title
                    creditCardBill.paymentStatus = newCreditCardBill.paymentStatus.rawValue
                    creditCardBill.amount = newCreditCardBill.amount
                    // Fetching Payment Method
                    let request = NBCDTransactionPaymentMethod.fetchRequest()
                    request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), newCreditCardBill.title)
                    let paymentMethods = try context.fetch(request)
                    if paymentMethods.isEmpty {
                        // Creating new Payment Method
                        let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                        paymentMethod.paymentMethodID = UUID()
                        paymentMethod.title = newCreditCardBill.title
                    }
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
    func loadAllCreditCardBills(completionHandler: @escaping (_ result: Result<[NBCreditCardBill], Error>) -> Void) {
        let request = NBCDCreditCardBill.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDCreditCardBill.dueDate), ascending: false)]
        do {
            let savedCreditCardBills = try persistentContainer.viewContext.fetch(request)
            let creditCardBillsToDisplay: [NBCreditCardBill] = savedCreditCardBills.compactMap { savedCreditCardBill in
                guard let creditCardBillId = savedCreditCardBill.creditCardBillID,
                      let startDate = savedCreditCardBill.startDate,
                      let endDate = savedCreditCardBill.endDate,
                      let dueDate = savedCreditCardBill.dueDate,
                      let title = savedCreditCardBill.title,
                      let paymentStatusRawValue = savedCreditCardBill.paymentStatus, let paymentStatus = NBCreditCardBill.NBCreditCardBillPaymentStatus(rawValue: paymentStatusRawValue) else { return nil }
                return NBCreditCardBill(id: creditCardBillId, startDate: startDate, endDate: endDate, dueDate: dueDate, title: title, amount: savedCreditCardBill.amount, paymentStatus: paymentStatus)
            }
            completionHandler(.success(creditCardBillsToDisplay))
        } catch let error {
            debugPrint(#function, error)
            completionHandler(.failure(error))
        }
    }
    func loadCreditCardBill(having id: UUID, completionHandler: @escaping (_ result: Result<NBCreditCardBill, Error>) -> Void) {
        let request = NBCDCreditCardBill.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDCreditCardBill.creditCardBillID), id as CVarArg)
        do {
            let savedCreditCardBills = try persistentContainer.viewContext.fetch(request)
            if savedCreditCardBills.count > 1 {
                debugPrint(#function, "Multiple Credit Card Bills found for id \(id)")
            }
            guard let savedCreditCardBill = savedCreditCardBills.first,
                  let creditCardBillId = savedCreditCardBill.creditCardBillID,
                  let startDate = savedCreditCardBill.startDate,
                  let endDate = savedCreditCardBill.endDate,
                  let dueDate = savedCreditCardBill.dueDate,
                  let title = savedCreditCardBill.title,
                  let paymentStatusRawValue = savedCreditCardBill.paymentStatus, let paymentStatus = NBCreditCardBill.NBCreditCardBillPaymentStatus(rawValue: paymentStatusRawValue) else { throw NBCDError.noDataFound }
            let creditCardBillToDisplay = NBCreditCardBill(id: creditCardBillId, startDate: startDate, endDate: endDate, dueDate: dueDate, title: title, amount: savedCreditCardBill.amount, paymentStatus: paymentStatus)
            completionHandler(.success(creditCardBillToDisplay))
        } catch let error {
            debugPrint(#function, error)
            completionHandler(.failure(error))
        }
    }
    func deleteCreditCardBill(having id: UUID, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let request = NBCDCreditCardBill.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDCreditCardBill.creditCardBillID), id as CVarArg)
            do {
                let creditCardBillsToDelete = try context.fetch(request)
                if creditCardBillsToDelete.count > 1 {
                    debugPrint(#function, "Multiple credit card bills found for id \(id)")
                }
                creditCardBillsToDelete.forEach { creditCardBillToDelete in
                    context.delete(creditCardBillToDelete)
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

extension NBCDManager {
    func importCreditCardBills(from filePath: URL, completionHandler: @escaping (_ result: Result<Bool, Error>) -> Void) {
        do {
            guard filePath.startAccessingSecurityScopedResource() else { throw NBCDError.noPermission }
            let data = try Data(contentsOf: filePath)
            filePath.stopAccessingSecurityScopedResource()
            let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\r\n") ?? []
            var creditCardBillsToSave = [NBCreditCardBill]()
            for line in lines {
                let components = line.components(separatedBy: ",")
                var tempCreditCardBill = NBCreditCardBill.NBTempCreditCardBill()
                for (index, component) in components.enumerated() {
                    switch index {
                    case .zero:
                        guard let startDate = Date.getDate(from: component, in: "dd/MM/yyyy") else { break }
                        tempCreditCardBill.startDate = startDate
                    case 1:
                        guard let endDate = Date.getDate(from: component, in: "dd/MM/yyyy") else { break }
                        tempCreditCardBill.endDate = endDate
                    case 2:
                        guard let dueDate = Date.getDate(from: component, in: "dd/MM/yyyy") else { break }
                        tempCreditCardBill.dueDate = dueDate
                    case 3:
                        tempCreditCardBill.title = component
                    case 4:
                        guard let amount = Double(component) else { break }
                        tempCreditCardBill.amount = amount
                    case 5:
                        guard let paidAmount = Double(component) else { continue }
                        tempCreditCardBill.paymentStatus = paidAmount == tempCreditCardBill.amount ? .paid : .due
                    default: break
                    }
                }
                guard let creditCardBill = tempCreditCardBill.getCreditCardBill() else { continue }
                creditCardBillsToSave.append(creditCardBill)
            }
            saveCreditCardBills(creditCardBillsToSave, completionHandler: completionHandler)
        } catch let error {
            completionHandler(.failure(error))
        }
    }
}
