//
//  Helpers.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-13.
//

import SwiftUI

extension Array where Element: Equatable {

    // Remove item from array by element
    @discardableResult
    mutating func remove(element: Element) -> Element? {
        guard let index = firstIndex(of: element) else { return nil }
        return remove(at: index)
    }
}

extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws -> T {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, _) = try await data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        
        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "\(releaseVersionNumber ?? "1.0").\(buildVersionNumber ?? "0")"
    }
    func releaseVersionOlder(than: String) -> Bool {
        return releaseVersionNumberPretty.compare(than, options: .numeric) == .orderedAscending
    }
    var displayName: String? {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? infoDictionary?["CFBundleName"] as? String
    }
}

extension View {
    func border(_ color: Color, edges: [Edge], width: CGFloat = 1) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}

extension Date {
    static func localDate() -> Date {
        let nowUTC = Date()
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: nowUTC))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {
            return nowUTC
        }
        return localDate
    }
    
    func toLocalDate() -> Date {
        let dateUTC = self
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: dateUTC))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: dateUTC) else {
            return dateUTC
        }
        return localDate

    }
}

extension View {
    /// Adds a modifier for this view that fires an action only when a time interval in seconds represented by
    /// `debounceTime` elapses between value changes.
    ///
    /// Each time the value changes before `debounceTime` passes, the previous action will be cancelled and the next
    /// action /// will be scheduled to run after that time passes again. This mean that the action will only execute
    /// after changes to the value /// stay unmodified for the specified `debounceTime` in seconds.
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether to run the closure.
    ///   - debounceTime: The time in seconds to wait after each value change before running `action` closure.
    ///   - action: A closure to run when the value changes.
    /// - Returns: A view that fires an action after debounced time when the specified value changes.
    public func onChange<Value>(
        of value: Value,
        debounceTime: TimeInterval,
        perform action: @escaping (_ newValue: Value) -> Void
    ) -> some View where Value: Equatable {
        self.modifier(DebouncedChangeViewModifier(trigger: value, debounceTime: debounceTime, action: action))
    }
    
    /// Same as above but adds before action
    ///   - debounceTask: The common task for multiple Values, but can be set to a different action for each change
    ///   - action: A closure to run when the value changes.
    /// - Returns: A view that fires an action after debounced time when the specified value changes.
    public func onChange<Value>(
        of value: Value,
        debounceTime: TimeInterval,
        task: Binding< Task<Void,Never>? >,
        perform action: @escaping (_ newValue: Value) -> Void
    ) -> some View where Value: Equatable {
        self.modifier(DebouncedTaskBindingChangeViewModifier(trigger: value, debounceTime: debounceTime, debouncedTask: task, action: action))
    }
}

private struct DebouncedChangeViewModifier<Value>: ViewModifier where Value: Equatable {
    let trigger: Value
    let debounceTime: TimeInterval
    let action: (Value) -> Void

    @State private var debouncedTask: Task<Void,Never>?

    func body(content: Content) -> some View {
        content.onChange(of: trigger) { old, value in
            debouncedTask?.cancel()
            debouncedTask = Task.delayed(seconds: debounceTime) { @MainActor in
                action(value)
            }
        }
    }
}

private struct DebouncedTaskBindingChangeViewModifier<Value>: ViewModifier where Value: Equatable {
    let trigger: Value
    let debounceTime: TimeInterval
    @Binding var debouncedTask: Task<Void,Never>?
    let action: (Value) -> Void

    func body(content: Content) -> some View {
        content.onChange(of: trigger) { old, value in
            debouncedTask?.cancel()
            debouncedTask = Task.delayed(seconds: debounceTime) { @MainActor in
                action(value)
            }
        }
    }
}

extension Task {
    /// Asynchronously runs the given `operation` in its own task after the specified number of `seconds`.
    ///
    /// The operation will be executed after specified number of `seconds` passes. You can cancel the task earlier
    /// for the operation to be skipped.
    ///
    /// - Parameters:
    ///   - time: Delay time in seconds.
    ///   - operation: The operation to execute.
    /// - Returns: Handle to the task which can be cancelled.
    @discardableResult
    public static func delayed(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async -> Void
    ) -> Self where Success == Void, Failure == Never {
        Self {
            do {
                try await Task<Never, Never>.sleep(nanoseconds: UInt64(seconds * 1e9))
                await operation()
            } catch {}
        }
    }
}

@resultBuilder
public struct StringBuilder {
    public static func buildBlock(_ components: String...) -> String {
        return components.reduce("", +)
    }
}

public extension String {
    init(@StringBuilder _ builder: () -> String) {
        self.init(builder())
    }
}

public extension Color {
    static func random(opacity: Double = 0.4) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: opacity
        )
    }
}

extension View {

    func testListRowBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.listRowBackground(Color.random())
#else
        self
#endif
    }

    func testBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.background(Color.random())
#else
        self
#endif
    }

    func testAnimatedBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.modifier(AnimatedBackground())
#else
        self
#endif
    }
}

struct AnimatedBackground: ViewModifier {
    @State private var isVisible: Bool = false
    let linewidth: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .overlay(content: {
                Rectangle()
                    .trim(from: isVisible ? 1 : 0, to: 1)
                    .stroke(Color.red, lineWidth: linewidth)
                    .padding(linewidth)

                Rectangle()
                    .trim(from: isVisible ? 1 : 0, to: 1)
                    .stroke(Color.blue, lineWidth: linewidth)
                    .rotationEffect(.degrees(180))
            })
            .onAppear(perform: {
                withAnimation(.linear(duration: 1)) {
                    isVisible = true
                }
            })
    }
}
