# BUILD_72A Quick Start Guide

## For Next Agents in Swarm

### What Agent 7 Delivered

**Models** (5 files in `ios-app/PTPerformance/Models/`):
1. `Block.swift` - Training block container
2. `BlockItem.swift` - Exercise item with sets/reps/load/RPE
3. `QuickMetrics.swift` - Session metrics aggregator
4. `Session.swift` - Top-level session with blocks array
5. `LogEvent.swift` - Event tracking (pre-existing, verified)

**Views** (4 files in `ios-app/PTPerformance/Views/Logging/`):
1. `BlockCard.swift` - Main card with 1-tap completion
2. `BlockHeader.swift` - Block header with progress
3. `BlockItemRow.swift` - Exercise item display
4. `QuickMetricsSummary.swift` - Metrics summary

### Quick Integration

#### 1. Add to Xcode Project

```ruby
# Run this Ruby script to add files to Xcode project
require 'xcodeproj'

project = Xcodeproj::Project.open('ios-app/PTPerformance/PTPerformance.xcodeproj')
target = project.targets.first

# Add models
models = [
  'Models/Block.swift',
  'Models/BlockItem.swift',
  'Models/QuickMetrics.swift',
  'Models/Session.swift'
]

# Add views
views = [
  'Views/Logging/BlockCard.swift',
  'Views/Logging/BlockHeader.swift',
  'Views/Logging/BlockItemRow.swift',
  'Views/Logging/QuickMetricsSummary.swift'
]

(models + views).each do |file|
  file_ref = project.new_file("ios-app/PTPerformance/#{file}")
  target.add_file_references([file_ref])
end

project.save
```

#### 2. Create ViewModel (Agent 8 Task)

```swift
import SwiftUI
import Combine

class SessionLoggingViewModel: ObservableObject {
    @Published var session: Session
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let sessionService: SessionService
    private var cancellables = Set<AnyCancellable>()

    init(session: Session, sessionService: SessionService) {
        self.session = session
        self.sessionService = sessionService
    }

    // MARK: - Block Actions

    func completeBlock(_ block: Block) {
        // Update session
        if let index = session.blocks.firstIndex(where: { $0.id == block.id }) {
            session.blocks[index] = block
        }

        // Log event
        let event = LogEvent.blockCompleted(
            patientId: session.patientId,
            sessionId: session.id,
            blockNumber: block.orderIndex,
            metadata: ["completion_type": "one_tap"]
        )
        logEvent(event)

        // Auto-save
        saveSession()
    }

    func completeSet(itemId: UUID, set: CompletedSet) {
        // Find and update item
        for blockIndex in session.blocks.indices {
            if let itemIndex = session.blocks[blockIndex].items.firstIndex(where: { $0.id == itemId }) {
                session.blocks[blockIndex].items[itemIndex].completedSets.append(set)

                // Check if item is now complete
                let item = session.blocks[blockIndex].items[itemIndex]
                if item.completedSets.count == item.prescribedSets {
                    session.blocks[blockIndex].items[itemIndex].isCompleted = true
                    session.blocks[blockIndex].items[itemIndex].completedAt = Date()
                }
                break
            }
        }

        // Log event
        let event = LogEvent.setComplete(
            sessionId: session.id,
            blockId: session.blocks.first?.id ?? UUID(),
            blockItemId: itemId,
            userId: session.patientId,
            setNumber: set.setNumber,
            reps: set.actualReps,
            load: set.actualLoad,
            rpe: set.actualRPE
        )
        logEvent(event)

        saveSession()
    }

    func quickAdjust(itemId: UUID, type: String, delta: Double) {
        for blockIndex in session.blocks.indices {
            if let itemIndex = session.blocks[blockIndex].items.firstIndex(where: { $0.id == itemId }) {
                if type == "load" {
                    session.blocks[blockIndex].items[itemIndex].adjustLoad(by: delta)
                } else if type == "reps" {
                    session.blocks[blockIndex].items[itemIndex].adjustReps(by: Int(delta))
                }
                break
            }
        }

        logEvent(LogEvent.quickAdjustment(
            sessionId: session.id,
            blockId: session.blocks.first?.id ?? UUID(),
            blockItemId: itemId,
            userId: session.patientId,
            adjustmentType: type,
            delta: String(format: "%.0f", delta)
        ))

        saveSession()
    }

    func reportPain(itemId: UUID, level: Int, location: String?) {
        // Log pain event
        for blockIndex in session.blocks.indices {
            if let itemIndex = session.blocks[blockIndex].items.firstIndex(where: { $0.id == itemId }) {
                // Update last completed set with pain info
                if var lastSet = session.blocks[blockIndex].items[itemIndex].completedSets.last {
                    lastSet.painLevel = level
                    lastSet.painLocation = location
                    let lastIndex = session.blocks[blockIndex].items[itemIndex].completedSets.count - 1
                    session.blocks[blockIndex].items[itemIndex].completedSets[lastIndex] = lastSet
                }
                break
            }
        }

        logEvent(LogEvent.painFlag(
            sessionId: session.id,
            blockId: session.blocks.first?.id ?? UUID(),
            blockItemId: itemId,
            userId: session.patientId,
            painLevel: level,
            location: location
        ))

        saveSession()
    }

    // MARK: - Persistence

    private func saveSession() {
        sessionService.updateSession(session)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func logEvent(_ event: LogEvent) {
        sessionService.logEvent(event)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
```

