//
//  About.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/03.
//  Copyright © 2020 ingun37. All rights reserved.
//

import SwiftUI

struct About: View {
    var version: String {
      Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    var githubUrl: String {
        "https://github.com/ingun37/mat4ipad"
    }
    var body: some View {
        VStack {
            Text("Thanks for using Expressive Calculator!")
                .font(.title)
            Text("This application is open souce. You can checkout full source code here")
            Text(self.githubUrl).foregroundColor(Color.blue)
                .textContentType(.URL).onTapGesture {
                    guard let url = URL(string: self.githubUrl) else { return }
                    UIApplication.shared.open(url)
            }
            Text("v" + version)
                .font(.footnote)
                .foregroundColor(Color.gray)
            
        }
        
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
