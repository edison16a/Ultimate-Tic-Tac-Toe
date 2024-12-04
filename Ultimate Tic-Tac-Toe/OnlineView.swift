import SwiftUI

struct OnlineView: View {
    @State private var rank: String = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
    @State private var bars: Int = UserDefaults.standard.integer(forKey: "bars")
    @State private var elo: Int = UserDefaults.standard.integer(forKey: "elo")
    @State private var leaderboard: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard()
    @State private var opponentName: String = ""
    @State private var inMatch: Bool = false
    @State private var showLeaderboard: Bool = false
    @State private var timer = Timer.publish(every: 10.0, on: .main, in: .common).autoconnect()

    // State variables for the playable board
    @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
    @State private var currentPlayer: String = "X"
    @State private var botMovePending: Bool = false

    var body: some View {
        VStack {
            Text("Rank: \(rank)")
                .font(.title)
                .padding()

            Image(rank.lowercased())
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding()

            if rank == "Champion" {
                Text("Elo: \(elo)")
                    .font(.largeTitle)
                    .padding()
            } else {
                ProgressBar(bars: $bars)
                    .padding()
            }

            if inMatch {
                VStack {
                    Text("Playing against \(opponentName)...")
                        .font(.headline)
                        .padding()

                    // Game Board View
                    GameBoardView(board: $board, currentPlayer: $currentPlayer, botMovePending: $botMovePending) {
                        checkGameOver()
                    }

                    Button(action: finishMatch) {
                        Text("End Match Early")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                Button(action: findOpponent) {
                    Text("Find Opponent")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }

            Button("Leaderboard") {
                showLeaderboard = true
            }
            .font(.headline)
            .padding()
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView(leaderboard: leaderboard)
            }
        }
        .onAppear(perform: loadProgress)
        .onReceive(timer) { _ in
            updateLeaderboard()
        }
        .navigationTitle("Online Mode")
    }

    func updateLeaderboard() {
        leaderboard = leaderboard.map { entry in
            var updatedEntry = entry
            updatedEntry.elo += Int.random(in: 10...25)
            return updatedEntry
        }
        leaderboard.sort { $0.elo > $1.elo }
    }

    func findOpponent() {
        opponentName = "Player\(Int.random(in: 1000...9999))"
        resetGameBoard()
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
            elo += Int.random(in: 10...25)
        } else {
            bars = 0
            rank = nextRank(from: rank)
        }
    }

    func rankDown() {
        if rank == "Champion" {
            elo = max(elo - Int.random(in: 10...25), 0)
        } else if rank != "Bronze" {
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
        if elo == 0 {
            elo = 150
        }
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

    // MARK: - Game Logic

    func resetGameBoard() {
        board = Array(repeating: Array(repeating: "", count: 3), count: 3)
        currentPlayer = "X"
        botMovePending = false
    }

    func checkGameOver() {
        if let winner = GameLogic.checkWinner(on: board) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                inMatch = false
                finishMatch()
            }
        } else if GameLogic.isDraw(on: board) {
            inMatch = false
        } else {
            botMovePending = currentPlayer == "O"
        }
    }
}

struct GameBoardView: View {
    @Binding var board: [[String]]
    @Binding var currentPlayer: String
    @Binding var botMovePending: Bool
    let onMoveComplete: () -> Void

    var body: some View {
        VStack {
            ForEach(0..<3, id: \.self) { row in
                HStack {
                    ForEach(0..<3, id: \.self) { col in
                        Button(action: {
                            if board[row][col].isEmpty && currentPlayer == "X" {
                                board[row][col] = currentPlayer
                                currentPlayer = "O"
                                onMoveComplete()
                                makeBotMove()
                            }
                        }) {
                            Text(board[row][col])
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                                .font(.largeTitle)
                        }
                    }
                }
            }
        }
    }

    func makeBotMove() {
        guard botMovePending else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let emptyCells = board.flatMap { $0 }.enumerated().filter { $1.isEmpty }
            if let move = emptyCells.randomElement() {
                let row = move.offset / 3
                let col = move.offset % 3
                board[row][col] = "O"
                currentPlayer = "X"
                onMoveComplete()
            }
        }
    }
}

struct GameLogic {
    static func checkWinner(on board: [[String]]) -> String? {
        // Horizontal, vertical, and diagonal checks
        for i in 0..<3 {
            if board[i][0] == board[i][1], board[i][1] == board[i][2], !board[i][0].isEmpty {
                return board[i][0]
            }
            if board[0][i] == board[1][i], board[1][i] == board[2][i], !board[0][i].isEmpty {
                return board[0][i]
            }
        }
        if board[0][0] == board[1][1], board[1][1] == board[2][2], !board[0][0].isEmpty {
            return board[0][0]
        }
        if board[0][2] == board[1][1], board[1][1] == board[2][0], !board[0][2].isEmpty {
            return board[0][2]
        }
        return nil
    }

    static func isDraw(on board: [[String]]) -> Bool {
        return board.flatMap { $0 }.allSatisfy { !$0.isEmpty }
    }
}
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let name: String
    var elo: Int

    static func mockLeaderboard() -> [LeaderboardEntry] {
        let usernames = [
            "CSA", "Revquant", "Swaggyboi19", "Buwuga", "IAMzMarsh",
            "ItssssssJake", "CallMeBaby", "sss", "YeahImASwifty", "WhatTheDogDoin", "edichessboi23"
        ]
        
        return usernames.enumerated().map { index, username in
            // Assign decreasing ELOs based on position
            LeaderboardEntry(name: username, elo: Int(floor(1500 - (Double(index+1) * 43.28374))))
        }
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
struct LeaderboardView: View {
    let leaderboard: [LeaderboardEntry]
    let currentPlayer: String = UserDefaults.standard.string(forKey: "username") ?? "You"

    var body: some View {
        NavigationView {
            List(leaderboard) { entry in
                HStack {
                    Text(entry.name)
                        .font(entry.name == currentPlayer ? .headline : .body)
                        .foregroundColor(entry.name == currentPlayer ? .blue : .primary)
                    Spacer()
                    Text("\(entry.elo)")
                }
            }
            .navigationTitle("Global Leaderboard")
        }
    }
}
