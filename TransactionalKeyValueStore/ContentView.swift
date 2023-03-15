//
//  ContentView.swift
//  TransactionalKeyValueStore
//
//  Created by Дмитрий Спичаков on 12.03.2023.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
   
    // MARK: BODY
    var body: some View {
        VStack {
            Text("Output: \(vm.output)")
            Text("Transaction status: \(vm.transactionStatus.rawValue)")
            originalStoreList
            inputSection
            executeButton            
            buttonsSection
        }
        .alert(isPresented: $vm.showAlert) {
            Alert(title: Text(vm.confirmMessage),
                  primaryButton: .default(Text("Ok")) {
                vm.confirmAction = true
                vm.executeCommand()
                vm.resetCommandLine()
            }, secondaryButton: .cancel())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: EXTENSION
extension ContentView {
    
    private var inputSection: some View {
        HStack {
            Text(">")
            
            if let command = vm.command?.rawValue {
                Text(command)
            }
            
            if !(vm.command == Commands.BEGIN || vm.command == Commands.COMMIT || vm.command == Commands.ROLLBACK) {
                TextField(vm.inputTitle, text: $vm.input)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var originalStoreList: some View {
        List {
            ForEach(vm.store.sorted(by: <), id: \.key) { key, value in
                Text("\(key): \(value)")
            }
        }
        .frame(height: 400)
    }
    
    private var executeButton: some View {
        ButtonReuse(title: "execute") {
            vm.executeCommand()
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .center) {
            Text("Set a command:")
                .padding()
            HStack {
                ButtonReuse(title: Commands.SET.rawValue) {
                    vm.inputTitle = InputTitles.SET.rawValue
                    vm.command = .SET
                }
                ButtonReuse(title: Commands.GET.rawValue) {
                    vm.inputTitle = InputTitles.GET_DELETE.rawValue
                    vm.command = .GET
                }
                ButtonReuse(title: Commands.DELETE.rawValue) {
                    vm.inputTitle = InputTitles.GET_DELETE.rawValue
                    vm.command = .DELETE
                }
                ButtonReuse(title: Commands.COUNT.rawValue) {
                    vm.inputTitle = InputTitles.COUNT.rawValue
                    vm.command = .COUNT
                }
            }
            HStack {
                ButtonReuse(title: Commands.BEGIN.rawValue) {
                    vm.command = .BEGIN
                }
                ButtonReuse(title: Commands.COMMIT.rawValue) {
                    vm.command = .COMMIT
                }
                ButtonReuse(title: Commands.ROLLBACK.rawValue) {
                    vm.command = .ROLLBACK
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width)
    }
    
}

/*
 ## **Examples**

 ### Set and get a value:

 ```markdown
 > SET foo 123
 > GET foo
 123
 ```

 ### Delete a value

 ```markdown
 > DELETE foo
 > GET foo
 key not set
 ```

 ### Count the number of occurrences of a value

 ```markdown
 > SET foo 123
 > SET bar 456
 > SET baz 123
 > COUNT 123
 2
 > COUNT 456
 1
 ```

 ### Commit a transaction

 ```markdown
 > SET bar 123
 > GET bar
 123
 > BEGIN
 > SET foo 456
 > GET bar
 123
 > DELETE bar
 > COMMIT
 > GET bar
 key not set
 > ROLLBACK
 no transaction
 > GET foo
 456
 ```

 ### Rollback a transaction

 ```markdown
 > SET foo 123
 > SET bar abc
 > BEGIN
 > SET foo 456
 > GET foo
 456
 > SET bar def
 > GET bar
 def
 > ROLLBACK
 > GET foo
 123
 > GET bar
 abc
 > COMMIT
 no transaction
 ```

 ### Nested transactions

 ```markdown
 > SET foo 123
 > SET bar 456
 > BEGIN
 > SET foo 456
 > BEGIN
 > COUNT 456
 2
 > GET foo
 456
 > SET foo 789
 > GET foo
 789
 > ROLLBACK
 > GET foo
 456
 > DELETE foo
 > GET foo
 key not set
 > ROLLBACK
 > GET foo
 123
 ```
 */
