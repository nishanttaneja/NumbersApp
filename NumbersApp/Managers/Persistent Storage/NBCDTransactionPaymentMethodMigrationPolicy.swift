//
//  NBCDTransactionPaymentMethodMigrationPolicy.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 30/12/23.
//

import CoreData

final class NBCDTransactionPaymentMethodMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let entityName = "NBCDTransaction"
        guard sInstance.entity.name == entityName,
              let transactionId = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.transactionID)) as? UUID,
              let date = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.date)) as? Date,
              let title = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.title)) as? String,
              let category = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.category)) as? String,
              let expenseType = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.expenseType)) as? String,
              let paymentMethodTitle = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.paymentMethod)) as? String,
              let amount = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.amount)) as? Double else { return }
        let newTransactionEntity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: manager.destinationContext)
        newTransactionEntity.setValue(transactionId, forKeyPath: #keyPath(NBCDTransaction.transactionID))
        newTransactionEntity.setValue(date, forKeyPath: #keyPath(NBCDTransaction.date))
        newTransactionEntity.setValue(title, forKeyPath: #keyPath(NBCDTransaction.title))
        newTransactionEntity.setValue(NBTransaction.NBTransactionType.debit.rawValue, forKeyPath: #keyPath(NBCDTransaction.transactionType))
        newTransactionEntity.setValue(category, forKeyPath: #keyPath(NBCDTransaction.category))
        newTransactionEntity.setValue(expenseType, forKeyPath: #keyPath(NBCDTransaction.expenseType))
        newTransactionEntity.setValue(amount, forKeyPath: #keyPath(NBCDTransaction.amount))
        let request = NSFetchRequest<NSManagedObject>(entityName: "NBCDTransactionPaymentMethod")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NBCDTransactionPaymentMethod.title), paymentMethodTitle)
        if let destinationPaymentMethod = try manager.destinationContext.fetch(request).first {
            newTransactionEntity.setValue(destinationPaymentMethod, forKeyPath: #keyPath(NBCDTransaction.paymentMethod))
        } else {
            let newPaymentMethodEntity = NSEntityDescription.insertNewObject(forEntityName: "NBCDTransactionPaymentMethod", into: manager.destinationContext)
            newPaymentMethodEntity.setValue(UUID(), forKeyPath: #keyPath(NBCDTransactionPaymentMethod.paymentMethodID))
            newPaymentMethodEntity.setValue(paymentMethodTitle, forKeyPath: #keyPath(NBCDTransactionPaymentMethod.title))
            newTransactionEntity.setValue(newPaymentMethodEntity, forKeyPath: #keyPath(NBCDTransaction.paymentMethod))
        }
    }
}
