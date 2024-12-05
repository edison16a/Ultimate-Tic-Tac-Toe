import SwiftUI

struct OnlineView: View {
    @State private var rank: String = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
    @State private var bars: Int = UserDefaults.standard.integer(forKey: "bars")
    @State private var elo: Int = UserDefaults.standard.integer(forKey: "elo")
    @State private var leaderboard: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard()
    @State private var opponentName: String = ""
    @State private var inMatch: Bool = false
    @State private var showLeaderboard: Bool = false
    @State private var timer = Timer.publish(every: Double.random(in: 10...25), on: .main, in: .common).autoconnect()
    @State private var matchEndedEarly: Bool = false
    // State variables for the playable board
    @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
    @State private var currentPlayer: String = "X"
    @State private var botMovePending: Bool = false
    @State private var matchmaking: Bool = false
    //utt
    

    var body: some View {
        VStack {
            if elo >= 1800{
                Text("Rank: \(rank)" + " (GM)")
                    .font(.title)
                    .padding()
            }
            else{
                Text("Rank: \(rank)")
                    .font(.title)
                    .padding()
            }

            
            Text("Gain 1 bar each win. Reach 3 to increase your rank. After Reaching Max Rank (Champion) You Will Have An Elo and Can Get on the Leadeboard.\n Reach 1800 Elo To Become an Official GrandMaster (GM)")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()

            Image(rank.lowercased())
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding()

            if rank == "Champion" {
                Text("Current Global Elo Rank: \(calculateGlobalRank(userElo: elo, leaderboard: leaderboard))")
                    .font(.headline)
                    .padding()

                
                Text("Elo: \(elo)")
                    .font(.largeTitle)
                    .padding()
            } else {
                ProgressBar(bars: $bars)
                    .padding()
                    .cornerRadius(5)
            }

            if matchmaking {
                VStack {
                    Text("Matchmaking...")
                        .font(.headline)
                        .padding()

                    ProgressView() // Spinning loader to simulate matchmaking
                        .scaleEffect(1.5)
                        .padding()
                }
            } else if inMatch {
                VStack {
                    Text("Playing against \(opponentName)...")
                        .font(.headline)
                        .padding()

                    // Game Board View
                    GameBoardView(board: $board, currentPlayer: $currentPlayer, botMovePending: $botMovePending) {
                        checkGameOver()
                    }

                    Button(action: {
                        matchEndedEarly = true // Mark the match as ended early
                        finishMatch()          // Call finishMatch to process the early end
                    }) {
                        Text("Forfeit")
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
                    Text("Play Ranked Match")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }


            Button("Global Elo Leaderboard") {
                showLeaderboard = true
            }
            .font(.headline)
            .padding()
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView(leaderboard: leaderboard)
            }
        }
        .onAppear {
            addToLeaderboardIfEligible()
        }
        .background(Color(UIColor.systemGray4)).ignoresSafeArea()
        .onAppear(perform: loadProgress)
        .onReceive(timer) { _ in
            updateLeaderboard()
        }
        .navigationTitle("Online Mode")
    }
    
    private func addToLeaderboardIfEligible() {
        // Check if the user's elo qualifies
        if elo >= 300 {
            // Calculate the current rank
            let rank = calculateGlobalRank(userElo: elo, leaderboard: leaderboard)
            let nameWithRank = "\(rank). You (GM)"
            
            // Ensure the "You" entry with rank is unique
            if !leaderboard.contains(where: { $0.name == nameWithRank }) {
                let userEntry = LeaderboardEntry(name: nameWithRank, elo: elo)
                leaderboard.append(userEntry)
                leaderboard.sort { $0.elo > $1.elo } // Sort by elo, descending
            }
        }
    }

    

    func updateLeaderboard() {
        leaderboard = leaderboard.map { entry in
            var updatedEntry = entry
            updatedEntry.elo += Int.random(in: -1...5)
            return updatedEntry
        }
        leaderboard.sort { $0.elo > $1.elo }
    }

    func findOpponent() {
        matchmaking = true // Start matchmaking
         // Random delay between 2-10 seconds
        let delay: Double
        if rank == "Champion" {
            delay = Double.random(in: 5...10)
        }
        else if rank == "Diamond" {
            delay = Double.random(in: 4...7)
        }
        else if rank == "Platinum" {
            delay = Double.random(in: 2...5)
        }
        else if rank == "Gold" {
            delay = Double.random(in: 1...3)
        }
        else if rank == "Silver" {
            delay = Double.random(in: 0...2)
        }
        else if rank == "Bronze" {
            delay = Double.random(in: 0...1)
        }
        else {
            delay = Double.random(in: 0...1)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            matchmaking = false // End matchmaking
            opponentName = "Anonymous\(Int.random(in: 1000...9999))"
            resetGameBoard()
            inMatch = true
        }
    }

    func finishMatch() {
        inMatch = false

        // If the match was ended early, simulate a loss
        if matchEndedEarly {
            bars -= 1
            if bars < 0 {
                rankDown()  // Handle rank down if bars go negative
            }
        } else {
            // If there is a winner, update bars accordingly
            if let winner = GameLogic.checkWinner(on: board) {
                // If 'X' wins (player wins)
                if winner == "X" {
                    bars += 1
                    if bars > 3 {
                        rankUp()  // Rank up if bars reach 3
                    }
                } else if winner == "O" { // If 'O' wins (bot wins)
                    if rank != "Bronze" {
                        bars -= 1
                        if bars < 0 {
                            rankDown()  // Handle rank down if bars go negative
                        }
                    } else if bars > 0 {
                        bars -= 1  // In Bronze, if bars > 0, just decrease bars
                    }
                }
            } else if GameLogic.isDraw(on: board) {
                // If the game is a draw, do nothing with bars or rank
                // You can decide what to do with bars/rank on draw, if needed
            }
        }

        // Handle "Champion" rank ELO adjustment
        if rank == "Champion" {
            if let winner = GameLogic.checkWinner(on: board), winner == "X" {
                elo += Int.random(in: 41...53)  // Increase ELO if the player wins
            } else if let winner = GameLogic.checkWinner(on: board), winner == "O" {
                elo = max(elo - Int.random(in: 89...114), 0)  // Decrease ELO if the bot wins
            } else{
                elo = max(elo - Int.random(in: 89...114), 0)
            }
        }

        // Save progress to UserDefaults
        saveProgress()
    }

    func rankUp() {
        if rank == "Champion" {
            elo += Int.random(in: 31...43)
        } else {
            bars = 1
            rank = nextRank(from: rank)
        }
    }

    func rankDown() {
        if rank == "Champion" {
            elo = max(elo - Int.random(in: 76...104), 0)
        } else if rank != "Bronze" {
            bars = 3
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
            elo = 400
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
    
    func calculateGlobalRank(userElo: Int, leaderboard: [LeaderboardEntry]) -> Int {
        let topElo = 2681 // Base Elo for rank #1
        let eloStep = 1 // Elo decrease per rank
        if leaderboard.contains(where: { $0.elo == userElo }) {
            return leaderboard.firstIndex(where: { $0.elo == userElo })! + 1
        } else {
            return (topElo - userElo) / eloStep + 11 // 11 accounts for top 10 leaderboard
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
        .background(Color(UIColor.systemGray4)).ignoresSafeArea()
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
            "chessking420 (GM)", "pawnstormer (GM)", "silentknight (GM)", "rookiebobby (GM)", "chessaddict99 (GM)",
            "gmhunter (GM)", "endgameboss (GM)", "bishoptakesyou (GM)", "notmyqueen (GM)", "darkhorse12 (GM)",
            "matein2pls (GM)", "chessmaniac (GM)", "e4e5c5 (GM)", "rapidgenius (GM)", "kingofblunders (GM)",
            "pawnpusher22 (GM)", "elochaser (GM)", "sicilianmaster (GM)", "caroCanDoIt (GM)", "timeflagger (GM)",
            "rookstorm (GM)", "swagbishop (GM)", "queenslayer77 (GM)", "checkmate21 (GM)", "pawntrapgod (GM)",
            "blitzcrafter (GM)", "tacticalguy (GM)", "stalemate404 (GM)", "chessmaster83 (GM)", "prophylaxis99 (GM)",
            "alphabrain (GM)", "endgamemaster (GM)", "tempoiskey (GM)", "rookrollin (GM)", "pawnwars (GM)",
            "bishop4life (GM)", "hangingpiece (GM)", "chesslover07 (GM)", "knightfall23 (GM)", "passpawnpls (GM)",
            "grindelo24 (GM)", "queensgambito (GM)", "kingchaser (GM)", "rookattack22 (GM)", "fischerwannabe (GM)",
            "nimzokid (GM)", "endgamewizard (GM)", "chessmonk (GM)", "flagmepls (GM)", "pawnspammer (GM)",
            "kingslayer99 (GM)", "matesomeone (GM)", "elohero88 (GM)", "kingcrusher13 (GM)", "rapidrookie (GM)",
            "grandswifty (GM)", "prodigychess (GM)", "whatthefork (GM)", "bishophustler (GM)", "boardwizard (GM)",
            "fianchetto94 (GM)", "stormrook (GM)", "notyourpawn (GM)", "tempohunter (GM)", "gambitguru (GM)",
            "sacqueen22 (GM)", "knightcrawler (GM)", "chessfanatic (GM)", "rooknroll (GM)", "passpawn24 (GM)",
            "forkmaster27 (GM)", "bishopattack99 (GM)", "chessvibes (GM)", "checkmatemaster (GM)", "kingsafetypls (GM)",
            "rapidslayer (GM)", "rookseeker (GM)", "matefound (GM)", "darkbishop12 (GM)", "eloeater44 (GM)",
            "queensrival (GM)", "kingchess45 (GM)", "timekiller99 (GM)", "boardking (GM)", "knightmoves4u (GM)",
            "rookchasers (GM)", "pawnkiller99 (GM)", "matehunter (GM)", "bishoptakesall (GM)", "flagitfast (GM)",
            "chessforever (GM)", "endgamemagic (GM)", "pawnmaster21 (GM)", "chesswinsyou (GM)", "eloendgame (GM)",
            "bishopfinesse (GM)", "pushpawnpls (GM)", "silentrook (GM)", "kingofsquares (GM)", "checkyourmoves (GM)",
            "notsofastgm (GM)", "queentrapgod (GM)", "elochaser23 (GM)", "rookieboss (GM)", "boardgrind99 (GM)", "GrandmasterGabe (GM)", "CheckmateCharlie (GM)", "KnightKnave (GM)", "RookRampage (GM)",
            "PawnPusher420 (GM)", "ChessFanatic91 (GM)", "StrategicSteve (GM)", "MateMaster77 (GM)",
            "BlitzBobby (GM)", "ProphylaxisPro (GM)", "KingSlayer08 (GM)", "EloHunter99 (GM)",
            "QueenCrusher (GM)", "SacForGlory (GM)", "TempoMaster (GM)", "EndgameAce (GM)",
            "DarkSquareMaster (GM)", "KnightLife22 (GM)", "PawnStorm77 (GM)", "RookTactician (GM)",
            "ChessWizard99 (GM)", "CheckmatePro (GM)", "FischerFury (GM)", "BoardKing (GM)",
            "FlaggingExpert (GM)", "TacticalLegend (GM)", "TempoChaser (GM)", "PassedPawnGod (GM)",
            "BlunderFree (GM)", "BishopBoss (GM)", "StalemateHunter (GM)", "KingSafety69 (GM)",
            "ChessAddict2024 (GM)", "RookRoller (GM)", "AlphaPawn (GM)", "EndgameLegend (GM)",
            "KnightKing42 (GM)", "GambitGuru (GM)", "EloSeeker22 (GM)", "ForkMaster99 (GM)",
            "TimeTroubleGM (GM)", "KingCrusher24 (GM)", "BlitzFrenzy (GM)", "SacrificeMaster (GM)",
            "PawnPromotion99 (GM)", "ChessChampion21 (GM)", "GrandmasterFlex (GM)", "KnightDreamer (GM)",
            "BlunderBeGone (GM)", "DarkHorseGM (GM)", "TempoWizard (GM)", "PassedPawnPro (GM)",
            "BishopSniper (GM)", "RapidGenius (GM)", "MateHunter88 (GM)", "FlaggingPapi (GM)",
            "RookSnatcher (GM)", "PawnWarlord (GM)", "SilentKnight (GM)", "TempoBandit (GM)",
            "EndgameWiz (GM)", "TacticsOverlord (GM)", "SwindleMaster (GM)", "MateFinder07 (GM)",
            "BlitzExpert (GM)", "BoardLegend (GM)", "PawnPusher69 (GM)", "DarkSquareGM (GM)",
            "KingOfBlunders (GM)", "CheckMateYo (GM)", "EloGoblin (GM)", "GambitGang (GM)",
            "Knightmare24 (GM)", "BackRankBandit (GM)", "EndgameSlayer (GM)", "RookMaster99 (GM)",
            "BlitzChad (GM)", "BoardSensei (GM)", "ChessSweat420 (GM)", "PawnStar44 (GM)",
            "BlunderSaver (GM)", "TacticsTyrant (GM)", "FlaggingDemon (GM)", "SacrificeDealer (GM)","EndgameAcePro (GM)",
        ]

        // Shuffle the usernames and take the first 40
        let randomUsernames = usernames.prefix(100)

        // Create leaderboard entries for the selected usernames
        return randomUsernames.enumerated().map { index, username in
            LeaderboardEntry(name: username, elo: 2550 + Int.random(in: 17...58))
        }
    }

}

struct ProgressBar: View {
    @Binding var bars: Int

    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                Rectangle()
                    .frame(width: 70, height: 30)
                    .cornerRadius(10)
                    .foregroundColor(index < bars ? .blue : .gray)
            }
        }
    }
}

struct LeaderboardView: View {
    let leaderboard: [LeaderboardEntry]
    let currentPlayer: String = UserDefaults.standard.string(forKey: "username") ?? "You (GM)"

    var body: some View {
        NavigationView {
            List(leaderboard) { entry in
                HStack {
                    Text(entry.name)
                        .font(entry.name.contains("You (GM)") ? .headline : .body)
                        .foregroundColor(entry.name.contains("You (GM)") ? .blue : .primary)
                    Spacer()
                    Text("\(entry.elo)")
                }
            }
            .navigationTitle("Global Elo Leaderboard")
        }
    }
}


