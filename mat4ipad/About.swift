//
//  About.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/03.
//  Copyright © 2020 ingun37. All rights reserved.
//

import SwiftUI

struct About: View {
    @ObservedObject var userDefaultsManager = UserDefaultsManager()

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
                Text("Expressive Algebra Calculator")
                    .font(.headline)
                Text("v" + version)
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            }.padding()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Show Tooltip")
                    Toggle("", isOn: $userDefaultsManager.showTooltip).labelsHidden()
                }
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
        }.padding()
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
public let showTooltipKey = "showTooltip"
public let useHandwritingKey = "useHandwriting"
public class UserDefaultsManager: ObservableObject {
    @Published public var showTooltip: Bool = UserDefaults.standard.object(forKey: showTooltipKey) as? Bool ?? true {
        didSet { UserDefaults.standard.set(self.showTooltip, forKey: showTooltipKey) }
    }
}
