import SwiftUI
import WidgetKit

struct TaskItem: Decodable, Identifiable {
    let id: String
    let title: String
    let dueAt: Double
    let endsAt: Double
    let dueDates: [Double]
    let durationMs: Double
    func nextDue(_ now: Double) -> Double {
        dueDates.sorted().first(where: { $0 + durationMs > now }) ?? dueDates.max() ?? dueAt
    }
}

struct TaskSnapshot: Decodable {
    let ownerId: String
    let total: Int
    let updatedAt: Double
    let expiresAt: Double
    let tasks: [TaskItem]
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let snapshot: TaskSnapshot?
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry { TaskEntry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(TaskEntry(date: Date(), snapshot: read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let now = Date()
        let snapshot = read()
        var dates = [now]
        if let data = snapshot {
            dates += data.tasks.flatMap { task in task.dueDates.flatMap {
                [Date(timeIntervalSince1970: $0 / 1000),
                 Date(timeIntervalSince1970: ($0 + task.durationMs) / 1000)]
            } }
            dates += [Date(timeIntervalSince1970: data.expiresAt / 1000)]
        }
        let entries = Array(Set(dates.filter { $0 >= now })).sorted().map { date in
            TaskEntry(date: date, snapshot: snapshot.flatMap {
                $0.expiresAt > date.timeIntervalSince1970 * 1000 ? $0 : nil
            })
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(1800))))
    }
    private func read() -> TaskSnapshot? {
        guard let raw = UserDefaults(suiteName: "group.com.example.shiftly")?.string(forKey: "taskSnapshot"),
              let bytes = raw.data(using: .utf8),
              let data = try? JSONDecoder().decode(TaskSnapshot.self, from: bytes),
              data.expiresAt > Date().timeIntervalSince1970 * 1000 else { return nil }
        return data
    }
}

struct TaskWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family
    private let accent = Color(red: 0.28, green: 0.85, blue: 0.75)
    private var arabic: Bool { Locale.current.languageCode == "ar" }
    private func url(_ task: TaskItem? = nil) -> URL {
        var parts = URLComponents()
        parts.scheme = "shiftly"
        parts.host = "task-widget"
        parts.queryItems = [
            URLQueryItem(name: "ownerId", value: entry.snapshot?.ownerId ?? ""),
            URLQueryItem(name: "taskId", value: task?.id ?? "")
        ]
        return parts.url!
    }
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(Color(red: 0.06, green: 0.11, blue: 0.13), for: .widget)
        } else {
            content.padding().background(Color(red: 0.06, green: 0.11, blue: 0.13))
        }
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHIFTLY").font(.caption2.bold()).foregroundColor(accent)
            if let snapshot = entry.snapshot {
                Text(arabic ? "متبقي \(snapshot.total) مهمة" : "\(snapshot.total) tasks remaining")
                    .font(.headline).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.75)
                if snapshot.tasks.isEmpty {
                    Text(arabic ? "خلصت كل مهامك!" : "All done!").foregroundColor(accent)
                }
                ForEach(Array(snapshot.tasks.prefix(family == .systemSmall ? 1 : 3))) { task in
                    Link(destination: url(task)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title).font(.subheadline.bold()).foregroundColor(.white).lineLimit(1)
                            let now = entry.date.timeIntervalSince1970 * 1000
                            let due = task.nextDue(now)
                            let end = due + task.durationMs
                            let running = due <= now && end > now
                            let overdue = end <= now
                            let target = running ? end : due
                            HStack(spacing: 5) {
                                Text(overdue ? (arabic ? "متأخرة" : "Overdue") :
                                     running ? (arabic ? "باقي للنهاية" : "Ends in") :
                                     (arabic ? "باقي للموعد" : "Due in"))
                                Text(Date(timeIntervalSince1970: target / 1000), style: .timer)
                            }.font(.caption2).foregroundColor(overdue ? .orange : accent)
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text(arabic ? "آخر تحديث" : "Updated")
                    Text(Date(timeIntervalSince1970: snapshot.updatedAt / 1000), style: .time)
                }.font(.system(size: 9)).foregroundColor(.gray)
            } else {
                Text(arabic ? "مهامك في لمحة" : "Your tasks, at a glance").font(.headline).foregroundColor(.white)
                Text(arabic ? "افتح شيفتلي لتحديث المهام" : "Open Shiftly to refresh tasks")
                    .font(.caption).foregroundColor(.gray)
            }
        }.widgetURL(url(family == .systemSmall ? entry.snapshot?.tasks.first : nil)).privacySensitive()
    }
}

@main
struct ShiftlyTasksWidget: Widget {
    let kind = "ShiftlyTasksWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in TaskWidgetView(entry: entry) }
            .configurationDisplayName("Shiftly tasks")
            .description("Remaining tasks and time until they are due.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
