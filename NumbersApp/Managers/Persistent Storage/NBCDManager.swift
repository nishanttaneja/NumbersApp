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
    
    private(set) lazy var persistentContainer: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "NBDB")
        let storeURL = URL.storeURL(for: "group.numbersapp.localdatabase", databaseName: "NBDB")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.shouldMigrateStoreAutomatically = false
        storeDescription.shouldInferMappingModelAutomatically = true
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        
//        let container = NSPersistentContainer(name: "NBDB")
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
        return persistentContainer
    }()
}

public extension URL {

    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
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
                transaction.transactionDescription = newTransaction.description
                transaction.category = newTransaction.category.rawValue
                transaction.subCategory = newTransaction.subCategory.rawValue
                transaction.amount = newTransaction.amount
                // Fetching Payment Method
                let request = NBCDTransactionPaymentMethod.fetchRequest()
                var predicates: [NSPredicate] = []
                if let debitAccount = newTransaction.debitAccount {
                    predicates.append(NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), debitAccount.title))
                }
                if let creditAccount = newTransaction.creditAccount {
                    predicates.append(NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), creditAccount.title))
                }
                request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                let paymentMethods = try context.fetch(request)
                if let debitAccount = paymentMethods.first(where: { $0.title?.isEmpty == false && $0.title == newTransaction.debitAccount?.title }) {
                    // Adding to Payment Method
                    debitAccount.addToDebitTransactions(transaction)
                } else if let debitAcount = newTransaction.debitAccount {
                    // Creating new Payment Method
                    let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                    paymentMethod.paymentMethodID = debitAcount.id
                    paymentMethod.title = debitAcount.title
                    paymentMethod.addToDebitTransactions(transaction)
                    if debitAcount.title == newTransaction.creditAccount?.title {
                        paymentMethod.addToCreditTransactions(transaction)
                    }
                }
                if let creditAccount = paymentMethods.first(where: { $0.title?.isEmpty == false && $0.title == newTransaction.creditAccount?.title }), creditAccount.title != newTransaction.debitAccount?.title {
                    // Adding to Payment Method
                    creditAccount.addToCreditTransactions(transaction)
                } else if let creditAccount = newTransaction.creditAccount, creditAccount.title != newTransaction.debitAccount?.title {
                    // Creating new Payment Method
                    let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                    paymentMethod.paymentMethodID = creditAccount.id
                    paymentMethod.title = creditAccount.title
                    paymentMethod.addToCreditTransactions(transaction)
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
                    transaction.transactionDescription = newTransaction.description
                    transaction.category = newTransaction.category.rawValue
                    transaction.subCategory = newTransaction.subCategory.rawValue
                    transaction.amount = newTransaction.amount
                    // Fetching Payment Method
                    let request = NBCDTransactionPaymentMethod.fetchRequest()
                    var predicates: [NSPredicate] = []
                    if let debitAccount = newTransaction.debitAccount {
                        predicates.append(NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), debitAccount.title))
                    }
                    if let creditAccount = newTransaction.creditAccount {
                        predicates.append(NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), creditAccount.title))
                    }
                    request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                    let paymentMethods = try context.fetch(request)
                    if let debitAccount = paymentMethods.first(where: { $0.title?.isEmpty == false && $0.title == newTransaction.debitAccount?.title }) {
                        // Adding to Payment Method
                        debitAccount.addToDebitTransactions(transaction)
                    } else if let debitAcount = newTransaction.debitAccount {
                        // Creating new Payment Method
                        let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                        paymentMethod.paymentMethodID = debitAcount.id
                        paymentMethod.title = debitAcount.title
                        paymentMethod.addToDebitTransactions(transaction)
                        if debitAcount.title == newTransaction.creditAccount?.title {
                            paymentMethod.addToCreditTransactions(transaction)
                        }
                    }
                    if let creditAccount = paymentMethods.first(where: { $0.title?.isEmpty == false && $0.title == newTransaction.creditAccount?.title }), creditAccount.title != newTransaction.debitAccount?.title {
                        // Adding to Payment Method
                        creditAccount.addToCreditTransactions(transaction)
                    } else if let creditAccount = newTransaction.creditAccount, creditAccount.title != newTransaction.debitAccount?.title {
                        // Creating new Payment Method
                        let paymentMethod = NBCDTransactionPaymentMethod(context: context)
                        paymentMethod.paymentMethodID = creditAccount.id
                        paymentMethod.title = creditAccount.title
                        paymentMethod.addToCreditTransactions(transaction)
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
                      let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                      let subCategoryRawValue = savedTransaction.subCategory, let subCategory = NBTransaction.NBTransactionSubCategory(rawValue: subCategoryRawValue) else { return nil }
                let debitAccount: NBTransaction.NBTransactionPaymentMethod?
                if let debitAccountId = savedTransaction.debitAccount?.paymentMethodID, let debitAccountTitle = savedTransaction.debitAccount?.title {
                    debitAccount = NBTransaction.NBTransactionPaymentMethod(id: debitAccountId, title: debitAccountTitle)
                } else {
                    debitAccount = nil
                }
                let creditAccount: NBTransaction.NBTransactionPaymentMethod?
                if let creditAccountId = savedTransaction.creditAccount?.paymentMethodID, let creditAccountTitle = savedTransaction.creditAccount?.title {
                    creditAccount = NBTransaction.NBTransactionPaymentMethod(id: creditAccountId, title: creditAccountTitle)
                } else {
                    creditAccount = nil
                }
                return NBTransaction(id: transactionId, date: date, title: title, description: savedTransaction.transactionDescription ?? "", category: category, subCategory: subCategory, debitAccount: debitAccount, creditAccount: creditAccount, amount: savedTransaction.amount)
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
                  let subCategoryRawValue = savedTransaction.subCategory, let subCategory = NBTransaction.NBTransactionSubCategory(rawValue: subCategoryRawValue) else { throw NBCDError.noDataFound }
            let debitAccount: NBTransaction.NBTransactionPaymentMethod?
            if let debitAccountId = savedTransaction.debitAccount?.paymentMethodID, let debitAccountTitle = savedTransaction.debitAccount?.title {
                debitAccount = NBTransaction.NBTransactionPaymentMethod(id: debitAccountId, title: debitAccountTitle)
            } else {
                debitAccount = nil
            }
            let creditAccount: NBTransaction.NBTransactionPaymentMethod?
            if let creditAccountId = savedTransaction.creditAccount?.paymentMethodID, let creditAccountTitle = savedTransaction.creditAccount?.title {
                creditAccount = NBTransaction.NBTransactionPaymentMethod(id: creditAccountId, title: creditAccountTitle)
            } else {
                creditAccount = nil
            }
            let transactionToDisplay = NBTransaction(id: transactionId, date: date, title: title, description: savedTransaction.transactionDescription ?? "", category: category, subCategory: subCategory, debitAccount: debitAccount, creditAccount: creditAccount, amount: savedTransaction.amount)
            completionHandler(.success(transactionToDisplay))
        } catch let error {
            debugPrint(#function, error)
            completionHandler(.failure(error))
        }
    }
    func loadAllTransactions(havingPaymentMethod paymentMethodTitle: String, startDate: Date, completionHandler: @escaping (_ result: Result<[NBTransaction], Error>) -> Void) {
        let request = NBCDTransaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDTransaction.date), ascending: false)]
        let debitAccountTitlePredicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransaction.debitAccount.title), paymentMethodTitle)
        let creditAccountTitlePredicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransaction.creditAccount.title), paymentMethodTitle)
        let accountTitlePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [debitAccountTitlePredicate, creditAccountTitlePredicate])
        let startDatePredicate = NSPredicate(format: "%K > %@", #keyPath(NBCDTransaction.date), startDate as CVarArg)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [accountTitlePredicate, startDatePredicate])
        do {
            let savedTransactions = try persistentContainer.viewContext.fetch(request)
            let transactionsToDisplay: [NBTransaction] = savedTransactions.compactMap { savedTransaction in
                guard let transactionId = savedTransaction.transactionID,
                      let date = savedTransaction.date,
                      let title = savedTransaction.title,
                      let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                      let subCategoryRawValue = savedTransaction.subCategory, let subCategory = NBTransaction.NBTransactionSubCategory(rawValue: subCategoryRawValue) else { return nil }
                let debitAccount: NBTransaction.NBTransactionPaymentMethod?
                if let debitAccountId = savedTransaction.debitAccount?.paymentMethodID, let debitAccountTitle = savedTransaction.debitAccount?.title {
                    debitAccount = NBTransaction.NBTransactionPaymentMethod(id: debitAccountId, title: debitAccountTitle)
                } else {
                    debitAccount = nil
                }
                let creditAccount: NBTransaction.NBTransactionPaymentMethod?
                if let creditAccountId = savedTransaction.creditAccount?.paymentMethodID, let creditAccountTitle = savedTransaction.creditAccount?.title {
                    creditAccount = NBTransaction.NBTransactionPaymentMethod(id: creditAccountId, title: creditAccountTitle)
                } else {
                    creditAccount = nil
                }
                return NBTransaction(id: transactionId, date: date, title: title, description: savedTransaction.description, category: category, subCategory: subCategory, debitAccount: debitAccount, creditAccount: creditAccount, amount: savedTransaction.amount)
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
                debugPrint(line)
                let components = line.components(separatedBy: ",").reversed()
                guard let dateString = components.last, let date = Date.getDate(from: dateString, in: "dd/MM/yyyy") else { continue }
                var tempTransaction = NBTransaction.NBTempTransaction(date: date)
                var descriptionComponents: [String] = []
                for (index, component) in components.enumerated() {
                    guard index < components.count-1 else { break }
                    debugPrint(index, component)
                    switch index {
                    case .zero:
                        guard let amount = Double(component) else { break }
                        tempTransaction.amount = amount
                    case 1:
                        if component.replacingOccurrences(of: " ", with: "").isEmpty == false {
                            tempTransaction.creditAccount = .init(title: component)
                        }
                    case 2:
                        if component.replacingOccurrences(of: " ", with: "").isEmpty == false {
                            tempTransaction.debitAccount = .init(title: component)
                        }
                    case 3:
                        tempTransaction.subCategory = .init(rawValue: component.lowercased())
                    case 4:
                        tempTransaction.category = .getCategory(for: component)
                    case components.count-2:
                        tempTransaction.title = component
                    default:
                        descriptionComponents.insert(component, at: .zero)
                    }
                }
                let description = descriptionComponents.joined(separator: ",")
                tempTransaction.description = description.replacingOccurrences(of: " ", with: "").isEmpty == false ? description : nil
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
    @available(*, renamed: "loadAllPaymentMethods()")
    func loadAllPaymentMethods(completionHandler: @escaping (_ result: Result<[NBTransaction.NBTransactionPaymentMethod], Error>) -> Void) {
        persistentContainer.viewContext.perform {
            do {
                let request = NBCDTransactionPaymentMethod.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: #keyPath(NBCDTransactionPaymentMethod.title), ascending: true)]
                let savedPaymentMethods = try self.persistentContainer.viewContext.fetch(request)
                let paymentMethodsToDisplay: [NBTransaction.NBTransactionPaymentMethod] = savedPaymentMethods.compactMap { savedPaymentMethod in
                    guard let id = savedPaymentMethod.paymentMethodID,
                          let title = savedPaymentMethod.title,
                          let debitTransactions: [NBTransaction] = (savedPaymentMethod.debitTransactions?.allObjects as? [NBCDTransaction])?.compactMap({ savedTransaction in
                              guard let transactionId = savedTransaction.transactionID,
                                    let date = savedTransaction.date,
                                    let title = savedTransaction.title,
                                    let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                                    let subCategoryRawValue = savedTransaction.subCategory, let subCategory = NBTransaction.NBTransactionSubCategory(rawValue: subCategoryRawValue) else { return nil }
                              return NBTransaction(id: transactionId, date: date, title: title, description: savedTransaction.transactionDescription ?? "", category: category, subCategory: subCategory, debitAccount: NBTransaction.NBTransactionPaymentMethod(id: id, title: title, transactions: []), creditAccount: nil, amount: savedTransaction.amount)
                          }),
                          let creditTransactions: [NBTransaction] = (savedPaymentMethod.creditTransactions?.allObjects as? [NBCDTransaction])?.compactMap({ savedTransaction in
                              guard let transactionId = savedTransaction.transactionID,
                                    let date = savedTransaction.date,
                                    let title = savedTransaction.title,
                                    let categoryRawValue = savedTransaction.category, let category = NBTransaction.NBTransactionCategory(rawValue: categoryRawValue),
                                    let subCategoryRawValue = savedTransaction.subCategory, let subCategory = NBTransaction.NBTransactionSubCategory(rawValue: subCategoryRawValue) else { return nil }
                              return NBTransaction(id: transactionId, date: date, title: title, description: savedTransaction.transactionDescription ?? "", category: category, subCategory: subCategory, debitAccount: nil, creditAccount: NBTransaction.NBTransactionPaymentMethod(id: id, title: title, transactions: []), amount: savedTransaction.amount)
                          }) else { return nil }
                    return NBTransaction.NBTransactionPaymentMethod(id: id, title: title, transactions: debitTransactions+creditTransactions)
                }
                completionHandler(.success(paymentMethodsToDisplay))
            } catch let error {
                completionHandler(.failure(error))
            }
        }
    }
    
    func loadAllPaymentMethods() async throws -> [NBTransaction.NBTransactionPaymentMethod] {
        return try await withCheckedThrowingContinuation { continuation in
            loadAllPaymentMethods() { result in
                continuation.resume(with: result)
            }
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
                        guard let paidAmount = Double(component) else { break }
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
