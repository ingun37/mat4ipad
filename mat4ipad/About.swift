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
    var devEmail: String {
        "ingun37@gmail.com"
    }
    var body: some View {
        VStack {
            VStack {
                Text("Thanks for using Expressive Algebra Calculator!")
                    .font(.title)
                Text("v" + version)
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            }.padding()
            HStack {
                Text("This application is open souce. Checkout in")
                Text("Github").foregroundColor(Color.blue)
                    .textContentType(.URL).onTapGesture {
                        guard let url = URL(string: self.githubUrl) else { return }
                        UIApplication.shared.open(url)
                }
            }
            
            HStack {
                Text("Developer email")
                Text(self.devEmail).onTapGesture {
                    guard let url = URL(string: "mailto:" + self.devEmail) else { return }
                    UIApplication.shared.open(url)
                }.foregroundColor(.blue)
            }
            
        }
        
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
