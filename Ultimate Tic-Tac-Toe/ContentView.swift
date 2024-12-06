
import SwiftUI

struct ContentView: View {
    @State private var gameMode: GameMode? = nil
    @State private var currentImageIndex = 1 // Start with screen1
    private let imageCount = 12 // Total number of images
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Ultimate Tic Tac Toe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Made By Edison Law and Revaant Srivastav")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Image("screen \(currentImageIndex+9)")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .onReceive(timer) { _ in
                     
                            currentImageIndex = (currentImageIndex % imageCount) + 1 // Cycle through images
               
                    }
                
                Button(action: {}) {
                    NavigationLink(destination: OnlineView()) {
                        Text("Play Ranked Online")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }




                
                NavigationLink(destination: GameView(isBot: true), tag: .bot, selection: $gameMode) {
                    Button(action: {
                        gameMode = .bot
                    }) {
                        Text("Play Against Bot")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                NavigationLink(destination: GameView(isBot: false), tag: .twoPlayer, selection: $gameMode) {
                    Button(action: {
                        gameMode = .twoPlayer
                    }) {
                        Text("2 Player Mode")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray4)).ignoresSafeArea()
        }
    }
}

enum GameMode {
    case bot, twoPlayer
}

struct GameView: View {
    let isBot: Bool
    @State private var board = Array(repeating: Array(repeating: "", count: 9), count: 9)
    @State private var activePlayer = "X"
    @State private var subBoardIndex: Int? = nil // Tracks which sub-board is active
    @State private var mainBoard = Array(repeating: "", count: 9)
    @State private var winner: String? = nil // Tracks the winner of the game

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
                                SubBoardView(
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

            Button("Restart") {
                resetGame()
            }
            .padding(10)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(20)
        .background(Color(UIColor.systemGray4)).ignoresSafeArea()
    }
    
    
    private func checkWin(_ board: [String]) -> Bool {
        let winPatterns: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        return winPatterns.contains { pattern in
            pattern.allSatisfy { board[$0] == activePlayer }
        }
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
            return // End the game here
        }

        // Determine next active sub-board
        if board[subIndex].allSatisfy({ !$0.isEmpty }) || mainBoard[subIndex] != "" {
            // If the next sub-board is full or captured, allow any move
            subBoardIndex = nil
        } else {
            // Otherwise, set the next sub-board
            subBoardIndex = subIndex
        }

        // Switch active player
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
        guard winner == nil else { return } // Skip if there's a winner

        func findWinningMove(for player: String, in subBoard: [String]) -> Int? {
            let winningPatterns = [
                [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
                [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
                [0, 4, 8], [2, 4, 6]             // Diagonals
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

        // Bot plays in the specified sub-board if it is active and available
        if let activeSubBoard = subBoardIndex, mainBoard[activeSubBoard].isEmpty {
            // Winning move (always prioritize winning a mini-board, even if unsafe)
            if let winningSlot = findWinningMove(for: "O", in: board[activeSubBoard]) {
                handleMove(activeSubBoard, winningSlot)
                return
            }

            // Block opponent's win
            if let blockingSlot = findWinningMove(for: "X", in: board[activeSubBoard]), !wouldSendPlayerToWinningMove(activeSubBoard, blockingSlot) {
                handleMove(activeSubBoard, blockingSlot)
                return
            }

            // Strategic safe move
            let safeMoves = getSafeMoves(activeSubBoard)
            if let bestSlot = safeMoves.first {
                handleMove(activeSubBoard, bestSlot)
                return
            }

            // If all moves are unsafe, fallback to any legal move in the active sub-board
            if let fallbackSlot = getFallbackMove(activeSubBoard) {
                handleMove(activeSubBoard, fallbackSlot)
                return
            }
        }

        // If no active sub-board or the active sub-board is unavailable, choose freely
        let availableBoards = board.enumerated().filter { mainBoard[$0.offset].isEmpty }.map { $0.offset }
        for boardIndex in availableBoards {
            // Winning move (always prioritize winning a mini-board, even if unsafe)
            if let winningSlot = findWinningMove(for: "O", in: board[boardIndex]) {
                handleMove(boardIndex, winningSlot)
                return
            }

            // Block opponent's win
            if let blockingSlot = findWinningMove(for: "X", in: board[boardIndex]), !wouldSendPlayerToWinningMove(boardIndex, blockingSlot) {
                handleMove(boardIndex, blockingSlot)
                return
            }

            // Strategic safe move
            let safeMoves = getSafeMoves(boardIndex)
            if let bestSlot = safeMoves.first {
                handleMove(boardIndex, bestSlot)
                return
            }
        }

        // If all moves are unsafe, fallback to a random valid move
        if let randomBoard = availableBoards.randomElement(), let fallbackSlot = getFallbackMove(randomBoard) {
            handleMove(randomBoard, fallbackSlot)
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

struct SubBoardView: View {
    @Binding var subBoard: [String]
    let isCaptured: String
    let isActive: Bool
    let player: String
    let onMove: (Int) -> Void

    var body: some View {
        VStack(spacing: 2) {
            if !isCaptured.isEmpty {
                Text(isCaptured)
                    .font(.system(size: 100)) // Larger font size
                    .fontWeight(.bold) // Make it bold
                    .foregroundColor(isCaptured == "X" ? .blue : .red)
                    .frame(width: 94, height: 94) // Adjust the frame to accommodate the larger font
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
                                .foregroundColor(subBoard[index] == "X" ? Color.blue.opacity(1) : (subBoard[index] == "O" ? Color.red.opacity(1) : .black)) // Softer colors
                                .frame(width: 30, height: 30)
                                .background(isActive && subBoard[index].isEmpty ? Color.green.opacity(0.5) : Color.gray.opacity(0.3)) // Softer backgrounds
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
