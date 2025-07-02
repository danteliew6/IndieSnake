import SwiftUI

struct ContentView: View {
    @StateObject private var game = SnakeGame()
    
    var body: some View {
        VStack {
            Text("Score: \(game.score)")
                .font(.title)
                .padding()
            ZStack {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                ForEach(game.snake, id: \.self) { segment in
                    Rectangle()
                        .frame(width: game.cellSize, height: game.cellSize)
                        .position(game.position(for: segment))
                        .foregroundColor(.green)
                }
                Rectangle()
                    .frame(width: game.cellSize, height: game.cellSize)
                    .position(game.position(for: game.food))
                    .foregroundColor(.red)
            }
            .frame(width: game.boardSize, height: game.boardSize)
            .gesture(DragGesture(minimumDistance: 10)
                .onEnded { value in
                    game.changeDirection(with: value)
                })
            if game.isGameOver {
                Text("Game Over!")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Button("Restart") {
                    game.restart()
                }
                .padding()
            }
        }
        .onAppear { game.start() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class SnakeGame: ObservableObject {
    @Published var snake: [CGPoint] = []
    @Published var food: CGPoint = .zero
    @Published var score = 0
    @Published var isGameOver = false
    
    let cellSize: CGFloat = 20
    let numRows = 20
    let numCols = 20
    var boardSize: CGFloat { cellSize * CGFloat(numRows) }
    
    private var direction: Direction = .right
    private var timer: Timer?
    
    enum Direction { case up, down, left, right }
    
    func start() {
        snake = [CGPoint(x: 10, y: 10)]
        direction = .right
        score = 0
        isGameOver = false
        spawnFood()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            self.move()
        }
    }
    
    func restart() {
        timer?.invalidate()
        start()
    }
    
    func move() {
        guard !isGameOver else { return }
        var newHead = snake[0]
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }
        // Check collisions
        if newHead.x < 0 || newHead.x >= CGFloat(numCols) || newHead.y < 0 || newHead.y >= CGFloat(numRows) || snake.contains(newHead) {
            isGameOver = true
            timer?.invalidate()
            return
        }
        snake.insert(newHead, at: 0)
        if newHead == food {
            score += 1
            spawnFood()
        } else {
            snake.removeLast()
        }
    }
    
    func spawnFood() {
        var newFood: CGPoint
        repeat {
            newFood = CGPoint(x: CGFloat(Int.random(in: 0..<numCols)), y: CGFloat(Int.random(in: 0..<numRows)))
        } while snake.contains(newFood)
        food = newFood
    }
    
    func changeDirection(with value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        if abs(horizontal) > abs(vertical) {
            if horizontal > 0 && direction != .left { direction = .right }
            else if horizontal < 0 && direction != .right { direction = .left }
        } else {
            if vertical > 0 && direction != .up { direction = .down }
            else if vertical < 0 && direction != .down { direction = .up }
        }
    }
    
    func position(for point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x + 0.5) * cellSize, y: (point.y + 0.5) * cellSize)
    }
}
