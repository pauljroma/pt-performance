//
//  WeakRef.swift
//  PTPerformance
//
//  ACP-937: Memory Leak Detection & Fix
//  Generic weak reference wrappers for safe delegate arrays and observer patterns.
//  Prevents retain cycles when storing references to objects you do not own.
//

import Foundation

// MARK: - WeakRef

/// A lightweight wrapper that holds a `weak` reference to an `AnyObject`-conforming type.
///
/// Use this when you need to store a reference to an object without extending its
/// lifetime -- for example, in delegate lists or observer registries.
///
/// ```swift
/// let ref = WeakRef(someDelegate)
/// // Later:
/// ref.value?.didSomething()
/// ```
final class WeakRef<T: AnyObject> {

    // MARK: - Properties

    /// The weakly-held object. Becomes `nil` once the object is deallocated.
    weak var value: T?

    // MARK: - Initialization

    /// Create a weak reference wrapper.
    /// - Parameter value: The object to hold a weak reference to.
    init(_ value: T) {
        self.value = value
    }
}

// MARK: - WeakArray

/// An array of weak references with automatic compaction of deallocated entries.
///
/// This is particularly useful for maintaining lists of delegates or observers
/// without causing retain cycles. Nil references are lazily cleaned up when
/// you call `compact()`, or you can iterate over only the live objects using
/// the `Sequence` conformance.
///
/// ```swift
/// var observers = WeakArray<SomeProtocol>()
/// observers.append(observer)
///
/// // Notify all live observers:
/// for observer in observers {
///     observer.didUpdate()
/// }
///
/// // Periodically clean up dead references:
/// observers.compact()
/// ```
final class WeakArray<T: AnyObject> {

    // MARK: - Private Storage

    private var refs: [WeakRef<T>] = []

    // MARK: - Initialization

    /// Create an empty weak array.
    init() {}

    /// Create a weak array from an existing sequence of objects.
    init<S: Sequence>(_ elements: S) where S.Element == T {
        refs = elements.map { WeakRef($0) }
    }

    // MARK: - Mutation

    /// Append a new weak reference.
    /// - Parameter element: The object to add.
    func append(_ element: T) {
        refs.append(WeakRef(element))
    }

    /// Remove all weak references whose underlying object matches `element`
    /// (by identity, not equality).
    /// - Parameter element: The object to remove.
    func remove(_ element: T) {
        refs.removeAll { $0.value === element }
    }

    /// Remove all entries whose referenced object has been deallocated.
    /// Call this periodically to keep the internal storage lean.
    func compact() {
        refs.removeAll { $0.value == nil }
    }

    /// Remove all entries (both live and dead).
    func removeAll() {
        refs.removeAll()
    }

    // MARK: - Access

    /// The currently alive objects. Dead references are skipped.
    var allObjects: [T] {
        refs.compactMap { $0.value }
    }

    /// The number of currently alive objects (dead references are not counted).
    var count: Int {
        refs.reduce(0) { $0 + ($1.value != nil ? 1 : 0) }
    }

    /// Whether there are any alive objects.
    var isEmpty: Bool {
        !refs.contains { $0.value != nil }
    }

    /// Access an alive object by index into the compacted (live-only) list.
    /// Returns `nil` if the index is out of bounds.
    subscript(index: Int) -> T? {
        let live = allObjects
        guard index >= 0, index < live.count else { return nil }
        return live[index]
    }

    /// The total number of stored references, including dead ones.
    /// Useful for deciding when to call `compact()`.
    var rawCount: Int {
        refs.count
    }
}

// MARK: - Sequence Conformance

extension WeakArray: Sequence {
    func makeIterator() -> IndexingIterator<[T]> {
        allObjects.makeIterator()
    }
}
