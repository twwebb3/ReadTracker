import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let sampleBooks: [(String, Int32, Int32, Int16, ReadingCadence)] = [
            ("The Great Gatsby", 180, 45, 15, .standard),
            ("Dune", 412, 120, 20, .standard),
            ("Clean Code", 464, 200, 10, .work),
        ]

        let calendar = Calendar.current
        for (title, totalPages, currentPage, pagesPerDay, cadence) in sampleBooks {
            let book = Book(context: viewContext)
            book.id = UUID()
            book.title = title
            book.totalPages = totalPages
            book.currentPage = currentPage
            book.pagesPerDay = pagesPerDay
            book.cadence = cadence.rawValue
            book.startDate = calendar.date(byAdding: .day, value: -7, to: Date())!
            book.isFinished = false

            let estimatedDate = CompletionCalculator.estimatedCompletionDate(
                remainingPages: totalPages,
                pagesPerDay: pagesPerDay,
                cadence: cadence,
                from: book.startDate!
            )
            book.originalEstimatedCompletionDate = estimatedDate
            book.estimatedCompletionDate = CompletionCalculator.estimatedCompletionDate(
                remainingPages: totalPages - currentPage,
                pagesPerDay: pagesPerDay,
                cadence: cadence,
                from: Date()
            )
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReadTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
