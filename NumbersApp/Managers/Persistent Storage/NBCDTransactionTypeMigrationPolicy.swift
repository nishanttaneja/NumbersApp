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
        debugPrint(sInstance.entity.name, entityName, sInstance.primitiveValue(forKey: #keyPath(NBCDTransaction.transactionType)), sInstance.value(forKeyPath: #keyPath(NBCDTransaction.transactionType)))
        guard sInstance.entity.name == entityName,
              sInstance.value(forKeyPath: #keyPath(NBCDTransaction.transactionType)) == nil else { return }
        let newTransactionEntity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: manager.destinationContext)
        newTransactionEntity.setValue(NBTransaction.NBTransactionType.debit.rawValue, forKey: #keyPath(NBCDTransaction.transactionType))
    }
}
