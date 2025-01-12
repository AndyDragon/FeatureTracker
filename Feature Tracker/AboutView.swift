//
//  AboutView.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2025-01-11.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismissWindow) var dismissWindow

    let packages =
        [
            "CloudKitSyncMonitor": [
                "Grant Grueninger (https://github.com/ggruen)"
            ],
            "SwiftDataKit": [
                "东坡肘子 (https://github.com/fatbobman)"
            ],
            "ToastView-SwiftUI": [
                "Gaurav Tak (https://github.com/gauravtakroro)",
                "modified by Andrew Forget (https://github.com/AndyDragon)"
            ]
        ]

    let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year ?? 2024

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .padding(.leading, 30)
                VStack(alignment: .center) {
                    Text(Bundle.main.displayName ?? "App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Version \(Bundle.main.releaseVersionNumberPretty)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("AndyDragon Software")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6 ))
                    Text("Copyright © 2024\((year > 2024) ? "-\(year)" : "")")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6 ))
                    Text("All rights reserved.")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6 ))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background().opacity(0.9)

            VStack {
                Text("This app uses the following packages / code:")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.5, green: 0.1, blue: 0.6 ))
                    .padding(.bottom, 10)
                Grid(alignment: .leadingFirstTextBaseline) {
                    ForEach(packages.sorted(by: { $0.key.lowercased() < $1.key.lowercased() }), id: \.key) { key, value in
                        GridRow {
                            Text(key)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .gridColumnAlignment(.trailing)
                            VStack(alignment: .leading) {
                                ForEach(value, id: \.self) { author in
                                    Text(author)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                }
                            }
                            .gridColumnAlignment(.leading)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .padding(.top, 10)

            HStack {
                Spacer()
                Button {
                    dismissWindow(id: "about")
                } label: {
                    Text("Close")
                        .foregroundStyle(.black)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                }
                .background(.gray)
                .cornerRadius(4)
                .padding([.bottom, .trailing], 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background(.white.opacity(0.9))
        .background()
        .frame(width: 600, height: 400)
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400, maxHeight: 400)
    }
}

#Preview {
    AboutView()
}
