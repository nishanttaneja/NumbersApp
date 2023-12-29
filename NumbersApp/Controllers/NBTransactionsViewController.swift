//
//  NBTransactionsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

final class NBTransactionsViewController: UITableViewController {
    // MARK: Properties
    private let defaultCellReuseIdentifier = "defaultCell-NBTransactionsViewController"
    private var transactions: [NBTransaction] = []
    private var addTransactionViewController: NBAddTransactionViewController?
    
    private func updateTransactions(to newTransactions: [NBTransaction]) {
        DispatchQueue.main.async { [weak self] in
            self?.transactions = newTransactions
            self?.tableView.reloadSections(.init(integer: .zero), with: .automatic)
        }
    }
    private func loadTransactions() {
        NBCDManager.shared.loadAllTransactions { [weak self] result in
            switch result {
            case .success(let transactions):
                self?.updateTransactions(to: transactions)
            case .failure(let failure):
                let alertController = UIAlertController(title: "Unable to load transactions", message: failure.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                self?.present(alertController, animated: true)
            }
        }
    }
    
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            guard indexPath.row < transactions.count else { return }
            NBCDManager.shared.deleteTransaction(having: transactions[indexPath.row].id) { [weak self] result in
                switch result {
                case .success(let success):
                    guard success else { return }
                    self?.loadTransactions()
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to delete transaction", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        default: break
        }
    }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        navigationItem.setRightBarButton(UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { _ in
            if self.addTransactionViewController == nil {
                self.addTransactionViewController = NBAddTransactionViewController()
            } else {
                self.addTransactionViewController?.addNewTransaction()
            }
            guard let addTransactionViewController = self.addTransactionViewController else { return }
            self.present(addTransactionViewController, animated: true)
        })), animated: true)
        loadTransactions()
        addNotificationObservers()
    }
    
    // MARK: AddTransactionDelegate
    func addTransaction(viewController: NBAddTransactionViewController, didAddTransaction newTransaction: NBTransaction) {
        transactions.insert(newTransaction, at: .zero)
        tableView.insertRows(at: [IndexPath(row: .zero, section: .zero)], with: .automatic)
    }
    
    // MARK: NotificationCenterManager
    @objc private func handleSaveNewTransaction(notification: Notification) {
        loadTransactions()
    }
    private func addNotificationObservers() {
        NBNCManager.shared.addObserver(self, selector: #selector(handleSaveNewTransaction(notification:)), forNotification: .NBCDManagerDidSaveNewTransaction)
    }
    private func removeNotificationObservers() {
        NBNCManager.shared.removeObserver(self, forNotification: .NBCDManagerDidSaveNewTransaction)
    }
}
