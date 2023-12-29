//
//  NBTransactionsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

final class NBTransactionsViewController: UITableViewController, NBAddTransactionViewControllerDelegate {
    // MARK: Properties
    private let defaultCellReuseIdentifier = "defaultCell-NBTransactionsViewController"
    private var transactions: [NBTransaction] = []
    private var addTransactionViewController: NBAddTransactionViewController?
    
    // MARK: TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath)
        guard indexPath.row < transactions.count else { return cell }
        let transaction = transactions[indexPath.row]
        cell.textLabel?.text = transaction.title + " - ₹" + String(transaction.amount)
        cell.detailTextLabel?.text = transaction.date.formatted(date: .abbreviated, time: .omitted)
        return cell
    }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        navigationItem.setRightBarButton(UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { _ in
            if self.addTransactionViewController == nil {
                self.addTransactionViewController = NBAddTransactionViewController()
                self.addTransactionViewController?.delegate = self
            } else {
                self.addTransactionViewController?.addNewTransaction()
            }
            guard let addTransactionViewController = self.addTransactionViewController else { return }
            self.present(addTransactionViewController, animated: true)
        })), animated: true)
    }
    
    // MARK: AddTransactionDelegate
    func addTransaction(viewController: NBAddTransactionViewController, didAddTransaction newTransaction: NBTransaction) {
        transactions.insert(newTransaction, at: .zero)
        tableView.insertRows(at: [IndexPath(row: .zero, section: .zero)], with: .automatic)
    }
}
