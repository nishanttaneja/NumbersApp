//
//  AppIntent.swift
//  PendingDuesWidget
//
//  Created by Nishant Taneja on 14/02/24.
//

import WidgetKit
import AppIntents

struct PendingDuesAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Pending Dues"
    static var description = IntentDescription("Displays pending dues for a card.")
    
    @Parameter(title: "Card")
    var card: CardEntity?
}

struct CardEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Card"
    static var defaultQuery = CardEntityQuery()
    
    let id: String
    let title: String
    let amount: Double
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    init(id: String, title: String, amount: Double) {
        self.id = id
        self.title = title
        self.amount = amount
    }
}

struct CardEntityQuery: EntityQuery {
    func suggestedEntities() async throws -> [CardEntity] {
        let paymentMethods = try await NBCDManager.shared.loadAllPaymentMethods()
        let cardEntities: [CardEntity] = paymentMethods.compactMap { paymentMethod in
            CardEntity(id: paymentMethod.id.uuidString, title: paymentMethod.title, amount: paymentMethod.transactions.reduce(Double.zero) { partialResult, transaction in
                var updatingAmount: Double = .zero
                if transaction.debitAccount != nil {
                    updatingAmount = partialResult - transaction.amount
                }
                if transaction.creditAccount != nil {
                    updatingAmount = partialResult + transaction.amount
                }
                return updatingAmount
            })
        }
        return cardEntities
    }
    func entities(for identifiers: [String]) async throws -> [CardEntity] {
        try await suggestedEntities().filter({ identifiers.contains($0.id) })
    }
    func defaultResult() async -> CardEntity? {
        try? await suggestedEntities().first
    }
}
