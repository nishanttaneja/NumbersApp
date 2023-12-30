//
//  NBCDTransactionTypeMigrationPolicy.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 30/12/23.
//

import CoreData

final class NBCDTransactionTypeMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let entityName = "NBCDTransaction"
        guard sInstance.entity.name == entityName,
              let transactionId = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.transactionID)) as? UUID,
              let date = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.date)) as? Date,
              let title = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.title)) as? String,
              let category = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.category)) as? String,
              let expenseType = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.expenseType)) as? String,
              let paymentMethod = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.paymentMethod)) as? String,
              let amount = sInstance.value(forKeyPath: #keyPath(NBCDTransaction.amount)) as? Double else { return }
        let newTransactionEntity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: manager.destinationContext)
        newTransactionEntity.setValue(transactionId, forKeyPath: #keyPath(NBCDTransaction.transactionID))
        newTransactionEntity.setValue(date, forKeyPath: #keyPath(NBCDTransaction.date))
        newTransactionEntity.setValue(title, forKeyPath: #keyPath(NBCDTransaction.title))
        newTransactionEntity.setValue(NBTransaction.NBTransactionType.debit.rawValue, forKeyPath: #keyPath(NBCDTransaction.transactionType))
        newTransactionEntity.setValue(category, forKeyPath: #keyPath(NBCDTransaction.category))
        newTransactionEntity.setValue(expenseType, forKeyPath: #keyPath(NBCDTransaction.expenseType))
        newTransactionEntity.setValue(paymentMethod, forKeyPath: #keyPath(NBCDTransaction.paymentMethod))
        newTransactionEntity.setValue(amount, forKeyPath: #keyPath(NBCDTransaction.amount))
    }
}
