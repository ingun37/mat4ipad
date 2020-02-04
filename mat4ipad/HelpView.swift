//
//  HelpView.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/04.
//  Copyright © 2020 ingun37. All rights reserved.
//

import SwiftUI

struct HelpView: View {
    @State var currentPage = 0
    var body: some View {
        VStack {
            HelpPageVC(currentPage: $currentPage)
            HStack {
                Button(action: {
                    print("Left")
                }, label: { Text("Left")})
                Button(action: {
                    print("Right")
                }, label: { Text("Right")})
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
