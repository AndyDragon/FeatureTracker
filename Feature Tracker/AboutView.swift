//
//  AboutView.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2025-01-11.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismissWindow) var dismissWindow

    @State private var showCredits = false

    let packages: [String:[String]]

    private let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year ?? 2024

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.vertical, showCredits ? 10 : 64)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.08))
            .background()

            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    Text(showCredits ? "This app uses the following packages / code:" : "")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.5, green: 0.1, blue: 0.6 ))
                        .animation(.easeIn(duration: showCredits ? 1.6 : 0).delay(showCredits ? 0.1 : 0), value: showCredits)
                    Spacer()
                    Button {
                        withAnimation {
                            showCredits.toggle()
                        }
                    } label: {
                        Triangle()
                            .fill(showCredits ? .black : .white)
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(showCredits ? -180.0 : -90.0), anchor: .center)
                    }
                    .buttonStyle(.borderless)
                    .help(showCredits ? "Hide the credits" : "Show the credits")
                }
                .padding(.horizontal)
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
                                    Text(.init(author))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                }
                            }
                            .gridColumnAlignment(.leading)
                        }
                    }
                }
                .opacity(showCredits ? 1 : 0)
                .animation(.easeIn(duration: showCredits ? 1 : 0).delay(showCredits ? 0.4 : 0), value: showCredits)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: showCredits ? 200 : 20)
            .background(.white.opacity(showCredits ? 0.9 : 0.08))
            .background()

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
            .padding(.top)
        }
        .background(.white.opacity(0.9))
        .background()
        .frame(width: 600, height: 400)
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400, maxHeight: 400)
    }
}

#Preview {
    AboutView(packages: ["Application": ["AndyDragon ([Github profile](https://github.com/AndyDragon))"]])
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}
