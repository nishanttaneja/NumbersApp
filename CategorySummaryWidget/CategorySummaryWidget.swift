//
//  CategorySummaryWidget.swift
//  CategorySummaryWidget
//
//  Created by Nishant Taneja on 14/02/24.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        var entry = SimpleEntry(date: currentDate, configuration: configuration, title: "Today")
        do {
            let transactions = try await NBCDManager.shared.loadAllTransactions(afterDateTime: currentDate.startOfDay)
            entry.amountDescription = "₹" + String(format: "%.2f", transactions.reduce(Double.zero, { partialResult, transaction in
                var sum = partialResult
                if let debitAccount = transaction.debitAccount {
                    sum += transaction.amount
                }
                if let creditAccount = transaction.creditAccount {
                    sum -= transaction.amount
                }
                return sum
            }))
        } catch let error {
            debugPrint(#function, error.localizedDescription)
        }
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    var title: String?
    var amountDescription: String?
}

struct CategorySummaryWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.title ?? "")
            Text(entry.amountDescription ?? "")
        }
    }
}

struct CategorySummaryWidget: Widget {
    let kind: String = "CategorySummaryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            CategorySummaryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    CategorySummaryWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
