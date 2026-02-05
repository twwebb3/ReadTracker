import SwiftUI
import CoreData

struct CompletedBooksView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.actualCompletionDate, ascending: false)],
        predicate: NSPredicate(format: "isFinished == YES"),
        animation: .default
    )
    private var books: FetchedResults<Book>

    private var averageDaysFromEstimate: Double {
        guard !books.isEmpty else { return 0 }
        let total = books.reduce(0) { sum, book in
            guard let actual = book.actualCompletionDate,
                  let estimated = book.originalEstimatedCompletionDate else { return sum }
            return sum + CompletionCalculator.daysFromEstimate(estimated: estimated, actual: actual)
        }
        return Double(total) / Double(books.count)
    }

    var body: some View {
        List {
            if !books.isEmpty {
                Section("Summary") {
                    HStack {
                        Text("Books Completed")
                        Spacer()
                        Text("\(books.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Avg. Days from Estimate")
                        Spacer()
                        let avg = averageDaysFromEstimate
                        Text(avgText(avg))
                            .foregroundStyle(avg <= 0 ? .green : .red)
                    }
                }
            }

            Section("Completed") {
                ForEach(books) { book in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title ?? "")
                            .font(.headline)

                        if let actual = book.actualCompletionDate {
                            Text("Finished \(actual, style: .date)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let actual = book.actualCompletionDate,
                           let estimated = book.originalEstimatedCompletionDate {
                            let diff = CompletionCalculator.daysFromEstimate(
                                estimated: estimated, actual: actual
                            )
                            Text(diffText(diff))
                                .font(.subheadline)
                                .foregroundStyle(diff <= 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if books.isEmpty {
                ContentUnavailableView(
                    "No Completed Books",
                    systemImage: "book.closed",
                    description: Text("Books you finish will appear here.")
                )
            }
        }
    }

    private func diffText(_ diff: Int) -> String {
        if diff < 0 {
            return "\(abs(diff)) day\(abs(diff) == 1 ? "" : "s") early"
        } else if diff > 0 {
            return "\(diff) day\(diff == 1 ? "" : "s") late"
        } else {
            return "On time"
        }
    }

    private func avgText(_ avg: Double) -> String {
        let rounded = abs(avg)
        let formatted = String(format: "%.1f", rounded)
        if avg < -0.05 {
            return "\(formatted)d early"
        } else if avg > 0.05 {
            return "\(formatted)d late"
        } else {
            return "On time"
        }
    }
}

#Preview {
    NavigationStack {
        CompletedBooksView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
