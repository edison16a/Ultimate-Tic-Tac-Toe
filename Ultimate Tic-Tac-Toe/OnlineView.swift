import SwiftUI

// MARK: - GameView2

struct GameView2: View {
    let isBot: Bool
    var onFinishMatch: (String?) -> Void // Callback to notify OnlineView when match finishes
    let rank: String // Pass current rank to decide bot strategy

    @State private var board = Array(repeating: Array(repeating: "", count: 9), count: 9)
    @State private var activePlayer = "X"
    @State private var subBoardIndex: Int? = nil
    @State private var mainBoard = Array(repeating: "", count: 9)
    @State private var winner: String? = nil

    var body: some View {
        VStack {
            Text("Ultimate Tic Tac Toe")
                .font(.largeTitle)
                .padding()

            if let winner = winner {
                Text("\(winner) Wins!")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding()
            } else {
                VStack(spacing: 5) {
                    ForEach(0..<3) { bigRow in
                        HStack(spacing: 5) {
                            ForEach(0..<3) { bigCol in
                                SubBoardView2(
                                    subBoard: $board[bigRow * 3 + bigCol],
                                    isCaptured: mainBoard[bigRow * 3 + bigCol],
                                    isActive: subBoardIndex == nil || subBoardIndex == (bigRow * 3 + bigCol),
                                    player: activePlayer,
                                    onMove: { subIndex in
                                        handleMove(bigRow * 3 + bigCol, subIndex)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }

            Button("Forfeit") {
                forfeitGame()
            }
            .padding(10)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(20)
        .background(Color(UIColor.systemGray4))
        .ignoresSafeArea()
    }
    private func forfeitGame() {
        onFinishMatch("O") // Pass `nil` to signal a forfeit
    }
    private func handleMove(_ bigIndex: Int, _ subIndex: Int) {
        guard board[bigIndex][subIndex].isEmpty else { return }

        board[bigIndex][subIndex] = activePlayer

        // Check if the player wins this sub-board
        if checkWin(board[bigIndex]) {
            mainBoard[bigIndex] = activePlayer
        }

        // Check if the main game is won
        if checkWin(mainBoard) {
            winner = activePlayer
            onFinishMatch(winner) // Notify OnlineView of the match result
            return
        }

        // Determine next active sub-board
        if board[subIndex].allSatisfy({ !$0.isEmpty }) || mainBoard[subIndex] != "" {
            subBoardIndex = nil
        } else {
            subBoardIndex = subIndex
        }

        // Switch active player or trigger bot
        if isBot && activePlayer == "X" {
            activePlayer = "O"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                botMove()
            }
        } else {
            activePlayer = activePlayer == "X" ? "O" : "X"
        }
    }

    private func botMove() {
        guard winner == nil else { return }

        if rank == "Silver" || rank == "Bronze" {
            randomBotMove()
        } else {
            intelligentBotMove()
        }
    }

    private func randomBotMove() {
        if let activeSubBoard = subBoardIndex, mainBoard[activeSubBoard].isEmpty {
            let availableSlots = board[activeSubBoard].enumerated().filter { $0.element.isEmpty }.map { $0.offset }
            if let randomSlot = availableSlots.randomElement() {
                handleMove(activeSubBoard, randomSlot)
                return
            }
        } else {
            let availableBoards = board.enumerated().filter { mainBoard[$0.offset].isEmpty }.map { $0.offset }
            if let randomBoard = availableBoards.randomElement() {
                let availableSlots = board[randomBoard].enumerated().filter { $0.element.isEmpty }.map { $0.offset }
                if let randomSlot = availableSlots.randomElement() {
                    handleMove(randomBoard, randomSlot)
                    return
                }
            }
        }
    }

    private func intelligentBotMove() {
        func findWinningMove(for player: String, in subBoard: [String]) -> Int? {
            let winningPatterns = [
                [0, 1, 2], [3, 4, 5], [6, 7, 8],
                [0, 3, 6], [1, 4, 7], [2, 5, 8],
                [0, 4, 8], [2, 4, 6]
            ]
            for pattern in winningPatterns {
                let values = pattern.map { subBoard[$0] }
                if values.filter({ $0 == player }).count == 2 && values.contains("") {
                    return pattern.first { subBoard[$0].isEmpty }
                }
            }
            return nil
        }

        func findBestMove(in subBoard: [String]) -> Int? {
            let corners = [0, 2, 6, 8], edges = [1, 3, 5, 7]
            for position in corners where subBoard[position].isEmpty {
                return position
            }
            for position in edges where subBoard[position].isEmpty {
                return position
            }
            return nil
        }

        func wouldSendPlayerToWinningMove(_ boardIndex: Int, _ slotIndex: Int) -> Bool {
            let nextSubBoard = slotIndex
            guard mainBoard[nextSubBoard].isEmpty else { return false }
            return findWinningMove(for: "X", in: board[nextSubBoard]) != nil
        }

        func getSafeMoves(_ boardIndex: Int) -> [Int] {
            return board[boardIndex].enumerated()
                .filter { $0.element.isEmpty && !wouldSendPlayerToWinningMove(boardIndex, $0.offset) }
                .map { $0.offset }
        }

        func getFallbackMove(_ boardIndex: Int) -> Int? {
            return board[boardIndex].enumerated()
                .filter { $0.element.isEmpty }
                .map { $0.offset }
                .randomElement()
        }

        if let activeSubBoard = subBoardIndex, mainBoard[activeSubBoard].isEmpty {
            if let winningSlot = findWinningMove(for: "O", in: board[activeSubBoard]) {
                handleMove(activeSubBoard, winningSlot)
                return
            }
            if let blockingSlot = findWinningMove(for: "X", in: board[activeSubBoard]), !wouldSendPlayerToWinningMove(activeSubBoard, blockingSlot) {
                handleMove(activeSubBoard, blockingSlot)
                return
            }
            let safeMoves = getSafeMoves(activeSubBoard)
            if let bestSlot = safeMoves.first {
                handleMove(activeSubBoard, bestSlot)
                return
            }
            if let fallbackSlot = getFallbackMove(activeSubBoard) {
                handleMove(activeSubBoard, fallbackSlot)
                return
            }
        }

        let availableBoards = board.enumerated().filter { mainBoard[$0.offset].isEmpty }.map { $0.offset }
        for boardIndex in availableBoards {
            if let winningSlot = findWinningMove(for: "O", in: board[boardIndex]) {
                handleMove(boardIndex, winningSlot)
                return
            }
            if let blockingSlot = findWinningMove(for: "X", in: board[boardIndex]), !wouldSendPlayerToWinningMove(boardIndex, blockingSlot) {
                handleMove(boardIndex, blockingSlot)
                return
            }
            let safeMoves = getSafeMoves(boardIndex)
            if let bestSlot = safeMoves.first {
                handleMove(boardIndex, bestSlot)
                return
            }
        }

        if let randomBoard = availableBoards.randomElement(), let fallbackSlot = getFallbackMove(randomBoard) {
            handleMove(randomBoard, fallbackSlot)
        }
    }

    private func checkWin(_ board: [String]) -> Bool {
        let winPatterns: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [2, 4, 6]
        ]
        return winPatterns.contains { pattern in
            pattern.allSatisfy { board[$0] == activePlayer }
        }
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: "", count: 9), count: 9)
        activePlayer = "X"
        subBoardIndex = nil
        mainBoard = Array(repeating: "", count: 9)
        winner = nil
    }
}

// MARK: - SubBoardView2

struct SubBoardView2: View {
    @Binding var subBoard: [String]
    let isCaptured: String
    let isActive: Bool
    let player: String
    let onMove: (Int) -> Void

    var body: some View {
        VStack(spacing: 2) {
            if !isCaptured.isEmpty {
                Text(isCaptured)
                    .font(.system(size: 100))
                    .fontWeight(.bold)
                    .foregroundColor(isCaptured == "X" ? .blue : .red)
                    .frame(width: 94, height: 94)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
            } else {
                ForEach(0..<3) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<3) { col in
                            let index = row * 3 + col
                            Text(subBoard[index])
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(subBoard[index] == "X" ? .blue : (subBoard[index] == "O" ? .red : .black))
                                .frame(width: 30, height: 30)
                                .background(isActive && subBoard[index].isEmpty ? Color.green.opacity(0.5) : Color.gray.opacity(0.3))
                                .cornerRadius(5)
                                .onTapGesture {
                                    if isActive && subBoard[index].isEmpty {
                                        onMove(index)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding(5)
        .background(Color.black)
        .cornerRadius(10)
    }
}

// MARK: - OnlineView

struct OnlineView: View {
    @State private var rank: String = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
    @State private var bars: Int = UserDefaults.standard.integer(forKey: "bars")
    @State private var elo: Int = UserDefaults.standard.integer(forKey: "elo")
    @State private var inMatchmaking: Bool = false
    @State private var inMatch: Bool = false
    @State private var showLeaderboard: Bool = false
    @State private var leaderboard: [LeaderboardEntry] = LeaderboardEntry.mockLeaderboard()
    @State private var timer = Timer.publish(every: Double.random(in: 10...25), on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack {
                Text("Rank: \(rank)")
                    .font(.title)
                    .padding()

                Image(rank.lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .padding()

                if rank != "Champion" {
                    ProgressBar(bars: $bars)
                        .padding()
                } else {
                    Text("Elo: \(elo)")
                        .font(.largeTitle)
                        .padding()
                }

                Text("Gain 1 bar each win. Reach 3 to increase your rank. After reaching max rank (Champion), you will have an Elo (your rating) and can get on the leaderboard.\n Reach 1800 Elo to attain the Grandmaster (GM) title")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()

                if rank == "Champion" {
                    Text("Current Global Elo Rank: \(calculateGlobalRank(userElo: elo, leaderboard: leaderboard))")
                        .font(.headline)
                        .padding()
                }

                if inMatchmaking {
                    VStack {
                        Text("Matchmaking...")
                            .font(.headline)
                            .padding()

                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    }
                } else if inMatch {
                    GameView2(isBot: true, onFinishMatch: { winner in
                        finishMatch(winner: winner)
                    }, rank: rank)
                    .onDisappear {
                        inMatch = false
                    }
                } else {
                    Button("Play Ranked Match") {
                        startMatchmaking()
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
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
                loadProgress()
            }
            .background(Color(UIColor.systemGray4))
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                updateLeaderboard()
            }
        }
    }

    private func startMatchmaking() {
        inMatchmaking = true
        let delay: Double
        switch rank {
        case "Bronze": delay = Double.random(in: 2...4)
        case "Silver": delay = Double.random(in: 3...5)
        case "Gold": delay = Double.random(in: 4...6)
        case "Platinum": delay = Double.random(in: 5...7)
        case "Diamond": delay = Double.random(in: 6...8)
        case "Champion": delay = Double.random(in: 2...9)
        default: delay = Double.random(in: 2...4)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            inMatchmaking = false
            inMatch = true
        }
    }

    private func finishMatch(winner: String?) {
        if let winner = winner {
            if winner == "X" {
                if rank == "Champion" {
                    elo += Int.random(in: 41...53)
                } else {
                    bars += 1
                    if bars >= 3 {
                        rankUp()
                    }
                }
            } else if winner == "O" {
                if rank == "Champion" {
                    elo = max(elo - Int.random(in: 89...114), 0)
                } else {
                    if rank != "Bronze" {
                        bars -= 1
                        if bars < 0 {
                            rankDown()
                        }
                    } else if bars > 0 {
                        bars -= 1
                    }
                }
            }
        }
        saveProgress()
        inMatch = false
    }

    private func rankUp() {
        switch rank {
        case "Bronze": rank = "Silver"
        case "Silver": rank = "Gold"
        case "Gold": rank = "Platinum"
        case "Platinum": rank = "Diamond"
        case "Diamond":
            rank = "Champion"
            elo = max(elo, 1000)
            bars = 0
        default:
            rank = "Champion"
            elo = max(elo, 1000)
            bars = 0
        }
    }

    private func rankDown() {
        switch rank {
        case "Silver": rank = "Bronze"
        case "Gold": rank = "Silver"
        case "Platinum": rank = "Gold"
        case "Diamond": rank = "Platinum"
        case "Champion":
            rank = "Diamond"
            elo = max(elo - Int.random(in: 76...104), 0)
        default: break
        }
    }

    private func calculateGlobalRank(userElo: Int, leaderboard: [LeaderboardEntry]) -> Int {
        let topElo = 2681
        let eloStep = 1
        if leaderboard.contains(where: { $0.elo == userElo }) {
            return leaderboard.firstIndex(where: { $0.elo == userElo })! + 1
        } else {
            return (topElo - userElo) / eloStep + 11
        }
    }

    private func saveProgress() {
        UserDefaults.standard.set(rank, forKey: "rank")
        UserDefaults.standard.set(bars, forKey: "bars")
        UserDefaults.standard.set(elo, forKey: "elo")
    }

    private func loadProgress() {
        // Load rank and bars from UserDefaults
        rank = UserDefaults.standard.string(forKey: "rank") ?? "Bronze"
        bars = UserDefaults.standard.integer(forKey: "bars")
        
        // Check if Elo exists in UserDefaults, otherwise initialize
        if UserDefaults.standard.object(forKey: "elo") == nil {
            if rank == "Champion" {
                elo = 1000 // Set initial Elo for Champion
            } else {
                elo = 0 // Default for other ranks
            }
            UserDefaults.standard.set(elo, forKey: "elo") // Save the initial Elo
        } else {
            elo = UserDefaults.standard.integer(forKey: "elo") // Load saved Elo
        }
    }

    private func updateLeaderboard() {
        leaderboard = leaderboard.map { entry in
            var updatedEntry = entry
            updatedEntry.elo += Int.random(in: -1...5)
            return updatedEntry
        }
        leaderboard.sort { $0.elo > $1.elo }
    }
}

// MARK: - ProgressBar

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

// MARK: - LeaderboardView

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

// MARK: - LeaderboardEntry

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
                    "notsofastgm (GM)", "queentrapgod (GM)", "elochaser23 (GM)", "rookieboss (GM)", "boardgrind99 (GM)",
                    "GrandmasterGabe (GM)", "CheckmateCharlie (GM)", "KnightKnave (GM)", "RookRampage (GM)",
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
                    "BlunderSaver (GM)", "TacticsTyrant (GM)", "FlaggingDemon (GM)", "SacrificeDealer (GM)",
                    "EndgameAcePro (GM)",
                ]

        let randomUsernames = usernames.prefix(15)

        return randomUsernames.enumerated().map { index, username in
            LeaderboardEntry(name: username, elo: 2550 + Int.random(in: 17...58))
        }
    }
}
