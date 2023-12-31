//
//  NBPaymentMethodsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import UIKit

final class NBPaymentMethodsViewController: UITableViewController {
    // MARK: Properties
    private var paymentMethods: [NBTransaction.NBTransactionPaymentMethod] = []
    private let defaultCellReuseIdentifier = "defaultCell-NBPaymentMethodsViewController"
    
    private func loadPaymentMethods() {
        NBCDManager.shared.loadAllPaymentMethods { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPaymentMethods):
                    self?.paymentMethods = savedPaymentMethods
                    self?.tableView.reloadData()
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load payment methods", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPaymentMethods()
        configTableView()
        configObservers()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc private func handleTransactionOrPaymentMethodUpdate(notification: Notification) {
        loadPaymentMethods()
    }
    private func configObservers() {
        NBNCManager.shared.addObserver(self, selector: #selector(handleTransactionOrPaymentMethodUpdate(notification:)), forNotification: .NBCDManagerDidUpdateTransaction)
        NBNCManager.shared.addObserver(self, selector: #selector(handleTransactionOrPaymentMethodUpdate(notification:)), forNotification: .NBCDManagerDidCreateNewTransactionPaymentMethod)
    }
    
    // MARK: TableView
    private func configTableView() {
        tableView.register(NBTransactionDetailTableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        paymentMethods.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath)
        guard let detailCell = cell as? NBTransactionDetailTableViewCell, indexPath.row < paymentMethods.count else { return cell }
        let paymentMethod = paymentMethods[indexPath.row]
        detailCell.textLabel?.text = paymentMethod.title
        detailCell.detailTextLabel?.text = "₹" + String(paymentMethod.getTotalAmount())
        return detailCell
    }
}
