
import SwiftUI

struct OnlineView: View {
    @State private var rank: String = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
    @State private var bars: Int = UserDefaults.standard.integer(forKey: "bars")
    @State private var elo: Int = UserDefaults.standard.integer(forKey: "elo")
    @State private var leaderboard: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard()
    @State private var botName: String = ""
    @State private var inMatch: Bool = false

    var body: some View {
        VStack {
            Text("Rank: \(rank)")
                .font(.title)
                .padding()

            ProgressBar(bars: $bars)
                .padding()

            if inMatch {
                Text("Playing against \(botName)...")
                    .font(.headline)
                    .padding()
                Button(action: finishMatch) {
                    Text("Finish Match")
                        .font(.headline)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Button(action: playMatch) {
                    Text("Play Match")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }

            NavigationLink("Leaderboard", destination: LeaderboardView(leaderboard: leaderboard))
                .padding()
        }
        .onAppear(perform: loadProgress)
        .navigationTitle("Online Mode")
    }

    func playMatch() {
        botName = generateBotName()
        inMatch = true
    }

    func finishMatch() {
        inMatch = false
        let win = Bool.random() // Simulate win/loss
        if win {
            bars += 1
            if bars >= 3 {
                rankUp()
            }
        } else {
            bars -= 1
            if bars < 0 {
                rankDown()
            }
        }
        saveProgress()
    }

    func rankUp() {
        if rank == "Champion" {
            elo += Int.random(in: 10...30)
        } else {
            bars = 0
            rank = nextRank(from: rank)
        }
    }

    func rankDown() {
        if rank != "Bronze" {
            bars = 2
            rank = previousRank(from: rank)
        } else {
            bars = 0
        }
    }

    func saveProgress() {
        UserDefaults.standard.set(rank, forKey: "rank")
        UserDefaults.standard.set(bars, forKey: "bars")
        UserDefaults.standard.set(elo, forKey: "elo")
    }

    func loadProgress() {
        rank = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
        bars = UserDefaults.standard.integer(forKey: "bars")
        elo = UserDefaults.standard.integer(forKey: "elo")
    }

    func nextRank(from rank: String) -> String {
        switch rank {
        case "Bronze": return "Silver"
        case "Silver": return "Gold"
        case "Gold": return "Platinum"
        case "Platinum": return "Diamond"
        case "Diamond": return "Champion"
        default: return "Champion"
        }
    }

    func previousRank(from rank: String) -> String {
        switch rank {
        case "Silver": return "Bronze"
        case "Gold": return "Silver"
        case "Platinum": return "Gold"
        case "Diamond": return "Platinum"
        case "Champion": return "Diamond"
        default: return "Bronze"
        }
    }

    func generateBotName() -> String {
        let names = ["Bot Slayer", "AI Master", "TicTacBot", "Strategic AI", "Champion Bot"]
        return names.randomElement() ?? "Bot"
    }
}

struct ProgressBar: View {
    @Binding var bars: Int

    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                Rectangle()
                    .frame(width: 30, height: 10)
                    .foregroundColor(index < bars ? .green : .gray)
            }
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let name: String
    let elo: Int

    static func mockLeaderboard() -> [LeaderboardEntry] {
        return (1...10).map { i in
            LeaderboardEntry(name: "Player \(i)", elo: 1000 + Int.random(in: 0...500))
        }.sorted { $0.elo > $1.elo }
    }
}

struct LeaderboardView: View {
    let leaderboard: [LeaderboardEntry]

    var body: some View {
        List(leaderboard) { entry in
            HStack {
                Text(entry.name)
                Spacer()
                Text("\(entry.elo)")
            }
        }
        .navigationTitle("Global Leaderboard")
    }
}

struct OnlineView_Previews: PreviewProvider {
    static var previews: some View {
        OnlineView()
    }
}
