//
//  ButtonView .swift
//  TransactionalKeyValueStore
//
//  Created by Дмитрий Спичаков on 15.03.2023.
//

import SwiftUI

struct ButtonReuse: View {
    
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title.uppercased())
        }
        .buttonStyle(.borderedProminent)
    }
}