#### 3. Create Main View

```swift
struct SessionLoggingView: View {
    @StateObject private var viewModel: SessionLoggingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Session header
                QuickMetricsSummary(
                    metrics: viewModel.session.quickMetrics,
                    compact: false
                )

                // Blocks
                ForEach(viewModel.session.blocks.indices, id: \.self) { index in
                    BlockCard(
                        block: $viewModel.session.blocks[index],
                        onBlockComplete: viewModel.completeBlock,
                        onSetComplete: viewModel.completeSet,
                        onQuickAdjust: viewModel.quickAdjust,
                        onPainReport: viewModel.reportPain
                    )
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.session.title)
    }
}
```

#### 4. Test Data

```swift
extension Session {
    static var sampleSession: Session {
        Session(
            id: UUID(),
            patientId: UUID(),
            scheduledFor: Date(),
            title: "Lower Body Strength",
            sessionType: .strength,
            blocks: [
                Block(
                    id: UUID(),
                    sessionId: UUID(),
                    blockType: .warmup,
                    title: "Warm-up",
                    orderIndex: 0,
                    items: [
                        BlockItem(
                            id: UUID(),
                            blockId: UUID(),
                            exerciseId: UUID(),
                            exerciseName: "Band Pull-Aparts",
                            orderIndex: 0,
                            prescribedSets: 3,
                            prescribedReps: "15"
                        )
                    ]
                ),
                Block(
                    id: UUID(),
                    sessionId: UUID(),
                    blockType: .mainWork,
                    title: "Main Work",
                    orderIndex: 1,
                    items: [
                        BlockItem(
                            id: UUID(),
                            blockId: UUID(),
                            exerciseId: UUID(),
                            exerciseName: "Back Squat",
                            orderIndex: 0,
                            prescribedSets: 5,
                            prescribedReps: "5",
                            prescribedLoad: 225,
                            prescribedRPE: 8,
                            tempo: "3-1-1-0"
                        )
                    ]
                )
            ]
        )
    }
}
```

### File Locations

```
ios-app/PTPerformance/
├── Models/
│   ├── Block.swift
│   ├── BlockItem.swift
│   ├── QuickMetrics.swift
│   ├── Session.swift
│   └── LogEvent.swift
└── Views/
    └── Logging/
        ├── BlockCard.swift
        ├── BlockHeader.swift
        ├── BlockItemRow.swift
        └── QuickMetricsSummary.swift
```

### Build Verification

```bash
# Quick compile check
cd ios-app/PTPerformance
xcodebuild -scheme PTPerformance -sdk iphonesimulator -configuration Debug build
```

### Key Features to Test

1. **1-tap completion**: Tap "Complete as Prescribed" button
2. **Individual set logging**: Tap "Log Set X" button
3. **Quick adjustments**: Tap +5/-5 buttons
4. **Pain reporting**: Tap pain icon, submit report
5. **Progress updates**: Watch progress bars animate
6. **Block expansion**: Tap header to expand/collapse

### Common Issues

1. **Binding errors**: Ensure parent owns the `Session`, children get `Binding<Block>`
2. **Preview crashes**: Check sample data has valid UUIDs
3. **Animation jank**: Verify `@State` is used correctly
4. **Color errors**: All colors use SwiftUI `Color` type

### Performance Tips

1. Use `LazyVStack` for long lists
2. Debounce save operations
3. Batch event logs
4. Cache metrics calculations

---

**Ready to integrate! Next agent can start with ViewModel (Agent 8) or Service Layer (Agent 9).**
