//
//  AdvancedToastModifiers.swift
//  Advanced Toast
//
//  Created by Gaurav Tak on 26/12/23.
//  Modified by Andrew Forget on 2025-01-10.
//

import SwiftUI

struct AdvancedToastModifiers: ViewModifier {
    @Binding var toasts: [AdvancedToast]
    @State private var workItems: [UUID:DispatchWorkItem] = [:]

    func body(content: Content) -> some View {
        content
            .allowsHitTesting(toasts.count(where: { $0.modal }) == 0)
            .focusEffectDisabled(toasts.count != 0)
            .blur(radius: toasts.count(where: { $0.modal }) > 0 ? 4 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if toasts.count(where: { $0.modal }) > 0 {
                        Rectangle()
                            .opacity(0.0000001)
                            .onTapGesture {
                                if toasts.count(where: { $0.blocking }) == 0 {
                                    dismissAllNonBlockingToasts()
                                }
                            }
                    }
                    HStack {
                        Spacer()
                        ZStack {
                            mainToastView()
                                .offset(x: -12, y: 20)
                                .animation(.spring(), value: toasts.count)
                        }
                    }
                }
            )
            .onChange(of: toasts) {
                showAdvancedToast()
            }
    }

    @ViewBuilder func mainToastView() -> some View {
        if !toasts.isEmpty {
            VStack {
                ForEach(toasts) { toast in
                    AdvancedToastView(
                        type: toast.type,
                        title: toast.title,
                        message: toast.message,
                        width: toast.width,
                        buttonTitle: toast.buttonTitle
                    ) {
                        dismissToast(toast)
                        if let onButtonTapped = toast.onButtonTapped {
                            onButtonTapped()
                        }
                    }
                    .transition(.move(edge: .trailing))
                    .animation(.spring(), value: !toast.isDismissed)
                }
                Spacer()
            }
            .transition(.move(edge: .trailing))
            .animation(.spring(), value: toasts)
        }
    }

    private func showAdvancedToast() {
        guard !toasts.isEmpty else { return }

        for toast in toasts {
            if toast.duration > 0 {
                workItems[toast.id]?.cancel()
                let task = DispatchWorkItem {
                    dismissToast(toast)
                }
                workItems[toast.id] = task
                DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
            }
        }
    }

    private func dismissToast(_ toast: AdvancedToast) {
        withAnimation {
            if var toastToDismiss = toasts.first(where: { $0 == toast }) {
                (toastToDismiss.onDismissed ?? { })()
                toastToDismiss.isDismissed = true
            }
            toasts.removeAll(where: { $0 == toast })
        }
        workItems[toast.id]?.cancel()
        workItems.removeValue(forKey: toast.id)
    }

    private func dismissAllNonBlockingToasts() {
        for toast in toasts {
            if !toast.blocking {
                dismissToast(toast)
            }
        }
    }
}
