//
//  ViewModel.swift
//  TransactionalKeyValueStore
//
//  Created by Дмитрий Спичаков on 15.03.2023.
//

import SwiftUI

enum Commands: String {
    case SET, GET, DELETE, COUNT, BEGIN, COMMIT, ROLLBACK
}

enum InputTitles: String {
    case inputCommand = "Input command"
    case SET = "Enter key and value separated by \" \""
    case GET_DELETE = "Enter key"
    case COUNT = "Enter value"
}

enum TransactionStatus: String {
    case None
    case InProgress
    case Committed
}

// MARK: VIEWMODEL
class ViewModel: ObservableObject {
    
    @Published var store: [String: String] = [:] // original store
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var command: Commands? = nil
    @Published var inputTitle: String = InputTitles.inputCommand.rawValue
    @Published var showAlert: Bool = false
    @Published var confirmMessage: String = ""
    @Published var confirmAction: Bool = false
    
    @Published var transactionStore: [String: String] = [:] // transaction store
    @Published var transactionStatus = TransactionStatus.None
    @Published var nestedTransactions: [ViewModel] = [] // nested transaction store

    func resetCommandLine() {
        input = ""
        command = nil
        inputTitle = InputTitles.inputCommand.rawValue
        showAlert = false
        confirmAction = false
    }
    
    func getKey() -> String {
        guard !input.isEmpty else { return "defaultKey" }
        return input.components(separatedBy: " ").dropLast()[0].description // Get key from key/value input String separated by " "
    }
    
    func getValue() -> String {
        guard !input.isEmpty else { return "defaultValue" }
        return input.components(separatedBy: " ").dropFirst()[1].description // Get value from key/value input String separated by " "
    }
    
    func setValueToStore() {
        if transactionStatus == .InProgress { // If begin was pressed store to transaction mode 1 level
            transactionStore[getKey()] = getValue()
        } else {
            store[getKey()] = getValue()
        }
    }
    
    func getValueFromStore() {
        if transactionStatus == .InProgress {
            output = transactionStore[input] ?? "Key not set"
        } else {
            output = store[input] ?? "Key not set"
        }
    }
    
    func deleteByKey() {
        if confirmAction { // To run code after confirmint action in alert
            if transactionStatus == .InProgress {
                transactionStore[input] = nil
            } else {
                store[input] = nil
            }
        }
    }
    
    func countByValue() {
        if transactionStatus == .InProgress {
            output = String(transactionStore.values.filter { $0 == input }.count)
        } else {
            output = String(store.values.filter { $0 == input }.count)
        }
    }
    
    func begin() { // Start a transaction
        if transactionStore.isEmpty { // Going to a transaction mode 1 level
            transactionStatus = .InProgress
            transactionStore = store
        } else { // If transactionStore !isEmpty start to create a nem object and store it in nestedTransactions store
            let nestedViewModel = ViewModel()
            nestedViewModel.transactionStatus = .InProgress
            nestedViewModel.transactionStore = transactionStore // Copy previous store to a new object transactionStore
            nestedTransactions.append(nestedViewModel) // Add new object to nested store
        }
    }

    func commit() { // Commit curent transaction
        if confirmAction { // To run code after confirming action in alert
            if nestedTransactions.count > 0 {
                let nestedViewModel = nestedTransactions.removeLast() // If we have nestedTransaction remove it from the nesdetTransaction store
                nestedViewModel.transactionStatus = .Committed
                store = nestedViewModel.store // Update current store
                transactionStore = [:] // Reset transaction store
            } else {
                transactionStatus = .None
                store = transactionStore // Update current store from 1 level
                transactionStore = [:] // Reset transaction store
            }
        }
    }

    func rollback() { // Rollback current transaction
        if confirmAction { // To run code after confirmint action in alert
            if nestedTransactions.count > 0 {
                let nestedViewModel = nestedTransactions.removeLast() // If we have nestedTransaction remove it from the nesdetTransaction store
                nestedViewModel.transactionStatus = .None
                transactionStore = nestedViewModel.transactionStore // Copy back to transactionStore
            } else {
                transactionStatus = .None
                transactionStore = [:] // Reset transaction store
            }
        }
    }
    
    func executeCommand() -> () { // Check pressed command and execute it
        switch command {
        case .SET:
            setValueToStore()
            resetCommandLine()
        case .GET:
            getValueFromStore()
            resetCommandLine()
        case .DELETE:
            confirmMessage = "DELETE item?"
            showAlert = true
            deleteByKey()
        case .COUNT:
            countByValue()
            resetCommandLine()
        case .BEGIN:
            begin()
            resetCommandLine()
        case .COMMIT:
            confirmMessage = "Do you want to COMMIT?"
            showAlert = true
            commit()
        case .ROLLBACK:
            confirmMessage = "Do you want to ROLLBACK?"
            showAlert = true
            rollback()
        case .none:
            confirmMessage = "Command not found"
            showAlert = true
        }
    }
    
    
}


