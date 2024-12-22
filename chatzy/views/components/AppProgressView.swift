//
//  AppProgressView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 22/12/24.
//

import SwiftUI

struct AppProgressView: View {
    var body: some View {
        ProgressView()
            .frame(width: 32, height: 32, alignment: .center)
            .padding(8)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2, x: 1, y: 1)
    }
}

#Preview {
    AppProgressView()
}
