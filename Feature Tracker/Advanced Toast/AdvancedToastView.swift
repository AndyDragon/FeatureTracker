//
//  AdvancedToastView.swift
//  Advanced Toast
//
//  Created by Gaurav Tak on 26/12/23.
//  Modified by Andrew Forget on 2025-01-10.
//

import SwiftUI

struct AdvancedToastView: View {
    var type: AdvancedToastStyle
    var title: String
    var message: String
    var width: CGFloat = 400
    var buttonTitle: String = "Dismiss"
    var onButtonTapped: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                if type == .progress {
                    ProgressView()
                        .frame(width: 40, height: 40)
                        .padding(2)
                        .background(type.themeColor)
                        .cornerRadius(22)
                } else {
                    ZStack {
                        Image(systemName: type.iconFileName)
                            .foregroundColor(Color.black)
                        Image(systemName: type.iconFileName)
                            .foregroundColor(type.themeColor.opacity(0.8))
                    }
                    .font(.system(size: 40, weight: .bold))
                }

                VStack(alignment: .leading) {
                    ZStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Color.black)
                        Text(title)
                            .font(.headline)
                            .foregroundColor(type.themeColor.opacity(0.8))
                    }

                    Text(message)
                        .font(.callout)
                        .foregroundColor(Color.black)
                }
                
                Spacer(minLength: 10)
                Divider()
                    .frame(height: 46, alignment: Alignment.center)
                    .padding(.vertical, -8)
                    .foregroundColor(Color.gray)
                Spacer(minLength: 10)

                if (type != .progress) {
                    Button {
                        onButtonTapped()
                    } label: {
                        Text(buttonTitle)
                            .foregroundColor(type.blocking ? Color.black : Color.gray)
                            .font(.callout)
                    }
                    .padding(.top, 13)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(type.themeColor)
                .frame(width: 6)
                .clipped(),
            alignment: .leading
        )
        .frame(minWidth: 0, maxWidth: width)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 25)
    }
}
